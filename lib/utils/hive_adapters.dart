// g:/Work/Project/clinic_management_system/lib/utils/hive_adapters.dart
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A Hive TypeAdapter for Firebase Firestore's Timestamp class.
/// This allows Timestamp objects to be stored directly in Hive.
class TimestampAdapter extends TypeAdapter<Timestamp> {
  @override
  final int typeId = 100; // Choose a unique typeId not used by other adapters

  @override
  Timestamp read(BinaryReader reader) {
    final seconds = reader.readInt();
    final nanoseconds = reader.readInt();
    return Timestamp(seconds, nanoseconds);
  }

  @override
  void write(BinaryWriter writer, Timestamp obj) {
    writer.writeInt(obj.seconds);
    writer.writeInt(obj.nanoseconds);
  }
}
