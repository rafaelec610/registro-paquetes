// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paquete.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaqueteAdapter extends TypeAdapter<Paquete> {
  @override
  final int typeId = 0;

  @override
  Paquete read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Paquete(
      fields[0] as String,
      fields[1] as String,
      fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Paquete obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.codigo)
      ..writeByte(1)
      ..write(obj.fecha)
      ..writeByte(2)
      ..write(obj.hora);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaqueteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
