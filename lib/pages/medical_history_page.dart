import 'package:flutter/material.dart';

class MedicalHistory {
  final String id;
  final String title;
  final String date;
  final String doctor;
  final String diagnosis;
  final String treatment;
  final String category;

  MedicalHistory({
    required this.id,
    required this.title,
    required this.date,
    required this.doctor,
    required this.diagnosis,
    required this.treatment,
    required this.category,
  });
}

class MedicalHistoryPage extends StatefulWidget {
  const MedicalHistoryPage({super.key});

  @override
  State<MedicalHistoryPage> createState() => _MedicalHistoryPageState();
}

class _MedicalHistoryPageState extends State<MedicalHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Todos';

  // Datos de prueba
  final List<MedicalHistory> _allRecords = [
    MedicalHistory(
      id: '1',
      title: 'Consulta General',
      date: '15 de Marzo 2025',
      doctor: 'Dr. Juan Pérez',
      diagnosis: 'Resfriado común',
      treatment: 'Paracetamol 500mg cada 8 horas, reposo',
      category: 'Consulta General',
    ),
    MedicalHistory(
      id: '2',
      title: 'Examen de Laboratorio',
      date: '10 de Marzo 2025',
      doctor: 'Dra. María González',
      diagnosis: 'Análisis de sangre - Valores normales',
      treatment: 'No requiere tratamiento, seguimiento anual',
      category: 'Laboratorio',
    ),
    MedicalHistory(
      id: '3',
      title: 'Control Cardiovascular',
      date: '5 de Marzo 2025',
      doctor: 'Dr. Carlos Ramírez',
      diagnosis: 'Presión arterial ligeramente elevada',
      treatment: 'Dieta baja en sodio, ejercicio 30 min diarios',
      category: 'Cardiología',
    ),
    MedicalHistory(
      id: '4',
      title: 'Consulta Dermatológica',
      date: '28 de Febrero 2025',
      doctor: 'Dra. Ana Martínez',
      diagnosis: 'Dermatitis por contacto',
      treatment: 'Crema con corticoides, evitar alérgenos',
      category: 'Dermatología',
    ),
    MedicalHistory(
      id: '5',
      title: 'Radiografía de Tórax',
      date: '20 de Febrero 2025',
      doctor: 'Dr. Luis Fernández',
      diagnosis: 'Sin hallazgos patológicos',
      treatment: 'No requiere tratamiento',
      category: 'Radiología',
    ),
    MedicalHistory(
      id: '6',
      title: 'Consulta Oftalmológica',
      date: '12 de Febrero 2025',
      doctor: 'Dra. Patricia Sánchez',
      diagnosis: 'Miopía leve',
      treatment: 'Prescripción de lentes correctivos',
      category: 'Oftalmología',
    ),
  ];

  final List<String> _categories = [
    'Todos',
    'Consulta General',
    'Laboratorio',
    'Cardiología',
    'Dermatología',
    'Radiología',
    'Oftalmología',
  ];

  List<MedicalHistory> get _filteredRecords {
    return _allRecords.where((record) {
      final matchesSearch = record.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          record.doctor.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          record.diagnosis.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == 'Todos' || record.category == _selectedCategory;

      return matchesSearch && matchesCategory;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 42,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Buscar en historial...',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: Icon(Icons.filter_list, color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
            ),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filtros de categoría
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Colors.orange[300],
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
                  '${_filteredRecords.length} registro(s) encontrado(s)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                if (_searchQuery.isNotEmpty || _selectedCategory != 'Todos')
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                        _selectedCategory = 'Todos';
                      });
                    },
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Limpiar filtros'),
                  ),
              ],
            ),
          ),

          const Divider(),

          // Lista de registros
          Expanded(
            child: _filteredRecords.isEmpty
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
                          'No se encontraron registros',
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
                    itemCount: _filteredRecords.length,
                    itemBuilder: (context, index) {
                      final record = _filteredRecords[index];
                      return _buildRecordCard(record);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(MedicalHistory record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showRecordDetails(record),
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
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.medical_services,
                      color: Colors.orange[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          record.date,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      record.category,
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor: Colors.orange[50],
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    record.doctor,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                record.diagnosis,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showRecordDetails(record),
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

  void _showRecordDetails(MedicalHistory record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(record.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Fecha:', record.date),
              const SizedBox(height: 12),
              _buildDetailRow('Doctor:', record.doctor),
              const SizedBox(height: 12),
              _buildDetailRow('Categoría:', record.category),
              const SizedBox(height: 12),
              const Text(
                'Diagnóstico:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(record.diagnosis),
              const SizedBox(height: 12),
              const Text(
                'Tratamiento:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(record.treatment),
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
