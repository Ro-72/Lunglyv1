import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/appointment.dart';
import '../models/doctor.dart';
import '../utils/doctor_photo_helper.dart';

class AppointmentDetailPatientPage extends StatelessWidget {
  final Appointment appointment;

  const AppointmentDetailPatientPage({
    super.key,
    required this.appointment,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Detalles de la Cita'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('doctors')
            .doc(appointment.doctorId)
            .get(),
        builder: (context, doctorSnapshot) {
          Doctor? doctor;
          if (doctorSnapshot.hasData && doctorSnapshot.data!.exists) {
            doctor = Doctor.fromMap(
              doctorSnapshot.data!.data() as Map<String, dynamic>,
              doctorSnapshot.data!.id,
            );
          }

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .get(),
            builder: (context, userSnapshot) {
              Map<String, dynamic>? userData;
              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                userData = userSnapshot.data!.data() as Map<String, dynamic>?;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Doctor Info Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Información del Médico',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 35,
                                  backgroundColor: Colors.grey[200],
                                  child: ClipOval(
                                    child: doctor?.profileImageUrl != null &&
                                            doctor!.profileImageUrl!.isNotEmpty
                                        ? Image.network(
                                            doctor!.profileImageUrl!,
                                            width: 70,
                                            height: 70,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Image.asset(
                                                DoctorPhotoHelper.getDoctorPhotoPath(
                                                    doctor?.photoNumber),
                                                width: 70,
                                                height: 70,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Icon(
                                                    Icons.person,
                                                    size: 35,
                                                    color: Colors.blue[700],
                                                  );
                                                },
                                              );
                                            },
                                          )
                                        : doctor != null
                                            ? Image.asset(
                                                DoctorPhotoHelper.getDoctorPhotoPath(
                                                    doctor!.photoNumber),
                                                width: 70,
                                                height: 70,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Icon(
                                                    Icons.person,
                                                    size: 35,
                                                    color: Colors.blue[700],
                                                  );
                                                },
                                              )
                                            : Icon(
                                                Icons.person,
                                                size: 35,
                                                color: Colors.blue[700],
                                              ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doctor?.name ?? 'Cargando...',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        doctor?.specialty ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        doctor?.hospital ?? '',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Appointment Details Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Detalles de la Cita',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              Icons.calendar_today,
                              'Fecha',
                              _formatDate(appointment.date),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.access_time,
                              'Hora',
                              appointment.startTime,
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.timer,
                              'Duración',
                              '${appointment.durationHours} hora${appointment.durationHours != 1 ? 's' : ''}',
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.attach_money,
                              'Costo',
                              '\$${appointment.price.toStringAsFixed(2)}',
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.credit_card,
                              'Método de Pago',
                              _getPaymentMethodName(appointment.paymentMethod),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.info_outline,
                              'Estado',
                              _getStatusText(appointment.status),
                              statusColor: _getStatusColor(appointment.status),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Patient Medical Profile Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mi Perfil Médico',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (userData != null) ...[
                              _buildDetailRow(
                                Icons.person,
                                'Nombre',
                                userData['name'] ?? 'No registrado',
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                Icons.email,
                                'Email',
                                userData['email'] ?? 'No registrado',
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                Icons.phone,
                                'Teléfono',
                                userData['phone'] ?? 'No registrado',
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                Icons.emergency,
                                'Contacto de Emergencia',
                                userData['emergencyContact'] ?? 'No registrado',
                                textColor: Colors.red[700],
                              ),
                              if (userData['medicalConditions'] != null &&
                                  userData['medicalConditions'].toString().isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.medical_services,
                                        size: 20, color: Colors.grey[600]),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Condiciones Médicas',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            userData['medicalConditions'],
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (userData['allergies'] != null &&
                                  userData['allergies'].toString().isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.warning_amber,
                                        size: 20, color: Colors.orange[700]),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Alergias',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            userData['allergies'],
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ] else
                              const Text(
                                'No se encontró información del perfil',
                                style: TextStyle(color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? statusColor,
    Color? textColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor ?? statusColor ?? Colors.grey[700],
                  fontWeight: statusColor != null ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]} ${date.year}';
  }

  String _getPaymentMethodName(String? method) {
    switch (method) {
      case 'creditCard':
        return 'Tarjeta de Crédito';
      case 'paypal':
        return 'PayPal';
      case 'bankTransfer':
        return 'Transferencia Bancaria';
      case 'yape':
        return 'Yape';
      default:
        return method ?? 'No especificado';
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'confirmed':
        return 'Confirmada';
      case 'completed':
        return 'Completada';
      case 'cancelled':
        return 'Cancelada';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
