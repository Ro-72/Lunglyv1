import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class AppointmentDetailPage extends StatefulWidget {
  final String appointmentId;
  final bool isPending;

  const AppointmentDetailPage({
    super.key,
    required this.appointmentId,
    required this.isPending,
  });

  @override
  State<AppointmentDetailPage> createState() => _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends State<AppointmentDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _medicalHistoryController = TextEditingController();

  List<Map<String, dynamic>> _medicines = [];
  List<Map<String, dynamic>> _selectedMedicines = [];
  Timer? _appointmentTimer;
  DateTime? _appointmentEndTime;
  Duration? _remainingTime;
  bool _isCompletingAppointment = false;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
    _startAppointmentTimer();
  }

  @override
  void dispose() {
    _medicalHistoryController.dispose();
    _appointmentTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMedicines() async {
    try {
      final String response = await rootBundle.loadString('assets/data/respiratory_medicines.json');
      final data = json.decode(response);
      setState(() {
        _medicines = List<Map<String, dynamic>>.from(data['medicines']);
      });
    } catch (e) {
      print('Error loading medicines: $e');
    }
  }

  void _startAppointmentTimer() async {
    final doc = await _firestore.collection('appointments').doc(widget.appointmentId).get();
    final data = doc.data();

    if (data != null && data['status'] == 'confirmed') {
      final appointmentDate = (data['appointmentDate'] as Timestamp).toDate();
      final duration = data['consultationMinutes'] as int? ?? 30;
      _appointmentEndTime = appointmentDate.add(Duration(minutes: duration));

      _appointmentTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final now = DateTime.now();
        if (_appointmentEndTime != null && now.isBefore(_appointmentEndTime!)) {
          setState(() {
            _remainingTime = _appointmentEndTime!.difference(now);
          });
        } else {
          timer.cancel();
          setState(() {
            _remainingTime = Duration.zero;
          });
          _autoCompleteAppointment();
        }
      });
    }
  }

  Future<void> _autoCompleteAppointment() async {
    if (!_isCompletingAppointment) {
      await _firestore.collection('appointments').doc(widget.appointmentId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'autoCompleted': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La cita finalizó automáticamente por tiempo'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Cita'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('appointments').doc(widget.appointmentId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final appointmentData = snapshot.data!.data() as Map<String, dynamic>?;
          if (appointmentData == null) {
            return const Center(child: Text('Cita no encontrada'));
          }

          final patientId = appointmentData['patientId'] as String;
          final appointmentDate = (appointmentData['appointmentDate'] as Timestamp).toDate();
          final duration = appointmentData['consultationMinutes'] as int? ?? 30;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timer card (solo para citas confirmadas)
                if (!widget.isPending && _remainingTime != null) ...[
                  Card(
                    color: _remainingTime!.inMinutes > 5 ? Colors.green[50] : Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer,
                            color: _remainingTime!.inMinutes > 5 ? Colors.green : Colors.red,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tiempo restante',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '${_remainingTime!.inMinutes}:${(_remainingTime!.inSeconds % 60).toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: _remainingTime!.inMinutes > 5 ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Información del paciente
                FutureBuilder<DocumentSnapshot>(
                  future: _firestore.collection('users').doc(patientId).get(),
                  builder: (context, patientSnapshot) {
                    if (!patientSnapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final patientData = patientSnapshot.data!.data() as Map<String, dynamic>?;
                    final patientName = patientData?['name'] ?? 'Paciente';
                    final patientEmail = patientData?['email'] ?? '';

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Información del Paciente',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.person, size: 20),
                                const SizedBox(width: 8),
                                Text(patientName, style: const TextStyle(fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.email, size: 20),
                                const SizedBox(width: 8),
                                Text(patientEmail, style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  '${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year} ${appointmentDate.hour.toString().padLeft(2, '0')}:${appointmentDate.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 20),
                                const SizedBox(width: 8),
                                Text('$duration minutos', style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                if (!widget.isPending) ...[
                  const SizedBox(height: 24),

                  // Historial Médico
                  const Text(
                    'Historial Médico',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _medicalHistoryController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Escribe el diagnóstico y observaciones...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Receta Médica
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Receta Médica',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddMedicineDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar Medicina'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4990E2),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Lista de medicinas seleccionadas
                  if (_selectedMedicines.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'No se han agregado medicinas a la receta',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ..._selectedMedicines.map((medicine) => _buildMedicineCard(medicine)).toList(),

                  const SizedBox(height: 24),

                  // Botón para finalizar cita
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _completeAppointment,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Finalizar Cita'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> medicine) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    medicine['description'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            final currentDose = medicine['dose'] as int;
                            if (currentDose > 50) {
                              medicine['dose'] = currentDose - 50;
                            }
                          });
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                        color: Colors.red,
                      ),
                      Text(
                        '${medicine['dose']} ${medicine['unit']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            medicine['dose'] = (medicine['dose'] as int) + 50;
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        color: Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _selectedMedicines.remove(medicine);
                });
              },
              icon: const Icon(Icons.delete),
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMedicineDialog() {
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredMedicines = _medicines
                .where((m) => m['name'].toString().toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return AlertDialog(
              title: const Text('Seleccionar Medicina'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Buscar medicina...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredMedicines.length,
                        itemBuilder: (context, index) {
                          final medicine = filteredMedicines[index];
                          return ListTile(
                            title: Text(medicine['name']),
                            subtitle: Text(medicine['description']),
                            trailing: Text('${medicine['defaultDose']} ${medicine['unit']}'),
                            onTap: () {
                              setState(() {
                                _selectedMedicines.add({
                                  'name': medicine['name'],
                                  'description': medicine['description'],
                                  'dose': medicine['defaultDose'],
                                  'unit': medicine['unit'],
                                });
                              });
                              Navigator.pop(context);
                            },
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
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _completeAppointment() async {
    if (_medicalHistoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingrese el historial médico')),
      );
      return;
    }

    if (_selectedMedicines.isEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sin receta médica'),
          content: const Text('¿Desea finalizar la cita sin agregar medicinas a la receta?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    setState(() {
      _isCompletingAppointment = true;
    });

    try {
      final appointmentDoc = await _firestore.collection('appointments').doc(widget.appointmentId).get();
      final appointmentData = appointmentDoc.data()!;
      final patientId = appointmentData['patientId'] as String;

      // Guardar historial médico y receta
      await _firestore
          .collection('users')
          .doc(patientId)
          .collection('medical_records')
          .add({
        'appointmentId': widget.appointmentId,
        'doctorId': appointmentData['doctorId'],
        'medicalHistory': _medicalHistoryController.text.trim(),
        'prescription': _selectedMedicines,
        'createdAt': FieldValue.serverTimestamp(),
        'appointmentDate': appointmentData['appointmentDate'],
      });

      // Actualizar estado de la cita
      await _firestore.collection('appointments').doc(widget.appointmentId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'manuallyCompleted': true,
      });

      _appointmentTimer?.cancel();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cita finalizada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al finalizar cita: $e')),
        );
      }
    } finally {
      setState(() {
        _isCompletingAppointment = false;
      });
    }
  }
}
