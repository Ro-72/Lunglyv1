import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'appointment_detail_page.dart';

class DoctorHomePage extends StatefulWidget {
  const DoctorHomePage({super.key});

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _userId => _auth.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return _userId == null
        ? const Center(child: Text('Usuario no autenticado'))
        : DefaultTabController(
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
          .where('doctorId', isEqualTo: _userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('appointmentDate')
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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
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
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: _userId)
          .where('status', isEqualTo: 'confirmed')
          .orderBy('appointmentDate')
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
                Icon(Icons.event_available, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No hay citas confirmadas',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return _buildAppointmentCard(
              doc.id,
              data,
              isPending: false,
            );
          },
        );
      },
    );
  }

  Widget _buildAppointmentCard(
    String appointmentId,
    Map<String, dynamic> data,
    {required bool isPending}
  ) {
    final patientId = data['patientId'] as String?;
    final appointmentDate = (data['appointmentDate'] as Timestamp?)?.toDate();
    final duration = data['consultationMinutes'] as int? ?? 30;

    return Card(
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
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    appointmentDate != null
                        ? '${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year}'
                        : 'Fecha no disponible',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    appointmentDate != null
                        ? '${appointmentDate.hour.toString().padLeft(2, '0')}:${appointmentDate.minute.toString().padLeft(2, '0')}'
                        : '--:--',
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
}
