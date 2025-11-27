import 'package:flutter/material.dart';
import 'doctor_profile_page.dart';

class DoctorProfileEditPage extends StatelessWidget {
  const DoctorProfileEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil Médico'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: const DoctorProfilePage(),
    );
  }
}
