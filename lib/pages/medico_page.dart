import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor.dart';

class MedicoPage extends StatefulWidget {
  const MedicoPage({super.key});

  @override
  State<MedicoPage> createState() => _MedicoPageState();
}

class _MedicoPageState extends State<MedicoPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedExperience = 'Todos';
  String _selectedLanguage = 'Todos';

  List<Doctor> _filterDoctors(List<Doctor> doctors) {
    return doctors.where((doctor) {
      // Filtro de búsqueda
      final matchesSearch = _searchQuery.isEmpty ||
          doctor.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          doctor.hospital.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          doctor.city.toLowerCase().contains(_searchQuery.toLowerCase());

      // Filtro de experiencia
      final matchesExperience = _selectedExperience == 'Todos' ||
          (_selectedExperience == '5-10 años' && doctor.yearsExperience >= 5 && doctor.yearsExperience <= 10) ||
          (_selectedExperience == '10-15 años' && doctor.yearsExperience >= 10 && doctor.yearsExperience <= 15) ||
          (_selectedExperience == '15+ años' && doctor.yearsExperience > 15);

      // Filtro de idioma
      final matchesLanguage = _selectedLanguage == 'Todos' ||
          doctor.languages.contains(_selectedLanguage);

      return matchesSearch && matchesExperience && matchesLanguage;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar médico, hospital o ciudad...',
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
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              // Filters Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'Experiencia',
                      value: _selectedExperience,
                      options: ['Todos', '5-10 años', '10-15 años', '15+ años'],
                      onChanged: (value) {
                        setState(() {
                          _selectedExperience = value;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Idioma',
                      value: _selectedLanguage,
                      options: ['Todos', 'Español', 'Inglés', 'Hindi', 'Árabe'],
                      onChanged: (value) {
                        setState(() {
                          _selectedLanguage = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Doctor Cards List with StreamBuilder
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('doctors')
                .where('specialty', whereIn: ['Neumología', 'Neumología Pediátrica', 'Neumología Intervencionista'])
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar médicos',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final doctors = snapshot.data?.docs
                  .map((doc) => Doctor.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                  .toList() ?? [];

              final filteredDoctors = _filterDoctors(doctors);

              return Column(
                children: [
                  // Results Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Neumólogos Disponibles',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '${filteredDoctors.length} médicos',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  // Doctor Cards
                  Expanded(
                    child: filteredDoctors.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No se encontraron médicos',
                                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredDoctors.length,
                            itemBuilder: (context, index) {
                              return _buildDoctorCard(filteredDoctors[index]);
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required List<String> options,
    required Function(String) onChanged,
  }) {
    return PopupMenuButton<String>(
      child: Chip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value == 'Todos' ? label : value,
              style: TextStyle(
                color: value != 'Todos' ? Theme.of(context).colorScheme.primary : null,
                fontWeight: value != 'Todos' ? FontWeight.bold : null,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
        backgroundColor: value != 'Todos'
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.white,
      ),
      onSelected: onChanged,
      itemBuilder: (context) {
        return options.map((option) {
          return PopupMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList();
      },
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Photo with Badge
                Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                      ),
                      child: ClipOval(
                        child: doctor.profileImageUrl != null
                            ? Image.network(
                                doctor.profileImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.person, size: 50, color: Colors.grey[400]);
                                },
                              )
                            : Icon(Icons.person, size: 50, color: Colors.grey[400]),
                      ),
                    ),
                    if (doctor.isApolloDoctor)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.lightBlue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Doctor Asegurador',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Doctor Information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Doctor Name
                      Text(
                        doctor.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Specialty
                      Text(
                        doctor.specialty,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Experience
                      Text(
                        '${doctor.yearsExperience} YEARS EXP',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Qualifications
                      Text(
                        doctor.qualifications.join(', '),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Languages
                      Text(
                        doctor.languages.join(', '),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Location
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${doctor.distanceKm.toStringAsFixed(0)} Km • ${doctor.city}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Hospital
                      Text(
                        doctor.hospital,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Rating
                      if (doctor.rating > 0 && doctor.patientCount != null)
                        Row(
                          children: [
                            const Icon(Icons.thumb_up, size: 14, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              '${(doctor.rating * 20).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${doctor.patientCount} pacientes)',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Price
            Text(
              'S/${doctor.pricePerAppointment.toStringAsFixed(0)}${doctor.followUpFee != null ? "/S/${doctor.followUpFee}" : ""}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            // Online Consult Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Handle online consultation
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Consulta Online',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Consulta en ${doctor.consultationMinutes} mins',
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Responder Button (optional)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // Handle response
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.teal,
                  side: const BorderSide(color: Colors.teal),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Detalles',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
