import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import '../models/treatment.dart';
import '../models/medication.dart';

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
/*       appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.healing, color: Color(0xFFD4AF37)),
            SizedBox(width: 8),
            Text('Tratamientos'),
          ],
        ),
        automaticallyImplyLeading: false,
      ), */
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
/*       appBar: AppBar(
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
      ), */
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

    // Show dialog to add treatment with multiple medications
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddTreatmentDialog(),
    );

    if (result == null) return;

    final name = result['name']?.trim() ?? '';
    final description = result['description']?.trim() ?? '';
    final medications = result['medications'] as List<Medication>? ?? [];
    final useSharedSettings = result['useSharedSettings'] as bool? ?? false;
    final sharedFrequency = result['sharedFrequency'] as String?;
    final sharedDurationDays = result['sharedDurationDays'] as int?;

    // Validar que los campos no estén vacíos
    if (name.isEmpty || medications.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Por favor completa el nombre y agrega al menos un medicamento')),
      );
      return;
    }

    try {
      final treatment = Treatment(
        id: '',
        name: name,
        description: description,
        medications: medications,
        userId: user.uid,
        useSharedSettings: useSharedSettings,
        sharedFrequency: sharedFrequency,
        sharedDurationDays: sharedDurationDays,
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

  Future<void> _completeDose(Treatment treatment, Medication medication) async {
    try {
      DateTime now = DateTime.now();
      Duration frequency = _getFrequencyDuration(medication.frequency);
      DateTime nextDose = now.add(frequency);

      // Actualizar el medicamento específico en la lista
      final updatedMedications = treatment.medications.map((med) {
        if (med.id == medication.id) {
          return med.copyWith(
            lastDose: now,
            nextDose: nextDose,
            isCompleted: true,
          );
        }
        return med;
      }).toList();

      await _firestore.collection('treatments').doc(treatment.id).update({
        'medications': updatedMedications.map((med) => med.toMap()).toList(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dosis de ${medication.name} registrada')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar dosis: $e')),
      );
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

  Widget _buildTreatmentCard(
    BuildContext context,
    Treatment treatment,
  ) {
    return TreatmentCardExpansion(
      treatment: treatment,
      onDelete: () => _deleteTreatment(treatment.id),
      onCompleteDose: (medication) => _completeDose(treatment, medication),
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

class TreatmentCardExpansion extends StatefulWidget {
  final Treatment treatment;
  final VoidCallback onDelete;
  final Function(Medication) onCompleteDose;

  const TreatmentCardExpansion({
    super.key,
    required this.treatment,
    required this.onDelete,
    required this.onCompleteDose,
  });

  @override
  State<TreatmentCardExpansion> createState() => _TreatmentCardExpansionState();
}

class _TreatmentCardExpansionState extends State<TreatmentCardExpansion> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.healing, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.treatment.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.treatment.description.isNotEmpty && !_isExpanded)
                          Text(
                            widget.treatment.description,
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.treatment.medications.length} medicamento${widget.treatment.medications.length != 1 ? "s" : ""}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.treatment.description.isNotEmpty) ...[
                    Text(
                      widget.treatment.description,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (widget.treatment.useSharedSettings) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.sync, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Configuración compartida: ${widget.treatment.sharedFrequency} - ${widget.treatment.sharedDurationDays} días',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Medicamentos (${widget.treatment.medications.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        color: Colors.red,
                        onPressed: widget.onDelete,
                        tooltip: 'Eliminar tratamiento',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...widget.treatment.medications.map((medication) =>
                      _buildMedicationItem(context, widget.treatment, medication)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicationItem(
    BuildContext context,
    Treatment treatment,
    Medication medication,
  ) {
    final bool isExpired = medication.isExpired;
    final int daysRemaining = medication.daysRemaining;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isExpired ? Colors.red.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isExpired ? Colors.red.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.medication,
                color: isExpired ? Colors.red : Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        decoration: isExpired ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(
                      '${medication.dosage} - ${medication.frequency}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: isExpired ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isExpired
                              ? 'Tratamiento finalizado'
                              : '$daysRemaining ${daysRemaining == 1 ? "día restante" : "días restantes"}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isExpired ? Colors.red : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isExpired) _buildDoseButton(treatment, medication),
            ],
          ),
          const SizedBox(height: 8),
          if (!isExpired) _buildMedicationTimer(medication),
        ],
      ),
    );
  }

  Widget _buildDoseButton(Treatment treatment, Medication medication) {
    Duration timeUntilNextDose = medication.nextDose.difference(DateTime.now());
    bool isDoseAvailable = timeUntilNextDose.isNegative;

    return IconButton(
      icon: const Icon(Icons.check_circle),
      color: isDoseAvailable ? Colors.green : Colors.grey,
      onPressed: isDoseAvailable ? () => widget.onCompleteDose(medication) : null,
      tooltip: isDoseAvailable ? 'Registrar dosis' : 'Dosis no disponible aún',
    );
  }

  Widget _buildMedicationTimer(Medication medication) {
    return StreamBuilder<Duration>(
      stream: Stream.periodic(const Duration(seconds: 1), (_) {
        return medication.nextDose.difference(DateTime.now());
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Text(
                  'Dosis disponible',
                  style: TextStyle(color: Colors.green, fontSize: 12),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer, color: Colors.blue, size: 16),
              const SizedBox(width: 8),
              Text(
                'Próxima dosis: ${_formatDuration(timeLeft)}',
                style: const TextStyle(color: Colors.blue, fontSize: 12),
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

// Dialog para agregar tratamiento con múltiples medicamentos
class AddTreatmentDialog extends StatefulWidget {
  const AddTreatmentDialog({super.key});

  @override
  State<AddTreatmentDialog> createState() => _AddTreatmentDialogState();
}

class _AddTreatmentDialogState extends State<AddTreatmentDialog> {
  final _treatmentNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  final List<Medication> _medications = [];

  bool _useSharedSettings = false;
  String _sharedFrequency = 'Diario';
  int _sharedDurationDays = 30;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Tratamiento'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _treatmentNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Tratamiento',
                  hintText: 'Ej: Tratamiento para Asma',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Detalles del tratamiento',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              // Switch para configuración compartida
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
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
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Misma frecuencia y duración para todos',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
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
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _sharedFrequency,
                        decoration: const InputDecoration(
                          labelText: 'Frecuencia',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: ['Diario', 'Cada 12 horas', 'Cada 8 horas', 'Cada 6 horas']
                            .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                            .toList(),
                        onChanged: (value) => setState(() => _sharedFrequency = value!),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _durationController,
                        decoration: const InputDecoration(
                          labelText: 'Duración (días)',
                          hintText: 'Ej: 30',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final duration = int.tryParse(value);
                          if (duration != null) {
                            setState(() {
                              _sharedDurationDays = duration;
                            });
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_medications.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'No hay medicamentos agregados',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ..._medications.asMap().entries.map((entry) {
                  final index = entry.key;
                  final med = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.medication, color: Colors.blue),
                      title: Text(med.name),
                      subtitle: Text(_useSharedSettings
                          ? '${med.dosage} - ${_sharedFrequency} - ${_sharedDurationDays} días'
                          : '${med.dosage} - ${med.frequency} - ${med.durationDays} días'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeMedication(index),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            // Aplicar configuración compartida si está activada
            List<Medication> finalMedications = _medications;
            if (_useSharedSettings && _medications.isNotEmpty) {
              finalMedications = _medications.map((med) {
                return med.copyWith(
                  frequency: _sharedFrequency,
                  durationDays: _sharedDurationDays,
                  nextDose: DateTime.now().add(_getFrequencyDuration(_sharedFrequency)),
                );
              }).toList();
            }

            Navigator.pop(context, {
              'name': _treatmentNameController.text,
              'description': _descriptionController.text,
              'medications': finalMedications,
              'useSharedSettings': _useSharedSettings,
              'sharedFrequency': _useSharedSettings ? _sharedFrequency : null,
              'sharedDurationDays': _useSharedSettings ? _sharedDurationDays : null,
            });
          },
          child: const Text('Guardar'),
        ),
      ],
    );
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

  Future<void> _addMedication() async {
    final result = await showDialog<Medication>(
      context: context,
      builder: (context) => AddMedicationDialog(
        showFrequencyField: !_useSharedSettings,
        defaultFrequency: _sharedFrequency,
        defaultDuration: _sharedDurationDays,
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

  @override
  void dispose() {
    _treatmentNameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }
}

// Dialog para agregar un medicamento individual
class AddMedicationDialog extends StatefulWidget {
  final bool showFrequencyField;
  final String defaultFrequency;
  final int defaultDuration;

  const AddMedicationDialog({
    super.key,
    this.showFrequencyField = true,
    this.defaultFrequency = 'Diario',
    this.defaultDuration = 30,
  });

  @override
  State<AddMedicationDialog> createState() => _AddMedicationDialogState();
}

class _AddMedicationDialogState extends State<AddMedicationDialog> {
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _durationController = TextEditingController();
  late String _frequency;
  late int _durationDays;

  @override
  void initState() {
    super.initState();
    _frequency = widget.defaultFrequency;
    _durationDays = widget.defaultDuration;
    _durationController.text = _durationDays.toString();
  }

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
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosis',
                hintText: 'Ej: 100mg, 2 puff',
              ),
            ),
            const SizedBox(height: 16),
            if (widget.showFrequencyField) ...[
              DropdownButtonFormField<String>(
                value: _frequency,
                decoration: const InputDecoration(labelText: 'Frecuencia'),
                items: ['Diario', 'Cada 12 horas', 'Cada 8 horas', 'Cada 6 horas']
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (value) => setState(() => _frequency = value!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duración (días)',
                  hintText: 'Ej: 30',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final duration = int.tryParse(value);
                  if (duration != null) {
                    _durationDays = duration;
                  }
                },
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuración compartida activa',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Frecuencia: ${widget.defaultFrequency}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Duración: ${widget.defaultDuration} días',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
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
          onPressed: () {
            if (_nameController.text.trim().isEmpty ||
                _dosageController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Por favor completa todos los campos')),
              );
              return;
            }

            final medication = Medication(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: _nameController.text.trim(),
              dosage: _dosageController.text.trim(),
              frequency: _frequency,
              durationDays: _durationDays,
              nextDose: DateTime.now().add(_getFrequencyDuration(_frequency)),
            );

            Navigator.pop(context, medication);
          },
          child: const Text('Agregar'),
        ),
      ],
    );
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

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _durationController.dispose();
    super.dispose();
  }
}
