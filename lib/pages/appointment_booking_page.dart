import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/doctor.dart';
import '../models/appointment.dart';
import '../models/payment_method.dart';

class AppointmentBookingPage extends StatefulWidget {
  final Doctor doctor;

  const AppointmentBookingPage({super.key, required this.doctor});

  @override
  State<AppointmentBookingPage> createState() => _AppointmentBookingPageState();
}

class _AppointmentBookingPageState extends State<AppointmentBookingPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late DateTime _currentMonth;
  final int _monthsToShow = 3;

  Map<String, List<String>> _availableSlots = {};
  Map<String, bool> _dateAvailability = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _initializeAvailability();
  }

  Future<void> _initializeAvailability() async {
    setState(() => _isLoading = true);

    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month + _monthsToShow, now.day);

    // Inicializar todos los días como disponibles por defecto
    for (int i = 0; i < (endDate.difference(now).inDays + 1); i++) {
      final date = now.add(Duration(days: i));
      final dateKey = _getDateKey(date);
      _dateAvailability[dateKey] = true;
    }

    await _loadAvailability();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAvailability() async {
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month + _monthsToShow, now.day);

    // Obtener TODAS las citas del doctor en una sola consulta
    final dateStart = DateTime(now.year, now.month, now.day);
    final dateEnd = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final allAppointments = await _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: widget.doctor.id)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateStart))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(dateEnd))
        .get();

    // Agrupar citas por fecha
    Map<String, List<Appointment>> appointmentsByDate = {};
    for (var doc in allAppointments.docs) {
      final appointment = Appointment.fromMap(doc.data(), doc.id);
      final dateKey = _getDateKey(appointment.date);
      appointmentsByDate.putIfAbsent(dateKey, () => []).add(appointment);
    }

    // Calcular slots disponibles para cada día
    for (int i = 0; i < (endDate.difference(now).inDays + 1); i++) {
      final date = now.add(Duration(days: i));
      final dateKey = _getDateKey(date);
      final dayAppointments = appointmentsByDate[dateKey] ?? [];

      final slots = _calculateAvailableSlotsForDate(date, dayAppointments);
      _availableSlots[dateKey] = slots;
      _dateAvailability[dateKey] = slots.isNotEmpty;
    }

    if (mounted) setState(() {});
  }

  List<String> _calculateAvailableSlotsForDate(DateTime date, List<Appointment> appointments) {
    // No permitir fechas pasadas
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck.isBefore(todayStart)) {
      return [];
    }

    // Horario de trabajo del doctor (8am - 4pm = 8 horas)
    const startHour = 8;
    const endHour = 16;

    // Crear lista de horarios disponibles
    List<String> availableSlots = [];
    Set<int> bookedHours = {};

    // Marcar horas ocupadas según las citas existentes
    for (var appointment in appointments) {
      final hour = int.parse(appointment.startTime.split(':')[0]);
      for (int i = 0; i < appointment.durationHours; i++) {
        bookedHours.add(hour + i);
      }
    }

    // Generar slots disponibles para todas las horas del día
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
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildDoctorInfo(),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildCalendar(),
                  ),
                ),
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
                    final availableSlots = _availableSlots[dateKey] ?? [];
                    final isAvailable = availableSlots.isNotEmpty;

                    return GestureDetector(
                      onTap: isPast || !isAvailable
                          ? null
                          : () => _showTimeSelectionDialog(date),
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isPast
                              ? Colors.grey[200]
                              : isAvailable
                                  ? Colors.green[100]
                                  : Colors.red[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            dayNumber.toString(),
                            style: TextStyle(
                              color: isPast ? Colors.grey[400] : Colors.black,
                              fontWeight: FontWeight.normal,
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

  bool _hasConsecutiveSlots(List<String> slots, int startHour, int duration) {
    for (int i = 0; i < duration; i++) {
      final requiredHour = startHour + i;
      final requiredTime = '${requiredHour.toString().padLeft(2, '0')}:00';
      if (!slots.contains(requiredTime)) {
        return false;
      }
    }
    return true;
  }

  Future<void> _showTimeSelectionDialog(DateTime selectedDate) async {
    final dateKey = _getDateKey(selectedDate);
    final slots = _availableSlots[dateKey] ?? [];

    if (slots.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay horarios disponibles para esta fecha'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String? selectedTime;
    int selectedDuration = 1;

    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Agendar Cita - ${_getDateString(selectedDate)}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Doctor: ${widget.doctor.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Selecciona un horario:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: slots.map((time) {
                        final isSelected = selectedTime == time;
                        final hour = int.parse(time.split(':')[0]);
                        final hasEnoughSlots = _hasConsecutiveSlots(slots, hour, selectedDuration);

                        return ChoiceChip(
                          label: Text(time),
                          selected: isSelected,
                          onSelected: hasEnoughSlots
                              ? (selected) {
                                  setDialogState(() {
                                    selectedTime = selected ? time : null;
                                  });
                                }
                              : null,
                          selectedColor: Colors.blue,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : hasEnoughSlots
                                    ? Colors.black
                                    : Colors.grey,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Duración de la cita:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('1 hora'),
                          selected: selectedDuration == 1,
                          onSelected: (selected) {
                            setDialogState(() {
                              selectedDuration = 1;
                              if (selectedTime != null) {
                                final hour = int.parse(selectedTime!.split(':')[0]);
                                if (!_hasConsecutiveSlots(slots, hour, selectedDuration)) {
                                  selectedTime = null;
                                }
                              }
                            });
                          },
                          selectedColor: Colors.blue,
                          labelStyle: TextStyle(
                            color: selectedDuration == 1 ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('2 horas'),
                          selected: selectedDuration == 2,
                          onSelected: (selected) {
                            setDialogState(() {
                              selectedDuration = 2;
                              if (selectedTime != null) {
                                final hour = int.parse(selectedTime!.split(':')[0]);
                                if (!_hasConsecutiveSlots(slots, hour, selectedDuration)) {
                                  selectedTime = null;
                                }
                              }
                            });
                          },
                          selectedColor: Colors.blue,
                          labelStyle: TextStyle(
                            color: selectedDuration == 2 ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    if (selectedTime != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total a pagar:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '\$${(widget.doctor.pricePerAppointment * selectedDuration).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: selectedTime != null
                      ? () {
                          Navigator.pop(dialogContext, {
                            'time': selectedTime,
                            'duration': selectedDuration,
                          });
                        }
                      : null,
                  child: const Text('Confirmar Cita'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      await _showPaymentMethodDialog(selectedDate, result['time'], result['duration']);
    }
  }

  Future<void> _showPaymentMethodDialog(DateTime date, String time, int duration) async {
    if (!mounted) return;

    final result = await showDialog<PaymentType>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Cita'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Selecciona el método de pago:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              _buildSimplePaymentOption(
                dialogContext,
                icon: Icons.credit_card,
                title: 'Tarjeta',
                onTap: () => Navigator.pop(dialogContext, PaymentType.creditCard),
              ),
              const SizedBox(height: 10),
              _buildSimplePaymentOption(
                dialogContext,
                icon: Icons.paypal,
                title: 'PayPal',
                onTap: () => Navigator.pop(dialogContext, PaymentType.paypal),
              ),
              const SizedBox(height: 10),
              _buildSimplePaymentOption(
                dialogContext,
                icon: Icons.account_balance,
                title: 'Transferencia',
                onTap: () => Navigator.pop(dialogContext, PaymentType.bankTransfer),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      await _processPayment(result, date, time, duration);
    }
  }

  Widget _buildSimplePaymentOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Colors.blue[700]),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.blue[700]),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment(PaymentType paymentType, DateTime date, String time, int duration) async {
    if (!mounted) return;

    // Guardar el appointment directamente
    try {
      await _bookAppointment(date, time, duration, paymentType);

      if (!mounted) return;

      // Mostrar confirmación simple
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
          title: const Text('¡Cita Agendada!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tu cita ha sido reservada exitosamente.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Fecha: ${_getDateString(date)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Hora: $time',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Duración: $duration ${duration == 1 ? 'hora' : 'horas'}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al agendar la cita: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getPaymentTypeName(PaymentType type) {
    switch (type) {
      case PaymentType.creditCard:
        return 'Tarjeta de Crédito';
      case PaymentType.paypal:
        return 'PayPal';
      case PaymentType.bankTransfer:
        return 'Transferencia Bancaria';
    }
  }

  Future<void> _bookAppointment(DateTime date, String time, int duration, PaymentType paymentType) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final appointment = Appointment(
      id: '',
      doctorId: widget.doctor.id,
      patientId: user.uid,
      date: date,
      startTime: time,
      durationHours: duration,
      price: widget.doctor.pricePerAppointment * duration,
      paymentMethod: paymentType.toString().split('.').last,
    );

    await _firestore.collection('appointments').add(appointment.toMap());

    if (!mounted) return;

    // Recargar disponibilidad
    await _loadAvailability();
  }

  String _getDateString(DateTime date) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]} ${date.year}';
  }

  String _getMonthName(DateTime date) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
