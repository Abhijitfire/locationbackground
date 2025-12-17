// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocationRecordAdapter extends TypeAdapter<LocationRecord> {
  @override
  final int typeId = 0;

  @override
  LocationRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocationRecord(
      time: fields[0] as String,
      latitude: fields[1] as double,
      longitude: fields[2] as double,
      address: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LocationRecord obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.time)
      ..writeByte(1)
      ..write(obj.latitude)
      ..writeByte(2)
      ..write(obj.longitude)
      ..writeByte(3)
      ..write(obj.address);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
