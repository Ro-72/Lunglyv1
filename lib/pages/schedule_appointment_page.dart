import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/doctor.dart';
import 'appointment_booking_page.dart';
// ESTA PAGINA ESTA DESCONTINUADA SOLO PARA EL ADMIN
class ScheduleAppointmentPage extends StatefulWidget {
  final String? selectedSpecialty;

  const ScheduleAppointmentPage({super.key, this.selectedSpecialty});

  @override
  State<ScheduleAppointmentPage> createState() => _ScheduleAppointmentPageState();
}

class _ScheduleAppointmentPageState extends State<ScheduleAppointmentPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;
  String _searchQuery = '';
  String? _selectedSpecialty;

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

  final List<String> _specialties = [
    'Todos',
    'Medicina General',
    'Dermatología',
    'Psiquiatría',
    'Otorrinolaringología',
    'Ginecología',
    'Cardiología',
    'Neumología',
    'Pediatría',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _specialties.length, vsync: this);

    // Si se pasó una especialidad seleccionada, navegar a esa pestaña
    if (widget.selectedSpecialty != null) {
      final index = _specialties.indexOf(widget.selectedSpecialty!);
      if (index != -1) {
        _tabController.index = index;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendar Cita'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar médico...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      onPressed: _showFilterDialog,
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: _specialties.map((specialty) => Tab(text: specialty)).toList(),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _specialties.map((specialty) {
          return _buildDoctorList(specialty);
        }).toList(),
      ),
      // TEMPORAL: Botón para agregar doctores de prueba
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTestDoctor,
        icon: const Icon(Icons.person_add),
        label: const Text('Doctor de Prueba'),
        backgroundColor: Colors.orange,
        tooltip: 'Agregar doctor de prueba (temporal)',
      ),
    );
  }

  Widget _buildDoctorList(String specialty) {
    return StreamBuilder<QuerySnapshot>(
      stream: specialty == 'Todos'
          ? _firestore.collection('doctors').snapshots()
          : _firestore
              .collection('doctors')
              .where('specialty', isEqualTo: specialty)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final doctors = snapshot.data?.docs
            .map((doc) => Doctor.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .where((doctor) {
              if (_searchQuery.isEmpty) return true;
              return doctor.name.toLowerCase().contains(_searchQuery) ||
                  doctor.specialty.toLowerCase().contains(_searchQuery);
            })
            .toList() ?? [];

        if (doctors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No se encontraron médicos',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: doctors.length,
          itemBuilder: (context, index) {
            return _buildDoctorCard(doctors[index]);
          },
        );
      },
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue[100],
            backgroundImage: doctor.profileImageUrl != null && doctor.profileImageUrl!.isNotEmpty
                ? NetworkImage(doctor.profileImageUrl!)
                : AssetImage(_getDefaultDoctorImage(doctor.id)),
            child: null,
          ),
          title: Text(
            doctor.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                doctor.title,
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber[700]),
                  const SizedBox(width: 4),
                  Text(
                    '${doctor.rating.toStringAsFixed(1)} (${doctor.reviewCount} reseñas)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Text(
                  '\$${doctor.pricePerAppointment.toStringAsFixed(2)} por cita',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          children: [
            const Divider(),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Acerca del Dr. ${doctor.name}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              doctor.description,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _scheduleAppointment(doctor);
                },
                icon: const Icon(Icons.calendar_today),
                label: const Text('Agendar Cita'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar por'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Precio más bajo'),
              leading: Radio<String>(
                value: 'price_low',
                groupValue: _selectedSpecialty,
                onChanged: (value) {
                  setState(() {
                    _selectedSpecialty = value;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Mejor calificación'),
              leading: Radio<String>(
                value: 'rating_high',
                groupValue: _selectedSpecialty,
                onChanged: (value) {
                  setState(() {
                    _selectedSpecialty = value;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Más reseñas'),
              leading: Radio<String>(
                value: 'reviews_high',
                groupValue: _selectedSpecialty,
                onChanged: (value) {
                  setState(() {
                    _selectedSpecialty = value;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedSpecialty = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Limpiar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _scheduleAppointment(Doctor doctor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentBookingPage(doctor: doctor),
      ),
    );
  }

  // TEMPORAL: Función para agregar doctores de prueba con datos peruanos
  Future<void> _addTestDoctor() async {
    final random = Random();

    // Nombres peruanos comunes
    final List<String> nombres = [
      'Carlos', 'María', 'José', 'Ana', 'Luis', 'Carmen', 'Pedro', 'Rosa',
      'Miguel', 'Isabel', 'Francisco', 'Elena', 'Antonio', 'Sofía', 'Manuel',
      'Patricia', 'Jorge', 'Lucía', 'Ricardo', 'Claudia'
    ];

    // Apellidos peruanos comunes
    final List<String> apellidos = [
      'García', 'Rodríguez', 'Martínez', 'López', 'González', 'Pérez',
      'Sánchez', 'Ramírez', 'Torres', 'Flores', 'Vargas', 'Castillo',
      'Romero', 'Herrera', 'Medina', 'Gutiérrez', 'Rojas', 'Díaz'
    ];

    // Títulos médicos
    final List<String> titulos = [
      'MD, PhD',
      'MD, MSc',
      'MD',
      'MD, FACP',
      'MD, FCCP',
      'MD, DNB'
    ];

    // Ciudades peruanas principales
    final List<String> ciudades = [
      'Lima', 'Arequipa', 'Trujillo', 'Chiclayo', 'Cusco',
      'Piura', 'Iquitos', 'Huancayo', 'Tacna', 'Pucallpa'
    ];

    // Hospitales peruanos reconocidos
    final List<String> hospitales = [
      'Hospital Rebagliati',
      'Hospital Almenara',
      'Hospital Dos de Mayo',
      'Clínica Ricardo Palma',
      'Clínica San Felipe',
      'Hospital Loayza',
      'Clínica Anglo Americana',
      'Hospital Cayetano Heredia',
      'Clínica Internacional',
      'Hospital María Auxiliadora'
    ];

    // Calificaciones médicas
    final List<List<String>> qualificationsBySpecialty = [
      ['Médico Cirujano', 'Neumología', 'FCCP'],
      ['Médico Cirujano', 'Especialista en Neumología', 'Magíster en Medicina'],
      ['Médico Cirujano', 'Neumología Pediátrica', 'DNB'],
      ['Médico Cirujano', 'Cardiología', 'FACP'],
      ['Médico Cirujano', 'Medicina Interna'],
    ];

    final Map<String, List<String>> especialidadesConDescripciones = {
      'Neumología': [
        'Especialista en enfermedades respiratorias con amplia experiencia en el tratamiento de asma, EPOC y fibrosis pulmonar.',
        'Experto en el diagnóstico y tratamiento de patologías pulmonares crónicas y agudas.',
        'Médico especializado en cuidado respiratorio con enfoque en medicina preventiva y rehabilitación pulmonar.',
      ],
      'Cardiología': [
        'Cardiólogo con especialización en prevención y tratamiento de enfermedades cardiovasculares.',
        'Experto en arritmias cardíacas e insuficiencia cardíaca con tecnología de vanguardia.',
        'Especialista en hipertensión arterial y rehabilitación cardíaca con enfoque integral.',
      ],
      'Medicina General': [
        'Médico general con enfoque integral en la salud del paciente y medicina preventiva.',
        'Especialista en atención primaria con amplia experiencia en diagnóstico y tratamiento.',
        'Médico familiar dedicado al cuidado integral de pacientes de todas las edades.',
      ],
      'Pediatría': [
        'Pediatra especializado en el cuidado integral de niños y adolescentes.',
        'Experto en desarrollo infantil y enfermedades pediátricas comunes.',
        'Médico pediatra con enfoque en medicina preventiva y vacunación infantil.',
      ],
    };

    final especialidad = especialidadesConDescripciones.keys.elementAt(
      random.nextInt(especialidadesConDescripciones.length)
    );

    final nombre = '${nombres[random.nextInt(nombres.length)]} ${apellidos[random.nextInt(apellidos.length)]}';
    final titulo = titulos[random.nextInt(titulos.length)];
    final descripcion = especialidadesConDescripciones[especialidad]![
      random.nextInt(especialidadesConDescripciones[especialidad]!.length)
    ];

    // Precios en soles peruanos (S/)
    final precio = (random.nextInt(16) + 10) * 10.0; // Entre S/100 y S/250

    final rating = (random.nextInt(21) + 30) / 10.0; // Entre 3.0 y 5.0
    final reviewCount = random.nextInt(100) + 10; // Entre 10 y 110 reseñas
    final yearsExperience = random.nextInt(16) + 5; // Entre 5 y 20 años
    final patientCount = random.nextInt(3000) + 500; // Entre 500 y 3500 pacientes
    final consultationMinutes = [15, 20, 25, 30][random.nextInt(4)];
    final distanceKm = random.nextDouble() * 50 + 5; // Entre 5 y 55 km
    final isApolloDoctor = random.nextBool();

    final ciudad = ciudades[random.nextInt(ciudades.length)];
    final hospital = hospitales[random.nextInt(hospitales.length)];
    final qualifications = qualificationsBySpecialty[random.nextInt(qualificationsBySpecialty.length)];

    // Idiomas comunes en Perú
    final idiomas = <String>['Español']; // Siempre español
    if (random.nextBool()) idiomas.add('Inglés');
    if (random.nextInt(10) < 2) idiomas.add('Quechua'); // 20% habla quechua

    final doctor = Doctor(
      id: '',
      name: 'Dr. $nombre',
      title: titulo,
      specialty: especialidad,
      description: descripcion,
      pricePerAppointment: precio,
      rating: rating,
      reviewCount: reviewCount,
      yearsExperience: yearsExperience,
      qualifications: qualifications,
      languages: idiomas,
      distanceKm: distanceKm,
      city: ciudad,
      hospital: hospital,
      patientCount: patientCount,
      consultationMinutes: consultationMinutes,
      isApolloDoctor: isApolloDoctor,
    );

    try {
      await _firestore.collection('doctors').add(doctor.toMap());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Doctor de prueba agregado: ${doctor.name} - ${doctor.hospital}, ${doctor.city}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar doctor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
