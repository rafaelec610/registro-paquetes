import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DevolucionPaquetesScreen extends StatefulWidget {
  const DevolucionPaquetesScreen({Key? key}) : super(key: key);

  @override
  State<DevolucionPaquetesScreen> createState() =>
      _DevolucionPaquetesScreenState();
}

class _DevolucionPaquetesScreenState extends State<DevolucionPaquetesScreen> {
  final List<String> paquetesEscaneados = [];
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

  // ================= GUARDAR =================
  Future<void> guardarDevoluciones() async {
    if (paquetesEscaneados.isEmpty) return;

    setState(() => isSaving = true);

    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final nombre = userDoc['nombre'];
    final rol = userDoc['rol'];

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
          'estado': 'devuelto',
          'fechaDevolucion': FieldValue.serverTimestamp(),
          'devueltoPor': {
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
      isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Devoluciones registradas correctamente')),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devolución de Paquetes'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // SCANNER
          SizedBox(
            height: 250,
            child: MobileScanner(onDetect: onDetect),
          ),

          const SizedBox(height: 10),

          // LISTA
          Expanded(
            child: ListView.builder(
              itemCount: paquetesEscaneados.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading:
                      const Icon(Icons.assignment_return, color: Colors.orange),
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

          // BOTÓN GUARDAR
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.assignment_return),
                label: const Text('Confirmar devolución'),
                onPressed: isSaving ? null : guardarDevoluciones,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
