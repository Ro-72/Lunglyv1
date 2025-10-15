import 'package:flutter/material.dart';

class Prescription {
  final String id;
  final String medicationName;
  final String date;
  final String doctor;
  final String dosage;
  final String frequency;
  final String duration;
  final String notes;
  final String status;

  Prescription({
    required this.id,
    required this.medicationName,
    required this.date,
    required this.doctor,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.notes,
    required this.status,
  });
}

class PrescriptionsPage extends StatefulWidget {
  const PrescriptionsPage({super.key});

  @override
  State<PrescriptionsPage> createState() => _PrescriptionsPageState();
}

class _PrescriptionsPageState extends State<PrescriptionsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'Todos';

  // Datos de prueba
  final List<Prescription> _allPrescriptions = [
    Prescription(
      id: '1',
      medicationName: 'Paracetamol 500mg',
      date: '15 de Marzo 2025',
      doctor: 'Dr. Juan Pérez',
      dosage: '500mg',
      frequency: 'Cada 8 horas',
      duration: '7 días',
      notes: 'Tomar después de las comidas',
      status: 'Activa',
    ),
    Prescription(
      id: '2',
      medicationName: 'Omeprazol 20mg',
      date: '10 de Marzo 2025',
      doctor: 'Dra. María González',
      dosage: '20mg',
      frequency: 'Una vez al día',
      duration: '30 días',
      notes: 'Tomar en ayunas, 30 minutos antes del desayuno',
      status: 'Activa',
    ),
    Prescription(
      id: '3',
      medicationName: 'Amoxicilina 500mg',
      date: '28 de Febrero 2025',
      doctor: 'Dr. Carlos Ramírez',
      dosage: '500mg',
      frequency: 'Cada 12 horas',
      duration: '10 días',
      notes: 'Completar todo el tratamiento aunque se sienta mejor',
      status: 'Completada',
    ),
    Prescription(
      id: '4',
      medicationName: 'Loratadina 10mg',
      date: '20 de Febrero 2025',
      doctor: 'Dra. Ana Martínez',
      dosage: '10mg',
      frequency: 'Una vez al día',
      duration: '15 días',
      notes: 'Para alergia estacional',
      status: 'Completada',
    ),
    Prescription(
      id: '5',
      medicationName: 'Ibuprofeno 400mg',
      date: '12 de Febrero 2025',
      doctor: 'Dr. Luis Fernández',
      dosage: '400mg',
      frequency: 'Cada 8 horas si hay dolor',
      duration: '5 días',
      notes: 'Tomar con alimentos. No exceder 1200mg diarios',
      status: 'Completada',
    ),
    Prescription(
      id: '6',
      medicationName: 'Metformina 850mg',
      date: '5 de Febrero 2025',
      doctor: 'Dra. Patricia Sánchez',
      dosage: '850mg',
      frequency: 'Dos veces al día',
      duration: 'Uso continuo',
      notes: 'Control de glucosa. Tomar con desayuno y cena',
      status: 'Activa',
    ),
    Prescription(
      id: '7',
      medicationName: 'Atorvastatina 20mg',
      date: '1 de Febrero 2025',
      doctor: 'Dr. Carlos Ramírez',
      dosage: '20mg',
      frequency: 'Una vez al día',
      duration: 'Uso continuo',
      notes: 'Tomar por la noche. Control de colesterol',
      status: 'Activa',
    ),
    Prescription(
      id: '8',
      medicationName: 'Salbutamol Inhalador',
      date: '25 de Enero 2025',
      doctor: 'Dr. Juan Pérez',
      dosage: '100mcg por inhalación',
      frequency: 'Según necesidad',
      duration: 'Uso continuo',
      notes: 'Para crisis de asma. Máximo 8 inhalaciones al día',
      status: 'Activa',
    ),
  ];

  final List<String> _statusList = ['Todos', 'Activa', 'Completada'];

  List<Prescription> get _filteredPrescriptions {
    return _allPrescriptions.where((prescription) {
      final matchesSearch = prescription.medicationName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          prescription.doctor.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          prescription.notes.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _selectedStatus == 'Todos' || prescription.status == _selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Recetas'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por medicamento, doctor o notas...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Filtros de estado
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _statusList.length,
              itemBuilder: (context, index) {
                final status = _statusList[index];
                final isSelected = _selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = status;
                      });
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Colors.purple[300],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Resultados
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredPrescriptions.length} receta(s) encontrada(s)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                if (_searchQuery.isNotEmpty || _selectedStatus != 'Todos')
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                        _selectedStatus = 'Todos';
                      });
                    },
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Limpiar filtros'),
                  ),
              ],
            ),
          ),

          const Divider(),

          // Lista de recetas
          Expanded(
            child: _filteredPrescriptions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron recetas',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredPrescriptions.length,
                    itemBuilder: (context, index) {
                      final prescription = _filteredPrescriptions[index];
                      return _buildPrescriptionCard(prescription);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(Prescription prescription) {
    final isActive = prescription.status == 'Activa';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showPrescriptionDetails(prescription),
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
                      color: isActive ? Colors.purple[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.medication,
                      color: isActive ? Colors.purple[700] : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prescription.medicationName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prescription.date,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      prescription.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.green[700] : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    prescription.doctor,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    prescription.frequency,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    prescription.duration,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                prescription.notes,
                style: const TextStyle(fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showPrescriptionDetails(prescription),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Ver detalles'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrescriptionDetails(Prescription prescription) {
    final isActive = prescription.status == 'Activa';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Expanded(
              child: Text(prescription.medicationName),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.green[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                prescription.status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.green[700] : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Fecha de prescripción:', prescription.date),
              const SizedBox(height: 12),
              _buildDetailRow('Médico:', prescription.doctor),
              const SizedBox(height: 12),
              _buildDetailRow('Dosis:', prescription.dosage),
              const SizedBox(height: 12),
              _buildDetailRow('Frecuencia:', prescription.frequency),
              const SizedBox(height: 12),
              _buildDetailRow('Duración:', prescription.duration),
              const SizedBox(height: 12),
              const Text(
                'Instrucciones:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Text(
                  prescription.notes,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}
