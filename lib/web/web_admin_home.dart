import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'web_paquetes_table.dart';

class WebAdminHome extends StatelessWidget {
  const WebAdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Paquetes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: const WebPaquetesTable(),
    );
  }
}
