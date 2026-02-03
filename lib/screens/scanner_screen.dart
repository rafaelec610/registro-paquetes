import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  final AudioPlayer player = AudioPlayer();

  final List<String> codigosEscaneados = [];
  bool procesando = false;
  bool excelGuardado = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _confirmarSalida,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Escanear paquetes'),
          actions: [
            IconButton(
              icon: const Icon(Icons.flash_on),
              onPressed: () => cameraController.toggleTorch(),
            ),
          ],
        ),
        body: Column(
          children: [

            // ======== CÁMARA ========
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
                      border: Border.all(
                        color: Colors.green,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.keyboard),
              label: const Text('Registrar código manual'),
              onPressed: _registrarCodigoManual,
            ),
            // ======== LISTA DE CÓDIGOS ========
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Códigos registrados: ${codigosEscaneados.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Expanded(
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
            // ======== BOTÓN GUARDAR ========
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Guardar y compartir',
                    style: TextStyle(fontSize: 16),
                  ),
                  onPressed: guardarYCompartirExcel,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======== ESCANEO ========
  void onDetect(BarcodeCapture capture) async {
    if (procesando) return;

    final barcode = capture.barcodes.first;
    final String? code = barcode.rawValue;

    if (code == null || codigosEscaneados.contains(code)) return;

    setState(() {
      procesando = true;
      codigosEscaneados.add(code);
    });

    await player.play(AssetSource('sounds/beep.mp3'));
    await Future.delayed(const Duration(milliseconds: 800));

    procesando = false;
  }

  // ======== CONFIRMAR SALIDA ========
  Future<bool> _confirmarSalida() async {
    if (excelGuardado) return true;

    final salir = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar salida'),
        content: const Text(
          'Aún no ha guardado y enviado\n¿Seguro que quiere salir?',
        ),
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

  // ======== GUARDAR EXCEL ========
  Future<void> guardarYCompartirExcel() async {
    if (codigosEscaneados.isEmpty) return;

    final xl.Excel workbook = xl.Excel.createExcel();
    final xl.Sheet sheet = workbook['Registros'];

    sheet.appendRow(['Código', 'Fecha', 'Hora']);

    final fecha = DateFormat('yyyy-MM-dd').format(DateTime.now());

    for (final codigo in codigosEscaneados) {
      final hora = DateFormat('HH:mm:ss').format(DateTime.now());
      sheet.appendRow([codigo, fecha, hora]);
    }

    final directory = await getApplicationDocumentsDirectory();
    final path =
        '${directory.path}/registros_${DateTime.now().millisecondsSinceEpoch}.xlsx';

    final bytes = workbook.save();
    if (bytes == null) return;

    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Registros de paquetes escaneados',
    );

    setState(() {
      excelGuardado = true;
    });
  }
  // ======== DIGITAR CODIGO MANUALMENTE ========
  Future<void> _registrarCodigoManual() async {
    final controller = TextEditingController();

    final codigo = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Registrar código manual'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Código',
            border: OutlineInputBorder(),
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
              if (value.isNotEmpty) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('Guardar'),
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
  // ======== EDITAR CODIGO ========
  Future<void> _editarCodigo(int index) async {
    final controller =
      TextEditingController(text: codigosEscaneados[index]);

    final nuevoCodigo = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar código'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
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
              if (value.isNotEmpty) {
                Navigator.pop(context, value);
              }
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
  // ========= ELIMINAR CODIGO ==========
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
