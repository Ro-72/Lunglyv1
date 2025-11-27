import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/auth_service.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passFocusNode = FocusNode();
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  // Colores del tema
  final Color colorCurve = const Color(0xFF4990E2);
  final Color backgroundColor = Colors.white;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passFocusNode.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Por favor completa todos los campos');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);

    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _signInAsAdmin() async {
    setState(() => _isLoading = true);

    try {
      await _authService.signInWithEmailAndPassword(
        'lujancarrion@gmail.com',
        'waoswaos',
      );
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInAsDoctor() async {
    setState(() => _isLoading = true);

    try {
      await _authService.signInWithEmailAndPassword(
        '2614@gmail.com',
        '123456',
      );
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: true,
      body: AnnotatedRegion(
        value: SystemUiOverlayStyle(
          statusBarColor: backgroundColor,
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarColor: backgroundColor,
        ),
        child: Container(
          color: Colors.white,
          child: SafeArea(
            top: true,
            bottom: false,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                // Curva decorativa de fondo
                ClipPath(
                  clipper: BottomShapeClipper(),
                  child: Container(color: colorCurve),
                ),
                SingleChildScrollView(
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: size.width * 0.05,
                      vertical: size.width * 0.05,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _loginGradientText(),
                        SizedBox(height: size.width * 0.025),
                        _textAccount(),
                        SizedBox(height: size.width * 0.075),
                        _loginFields(size),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _loginGradientText() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          Color.fromRGBO(255, 255, 255, 1),
          Color.fromRGBO(255, 255, 255, 1),
        ],
      ).createShader(bounds),
      child: const Text(
        'Login',
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _textAccount() {
    return RichText(
      text: TextSpan(
        text: "¿No tienes cuenta? ",
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
        ),
        children: [
          TextSpan(
            style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
            text: 'Regístrate aquí.',
            recognizer: TapGestureRecognizer()
              ..onTap = () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterPage(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emailWidget(Size size) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: _emailController,
        focusNode: _emailFocusNode,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: "Email",
          hintText: "Ingresa tu email",
          prefixIcon: Icon(Icons.email, color: colorCurve),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onFieldSubmitted: (value) {
          FocusScope.of(context).requestFocus(_passFocusNode);
        },
      ),
    );
  }

  Widget _passwordWidget(Size size) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: _passwordController,
        focusNode: _passFocusNode,
        obscureText: true,
        decoration: InputDecoration(
          labelText: "Contraseña",
          hintText: "Ingresa tu contraseña",
          prefixIcon: Icon(Icons.lock_outline, color: colorCurve),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _loginButtonWidget(Size size) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: size.width * 0.05,
        horizontal: size.width * 0.04,
      ),
      width: size.width * 0.5,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signIn,
        style: ElevatedButton.styleFrom(
          elevation: 8.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          padding: EdgeInsets.all(size.width * 0.03),
          backgroundColor: colorCurve,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                "LOGIN",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                ),
              ),
      ),
    );
  }

  Widget _temporaryButtons(Size size) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _signInAsDoctor,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Colors.blue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.medical_services, color: Colors.blue),
            label: const Text(
              'Médico Prueba (Temporal)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        SizedBox(height: size.width * 0.02),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _signInAsAdmin,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Colors.orange),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.admin_panel_settings, color: Colors.orange),
            label: const Text(
              'Administrador (Temporal)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _socialButtons(Size size) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isGoogleLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: colorCurve),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        icon: _isGoogleLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const FaIcon(
                FontAwesomeIcons.google,
                color: Color(0xFFDB4437),
                size: 20,
              ),
        label: Text(
          _isGoogleLoading ? 'Iniciando sesión...' : 'Continuar con Google',
          style: TextStyle(
            fontSize: 16,
            color: colorCurve,
          ),
        ),
      ),
    );
  }

  Widget _loginFields(Size size) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _emailWidget(size),
          SizedBox(height: size.width * 0.02),
          _passwordWidget(size),
          SizedBox(height: size.width * 0.02),
          _loginButtonWidget(size),
          SizedBox(height: size.width * 0.05),
          _temporaryButtons(size),
          SizedBox(height: size.width * 0.07),
          Text(
            "O inicia sesión con",
            style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
          ),
          SizedBox(height: size.width * 0.03),
          _socialButtons(size),
        ],
      ),
    );
  }
}

// Clipper para la curva decorativa
class BottomShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.4,
      size.width,
      size.height * 0.3,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}