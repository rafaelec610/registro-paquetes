import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/animated_button.dart';
import '../utils/page_transitions.dart';
import 'register_screen.dart';

import 'admin_panel.dart';
import 'user_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {

  final documentoController = TextEditingController();
  final passwordController = TextEditingController();

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    documentoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    try {
      setState(() => isLoading = true);

      final documento = documentoController.text.trim();
      final password = passwordController.text.trim();

      if (documento.isEmpty || password.isEmpty) {
        throw 'Debe completar todos los campos';
      }

      final query = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('documento', isEqualTo: documento)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw 'Documento no registrado';
      }

      final userData = query.docs.first.data();
      final correo = userData['correo'];
      final rol = userData['rol'];

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: correo,
        password: password,
      );

      if (rol == 'admin') {
        Navigator.pushReplacement(context, routeSlide(const AdminPanel()));

      } else {
        Navigator.pushReplacement(context, routeSlide(const UserHomeScreen()));

      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // LOGO / TÍTULO
                  const Icon(Icons.lock, size: 80, color: Colors.black),
                  const SizedBox(height: 16),
                  const Text(
                    'Iniciar Sesión',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // DOCUMENTO
                  TextField(
                    controller: documentoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Documento',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // CONTRASEÑA
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // BOTÓN ANIMADO
                  AnimatedButton(
                    text: isLoading ? 'Cargando...' : 'Ingresar',
                    icon: Icons.login,
                    color: Colors.yellow,
                    onPressed: isLoading ? () {} : _login,
                ),

                const SizedBox(height: 20),

                TextButton(
                    onPressed: () {
                        Navigator.push(
                            context,
                            routeSlide(const RegisterScreen()),
                        );
                    },
                    child: const Text(
                        '¿No tienes cuenta? Regístrate',
                        style: TextStyle(
                            color: Colors.green,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                        ),
                    ),
                ),


                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
