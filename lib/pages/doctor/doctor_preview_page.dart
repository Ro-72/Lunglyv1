import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/doctor.dart';

class DoctorPreviewPage extends StatefulWidget {
  const DoctorPreviewPage({super.key});

  @override
  State<DoctorPreviewPage> createState() => _DoctorPreviewPageState();
}

class _DoctorPreviewPageState extends State<DoctorPreviewPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _userId => _auth.currentUser?.uid;
  bool _isLoading = true;
  Doctor? _doctor;

  @override
  void initState() {
    super.initState();
    _loadDoctorProfile();
  }

  Future<void> _loadDoctorProfile() async {
    setState(() => _isLoading = true);

    try {
      final userId = _userId;
      if (userId == null) {
        print('DoctorPreviewPage: userId es null');
        return;
      }

      print('DoctorPreviewPage: Buscando perfil para userId: $userId');

      // Buscar el perfil del doctor en la colección doctors
      final querySnapshot = await _firestore
          .collection('doctors')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      print('DoctorPreviewPage: Documentos encontrados: ${querySnapshot.docs.length}');

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        print('DoctorPreviewPage: Datos del doctor: $data');

        setState(() {
          _doctor = Doctor.fromMap(data, doc.id);
        });
        print('DoctorPreviewPage: Doctor cargado exitosamente');
      } else {
        print('DoctorPreviewPage: No se encontró ningún documento con userId: $userId');
      }
    } catch (e, stackTrace) {
      print('DoctorPreviewPage: Error al cargar perfil: $e');
      print('DoctorPreviewPage: StackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar perfil: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vista Previa de Perfil'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _doctor == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No se ha encontrado tu perfil médico',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Completa tu perfil en "Mi Perfil Médico"',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Volver'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner informativo
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: Colors.blue.shade50,
                        child: Row(
                          children: [
                            Icon(Icons.visibility, color: Colors.blue.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Así es como los pacientes ven tu perfil',
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tarjeta de perfil (como se ve en la lista de médicos)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Encabezado con foto y nombre
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundColor: const Color(0xFF4990E2),
                                      child: _doctor!.profileImageUrl != null
                                          ? ClipOval(
                                              child: Image.network(
                                                _doctor!.profileImageUrl!,
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) =>
                                                    const Icon(Icons.medical_services,
                                                        size: 40, color: Colors.white),
                                              ),
                                            )
                                          : const Icon(Icons.medical_services,
                                              size: 40, color: Colors.white),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _doctor!.name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _doctor!.title,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _doctor!.specialty,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF4990E2),
                                              fontWeight: FontWeight.w500,
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

                                // Información rápida
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildInfoChip(
                                      Icons.star,
                                      '${_doctor!.rating.toStringAsFixed(1)} ⭐',
                                      Colors.orange,
                                    ),
                                    _buildInfoChip(
                                      Icons.work,
                                      '${_doctor!.yearsExperience} años',
                                      Colors.blue,
                                    ),
                                    _buildInfoChip(
                                      Icons.people,
                                      '${_doctor!.patientCount}+ pacientes',
                                      Colors.green,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Ubicación y hospital
                                _buildInfoRow(
                                  Icons.local_hospital,
                                  _doctor!.hospital,
                                ),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  Icons.location_on,
                                  _doctor!.city,
                                ),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  Icons.access_time,
                                  '${_doctor!.consultationMinutes} min por consulta',
                                ),
                                const SizedBox(height: 16),

                                // Precio
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.attach_money,
                                          color: Colors.green.shade700, size: 20),
                                      const SizedBox(width: 4),
                                      Text(
                                        'S/ ${_doctor!.pricePerAppointment}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                      Text(
                                        ' por consulta',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 8),

                                // Descripción
                                const Text(
                                  'Acerca del médico',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _doctor!.description,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.justify,
                                ),
                                const SizedBox(height: 16),

                                // Idiomas
                                if (_doctor!.languages.isNotEmpty) ...[
                                  const Text(
                                    'Idiomas',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: _doctor!.languages
                                        .map((lang) => Chip(
                                              label: Text(lang),
                                              backgroundColor: Colors.blue.shade50,
                                            ))
                                        .toList(),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Cualificaciones
                                if (_doctor!.qualifications.isNotEmpty) ...[
                                  const Text(
                                    'Cualificaciones',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...(_doctor!.qualifications.map((qual) => Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check_circle,
                                                size: 16, color: Color(0xFF4990E2)),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(qual)),
                                          ],
                                        ),
                                      ))),
                                  const SizedBox(height: 16),
                                ],

                                // Botón de agendar cita (deshabilitado en vista previa)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: null, // Deshabilitado en vista previa
                                    icon: const Icon(Icons.calendar_today),
                                    label: const Text('Agendar Cita'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Center(
                                  child: Text(
                                    '(Botón deshabilitado en vista previa)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
        ),
      ],
    );
  }
}
