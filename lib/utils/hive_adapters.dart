// g:/Work/Project/physioone/lib/utils/hive_adapters.dart
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A Hive TypeAdapter for Firebase Firestore's Timestamp class.
/// This allows Timestamp objects to be stored directly in Hive.
class TimestampAdapter extends TypeAdapter<Timestamp> {
  @override
  final int typeId = 50; // Changed from 100 to 50 to avoid conflicts

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

// If you have other adapters, assign them unique typeIds:
// UserModel should use typeId: 100 (if it exists)
// AppointmentModel should use typeId: 101
// ClientModel should use typeId: 102  
// DoctorModel should use typeId: 103
// etc.

/// Example of how your other adapters should look:
/*
@HiveType(typeId: 100)
class UserModel extends HiveObject {
  // Your UserModel fields
}

@HiveType(typeId: 101) 
class AppointmentModel extends HiveObject {
  // Your AppointmentModel fields
}

@HiveType(typeId: 102)
class ClientModel extends HiveObject {
  // Your ClientModel fields  
}

@HiveType(typeId: 103)
class DoctorModel extends HiveObject {
  // Your DoctorModel fields
}
*/