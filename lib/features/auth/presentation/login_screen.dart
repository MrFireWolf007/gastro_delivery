import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth_controller.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController _controller = AuthController();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('rememberMe') ?? false;
    });
  }

  Future<void> _saveRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', value);
  }

  Future<void> _onLoginPressed() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _controller.login(
        email: emailController.text.trim(),
        password: passwordController.text,
        context: context,
      );

      // Comprueba si el login fue exitoso
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _saveRememberMe(_rememberMe);
        // Aquí podrías navegar a la pantalla principal si lo deseas.
        // Navigator.pushReplacementNamed(context, '/home');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final isTablet = screenWidth >= 600;
            final horizontalPadding = 16.0;
            final maxContentWidth = isTablet ? 600.0 : 520.0;

            final logoHeight = (screenHeight * 0.22).clamp(120.0, 260.0);
            final headerFontSize = isTablet ? 20.0 : 18.0;
            final fieldVerticalPadding = isTablet ? 16.0 : 14.0;
            final verticalSpacing = isTablet ? 14.0 : 12.0;
            final buttonHeight = 52.0;

            return Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        "images/logo.jpg",
                        height: logoHeight,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "🍕Bienvenido a GastroDeliveryPro🍔",
                        style: TextStyle(
                          fontSize: headerFontSize,
                          fontWeight: FontWeight.bold,
                          fontFamily:  'Roboto',
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: 'Correo electrónico',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: fieldVerticalPadding, horizontal: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: verticalSpacing),
                      TextField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          hintText: 'Contraseña',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: fieldVerticalPadding, horizontal: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        obscureText: true,
                      ),
                      SizedBox(height: 12),
                      // Row con checkbox "Recordarme" y posible "Olvidé contraseña"
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (v) {
                              setState(() {
                                _rememberMe = v ?? false;
                              });
                            },
                          ),
                          const Expanded(
                            child: Text(
                              'Recordarme',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: _isLoading ? null : _onLoginPressed,
                          child: _isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                              : const Text('Iniciar sesión', style: TextStyle(fontSize: 16, color: Colors.black)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          '¿No tienes cuenta? Registrate aquí',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}