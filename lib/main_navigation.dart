import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/auth_service.dart';
import 'pages/inicio_page.dart';
import 'pages/chatbot_page.dart';
import 'pages/medico_page.dart';
import 'pages/tratamiento_page.dart';
import 'pages/profile_page.dart';
import 'pages/payment_methods_page.dart';
import 'pages/settings_page.dart';
import 'pages/about_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final _authService = AuthService();

  // GlobalKeys for nested navigators
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  Widget _buildNavigator(int index, Widget page) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(builder: (context) => page);
      },
    );
  }

  final List<Widget> _pages = [
    const InicioPage(),
    const ChatbotPage(),
    const MedicoPage(),
    const TratamientoPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // Check if the current tab's navigator can pop
        final navigatorState = _navigatorKeys[_currentIndex].currentState;
        if (navigatorState != null && navigatorState.canPop()) {
          navigatorState.pop();
          return;
        }

        // Si no estás en la página de inicio, ve a inicio
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        } else {
          // Si ya estás en inicio, sal de la app
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'Lungly',
                style: TextStyle(
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
        drawer: _buildDrawer(context),
        body: _buildNavigator(_currentIndex, _pages[_currentIndex]),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble),
              label: 'Chatbot',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medical_services),
              label: 'Médico',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.healing), label: 'Trat'),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
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
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Perfil Médico'),
            onTap: () async {
              // Navegar sin cerrar el drawer
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
              // El drawer permanece abierto cuando regresas
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Métodos de Pago'),
            onTap: () async {
              // Navegar sin cerrar el drawer
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaymentMethodsPage(),
                ),
              );
              // El drawer permanece abierto cuando regresas
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración'),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Acerca de'),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar Sesión'),
            onTap: () async {
              await _authService.signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
