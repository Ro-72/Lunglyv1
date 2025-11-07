import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor.dart';
import 'appointment_booking_page.dart';
import 'doctor_detail_page.dart';

class MedicoPage extends StatefulWidget {
  final String? selectedSpecialty;

  const MedicoPage({super.key, this.selectedSpecialty});

  @override
  State<MedicoPage> createState() => _MedicoPageState();
}

class _MedicoPageState extends State<MedicoPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedLocation = 'Todos';
  late String _selectedSpecialty;

  @override
  void initState() {
    super.initState();
    // Inicializar con la especialidad seleccionada o 'Todos'
    _selectedSpecialty = widget.selectedSpecialty ?? 'Todos';
  }

  // Lista de imágenes por defecto disponibles
  final List<String> _defaultDoctorImages = [
    'assets/photos/0868a03e801b077b8cdfa5b164fe2a08_medium_square.jpg',
    'assets/photos/32d4f7b7-5d21-4250-973c-1f621051c500_medium_square.jpg',
    'assets/photos/976f14d7-bda9-41e1-94dc-89b4f5f14efa_medium_square.jpg',
    'assets/photos/e10cc9d0d8671ebb7ea12d22badd52f5.jpeg',
    'assets/photos/e10cc9d0d8671ebb7ea12d22badd52f5_140_square.jpg',
  ];

  // Obtener imagen por defecto según el ID del doctor
  String _getDefaultDoctorImage(String doctorId) {
    final index = doctorId.hashCode.abs() % _defaultDoctorImages.length;
    return _defaultDoctorImages[index];
  }

  List<Doctor> _filterDoctors(List<Doctor> doctors) {
    return doctors.where((doctor) {
      // Filtro de búsqueda
      final matchesSearch =
          _searchQuery.isEmpty ||
          doctor.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          doctor.hospital.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          doctor.city.toLowerCase().contains(_searchQuery.toLowerCase());

      // Filtro de especialidad
      final matchesSpecialty =
          _selectedSpecialty == 'Todos' ||
          doctor.specialty == _selectedSpecialty;

      // Filtro de ubicación
      final matchesLocation =
          _selectedLocation == 'Todos' ||
          doctor.city.toLowerCase().contains(_selectedLocation.toLowerCase());

      return matchesSearch && matchesSpecialty && matchesLocation;
    }).toList();
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
              hintText: 'Buscar médicos...',
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
          // Filters Row
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'Especialidad',
                    value: _selectedSpecialty,
                    options: [
                      'Todos',
                      'Medicina General',
                      'Dermatología',
                      'Psiquiatría',
                      'Otorrinolaringología',
                      'Ginecología',
                      'Cardiología',
                      'Neumología',
                      'Pediatría',
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSpecialty = value;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Lugar',
                    value: _selectedLocation,
                    options: [
                      'Todos',
                      'Lima',
                      'Arequipa',
                      'Trujillo',
                      'Chiclayo',
                      'Cusco',
                      'Piura',
                      'Ica',
                      'Tacna',
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedLocation = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          // Doctor Cards List with StreamBuilder
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('doctors').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar médicos',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final doctors =
                    snapshot.data?.docs
                        .map(
                          (doc) => Doctor.fromMap(
                            doc.data() as Map<String, dynamic>,
                            doc.id,
                          ),
                        )
                        .toList() ??
                    [];

                final filteredDoctors = _filterDoctors(doctors);

                return Column(
                  children: [
                    // Results Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _selectedSpecialty == 'Todos'
                                  ? 'Médicos Disponibles'
                                  : '$_selectedSpecialty - Disponibles',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
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
                      child:
                          filteredDoctors.isEmpty
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
                                      'No se encontraron médicos',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: filteredDoctors.length,
                                itemBuilder: (context, index) {
                                  return _buildDoctorCard(
                                    filteredDoctors[index],
                                  );
                                },
                              ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
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
                color:
                    value != 'Todos'
                        ? Theme.of(context).colorScheme.primary
                        : null,
                fontWeight: value != 'Todos' ? FontWeight.bold : null,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
        backgroundColor:
            value != 'Todos'
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Colors.white,
      ),
      onSelected: onChanged,
      itemBuilder: (context) {
        return options.map((option) {
          return PopupMenuItem<String>(value: option, child: Text(option));
        }).toList();
      },
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        child:
                            doctor.profileImageUrl != null &&
                                    doctor.profileImageUrl!.isNotEmpty
                                ? Image.network(
                                  doctor.profileImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    // Si falla la carga de la red, usar imagen por defecto
                                    return Image.asset(
                                      _getDefaultDoctorImage(doctor.id),
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.grey[400],
                                        );
                                      },
                                    );
                                  },
                                )
                                : Image.asset(
                                  _getDefaultDoctorImage(doctor.id),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.grey[400],
                                    );
                                  },
                                ),
                      ),
                    ),
                    if (doctor.isApolloDoctor)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 2,
                            horizontal: 4,
                          ),
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
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Languages
                      Text(
                        doctor.languages.join(', '),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 6),
                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[600],
                          ),
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
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 6),
                      // Rating
                      if (doctor.rating > 0 && doctor.patientCount != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.thumb_up,
                              size: 14,
                              color: Colors.green,
                            ),
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
              'S/${doctor.pricePerAppointment.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            // Agendar Cita Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => AppointmentBookingPage(doctor: doctor),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today, size: 18),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Agendar Cita',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Consulta de ${doctor.consultationMinutes} mins',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Detalles Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DoctorDetailPage(doctor: doctor),
                    ),
                  );
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
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
