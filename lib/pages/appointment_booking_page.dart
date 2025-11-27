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

class _AppointmentBookingPageState extends State<AppointmentBookingPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late TabController _tabController;
  bool _isLoading = true;
  Map<String, List<String>> _availableSlots = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAvailableSlots();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableSlots() async {
    setState(() => _isLoading = true);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // Cargar slots para hoy y mañana
    await _loadSlotsForDate(today, 'today');
    await _loadSlotsForDate(tomorrow, 'tomorrow');

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSlotsForDate(DateTime date, String key) async {
    final dateEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final appointments =
        await _firestore
            .collection('appointments')
            .where('doctorId', isEqualTo: widget.doctor.id)
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(date))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(dateEnd))
            .get();

    final bookedSlots = <String>{};
    for (var doc in appointments.docs) {
      final appointment = Appointment.fromMap(doc.data(), doc.id);
      bookedSlots.add(appointment.startTime);
    }

    // Generar slots de 15 minutos desde las 8:00 AM hasta las 10:00 PM
    final slots = <String>[];
    for (int hour = 8; hour < 22; hour++) {
      for (int minute = 0; minute < 60; minute += 15) {
        final timeStr =
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

        // Si es hoy, solo mostrar slots futuros
        if (key == 'today') {
          final now = DateTime.now();
          final slotTime = DateTime(
            date.year,
            date.month,
            date.day,
            hour,
            minute,
          );
          if (slotTime.isAfter(now) && !bookedSlots.contains(timeStr)) {
            slots.add(timeStr);
          }
        } else if (!bookedSlots.contains(timeStr)) {
          slots.add(timeStr);
        }
      }
    }

    _availableSlots[key] = slots;
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${hour12.toString().padLeft(2, '0')}:$minute\n$period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  children: [
                    // Video Consultation Card
                    _buildConsultationCard(
                      icon: Icons.video_call,
                      title: 'Consulta',
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),

                    // Clinic Appointment Card (solo si es doctor Apollo)
                    if (widget.doctor.isApolloDoctor)
                      _buildConsultationCard(
                        icon: Icons.local_hospital,
                        title: 'Cita en Clínica',
                        color: Colors.cyan,
                      ),

                    const SizedBox(height: 24),

                    // Sección de Opiniones
                    _buildOpinionsSection(),

                    const SizedBox(height: 24),

                    // Clinic Details (solo si es doctor Apollo)
                    if (widget.doctor.isApolloDoctor) _buildClinicDetails(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
    );
  }

  Widget _buildConsultationCard({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    final todaySlots = _availableSlots['today'] ?? [];
    final tomorrowSlots = _availableSlots['tomorrow'] ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '\$${widget.doctor.pricePerAppointment.toStringAsFixed(0)} Tarifa',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: color,
            unselectedLabelColor: Colors.grey,
            indicatorColor: color,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Hoy'),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${todaySlots.length} Espacios',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Mañana'),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${tomorrowSlots.length} Espacios',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Time Slots
          SizedBox(
            height: 120,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTimeSlotsList(todaySlots, DateTime.now()),
                _buildTimeSlotsList(
                  tomorrowSlots,
                  DateTime.now().add(const Duration(days: 1)),
                ),
              ],
            ),
          ),

          // View All Slots Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton(
              onPressed: () {},
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ver Todos los Horarios',
                    style: TextStyle(color: color, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16, color: color),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotsList(List<String> slots, DateTime date) {
    if (slots.isEmpty) {
      return const Center(
        child: Text(
          'No hay espacios disponibles',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Mostrar solo los primeros 4 slots
    final displaySlots = slots.take(4).toList();

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      itemCount: displaySlots.length,
      itemBuilder: (context, index) {
        final time = displaySlots[index];
        return GestureDetector(
          onTap: () => _showBookingConfirmation(date, time),
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Center(
              child: Text(
                _formatTime(time),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                  height: 1.3,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOpinionsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Opiniones de Pacientes',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildOpinionCard(
            name: 'María González',
            opinion:
                'Excelente doctor! Muy profesional y atento. Se tomó el tiempo para explicar todo claramente.',
            rating: 5,
            date: 'Hace 2 días',
          ),
          const SizedBox(height: 12),
          _buildOpinionCard(
            name: 'Carlos Ramírez',
            opinion:
                'Gran experiencia. La consulta fue muy completa y el doctor muy conocedor.',
            rating: 5,
            date: 'Hace 1 semana',
          ),
          const SizedBox(height: 12),
          _buildOpinionCard(
            name: 'Ana López',
            opinion: 'Muy recomendado! Servicio muy atento y profesional.',
            rating: 5,
            date: 'Hace 2 semanas',
          ),
        ],
      ),
    );
  }

  Widget _buildOpinionCard({
    required String name,
    required String opinion,
    required int rating,
    required String date,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue[100],
                child: Text(
                  name[0],
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(
                          rating,
                          (index) => const Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            opinion,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicDetails() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Detalles de la Clínica',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          // Map placeholder
          Container(
            height: 150,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(Icons.map, size: 64, color: Colors.grey[400]),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.navigation,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                  ),
                ),
                Positioned(
                  top: 60,
                  left: 80,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.local_hospital,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Clinic info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.green[600], size: 20),
                    const SizedBox(width: 4),
                    const Text(
                      '4.5',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.doctor.hospital,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.doctor.city}, CA 90232, United States',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Horarios',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Lun - Dom',
                      style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Abierto Hoy',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Text(
                    '08:00 AM - 10:00 PM',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.phone),
                    label: const Text('Contactar Clínica'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showBookingConfirmation(DateTime date, String time) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Cita'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Doctor: ${widget.doctor.name}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Fecha: ${_getDateString(date)}'),
              Text('Hora: $time'),
              const SizedBox(height: 8),
              Text(
                'Tarifa: \$${widget.doctor.pricePerAppointment.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (result == true && mounted) {
      await _showPaymentMethodDialog(date, time);
    }
  }

  Future<void> _showPaymentMethodDialog(DateTime date, String time) async {
    final result = await showDialog<PaymentType>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Seleccionar Método de Pago'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPaymentOption(
                dialogContext,
                icon: Icons.credit_card,
                title: 'Tarjeta de Crédito',
                onTap:
                    () => Navigator.pop(dialogContext, PaymentType.creditCard),
              ),
              const SizedBox(height: 10),
              _buildPaymentOption(
                dialogContext,
                icon: Icons.paypal,
                title: 'PayPal',
                onTap: () => Navigator.pop(dialogContext, PaymentType.paypal),
              ),
              const SizedBox(height: 10),
              _buildPaymentOption(
                dialogContext,
                icon: Icons.account_balance,
                title: 'Transferencia Bancaria',
                onTap:
                    () =>
                        Navigator.pop(dialogContext, PaymentType.bankTransfer),
              ),
              const SizedBox(height: 10),
              _buildPaymentOption(
                dialogContext,
                icon: Icons.phone_android,
                title: 'Yape',
                color: Colors.green,
                onTap:
                    () => Navigator.pop(dialogContext, PaymentType.yape),
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
      await _processPayment(result, date, time);
    }
  }

  Widget _buildPaymentOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = const Color(0xFF0066FF),
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: color),
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
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment(
    PaymentType paymentType,
    DateTime date,
    String time,
  ) async {
    try {
      await _bookAppointment(date, time, paymentType);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder:
            (dialogContext) => AlertDialog(
              icon: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              title: const Text('¡Cita Agendada!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Tu cita ha sido agendada exitosamente.',
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
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.of(context).pop();
                  },
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

  Future<void> _bookAppointment(
    DateTime date,
    String time,
    PaymentType paymentType,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final appointment = Appointment(
      id: '',
      doctorId: widget.doctor.id,
      patientId: user.uid,
      date: date,
      startTime: time,
      durationHours: 1,
      price: widget.doctor.pricePerAppointment,
      paymentMethod: paymentType.toString().split('.').last,
      isArchived: false,
    );

    await _firestore.collection('appointments').add(appointment.toMap());

    if (!mounted) return;

    await _loadAvailableSlots();
  }

  String _getDateString(DateTime date) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${date.day} de ${months[date.month - 1]}, ${date.year}';
  }
}
