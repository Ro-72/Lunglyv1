import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lungly App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF64B5F6), // Azul suave
          primary: const Color(0xFF64B5F6),
          secondary: const Color(0xFF81C784), // Verde suave
          tertiary: const Color(0xFFFFB74D), // Naranja suave
          background: const Color(0xFFF5F5F5), // Gris muy claro
        ),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(
            color: Color(0xFF2C2C2C),
          ),
        ),
        textTheme: TextTheme(
          headlineMedium: TextTheme.of(context).headlineMedium?.copyWith(
            color: const Color(0xFF2C2C2C),
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextTheme.of(context).titleLarge?.copyWith(
            color: const Color(0xFF2C2C2C),
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextTheme.of(context).bodyLarge?.copyWith(
            color: const Color(0xFF4A4A4A),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

