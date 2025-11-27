import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/treatment.dart';
import '../models/medication.dart';

class PrescriptionsPage extends StatelessWidget {
  const PrescriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Recetas Médicas'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Debes iniciar sesión para ver tus recetas'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Recetas Médicas'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('medical_records')
            .where('prescription', isNull: false)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data?.docs ?? [];
          final prescriptions = records.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final prescription = data['prescription'] as List<dynamic>?;
            return prescription != null && prescription.isNotEmpty;
          }).toList();

          if (prescriptions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medication_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes recetas médicas',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Las recetas aparecerán aquí después de tus consultas',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: prescriptions.length,
            itemBuilder: (context, index) {
              final recordDoc = prescriptions[index];
              final recordData = recordDoc.data() as Map<String, dynamic>;
              return _PrescriptionCard(
                recordId: recordDoc.id,
                recordData: recordData,
              );
            },
          );
        },
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final String recordId;
  final Map<String, dynamic> recordData;

  const _PrescriptionCard({
    required this.recordId,
    required this.recordData,
  });

  @override
  Widget build(BuildContext context) {
    final prescription = recordData['prescription'] as List<dynamic>? ?? [];
    final appointmentDate = recordData['appointmentDate'] as Timestamp?;
    final alreadyStarted = recordData['treatmentStarted'] as bool? ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                    color: alreadyStarted ? Colors.grey[300] : Colors.purple[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.medication,
                    color: alreadyStarted ? Colors.grey[600] : Colors.purple[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Receta Médica',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (appointmentDate != null)
                        Text(
                          _formatDate(appointmentDate.toDate()),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                if (alreadyStarted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'En tratamiento',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Medicamentos:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...prescription.map((med) {
              final medicine = med as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            medicine['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            medicine['dose'].toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (medicine['frequency'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${medicine['frequency']} durante ${medicine['durationDays']} días',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (medicine['description'] != null &&
                        medicine['description'].toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        medicine['description'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
            if (!alreadyStarted) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _startTreatment(context, prescription, recordId),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Iniciar Tratamiento'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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

  Future<void> _startTreatment(
    BuildContext context,
    List<dynamic> prescription,
    String recordId,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Iniciar Tratamiento'),
        content: const Text(
          '¿Deseas iniciar el seguimiento de este tratamiento?\n\n'
          'Se creará un nuevo tratamiento activo con todos los medicamentos de esta receta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
            ),
            child: const Text('Iniciar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Convertir medicamentos de la receta a Medication objects
      final medications = prescription.map((med) {
        final medicine = med as Map<String, dynamic>;
        final frequency = medicine['frequency'] as String? ?? 'Cada 8 horas';
        final durationDays = medicine['durationDays'] as int? ?? 7;

        return Medication(
          id: DateTime.now().millisecondsSinceEpoch.toString() + medicine['name'].hashCode.toString(),
          name: medicine['name'] ?? '',
          dosage: medicine['dose'].toString(),
          frequency: frequency,
          durationDays: durationDays,
          nextDose: DateTime.now().add(_getFrequencyDuration(frequency)),
        );
      }).toList();

      // Crear el tratamiento
      final treatment = Treatment(
        id: '',
        name: 'Receta Médica - ${_formatDate(DateTime.now())}',
        description: 'Tratamiento basado en receta médica',
        medications: medications,
        userId: user.uid,
      );

      // Guardar en Firebase
      await FirebaseFirestore.instance
          .collection('treatments')
          .add(treatment.toMap());

      // Marcar la receta como iniciada
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medical_records')
          .doc(recordId)
          .update({'treatmentStarted': true});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tratamiento iniciado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar tratamiento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
