import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import '../models/treatment.dart';

class TratamientoPage extends StatelessWidget {
  const TratamientoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const TratamientoPageContent();
        } else {
          return const TratamientoAuthRequired();
        }
      },
    );
  }
}

class TratamientoAuthRequired extends StatelessWidget {
  const TratamientoAuthRequired({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.healing, color: Color(0xFFD4AF37)),
            SizedBox(width: 8),
            Text('Tratamientos'),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade100, Colors.grey.shade200],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Acceso Restringido',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Para acceder a sus tratamientos es necesario iniciar sesión.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Iniciar Sesión'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TratamientoPageContent extends StatefulWidget {
  const TratamientoPageContent({super.key});

  @override
  State<TratamientoPageContent> createState() => _TratamientoPageContentState();
}

class _TratamientoPageContentState extends State<TratamientoPageContent> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.healing, color: Color(0xFFD4AF37)),
            SizedBox(width: 8),
            Text('Tratamientos'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('treatments')
            .where('userId', isEqualTo: _auth.currentUser?.uid)
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final treatments = snapshot.data?.docs
              .map((doc) => Treatment.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList() ?? [];

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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...treatments.map(
                  (treatment) => _buildTreatmentCard(
                    context,
                    treatment,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Opciones',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
        },
      ),
    );
  }

  Future<void> _addTreatment() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Guardar el messenger antes de mostrar el diálogo
    final messenger = ScaffoldMessenger.of(context);

    // Show dialog to add treatment
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const AddTreatmentDialog(),
    );

    if (result == null) return;

    final name = result['name']?.trim() ?? '';
    final dosage = result['dosage']?.trim() ?? '';
    final frequency = result['frequency'] ?? 'Diario';

    // Validar que los campos no estén vacíos
    if (name.isEmpty || dosage.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    try {
      final treatment = Treatment(
        id: '',
        name: name,
        dosage: dosage,
        frequency: frequency,
        nextDose: DateTime.now().add(const Duration(hours: 24)),
        userId: user.uid,
      );

      await _firestore.collection('treatments').add(treatment.toMap());

      messenger.showSnackBar(
        const SnackBar(content: Text('Tratamiento agregado exitosamente')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error al agregar tratamiento: $e')),
      );
    }
  }

  Future<void> _deleteTreatment(String treatmentId) async {
    try {
      await _firestore.collection('treatments').doc(treatmentId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tratamiento eliminado')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e')),
      );
    }
  }

  Future<void> _completeDose(Treatment treatment) async {
    try {
      DateTime now = DateTime.now();
      Duration frequency = _getFrequencyDuration(treatment.frequency);
      DateTime nextDose = now.add(frequency);

      await _firestore.collection('treatments').doc(treatment.id).update({
        'lastDose': now,
        'nextDose': nextDose,
        'isCompleted': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dosis registrada')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar dosis: $e')),
      );
    }
  }

  Duration _getFrequencyDuration(String frequency) {
    switch (frequency) {
      case 'Cada 8 horas':
        return const Duration(hours: 8);
      case 'Cada 12 horas':
        return const Duration(hours: 12);
      case 'Diario':
      default:
        return const Duration(hours: 24);
    }
  }

  Widget _buildTreatmentCard(
    BuildContext context,
    Treatment treatment,
  ) {
    Duration timeUntilNextDose = treatment.nextDose.difference(DateTime.now());
    bool isDoseAvailable = timeUntilNextDose.isNegative;

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
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.medication, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        treatment.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        treatment.dosage,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check_circle),
                  color: isDoseAvailable ? Colors.green : Colors.grey,
                  onPressed: isDoseAvailable ? () => _completeDose(treatment) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                  onPressed: () => _deleteTreatment(treatment.id),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildNextDoseTimer(treatment),
          ],
        ),
      ),
    );
  }

  Widget _buildNextDoseTimer(Treatment treatment) {
    return StreamBuilder<Duration>(
      stream: Stream.periodic(const Duration(seconds: 1), (_) {
        return treatment.nextDose.difference(DateTime.now());
      }),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        Duration timeLeft = snapshot.data!;
        bool isDoseAvailable = timeLeft.isNegative;

        if (isDoseAvailable) {
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Text(
                  'Dosis disponible',
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer, color: Colors.blue, size: 16),
              const SizedBox(width: 8),
              Text(
                'Próxima dosis en: ${_formatDuration(timeLeft)}',
                style: const TextStyle(color: Colors.blue),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
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
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Add this new dialog widget at the bottom of the file
class AddTreatmentDialog extends StatefulWidget {
  const AddTreatmentDialog({super.key});

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
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del medicamento',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dosageController,
              decoration: const InputDecoration(labelText: 'Dosis'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _frequency,
              decoration: const InputDecoration(labelText: 'Frecuencia'),
              items:
                  ['Diario', 'Cada 12 horas', 'Cada 8 horas']
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
              onChanged: (value) => setState(() => _frequency = value!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, {
              'name': _nameController.text,
              'dosage': _dosageController.text,
              'frequency': _frequency,
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
    super.dispose();
  }
}
