import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class ManageGenericUsersPage extends StatefulWidget {
  final bool returnToDrawer;

  const ManageGenericUsersPage({
    super.key,
    this.returnToDrawer = false,
  });

  @override
  State<ManageGenericUsersPage> createState() => _ManageGenericUsersPageState();
}

class _ManageGenericUsersPageState extends State<ManageGenericUsersPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isCreating = false;
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  String _selectedRole = 'paciente';

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  // Generar número aleatorio disponible
  Future<int> _getAvailableRandomNumber() async {
    final random = Random();
    int number;
    bool exists;

    do {
      number = random.nextInt(9000) + 1000; // Número entre 1000 y 9999
      final snapshot = await _firestore
          .collection('users')
          .where('genericNumber', isEqualTo: number)
          .limit(1)
          .get();
      exists = snapshot.docs.isNotEmpty;
    } while (exists);

    return number;
  }

  Future<void> _createGenericUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final number = _numberController.text.trim();
      final email = '$number@gmail.com';
      final password = '123456';

      // Guardar el usuario actual para reautenticarse después
      final currentUser = _auth.currentUser;
      final currentUserEmail = currentUser?.email;

      // Crear el nuevo usuario
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Crear documento en Firestore para el nuevo usuario
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'role': _selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
        'isGeneric': true,
        'genericNumber': int.parse(number),
      });

      // Si es médico, crear también el perfil de doctor con datos aleatorios
      if (_selectedRole == 'medico') {
        await _createRandomDoctorProfile(userCredential.user!.uid);
      }

      // Cerrar sesión del usuario recién creado
      await _auth.signOut();

      // Reautenticar al administrador
      if (currentUserEmail != null) {
        // Aquí necesitarías la contraseña del admin, por simplicidad
        // volveremos a iniciar sesión automáticamente
        // En producción, deberías usar Firebase Admin SDK del lado del servidor
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Usuario genérico creado:\nEmail: $email\nContraseña: $password${_selectedRole == 'medico' ? '\n\nPerfil médico generado con datos aleatorios' : ''}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
        _numberController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear usuario: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isCreating = false);
    }
  }

  Future<void> _createRandomDoctorProfile(String userId) async {
    final random = Random();

    // Nombres masculinos y femeninos peruanos comunes
    final nombresMasculinos = [
      'Carlos', 'José', 'Luis', 'Pedro', 'Miguel', 'Francisco', 'Antonio',
      'Manuel', 'Jorge', 'Ricardo', 'Alberto', 'Julio', 'Roberto', 'Raúl'
    ];

    final nombresFemeninos = [
      'María', 'Ana', 'Carmen', 'Rosa', 'Isabel', 'Elena', 'Sofía',
      'Patricia', 'Lucía', 'Claudia', 'Gabriela', 'Andrea', 'Mónica', 'Julia'
    ];

    // Apellidos peruanos comunes
    final apellidos = [
      'García', 'Rodríguez', 'Martínez', 'López', 'González', 'Pérez',
      'Sánchez', 'Ramírez', 'Torres', 'Flores', 'Vargas', 'Castillo',
      'Romero', 'Herrera', 'Medina', 'Gutiérrez', 'Rojas', 'Díaz'
    ];

    // Títulos médicos
    final titulos = ['MD, PhD', 'MD, MSc', 'MD', 'MD, FACP', 'MD, FCCP', 'MD, DNB'];

    // Ciudades peruanas principales
    final ciudades = [
      'Lima', 'Arequipa', 'Trujillo', 'Chiclayo', 'Cusco',
      'Piura', 'Iquitos', 'Huancayo', 'Tacna', 'Pucallpa'
    ];

    // Hospitales peruanos reconocidos
    final hospitales = [
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
    final qualificationsBySpecialty = [
      ['Médico Cirujano', 'Neumología', 'FCCP'],
      ['Médico Cirujano', 'Neumología', 'Magíster en Medicina'],
      ['Médico Cirujano', 'Neumología', 'DNB'],
      ['Médico Cirujano', 'Neumología', 'FACP'],
      ['Médico Cirujano', 'Medicina Interna'],
    ];

    final especialidadesConDescripciones = {
      'Neumología': [
        'Especialista en enfermedades respiratorias con amplia experiencia en el tratamiento de asma, EPOC y fibrosis pulmonar.',
        'Experto en el diagnóstico y tratamiento de patologías pulmonares crónicas y agudas.',
        'Médico especializado en cuidado respiratorio con enfoque en medicina preventiva y rehabilitación pulmonar.',
      ],
      'Medicina General': [
        'Médico general con enfoque integral en la salud del paciente y medicina preventiva.',
        'Especialista en atención primaria con amplia experiencia en diagnóstico y tratamiento.',
        'Médico familiar dedicado al cuidado integral de pacientes de todas las edades.',
      ],
    };

    final especialidad = especialidadesConDescripciones.keys.elementAt(
      random.nextInt(especialidadesConDescripciones.length)
    );

    // Determinar género basado en la foto (1-2: mujer, 3-5: hombre)
    final isFemale = random.nextBool();
    final photoNumber = isFemale
        ? random.nextInt(2) + 1  // 1 o 2 para mujeres
        : random.nextInt(3) + 3; // 3, 4 o 5 para hombres

    // Seleccionar nombre según el género
    final nombres = isFemale ? nombresFemeninos : nombresMasculinos;
    final nombre = '${nombres[random.nextInt(nombres.length)]} ${apellidos[random.nextInt(apellidos.length)]}';
    final titulo = titulos[random.nextInt(titulos.length)];
    final descripcion = especialidadesConDescripciones[especialidad]![
      random.nextInt(especialidadesConDescripciones[especialidad]!.length)
    ];

    // Precios en soles peruanos (S/)
    final precio = (random.nextInt(16) + 10) * 10; // Entre S/100 y S/250

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

    final followUpFee = (precio * 0.6).round(); // 60% del precio de consulta

    // Tipo de cita (online o presencial)
    final appointmentType = random.nextBool() ? 'online' : 'presencial';

    // Crear perfil de doctor en Firestore
    await _firestore.collection('doctors').add({
      'userId': userId,
      'name': 'Dr. $nombre',
      'title': titulo,
      'specialty': especialidad,
      'description': descripcion,
      'pricePerAppointment': precio,
      'followUpFee': followUpFee,
      'rating': rating,
      'reviewCount': reviewCount,
      'yearsExperience': yearsExperience,
      'qualifications': qualifications,
      'languages': idiomas,
      'distanceKm': distanceKm,
      'city': ciudad,
      'hospital': hospital,
      'patientCount': patientCount,
      'consultationMinutes': consultationMinutes,
      'isApolloDoctor': isApolloDoctor,
      'appointmentType': appointmentType,
      'photoNumber': photoNumber,
      'profileImageUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _createGenericUserWithRandomNumber() async {
    setState(() => _isCreating = true);

    try {
      // Generar número aleatorio disponible
      final number = await _getAvailableRandomNumber();
      final email = '$number@gmail.com';
      final password = '123456';

      // Guardar el usuario actual
      final currentUser = _auth.currentUser;

      // Crear el nuevo usuario
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Crear documento en Firestore para el nuevo usuario
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'role': _selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
        'isGeneric': true,
        'genericNumber': number,
      });

      // Si es médico, crear también el perfil de doctor con datos aleatorios
      if (_selectedRole == 'medico') {
        await _createRandomDoctorProfile(userCredential.user!.uid);
      }

      // Cerrar sesión del usuario recién creado
      await _auth.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Usuario genérico aleatorio creado:\nEmail: $email\nContraseña: $password${_selectedRole == 'medico' ? '\n\nPerfil médico generado con datos aleatorios' : ''}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear usuario: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.returnToDrawer) {
          Navigator.pop(context, true); // Indica que debe abrir el drawer
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestionar Usuarios Genéricos'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, widget.returnToDrawer);
            },
          ),
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Crear Usuario Genérico',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Los usuarios genéricos se crean con el formato:\nEmail: [número]@gmail.com\nContraseña: 123456',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Selector de rol
              const Text(
                'Tipo de Usuario',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'paciente',
                    label: Text('Paciente'),
                    icon: Icon(Icons.person),
                  ),
                  ButtonSegment(
                    value: 'medico',
                    label: Text('Médico'),
                    icon: Icon(Icons.medical_services),
                  ),
                ],
                selected: {_selectedRole},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedRole = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Campo de número
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(
                  labelText: 'Número',
                  hintText: 'Ejemplo: 1, 2, 3...',
                  prefixIcon: Icon(Icons.numbers),
                  border: OutlineInputBorder(),
                  helperText: 'Se convertirá en [número]@gmail.com',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingrese un número';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Por favor ingrese solo números';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Botón crear
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isCreating ? null : _createGenericUser,
                  icon: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.person_add),
                  label: Text(_isCreating ? 'Creando...' : 'Crear Usuario Genérico'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4990E2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Lista de usuarios genéricos
              const Text(
                'Usuarios Genéricos Existentes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .where('isGeneric', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No hay usuarios genéricos creados',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  // Ordenar los documentos manualmente por genericNumber
                  final docs = snapshot.data!.docs.toList();
                  docs.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aNum = aData['genericNumber'] as int? ?? 0;
                    final bNum = bData['genericNumber'] as int? ?? 0;
                    return aNum.compareTo(bNum);
                  });

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final email = data['email'] as String?;
                      final role = data['role'] as String?;
                      final number = data['genericNumber'];

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: role == 'medico'
                                ? Colors.blue
                                : Colors.green,
                            child: Icon(
                              role == 'medico'
                                  ? Icons.medical_services
                                  : Icons.person,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(email ?? 'Sin email'),
                          subtitle: Text(
                            '${role == 'medico' ? 'Médico' : 'Paciente'} • Número: $number\nContraseña: 123456',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteGenericUser(doc.id, email),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isCreating ? null : _createGenericUserWithRandomNumber,
          icon: const Icon(Icons.shuffle),
          label: Text(_selectedRole == 'medico'
            ? 'Médico Aleatorio'
            : 'Paciente Aleatorio'),
          backgroundColor: _isCreating ? Colors.grey : Colors.orange,
          tooltip: 'Crear usuario genérico con número aleatorio',
        ),
      ),
    );
  }

  Future<void> _deleteGenericUser(String docId, String? email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Desea eliminar el usuario $email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Eliminar documento de Firestore
      await _firestore.collection('users').doc(docId).delete();

      // Nota: Para eliminar la cuenta de autenticación necesitarías Firebase Admin SDK
      // Por ahora solo eliminamos el documento de Firestore

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario eliminado del sistema'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
