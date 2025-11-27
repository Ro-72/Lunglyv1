import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'appointment_detail_page.dart';
import 'appointment_detail_doctor_page.dart';
import '../../models/treatment.dart';
import '../../models/medication.dart';

class DoctorHomePage extends StatefulWidget {
  const DoctorHomePage({super.key});

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _userId => _auth.currentUser?.uid;
  String? _doctorId;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _loadDoctorId();
  }

  Future<void> _loadDoctorId() async {
    if (_userId == null) return;

    try {
      final querySnapshot = await _firestore
          .collection('doctors')
          .where('userId', isEqualTo: _userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _doctorId = querySnapshot.docs.first.id;
        });
      }
    } catch (e) {
      print('Error loading doctor ID: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Center(child: Text('Usuario no autenticado'));
    }

    if (_doctorId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.primary,
            child: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: [
                Tab(
                  icon: Icon(Icons.pending_actions),
                  text: 'Citas por Confirmar',
                ),
                Tab(
                  icon: Icon(Icons.check_circle),
                  text: 'Citas Confirmadas',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPendingAppointments(),
                _buildConfirmedAppointments(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingAppointments() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: _doctorId)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No hay citas pendientes',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Ordenar manualmente por appointmentDate
        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aDate = (aData['appointmentDate'] as Timestamp?)?.toDate();
          final bDate = (bData['appointmentDate'] as Timestamp?)?.toDate();

          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return aDate.compareTo(bDate);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return _buildAppointmentCard(
              doc.id,
              data,
              isPending: true,
            );
          },
        );
      },
    );
  }

  Widget _buildConfirmedAppointments() {
    return Column(
      children: [
        // Filtro para mostrar/ocultar archivadas
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[100],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mostrar citas archivadas',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Switch(
                value: _showArchived,
                onChanged: (value) {
                  setState(() {
                    _showArchived = value;
                  });
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('appointments')
                .where('doctorId', isEqualTo: _doctorId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              // Filtrar citas según el estado y el toggle
              final allDocs = snapshot.data?.docs ?? [];
              final filteredDocs = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status'] as String?;

                if (_showArchived) {
                  // Mostrar solo completadas/archivadas
                  return status == 'completed';
                } else {
                  // Mostrar solo confirmadas (no completadas)
                  return status == 'confirmed';
                }
              }).toList();

              if (filteredDocs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _showArchived ? Icons.archive : Icons.event_available,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _showArchived
                            ? 'No hay citas archivadas'
                            : 'No hay citas confirmadas',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              // Ordenar manualmente por appointmentDate
              filteredDocs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aDate = (aData['appointmentDate'] as Timestamp?)?.toDate();
                final bDate = (bData['appointmentDate'] as Timestamp?)?.toDate();

                if (aDate == null && bDate == null) return 0;
                if (aDate == null) return 1;
                if (bDate == null) return -1;
                return aDate.compareTo(bDate);
              });

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final doc = filteredDocs[index];
                  final data = doc.data() as Map<String, dynamic>;

                  return _buildConfirmedAppointmentCard(
                    doc.id,
                    data,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentCard(
    String appointmentId,
    Map<String, dynamic> data,
    {required bool isPending}
  ) {
    final patientId = data['patientId'] as String?;
    final appointmentDateTimestamp = data['appointmentDate'];
    final appointmentDate = appointmentDateTimestamp != null
        ? (appointmentDateTimestamp is Timestamp
            ? appointmentDateTimestamp.toDate()
            : null)
        : null;
    final duration = data['consultationMinutes'] as int? ?? 30;
    final startTime = data['startTime'] as String?;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentDetailDoctorPage(
              appointmentId: appointmentId,
              appointmentData: data,
            ),
          ),
        );
      },
      child: Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppointmentDetailPage(
                appointmentId: appointmentId,
                isPending: isPending,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isPending
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isPending ? Icons.schedule : Icons.check_circle,
                      color: isPending ? Colors.orange : Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FutureBuilder<DocumentSnapshot>(
                      future: _firestore.collection('users').doc(patientId).get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Text('Cargando...');
                        }

                        final patientData = snapshot.data?.data() as Map<String, dynamic>?;
                        final patientName = patientData?['name'] as String? ?? 'Paciente';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patientName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${duration} minutos',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(

              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    startTime ?? 'Hora no disponible',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              if (isPending) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmAppointment(appointmentId),
                    icon: const Icon(Icons.check),
                    label: const Text('Confirmar Cita'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _confirmAppointment(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'confirmed',
        'confirmedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cita confirmada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al confirmar cita: $e')),
        );
      }
    }
  }

  Widget _buildConfirmedAppointmentCard(
    String appointmentId,
    Map<String, dynamic> data,
  ) {
    final patientId = data['patientId'] as String?;
    final appointmentDateTimestamp = data['appointmentDate'];
    final appointmentDate = appointmentDateTimestamp != null
        ? (appointmentDateTimestamp is Timestamp
            ? appointmentDateTimestamp.toDate()
            : null)
        : null;
    final duration = data['consultationMinutes'] as int? ?? 30;
    final startTime = data['startTime'] as String?;
    final status = data['status'] as String?;
    final isCompleted = status == 'completed';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentDetailDoctorPage(
              appointmentId: appointmentId,
              appointmentData: data,
            ),
          ),
        );
      },
      child: Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('users').doc(patientId).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final patientData = snapshot.data?.data() as Map<String, dynamic>?;
            final patientName = patientData?['name'] as String? ?? 'Paciente';
            final patientEmail = patientData?['email'] as String? ?? '';
            final patientPhone = patientData?['phone'] as String?;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con estado
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.grey.withValues(alpha: 0.1)
                            : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isCompleted ? Icons.archive : Icons.check_circle,
                        color: isCompleted ? Colors.grey : Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCompleted ? 'Cita Archivada' : 'Cita Confirmada',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isCompleted ? Colors.grey : Colors.green,
                            ),
                          ),
                          if (appointmentDate != null)
                            Text(
                              '${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year} ${appointmentDate.hour.toString().padLeft(2, '0')}:${appointmentDate.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Información del paciente
                const Text(
                  'Información del Paciente',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.person,
                        size: 30,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patientName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (patientEmail.isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.email, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    patientEmail,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          if (patientPhone != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  patientPhone,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      startTime ?? 'Hora no disponible',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Duración: $duration minutos',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),

                if (!isCompleted) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showAddMedicalHistoryDialog(
                            appointmentId,
                            patientId!,
                            patientName,
                          ),
                          icon: const Icon(Icons.medical_services, size: 18),
                          label: const Text(
                            'Historial',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showAddPrescriptionDialog(
                            appointmentId,
                            patientId!,
                            patientName,
                          ),
                          icon: const Icon(Icons.medication, size: 18),
                          label: const Text(
                            'Receta',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _completeAppointment(appointmentId),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text(
                        'Finalizar Cita',
                        style: TextStyle(fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      ),
    );
  }

  Future<void> _showAddMedicalHistoryDialog(
    String appointmentId,
    String patientId,
    String patientName,
  ) async {
    final diagnosisController = TextEditingController();
    final symptomsController = TextEditingController();
    final treatmentController = TextEditingController();
    final notesController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Historial Médico - $patientName'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Diagnóstico',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: diagnosisController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Ingrese el diagnóstico...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (diagnosisController.text.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor ingrese al menos el diagnóstico'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        diagnosisController.dispose();
        symptomsController.dispose();
        treatmentController.dispose();
        notesController.dispose();
        return;
      }

      try {
        final appointmentDoc = await _firestore
            .collection('appointments')
            .doc(appointmentId)
            .get();
        final appointmentData = appointmentDoc.data();

        await _firestore
            .collection('users')
            .doc(patientId)
            .collection('medical_records')
            .add({
          'appointmentId': appointmentId,
          'doctorId': _doctorId,
          'diagnosis': diagnosisController.text.trim(),
          'symptoms': symptomsController.text.trim(),
          'treatment': treatmentController.text.trim(),
          'notes': notesController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'appointmentDate': appointmentData?['appointmentDate'],
          'medicalHistory': diagnosisController.text.trim(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Historial médico guardado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar historial: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    diagnosisController.dispose();
    symptomsController.dispose();
    treatmentController.dispose();
    notesController.dispose();
  }

  Future<void> _showAddPrescriptionDialog(
    String appointmentId,
    String patientId,
    String patientName,
  ) async {
    final result = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (context) => _AddPrescriptionDialog(
        patientName: patientName,
        doctorId: _doctorId!,
        patientId: patientId,
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        // Convertir medicamentos de la receta a Medication objects
        final medications = result.map((med) {
          final frequency = med['frequency'] as String? ?? 'Cada 8 horas';
          final durationDays = med['durationDays'] as int? ?? 7;

          return Medication(
            id: DateTime.now().millisecondsSinceEpoch.toString() + med['name'].hashCode.toString(),
            name: med['name'] ?? '',
            dosage: med['dose'].toString(),
            frequency: frequency,
            durationDays: durationDays,
            nextDose: DateTime.now().add(_getFrequencyDuration(frequency)),
          );
        }).toList();

        // Crear el tratamiento (receta)
        final treatment = Treatment(
          id: '',
          name: 'Receta Médica - ${_formatDate(DateTime.now())}',
          description: 'Receta médica del doctor',
          medications: medications,
          userId: patientId,
          isPrescription: true,
          prescriptionActivated: false,
        );

        // Guardar en Firebase
        await _firestore
            .collection('treatments')
            .add(treatment.toMap());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Receta guardada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar receta: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _completeAppointment(String appointmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar Cita'),
        content: const Text(
          '¿Está seguro de que desea finalizar y archivar esta cita?\n\n'
          'Asegúrese de haber agregado el historial médico y receta antes de finalizar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Sí, Finalizar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cita finalizada y archivada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al finalizar cita: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]} ${date.year}';
  }

  Duration _getFrequencyDuration(String frequency) {
    switch (frequency) {
      case 'Cada 6 horas':
        return const Duration(hours: 6);
      case 'Cada 8 horas':
        return const Duration(hours: 8);
      case 'Cada 12 horas':
        return const Duration(hours: 12);
      case 'Diario':
      default:
        return const Duration(hours: 24);
    }
  }
}

// Dialog para agregar receta médica con múltiples medicamentos
class _AddPrescriptionDialog extends StatefulWidget {
  final String patientName;
  final String doctorId;
  final String patientId;

  const _AddPrescriptionDialog({
    required this.patientName,
    required this.doctorId,
    required this.patientId,
  });

  @override
  State<_AddPrescriptionDialog> createState() => _AddPrescriptionDialogState();
}

class _AddPrescriptionDialogState extends State<_AddPrescriptionDialog> {
  final List<Map<String, dynamic>> _medications = [];
  bool _useSharedSettings = false;
  String _sharedFrequency = 'Cada 8 horas';
  int _sharedDurationDays = 7;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Receta Médica - ${widget.patientName}'),
      content: SizedBox(
        width: double.maxFinite,
        height: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Configuración compartida switch
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Configuración compartida',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Misma frecuencia y duración para todos',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _useSharedSettings,
                        onChanged: (value) {
                          setState(() {
                            _useSharedSettings = value;
                          });
                        },
                      ),
                    ],
                  ),
                  if (_useSharedSettings) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _sharedFrequency,
                      decoration: const InputDecoration(
                        labelText: 'Frecuencia',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: ['Diario', 'Cada 12 horas', 'Cada 8 horas', 'Cada 6 horas']
                          .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _sharedFrequency = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: _sharedDurationDays.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duración (días)',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _sharedDurationDays = int.tryParse(value) ?? 7;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Medicamentos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addMedication,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4990E2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_medications.isEmpty)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'No se han agregado medicamentos',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _medications.length,
                  itemBuilder: (context, index) {
                    final med = _medications[index];
                    final frequency = _useSharedSettings ? _sharedFrequency : med['frequency'];
                    final durationDays = _useSharedSettings ? _sharedDurationDays : med['durationDays'];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.medication, color: Colors.green),
                        title: Text(
                          med['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${med['dose']} - $frequency durante $durationDays días',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeMedication(index),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _medications.isEmpty
              ? null
              : () {
                  // Aplicar configuración compartida si está activada
                  final finalMedications = _medications.map((med) {
                    if (_useSharedSettings) {
                      return {
                        ...med,
                        'frequency': _sharedFrequency,
                        'durationDays': _sharedDurationDays,
                      };
                    }
                    return med;
                  }).toList();
                  Navigator.pop(context, finalMedications);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          ),
          child: const Text('Guardar Receta'),
        ),
      ],
    );
  }

  Future<void> _addMedication() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddMedicationDialog(
        useSharedSettings: _useSharedSettings,
      ),
    );

    if (result != null) {
      setState(() {
        _medications.add(result);
      });
    }
  }

  void _removeMedication(int index) {
    setState(() {
      _medications.removeAt(index);
    });
  }
}

// Dialog para agregar un medicamento individual
class _AddMedicationDialog extends StatefulWidget {
  final bool useSharedSettings;

  const _AddMedicationDialog({
    this.useSharedSettings = false,
  });

  @override
  State<_AddMedicationDialog> createState() => _AddMedicationDialogState();
}

class _AddMedicationDialogState extends State<_AddMedicationDialog> {
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _unitController = TextEditingController(text: 'mg');
  final _durationController = TextEditingController(text: '7');
  String _frequency = 'Cada 8 horas';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Medicamento'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nombre del medicamento',
                hintText: 'Ej: Salbutamol',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dosageController,
                    decoration: const InputDecoration(
                      labelText: 'Dosis',
                      hintText: 'Ej: 100mg, 2 puff',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            if (!widget.useSharedSettings) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _frequency,
                decoration: const InputDecoration(
                  labelText: 'Frecuencia',
                  border: OutlineInputBorder(),
                ),
                items: ['Diario', 'Cada 12 horas', 'Cada 8 horas', 'Cada 6 horas']
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (value) => setState(() => _frequency = value!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duración (días)',
                  hintText: 'Ej: 7',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty ||
                _dosageController.text.trim().isEmpty) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor completa el nombre y la dosis'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
              return;
            }

            Navigator.pop(context, {
              'name': _nameController.text.trim(),
              'dose': _dosageController.text.trim(),
              'unit': 'N/A',
              'frequency': _frequency,
              'durationDays': int.tryParse(_durationController.text.trim()) ?? 7,
              'description': '$_frequency durante ${_durationController.text.trim()} días',
            });
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _unitController.dispose();
    _durationController.dispose();
    super.dispose();
  }
}
