import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EntradaPaquetesScreen extends StatefulWidget {
  const EntradaPaquetesScreen({super.key});

  @override
  State<EntradaPaquetesScreen> createState() => _EntradaPaquetesScreenState();
}

class _EntradaPaquetesScreenState extends State<EntradaPaquetesScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  final AudioPlayer player = AudioPlayer();

  final List<String> codigosEscaneados = [];
  bool procesando = false;
  bool guardando = false;

  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _confirmarSalida,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Entrada de paquetes'),
          actions: [
            IconButton(
              icon: const Icon(Icons.flash_on),
              onPressed: () => cameraController.toggleTorch(),
            ),
          ],
        ),
        body: Column(
          children: [
            // ===== CÁMARA =====
            Expanded(
              flex: 3,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: cameraController,
                    onDetect: onDetect,
                  ),
                  Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),

            // ===== BOTONES =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.keyboard),
                      label: const Text('Registrar manual'),
                      onPressed: _registrarCodigoManual,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: guardando
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Icon(Icons.save),
                      label: const Text('Guardar'),
                      onPressed: guardando ? null : _guardarTodoEnFirestore,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ===== LISTA =====
            Expanded(
              flex: 2,
              child: ListView.builder(
                itemCount: codigosEscaneados.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.qr_code, color: Colors.green),
                    title: Text(codigosEscaneados[index]),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _editarCodigo(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _eliminarCodigo(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== ESCANEO =====
  void onDetect(BarcodeCapture capture) async {
    if (procesando) return;

    final code = capture.barcodes.first.rawValue;
    if (code == null || codigosEscaneados.contains(code)) return;

    setState(() {
      procesando = true;
      codigosEscaneados.add(code);
    });

    await player.play(AssetSource('sounds/beep.mp3'));

    await Future.delayed(const Duration(milliseconds: 600));
    procesando = false;
  }

  // ===== GUARDAR TODO =====
  Future<void> _guardarTodoEnFirestore() async {
    if (codigosEscaneados.isEmpty) return;

    setState(() => guardando = true);

    final fecha = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final hora = DateFormat('HH:mm:ss').format(DateTime.now());

    final userDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user!.uid)
        .get();

    final batch = FirebaseFirestore.instance.batch();

    for (final codigo in codigosEscaneados) {
      final doc = FirebaseFirestore.instance.collection('paquetes_entradas').doc();

      batch.set(doc, {
        'codigo': codigo,
        'fecha': fecha,
        'hora': hora,
        'timestamp': Timestamp.now(),
        'usuario': {
          'uid': user!.uid,
          'nombre': userDoc['nombres'],
          'rol': userDoc['rol'],
        },
      });
    }

    await batch.commit();

    setState(() {
      codigosEscaneados.clear();
      guardando = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paquetes guardados correctamente')),
    );
  }

  // ===== CONFIRMAR SALIDA =====
  Future<bool> _confirmarSalida() async {
    if (codigosEscaneados.isEmpty) return true;

    final salir = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar salida'),
        content: const Text('Tienes paquetes sin guardar. ¿Seguro que quieres salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    return salir ?? false;
  }

  // ===== REGISTRO MANUAL =====
  Future<void> _registrarCodigoManual() async {
    final controller = TextEditingController();

    final codigo = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Registrar código manual'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Código',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (codigo != null && !codigosEscaneados.contains(codigo)) {
      setState(() {
        codigosEscaneados.add(codigo);
      });
    }
  }

  // ===== EDITAR =====
  Future<void> _editarCodigo(int index) async {
    final controller = TextEditingController(text: codigosEscaneados[index]);

    final nuevoCodigo = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar código'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (nuevoCodigo != null) {
      setState(() {
        codigosEscaneados[index] = nuevoCodigo;
      });
    }
  }

  // ===== ELIMINAR =====
  void _eliminarCodigo(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar código'),
        content: const Text('¿Desea eliminar este código?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                codigosEscaneados.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
