import 'dart:io';
import 'package:excel/excel.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/paquete.dart';

Future<File> generarExcelDiario() async {

  final box = Hive.box<Paquete>('paquetes');
  final hoy = DateFormat('yyyy-MM-dd').format(DateTime.now());

  final excel = Excel.createExcel();
  final sheet = excel['Paquetes'];

  sheet.appendRow(['Código', 'Fecha', 'Hora']);

  for (var p in box.values.where((e) => e.fecha == hoy)) {
    sheet.appendRow([p.codigo, p.fecha, p.hora]);
  }

  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/paquetes_$hoy.xlsx');
  file.writeAsBytesSync(excel.encode()!);

  return file;
}
