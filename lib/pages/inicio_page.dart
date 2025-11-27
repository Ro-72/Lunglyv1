import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'specialty_selection_page.dart';
import 'my_appointments_page.dart';
import 'medical_history_page.dart';
import 'prescriptions_page.dart';
import 'emergency_contact_page.dart';

// Helper class para dimensiones responsivas
class Screen {
  final Size size;
  Screen(this.size);
  
  double getWidthPx(double px) => (px / 375.0) * size.width;
}

// Clipper para la forma curva del fondo
class BottomShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0.0, size.height - 100);
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 50);
    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 100);
    var secondEndPoint = Offset(size.width, size.height - 30);

    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);
    path.lineTo(size.width, 0.0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Widget para texto con gradiente
class GradientText extends StatelessWidget {
  final String text;
  final Gradient gradient;
  final TextStyle style;

  const GradientText(
    this.text, {
    required this.gradient,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        text,
        style: style.copyWith(color: Colors.white),
      ),
    );
  }
}

class InicioPage extends StatelessWidget {
  const InicioPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;
    final size = Screen(MediaQuery.of(context).size);
    final colorCurve = const Color(0xFF478EDF);
    final backgroundColor = const Color(0xFFF5F5F5);

    return Stack(
      children: [
        // Fondo con forma curva
        ClipPath(
          clipper: BottomShapeClipper(),
          child: Container(
            height: size.getWidthPx(250),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorCurve,
                  colorCurve.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        // Contenido
        SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(size.getWidthPx(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: size.getWidthPx(20)),
                // Tarjeta de bienvenida
                _buildWelcomeCard(context, user, size, colorCurve),
                SizedBox(height: size.getWidthPx(30)),
                // Título de opciones
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: size.getWidthPx(4)),

                ),
                SizedBox(height: size.getWidthPx(16)),
                // Opciones médicas
                _buildOptionCard(
                  context,
                  size,
                  icon: Icons.calendar_today,
                  title: 'Agendar Cita',
                  subtitle: 'Programa una nueva consulta',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SpecialtySelectionPage(),
                      ),
                    );
                  },
                ),
                SizedBox(height: size.getWidthPx(12)),
                _buildOptionCard(
                  context,
                  size,
                  icon: Icons.list_alt,
                  title: 'Mis Citas',
                  subtitle: 'Ver citas programadas',
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyAppointmentsPage(),
                      ),
                    );
                  },
                ),
                SizedBox(height: size.getWidthPx(12)),
                _buildOptionCard(
                  context,
                  size,
                  icon: Icons.history,
                  title: 'Historial Médico',
                  subtitle: 'Consulta tu historial',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MedicalHistoryPage(),
                      ),
                    );
                  },
                ),
                SizedBox(height: size.getWidthPx(12)),
                _buildOptionCard(
                  context,
                  size,
                  icon: Icons.description,
                  title: 'Recetas',
                  subtitle: 'Ver recetas médicas',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrescriptionsPage(),
                      ),
                    );
                  },
                ),
                SizedBox(height: size.getWidthPx(12)),
                _buildOptionCard(
                  context,
                  size,
                  icon: Icons.emergency,
                  title: 'Emergencia',
                  subtitle: 'Contacto de emergencia',
                  color: Colors.red,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EmergencyContactPage(),
                      ),
                    );
                  },
                ),
                SizedBox(height: size.getWidthPx(20)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(BuildContext context, dynamic user, Screen size, Color colorCurve) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: EdgeInsets.all(size.getWidthPx(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(size.getWidthPx(10)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorCurve.withOpacity(0.2),
                      colorCurve.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.favorite,
                  color: colorCurve,
                  size: 28,
                ),
              ),
              SizedBox(width: size.getWidthPx(12)),
              Text(
                '¡Bienvenido!',
                style: TextStyle(
                  fontFamily: 'Exo2',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          SizedBox(height: size.getWidthPx(12)),
          Text(
            'Esperamos que tengas un excelente día',
            style: TextStyle(
              fontFamily: 'Exo2',
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: size.getWidthPx(8)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: size.getWidthPx(12),
              vertical: size.getWidthPx(6),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorCurve.withOpacity(0.1),
                  colorCurve.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user?.email ?? 'Usuario',
              style: TextStyle(
                fontFamily: 'Exo2',
                fontSize: 14,
                color: colorCurve,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    Screen size, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(size.getWidthPx(16)),
            child: Row(
              children: [
                // Icono con gradiente
                Container(
                  padding: EdgeInsets.all(size.getWidthPx(12)),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.2),
                        color.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 32,
                  ),
                ),
                SizedBox(width: size.getWidthPx(16)),
                // Textos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Exo2',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C2C2C),
                        ),
                      ),
                      SizedBox(height: size.getWidthPx(4)),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'Exo2',
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Flecha
                Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}