import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../widgets/animated_button.dart';
import '../utils/page_transitions.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {

  final nombreController = TextEditingController();
  final apellidoController = TextEditingController();

  final user = FirebaseAuth.instance.currentUser;
  String? fotoUrl;

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  Future<void> _loadUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user!.uid)
        .get();

    setState(() {
      nombreController.text = doc['nombres'] ?? '';
      apellidoController.text = doc['apellidos'] ?? '';
      fotoUrl = doc['foto'];
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 70);

    if (picked == null) return;

    final file = File(picked.path);
    final ref = FirebaseStorage.instance
        .ref('perfiles/${user!.uid}.jpg');

    await ref.putFile(file);
    final url = await ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user!.uid)
        .update({'foto': url});

    setState(() => fotoUrl = url);
  }

  Future<void> _saveProfile() async {
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user!.uid)
        .update({
      'nombres': nombreController.text,
      'apellidos': apellidoController.text,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil actualizado')),
    );
  }

  Future<void> _changePassword() async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Correo enviado para cambiar contraseña')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),

      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [

                AnimatedScale(
                  scale: 1,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutBack,
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.black,
                    backgroundImage:
                        fotoUrl != null ? NetworkImage(fotoUrl!) : null,
                    child: fotoUrl == null
                        ? const Icon(Icons.person, size: 60, color: Colors.white)
                        : null,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: () => _pickImage(ImageSource.camera),
                    ),
                    IconButton(
                      icon: const Icon(Icons.photo),
                      onPressed: () => _pickImage(ImageSource.gallery),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombres',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: apellidoController,
                  decoration: const InputDecoration(
                    labelText: 'Apellidos',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 25),

                AnimatedButton(
                    text: 'Guardar cambios',
                    icon: Icons.save,
                    color: Colors.green,
                    onPressed: _saveProfile,
                ),


                const SizedBox(height: 15),

                AnimatedButton(
                    text: 'Cambiar contraseña',
                    icon: Icons.lock_reset,
                    color: Colors.yellow,
                     onPressed: _changePassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
