import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/doctor.dart';
import '../models/appointment.dart';

class AppointmentBookingPage extends StatefulWidget {
  final Doctor doctor;

  const AppointmentBookingPage({super.key, required this.doctor});

  @override
  State<AppointmentBookingPage> createState() => _AppointmentBookingPageState();
}

class _AppointmentBookingPageState extends State<AppointmentBookingPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime? _selectedDate;
  String? _selectedTime;
  int _selectedDuration = 1;

  late DateTime _currentMonth;
  final int _monthsToShow = 3;

  Map<String, List<String>> _availableSlots = {};
  Map<String, bool> _dateAvailability = {};

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month + _monthsToShow, now.day);

    for (int i = 0; i < (endDate.difference(now).inDays + 1); i++) {
      final date = now.add(Duration(days: i));
      final dateKey = _getDateKey(date);

      final slots = await _getAvailableSlotsForDate(date);
      _availableSlots[dateKey] = slots;
      _dateAvailability[dateKey] = slots.isNotEmpty;
    }

    if (mounted) setState(() {});
  }

  Future<List<String>> _getAvailableSlotsForDate(DateTime date) async {
    // Obtener el horario del doctor (por defecto 8am - 4pm)
    final startHour = 8;
    final endHour = 16;

    // Obtener citas existentes para este día
    final dateStart = DateTime(date.year, date.month, date.day);
    final dateEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final appointments = await _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: widget.doctor.id)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateStart))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(dateEnd))
        .get();

    // Crear lista de horarios disponibles
    List<String> availableSlots = [];
    Set<int> bookedHours = {};

    // Marcar horas ocupadas
    for (var doc in appointments.docs) {
      final appointment = Appointment.fromMap(doc.data(), doc.id);
      final hour = int.parse(appointment.startTime.split(':')[0]);
      for (int i = 0; i < appointment.durationHours; i++) {
        bookedHours.add(hour + i);
      }
    }

    // Generar slots disponibles
    for (int hour = startHour; hour < endHour; hour++) {
      if (!bookedHours.contains(hour)) {
        final timeStr = '${hour.toString().padLeft(2, '0')}:00';
        availableSlots.add(timeStr);
      }
    }

    return availableSlots;
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agendar Cita - ${widget.doctor.name}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          _buildDoctorInfo(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildCalendar(),
                  if (_selectedDate != null) _buildTimeSlots(),
                  if (_selectedTime != null) _buildDurationSelector(),
                ],
              ),
            ),
          ),
          if (_selectedDate != null && _selectedTime != null)
            _buildBookButton(),
        ],
      ),
    );
  }

  Widget _buildDoctorInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue[50],
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue[100],
            child: Icon(Icons.person, size: 30, color: Colors.blue[700]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctor.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.doctor.title,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${widget.doctor.pricePerAppointment.toStringAsFixed(2)}/hora',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Selecciona una fecha',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ...List.generate(_monthsToShow, (monthIndex) {
          final month = DateTime(_currentMonth.year, _currentMonth.month + monthIndex, 1);
          return _buildMonthCalendar(month);
        }),
      ],
    );
  }

  Widget _buildMonthCalendar(DateTime month) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstDayOfWeek = DateTime(month.year, month.month, 1).weekday;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            _getMonthName(month),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                    .map((day) => SizedBox(
                          width: 40,
                          child: Text(
                            day,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              ...List.generate((daysInMonth + firstDayOfWeek - 1) ~/ 7 + 1, (weekIndex) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (dayIndex) {
                    final dayNumber = weekIndex * 7 + dayIndex - firstDayOfWeek + 2;
                    if (dayNumber < 1 || dayNumber > daysInMonth) {
                      return const SizedBox(width: 40, height: 40);
                    }

                    final date = DateTime(month.year, month.month, dayNumber);
                    final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
                    final dateKey = _getDateKey(date);
                    final isAvailable = _dateAvailability[dateKey] ?? false;
                    final isSelected = _selectedDate != null &&
                        date.year == _selectedDate!.year &&
                        date.month == _selectedDate!.month &&
                        date.day == _selectedDate!.day;

                    return GestureDetector(
                      onTap: isPast || !isAvailable
                          ? null
                          : () {
                              setState(() {
                                _selectedDate = date;
                                _selectedTime = null;
                              });
                            },
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isPast
                              ? Colors.grey[200]
                              : isSelected
                                  ? Colors.blue
                                  : isAvailable
                                      ? Colors.green[100]
                                      : Colors.red[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            dayNumber.toString(),
                            style: TextStyle(
                              color: isPast
                                  ? Colors.grey[400]
                                  : isSelected
                                      ? Colors.white
                                      : Colors.black,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTimeSlots() {
    final dateKey = _getDateKey(_selectedDate!);
    final slots = _availableSlots[dateKey] ?? [];

    if (slots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No hay horarios disponibles para esta fecha'),
      );
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Selecciona una hora',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: slots.map((time) {
              final isSelected = _selectedTime == time;
              return ChoiceChip(
                label: Text(time),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedTime = selected ? time : null;
                  });
                },
                selectedColor: Colors.blue,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDurationSelector() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Duración de la cita',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('1 hora'),
                selected: _selectedDuration == 1,
                onSelected: (selected) {
                  setState(() {
                    _selectedDuration = 1;
                  });
                },
                selectedColor: Colors.blue,
                labelStyle: TextStyle(
                  color: _selectedDuration == 1 ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('2 horas'),
                selected: _selectedDuration == 2,
                onSelected: (selected) {
                  setState(() {
                    _selectedDuration = 2;
                  });
                },
                selectedColor: Colors.blue,
                labelStyle: TextStyle(
                  color: _selectedDuration == 2 ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBookButton() {
    final totalPrice = widget.doctor.pricePerAppointment * _selectedDuration;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total a pagar:',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  '\$${totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _bookAppointment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Confirmar Cita',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _bookAppointment() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final appointment = Appointment(
        id: '',
        doctorId: widget.doctor.id,
        patientId: user.uid,
        date: _selectedDate!,
        startTime: _selectedTime!,
        durationHours: _selectedDuration,
        price: widget.doctor.pricePerAppointment * _selectedDuration,
      );

      await _firestore.collection('appointments').add(appointment.toMap());

      messenger.showSnackBar(
        const SnackBar(
          content: Text('¡Cita agendada exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );

      navigator.pop();
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error al agendar cita: $e')),
      );
    }
  }

  String _getMonthName(DateTime date) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
