// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_backup_service.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BackupLogEntryAdapter extends TypeAdapter<BackupLogEntry> {
  @override
  final int typeId = 0;

  @override
  BackupLogEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BackupLogEntry()
      ..id = fields[0] as String?
      ..timestamp = fields[1] as DateTime?
      ..logType = fields[2] as String?
      ..date = fields[3] as String?
      ..time = fields[4] as String?
      ..address = fields[5] as String?
      ..zoneName = fields[6] as String?
      ..status = fields[7] as String?
      ..information = fields[8] as String?
      ..user = fields[9] as String?;
  }

  @override
  void write(BinaryWriter writer, BackupLogEntry obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.logType)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.time)
      ..writeByte(5)
      ..write(obj.address)
      ..writeByte(6)
      ..write(obj.zoneName)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.information)
      ..writeByte(9)
      ..write(obj.user);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupLogEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BackupMetadataAdapter extends TypeAdapter<BackupMetadata> {
  @override
  final int typeId = 1;

  @override
  BackupMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BackupMetadata()
      ..date = fields[0] as String?
      ..troubleLogsCount = fields[1] as int?
      ..statusLogsCount = fields[2] as int?
      ..fireLogsCount = fields[3] as int?
      ..connectionLogsCount = fields[4] as int?
      ..lastBackupTime = fields[5] as DateTime?
      ..isCompressed = fields[6] as bool?;
  }

  @override
  void write(BinaryWriter writer, BackupMetadata obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.troubleLogsCount)
      ..writeByte(2)
      ..write(obj.statusLogsCount)
      ..writeByte(3)
      ..write(obj.fireLogsCount)
      ..writeByte(4)
      ..write(obj.connectionLogsCount)
      ..writeByte(5)
      ..write(obj.lastBackupTime)
      ..writeByte(6)
      ..write(obj.isCompressed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
