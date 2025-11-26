import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/doctor/doctor_home_wrapper.dart';
import 'main_navigation.dart';

class RoleBasedHome extends StatefulWidget {
  const RoleBasedHome({super.key});

  @override
  State<RoleBasedHome> createState() => _RoleBasedHomeState();
}

class _RoleBasedHomeState extends State<RoleBasedHome> {
  static const String adminEmail = 'lujancarrion@gmail.com';
  String? _selectedInterface;

  @override
  void initState() {
    super.initState();
    _loadSelectedInterface();
  }

  Future<void> _loadSelectedInterface() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedInterface = prefs.getString('selected_interface');
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuario no autenticado')),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Si no existe el documento, crear uno por defecto
        if (!snapshot.hasData || !snapshot.data!.exists) {
          _createDefaultUserDocument(user.uid, user.email);
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final userRole = userData['role'] as String? ?? 'paciente';
        final isAdmin = user.email == adminEmail;

        // Para administrador, usar la interfaz seleccionada o por defecto 'paciente'
        String effectiveRole = userRole;
        if (isAdmin && _selectedInterface != null) {
          effectiveRole = _selectedInterface!;
        }

        // Mostrar interfaz según el rol efectivo
        if (effectiveRole == 'medico') {
          return DoctorHomeWrapper(
            isAdmin: isAdmin,
            onInterfaceChange: isAdmin ? _changeInterface : null,
          );
        } else {
          return MainNavigation(
            isAdmin: isAdmin,
            onInterfaceChange: isAdmin ? _changeInterface : null,
          );
        }
      },
    );
  }

  Future<void> _createDefaultUserDocument(String uid, String? email) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': email,
        'role': 'paciente',
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Refrescar el widget
      setState(() {});
    } catch (e) {
      print('Error creating user document: $e');
    }
  }

  Future<void> _changeInterface(String newInterface) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_interface', newInterface);
    setState(() {
      _selectedInterface = newInterface;
    });
  }
}

