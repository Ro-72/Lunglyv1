import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/treatment.dart';
import '../models/medication.dart';

class TreatmentHistoryPage extends StatefulWidget {
  const TreatmentHistoryPage({super.key});

  @override
  State<TreatmentHistoryPage> createState() => _TreatmentHistoryPageState();
}

class _TreatmentHistoryPageState extends State<TreatmentHistoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _filterStatus = 'Todos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Tratamientos'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Filtrar:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Todos'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Activos'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Completados'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Cancelados'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Lista de tratamientos
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('treatments')
                  .where('userId', isEqualTo: _auth.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allTreatments = snapshot.data?.docs
                    .map((doc) => Treatment.fromMap(
                        doc.data() as Map<String, dynamic>, doc.id))
                    .toList() ?? [];

                // Ordenar por fecha de creación (más reciente primero)
                allTreatments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                // Filtrar según el estado seleccionado
                final filteredTreatments = _filterTreatments(allTreatments);

                if (filteredTreatments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay tratamientos ${_filterStatus.toLowerCase()}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredTreatments.length,
                  itemBuilder: (context, index) {
                    return _buildTreatmentCard(filteredTreatments[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filterStatus == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = label;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  List<Treatment> _filterTreatments(List<Treatment> treatments) {
    if (_filterStatus == 'Todos') {
      return treatments;
    } else if (_filterStatus == 'Activos') {
      return treatments.where((t) => t.isActive).toList();
    } else if (_filterStatus == 'Completados') {
      return treatments.where((t) => !t.isActive && _isCompleted(t)).toList();
    } else if (_filterStatus == 'Cancelados') {
      return treatments.where((t) => !t.isActive && !_isCompleted(t)).toList();
    }
    return treatments;
  }

  bool _isCompleted(Treatment treatment) {
    // Un tratamiento está completado si todos sus medicamentos están expirados
    return treatment.medications.every((med) => med.isExpired);
  }

  Widget _buildTreatmentCard(Treatment treatment) {
    final isActive = treatment.isActive;
    final isCompleted = !isActive && _isCompleted(treatment);
    final completedMeds = treatment.medications.where((m) => m.isExpired).length;
    final totalMeds = treatment.medications.length;
    final progress = totalMeds > 0 ? completedMeds / totalMeds : 0.0;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isActive) {
      statusColor = Colors.green;
      statusText = 'Activo';
      statusIcon = Icons.play_circle;
    } else if (isCompleted) {
      statusColor = Colors.blue;
      statusText = 'Completado';
      statusIcon = Icons.check_circle;
    } else {
      statusColor = Colors.orange;
      statusText = 'Cancelado';
      statusIcon = Icons.cancel;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _showTreatmentDetails(treatment),
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
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statusIcon, color: statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          treatment.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (treatment.description.isNotEmpty)
                          Text(
                            treatment.description,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.medication, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '$totalMeds medicamento${totalMeds != 1 ? "s" : ""}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(treatment.createdAt),
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              if (isActive || isCompleted) ...[
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progreso',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '$completedMeds/$totalMeds completados',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showTreatmentDetails(Treatment treatment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    treatment.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  if (treatment.description.isNotEmpty) ...[
                    const Text(
                      'Descripción',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      treatment.description,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'Medicamentos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...treatment.medications.map((med) => _buildMedicationItem(med)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationItem(Medication medication) {
    final isExpired = medication.isExpired;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isExpired ? Colors.grey[100] : Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isExpired ? Colors.grey[300]! : Colors.blue[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.medication,
            color: isExpired ? Colors.grey : Colors.blue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: isExpired ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  '${medication.dosage} - ${medication.frequency}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (isExpired)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Finalizado',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${medication.daysRemaining} días',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
