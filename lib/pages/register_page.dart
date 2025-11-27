import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

// Necesitarás crear estos widgets personalizados o adaptarlos
class Screen {
  final Size size;
  Screen(this.size);
  
  double getWidthPx(double px) => (px / 375.0) * size.width;
}

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

class BoxField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final String lableText;
  final bool obscureText;
  final IconData icon;
  final Color iconColor;
  final Function(String)? onSaved;
  final Function(String)? onFieldSubmitted;

  const BoxField({
    required this.controller,
    this.focusNode,
    required this.hintText,
    required this.lableText,
    required this.obscureText,
    required this.icon,
    required this.iconColor,
    this.onSaved,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        onSaved: (val) => onSaved?.call(val ?? ''),
        onFieldSubmitted: onFieldSubmitted,
        decoration: InputDecoration(
          icon: Icon(icon, color: iconColor),
          hintText: hintText,
          labelText: lableText,
          border: InputBorder.none,
          labelStyle: const TextStyle(fontFamily: 'Exo2'),
          hintStyle: const TextStyle(fontFamily: 'Exo2'),
        ),
        style: const TextStyle(fontFamily: 'Exo2'),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passFocusNode = FocusNode();
  final _confirmPassFocusNode = FocusNode();
  
  final _authService = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  String _selectedRole = 'paciente';
  String? _selectedSpecialty;

  late Screen size;
  
  final Color backgroundColor = const Color(0xFFF5F5F5);
  final Color colorCurve = const Color(0xFF4990E2);

  final List<String> _specialties = [
    'Medicina General',
    'Neumología',

  ];

  Future<void> _register() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showError('Por favor completa todos los campos');
      return;
    }

    if (_selectedRole == 'medico' && _selectedSpecialty == null) {
      _showError('Por favor selecciona una especialidad');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Las contraseñas no coinciden');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _authService.createUserWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (userCredential != null && userCredential.user != null) {
        final userData = {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _selectedRole,
          'createdAt': FieldValue.serverTimestamp(),
        };

        if (_selectedRole == 'medico' && _selectedSpecialty != null) {
          userData['specialty'] = _selectedSpecialty!;
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userData);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    size = Screen(MediaQuery.of(context).size);

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: <Widget>[
          ClipPath(
            clipper: BottomShapeClipper(),
            child: Container(
              color: colorCurve,
            ),
          ),
          SingleChildScrollView(
            child: SafeArea(
              top: true,
              bottom: false,
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: size.getWidthPx(20),
                  vertical: size.getWidthPx(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: colorCurve),
                          onPressed: () => Navigator.pop(context, false),
                        ),
                        SizedBox(width: size.getWidthPx(10)),
                        _registerGradientText(),
                      ],
                    ),
                    SizedBox(height: size.getWidthPx(10)),
                    _textAccount(),
                    SizedBox(height: size.getWidthPx(30)),
                    _buildRoleSelector(),
                    SizedBox(height: size.getWidthPx(20)),
                    _registerFields(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _registerGradientText() {
    return GradientText(
      'Registrarse',
      gradient: LinearGradient(
        colors: [
          const Color.fromARGB(255, 240, 240, 240),
          const Color.fromARGB(255, 255, 255, 255),
        ],
      ),
      style: const TextStyle(
        fontFamily: 'Exo2',
        fontSize: 36,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _textAccount() {
    return RichText(
      text: TextSpan(
        text: "¿Ya tienes cuenta? ",
        children: [
          TextSpan(
            style: const TextStyle(color: Colors.deepOrange),
            text: 'Inicia sesión aquí',
            recognizer: TapGestureRecognizer()
              ..onTap = () => Navigator.pop(context),
          ),
        ],
        style: const TextStyle(
          fontFamily: 'Exo2',
          color: Colors.black87,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: EdgeInsets.all(size.getWidthPx(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecciona tu rol:',
            style: TextStyle(
              fontFamily: 'Exo2',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorCurve,
            ),
          ),
          SizedBox(height: size.getWidthPx(12)),
          Row(
            children: [
              Expanded(
                child: _buildRoleCard(
                  role: 'paciente',
                  icon: Icons.person,
                  label: 'Paciente',
                ),
              ),
              SizedBox(width: size.getWidthPx(16)),
              Expanded(
                child: _buildRoleCard(
                  role: 'medico',
                  icon: Icons.medical_services,
                  label: 'Médico',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedRole == role;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedRole = role;
          if (role == 'paciente') {
            _selectedSpecialty = null;
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(size.getWidthPx(16)),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    const Color.fromRGBO(97, 6, 165, 0.2),
                    const Color.fromRGBO(45, 160, 240, 0.2),
                  ],
                )
              : null,
          border: Border.all(
            color: isSelected ? colorCurve : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? colorCurve : Colors.grey,
            ),
            SizedBox(height: size.getWidthPx(8)),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Exo2',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? colorCurve : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _registerFields() {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          BoxField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            hintText: "Ingresa tu nombre",
            lableText: "Nombre Completo",
            obscureText: false,
            icon: Icons.person,
            iconColor: colorCurve,
            onFieldSubmitted: (value) {
              FocusScope.of(context).requestFocus(_emailFocusNode);
            },
          ),
          if (_selectedRole == 'medico') _buildSpecialtyDropdown(),
          BoxField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            hintText: "Ingresa tu correo",
            lableText: "Correo Electrónico",
            obscureText: false,
            icon: Icons.email,
            iconColor: colorCurve,
            onFieldSubmitted: (value) {
              FocusScope.of(context).requestFocus(_passFocusNode);
            },
          ),
          BoxField(
            controller: _passwordController,
            focusNode: _passFocusNode,
            hintText: "Ingresa tu contraseña",
            lableText: "Contraseña",
            obscureText: true,
            icon: Icons.lock_outline,
            iconColor: colorCurve,
            onFieldSubmitted: (value) {
              FocusScope.of(context).requestFocus(_confirmPassFocusNode);
            },
          ),
          BoxField(
            controller: _confirmPasswordController,
            focusNode: _confirmPassFocusNode,
            hintText: "Confirma tu contraseña",
            lableText: "Confirmar Contraseña",
            obscureText: true,
            icon: Icons.lock_outline,
            iconColor: colorCurve,
          ),
          _signUpButtonWidget(),
        ],
      ),
    );
  }

  Widget _buildSpecialtyDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedSpecialty,
        decoration: InputDecoration(
          icon: Icon(Icons.medical_information, color: colorCurve),
          labelText: 'Especialidad',
          border: InputBorder.none,
          labelStyle: const TextStyle(fontFamily: 'Exo2'),
        ),
        hint: const Text(
          'Selecciona tu especialidad',
          style: TextStyle(fontFamily: 'Exo2'),
        ),
        isExpanded: true,
        items: _specialties.map((String specialty) {
          return DropdownMenuItem<String>(
            value: specialty,
            child: Text(
              specialty,
              style: const TextStyle(fontFamily: 'Exo2'),
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedSpecialty = newValue;
          });
        },
      ),
    );
  }

  Widget _signUpButtonWidget() {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: size.getWidthPx(20),
        horizontal: size.getWidthPx(16),
      ),
      width: size.getWidthPx(200),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
        style: ElevatedButton.styleFrom(
          elevation: 8.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          padding: EdgeInsets.all(size.getWidthPx(12)),
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
                "Registrarse",
                style: TextStyle(
                  fontFamily: 'Exo2',
                  color: Colors.white,
                  fontSize: 20.0,
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passFocusNode.dispose();
    _confirmPassFocusNode.dispose();
    super.dispose();
  }
}