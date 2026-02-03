import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class EntregaPaquetesScreen extends StatefulWidget {
  const EntregaPaquetesScreen({Key? key}) : super(key: key);

  @override
  State<EntregaPaquetesScreen> createState() => _EntregaPaquetesScreenState();
}

class _EntregaPaquetesScreenState extends State<EntregaPaquetesScreen> {
  final List<String> paquetesEscaneados = [];
  File? fotoEntrega;
  bool isSaving = false;

  // ================= SCAN =================
  void onDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code != null && !paquetesEscaneados.contains(code)) {
        setState(() => paquetesEscaneados.add(code));
      }
    }
  }

  // ================= FOTO =================
  Future<void> tomarFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
    );

    if (picked != null) {
      setState(() {
        fotoEntrega = File(picked.path);
      });
    }
  }

  // ================= GUARDAR =================
  Future<void> guardarEntregas() async {
    if (paquetesEscaneados.isEmpty || fotoEntrega == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escanee paquetes y tome la foto')),
      );
      return;
    }

    setState(() => isSaving = true);

    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final nombre = userDoc['nombre'];
    final rol = userDoc['rol'];

    // ===== SUBIR FOTO =====
    final fotoRef = FirebaseStorage.instance
        .ref('pruebas_entrega/${DateTime.now().millisecondsSinceEpoch}.jpg');

    await fotoRef.putFile(fotoEntrega!);
    final fotoUrl = await fotoRef.getDownloadURL();

    final batch = FirebaseFirestore.instance.batch();

    for (final codigo in paquetesEscaneados) {
      final query = await FirebaseFirestore.instance
          .collection('paquetes')
          .where('codigo', isEqualTo: codigo)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final docRef = query.docs.first.reference;

        batch.update(docRef, {
          'estado': 'entregado',
          'fechaEntrega': FieldValue.serverTimestamp(),
          'pruebaEntregaUrl': fotoUrl,
          'entregadoPor': {
            'uid': user.uid,
            'nombre': nombre,
            'rol': rol,
          },
        });
      }
    }

    await batch.commit();

    setState(() {
      paquetesEscaneados.clear();
      fotoEntrega = null;
      isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paquetes entregados correctamente')),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrega de Paquetes'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // SCANNER
          SizedBox(
            height: 250,
            child: MobileScanner(onDetect: onDetect),
          ),

          // FOTO
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: tomarFoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Foto prueba entrega'),
                ),
                const SizedBox(width: 10),
                if (fotoEntrega != null)
                  const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
          ),

          // LISTA
          Expanded(
            child: ListView.builder(
              itemCount: paquetesEscaneados.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.inventory),
                  title: Text(paquetesEscaneados[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        paquetesEscaneados.removeAt(index);
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // GUARDAR
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.check),
                label: const Text('Confirmar entrega'),
                onPressed: isSaving ? null : guardarEntregas,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
