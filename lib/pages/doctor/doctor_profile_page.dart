import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorProfilePage extends StatefulWidget {
  const DoctorProfilePage({super.key});

  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _cityController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _consultationMinutesController = TextEditingController();
  final _priceController = TextEditingController();
  final _followUpFeeController = TextEditingController();
  final _yearsExperienceController = TextEditingController();

  final List<String> _languages = [];
  final List<String> _qualifications = [];
  final _languageController = TextEditingController();
  final _qualificationController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _doctorDocId;

  String? get _userId => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadDoctorProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _specialtyController.dispose();
    _cityController.dispose();
    _hospitalController.dispose();
    _descriptionController.dispose();
    _consultationMinutesController.dispose();
    _priceController.dispose();
    _followUpFeeController.dispose();
    _yearsExperienceController.dispose();
    _languageController.dispose();
    _qualificationController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorProfile() async {
    setState(() => _isLoading = true);

    try {
      final userId = _userId;
      if (userId == null) return;

      // Buscar el perfil del doctor en la colección doctors
      final querySnapshot = await _firestore
          .collection('doctors')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        _doctorDocId = doc.id;
        final data = doc.data();

        setState(() {
          _nameController.text = data['name'] ?? '';
          _titleController.text = data['title'] ?? '';
          _specialtyController.text = data['specialty'] ?? '';
          _cityController.text = data['city'] ?? '';
          _hospitalController.text = data['hospital'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _consultationMinutesController.text = (data['consultationMinutes'] ?? 30).toString();
          _priceController.text = (data['pricePerAppointment'] ?? 0).toString();
          _followUpFeeController.text = (data['followUpFee'] ?? 0).toString();
          _yearsExperienceController.text = (data['yearsExperience'] ?? 0).toString();

          if (data['languages'] != null) {
            _languages.addAll(List<String>.from(data['languages']));
          }
          if (data['qualifications'] != null) {
            _qualifications.addAll(List<String>.from(data['qualifications']));
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar perfil: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final userId = _userId;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final profileData = {
        'userId': userId,
        'name': _nameController.text.trim(),
        'title': _titleController.text.trim(),
        'specialty': _specialtyController.text.trim(),
        'city': _cityController.text.trim(),
        'hospital': _hospitalController.text.trim(),
        'description': _descriptionController.text.trim(),
        'consultationMinutes': int.tryParse(_consultationMinutesController.text) ?? 30,
        'pricePerAppointment': int.tryParse(_priceController.text) ?? 0,
        'followUpFee': int.tryParse(_followUpFeeController.text) ?? 0,
        'yearsExperience': int.tryParse(_yearsExperienceController.text) ?? 0,
        'languages': _languages,
        'qualifications': _qualifications,
        'profileImageUrl': null,
        'isApolloDoctor': false,
        'rating': 0.0,
        'reviewCount': 0,
        'patientCount': 0,
        'distanceKm': 0.0,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_doctorDocId != null) {
        // Actualizar perfil existente
        await _firestore.collection('doctors').doc(_doctorDocId).update(profileData);
      } else {
        // Crear nuevo perfil
        profileData['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await _firestore.collection('doctors').add(profileData);
        _doctorDocId = docRef.id;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil guardado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar perfil: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información básica
                    const Text(
                      'Información Básica',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre Completo *',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingrese su nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título (ej: MD, FCCP) *',
                        prefixIcon: Icon(Icons.workspace_premium),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingrese su título';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _specialtyController,
                      decoration: const InputDecoration(
                        labelText: 'Especialidad *',
                        prefixIcon: Icon(Icons.medical_services),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingrese su especialidad';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción profesional *',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                        hintText: 'Breve descripción de su experiencia y especialización...',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingrese una descripción';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Ubicación y hospital
                    const Text(
                      'Ubicación y Lugar de Trabajo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'Ciudad *',
                        prefixIcon: Icon(Icons.location_city),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingrese su ciudad';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _hospitalController,
                      decoration: const InputDecoration(
                        labelText: 'Hospital/Clínica *',
                        prefixIcon: Icon(Icons.local_hospital),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingrese su hospital o clínica';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Consulta y honorarios
                    const Text(
                      'Consulta y Honorarios',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _consultationMinutesController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Duración consulta (min)',
                              prefixIcon: Icon(Icons.timer),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Requerido';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _yearsExperienceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Años de experiencia',
                              prefixIcon: Icon(Icons.work),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Requerido';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Precio por cita (S/)',
                              prefixIcon: Icon(Icons.attach_money),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Requerido';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _followUpFeeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Cita de seguimiento (S/)',
                              prefixIcon: Icon(Icons.replay),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Requerido';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Idiomas
                    const Text(
                      'Idiomas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      children: _languages.map((lang) {
                        return Chip(
                          label: Text(lang),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setState(() {
                              _languages.remove(lang);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _languageController,
                            decoration: const InputDecoration(
                              labelText: 'Agregar idioma',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (_languageController.text.trim().isNotEmpty) {
                              setState(() {
                                _languages.add(_languageController.text.trim());
                                _languageController.clear();
                              });
                            }
                          },
                          child: const Text('Agregar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Cualificaciones
                    const Text(
                      'Cualificaciones',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      children: _qualifications.map((qual) {
                        return Chip(
                          label: Text(qual),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setState(() {
                              _qualifications.remove(qual);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _qualificationController,
                            decoration: const InputDecoration(
                              labelText: 'Agregar cualificación',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (_qualificationController.text.trim().isNotEmpty) {
                              setState(() {
                                _qualifications.add(_qualificationController.text.trim());
                                _qualificationController.clear();
                              });
                            }
                          },
                          child: const Text('Agregar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Botón de guardar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveProfile,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isSaving ? 'Guardando...' : 'Guardar Perfil'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4990E2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
  }
}
