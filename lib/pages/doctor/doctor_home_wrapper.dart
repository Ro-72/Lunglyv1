import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'doctor_home_page.dart';
import 'doctor_profile_page.dart';
import '../chatbot_page.dart';
import '../about_page.dart';
import '../settings_page.dart';
import '../admin/manage_generic_users_page.dart';
import '../../services/auth_service.dart';

class DoctorHomeWrapper extends StatefulWidget {
  final bool isAdmin;
  final Function(String)? onInterfaceChange;

  const DoctorHomeWrapper({
    super.key,
    this.isAdmin = false,
    this.onInterfaceChange,
  });

  @override
  State<DoctorHomeWrapper> createState() => _DoctorHomeWrapperState();
}

class _DoctorHomeWrapperState extends State<DoctorHomeWrapper> {
  int _currentIndex = 0;
  final _authService = AuthService();

  final List<Widget> _pages = [
    const DoctorHomePage(),
    const ChatbotPage(),
    const DoctorProfilePage(),
  ];

  final List<String> _pageTitles = [
    'Lungly',
    'Chatbot',
    'Mi Perfil Médico',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              _pageTitles[_currentIndex],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                'assets/icons/lungly2.jpg',
                height: 40,
                width: 40,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.account_circle, size: 64, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    _authService.currentUser?.email ?? 'User',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  if (widget.isAdmin)
                    const SizedBox(height: 4),
                  if (widget.isAdmin)
                    const Text(
                      'Administrador - Vista Médico',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                ],
              ),
            ),
            // Opción para cambiar de interfaz (solo para admin)
            if (widget.isAdmin && widget.onInterfaceChange != null) ...[
              ListTile(
                leading: const Icon(Icons.swap_horiz, color: Color(0xFF4990E2)),
                title: const Text(
                  'Cambiar a Vista Paciente',
                  style: TextStyle(
                    color: Color(0xFF4990E2),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onInterfaceChange!('paciente');
                },
              ),
              const Divider(),
            ],
            if (widget.isAdmin) ...[
              ListTile(
                leading: const Icon(Icons.group_add, color: Color(0xFF4990E2)),
                title: const Text(
                  'Gestionar Usuarios Genéricos',
                  style: TextStyle(
                    color: Color(0xFF4990E2),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageGenericUsersPage(),
                    ),
                  );
                },
              ),
              const Divider(),
            ],
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Métodos de Pago'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funcionalidad en desarrollo'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuración'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Acerca de'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Cerrar Sesión'),
                    content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Cerrar Sesión'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  await _authService.signOut();
                }
              },
            ),
          ],
        ),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF4990E2),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chatbot',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
