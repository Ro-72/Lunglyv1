import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/treatment.dart';

class TratamientoPage extends StatefulWidget {
  const TratamientoPage({super.key});

  @override
  State<TratamientoPage> createState() => _TratamientoPageState();
}

class _TratamientoPageState extends State<TratamientoPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Treatment> treatments = [];

  @override
  void initState() {
    super.initState();
    _loadTreatments();
  }

  Future<void> _loadTreatments() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot =
        await _firestore
            .collection('treatments')
            .where('userId', isEqualTo: user.uid)
            .where('isActive', isEqualTo: true)
            .get();

    setState(() {
      treatments =
          snapshot.docs
              .map((doc) => Treatment.fromMap(doc.data(), doc.id))
              .toList();
    });
  }

  Future<void> _addTreatment() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Show dialog to add treatment
    showDialog(
      context: context,
      builder:
          (context) => AddTreatmentDialog(
            onAdd: (name, dosage, frequency) async {
              final treatment = Treatment(
                id: '',
                name: name,
                dosage: dosage,
                frequency: frequency,
                nextDose: DateTime.now().add(const Duration(hours: 24)),
                userId: user.uid,
              );

              final doc = await _firestore
                  .collection('treatments')
                  .add(treatment.toMap());
              setState(() {
                treatments.add(Treatment.fromMap(treatment.toMap(), doc.id));
              });
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.healing,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tratamiento',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Seguimiento de tu tratamiento',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tratamientos Activos',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...treatments.map(
            (treatment) => _buildTreatmentCard(
              context,
              title: treatment.name,
              dosage: treatment.dosage,
              nextDose: 'Próxima dosis: ${_formatDateTime(treatment.nextDose)}',
              progress: treatment.progress,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Opciones',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.add,
                  label: 'Agregar',
                  color: Colors.blue,
                  onTap: () {
                    _addTreatment();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.history,
                  label: 'Historial',
                  color: Colors.orange,
                  onTap: () {
                    // View treatment history
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.notifications,
                  label: 'Recordatorios',
                  color: Colors.purple,
                  onTap: () {
                    // Set reminders
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.analytics,
                  label: 'Progreso',
                  color: Colors.green,
                  onTap: () {
                    // View progress
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentCard(
    BuildContext context, {
    required String title,
    required String dosage,
    required String nextDose,
    required double progress,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.medication, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        dosage,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    // Show options
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              nextDose,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress * 100).toInt()}% completado',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// Add this new dialog widget at the bottom of the file
class AddTreatmentDialog extends StatefulWidget {
  final Function(String name, String dosage, String frequency) onAdd;

  const AddTreatmentDialog({super.key, required this.onAdd});

  @override
  State<AddTreatmentDialog> createState() => _AddTreatmentDialogState();
}

class _AddTreatmentDialogState extends State<AddTreatmentDialog> {
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  String _frequency = 'Diario';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Tratamiento'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre del medicamento',
            ),
          ),
          TextField(
            controller: _dosageController,
            decoration: const InputDecoration(labelText: 'Dosis'),
          ),
          DropdownButtonFormField<String>(
            value: _frequency,
            items:
                ['Diario', 'Cada 12 horas', 'Cada 8 horas']
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
            onChanged: (value) => setState(() => _frequency = value!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            widget.onAdd(
              _nameController.text,
              _dosageController.text,
              _frequency,
            );
            Navigator.pop(context);
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
