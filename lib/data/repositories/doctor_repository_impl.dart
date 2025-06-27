// lib/data/repositories/doctor_repository_impl.dart
import 'package:clinic_management_system/domain/entities/doctor.dart';
import 'package:clinic_management_system/domain/repositories/doctor_repository.dart';
import 'package:clinic_management_system/data/models/doctor_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class DoctorRepositoryImpl implements DoctorRepository {
  final FirebaseFirestore _firestore;
  final Box _hiveDoctorsBox;

  DoctorRepositoryImpl(this._firestore, this._hiveDoctorsBox);

  CollectionReference get _doctorsCollection => _firestore.collection('doctors');

  @override
  Future<List<Doctor>> getAllDoctors() async {
    final List<Doctor> doctors = [];
    // Prioritize Hive for reading
    _hiveDoctorsBox.values.forEach((doctorMap) {
      // Safely cast doctorMap from Hive to Map<String, dynamic>
      if (doctorMap is Map<dynamic, dynamic>) {
        final model = DoctorModel.fromMap('id_not_used_for_hive', Map<String, dynamic>.from(doctorMap));
        doctors.add(model.toEntity());
      }
    });

    // If Hive is empty or stale, consider a refresh from Firestore
    if (doctors.isEmpty) {
      try {
        final snapshot = await _doctorsCollection.get();
        for (var doc in snapshot.docs) {
          // Safely cast doc.data() from Firestore to Map<String, dynamic>
          final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          final model = DoctorModel.fromMap(doc.id, data);
          doctors.add(model.toEntity());
          _hiveDoctorsBox.put(doc.id, data); // Cache in Hive
        }
      } catch (e) {
        print('Error fetching doctors from Firestore: $e');
        // You might want to throw an exception or return an empty list
      }
    }
    return doctors;
  }

  @override
  Future<List<Doctor>> getAvailableDoctorsForDate(DateTime date) async {
    final String dayOfWeek = DateFormat('EEEE').format(date);
    final allDoctors = await getAllDoctors(); // Get all doctors first
    return allDoctors.where((doctor) => doctor.availableDays.contains(dayOfWeek)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}


// // lib/data/repositories/doctor_repository_impl.dart
// import 'package:clinic_management_system/domain/entities/doctor.dart';
// import 'package:clinic_management_system/domain/repositories/doctor_repository.dart';
// import 'package:clinic_management_system/data/models/doctor_model.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:intl/intl.dart';

// class DoctorRepositoryImpl implements DoctorRepository {
//   final FirebaseFirestore _firestore;
//   final Box _hiveDoctorsBox;

//   DoctorRepositoryImpl(this._firestore, this._hiveDoctorsBox);

//   CollectionReference get _doctorsCollection => _firestore.collection('doctors');

//   @override
//   Future<List<Doctor>> getAllDoctors() async {
//     final List<Doctor> doctors = [];
//     // Prioritize Hive for reading
//     _hiveDoctorsBox.values.forEach((doctorMap) {
//       final model = DoctorModel.fromMap('id_not_used_for_hive', Map<String, dynamic>.from(doctorMap));
//       doctors.add(model.toEntity());
//     });
//     // If Hive is empty or stale, consider a refresh from Firestore
//     if (doctors.isEmpty) {
//       try {
//         final snapshot = await _doctorsCollection.get();
//         for (var doc in snapshot.docs) {
//           final model = DoctorModel.fromMap(doc.id, doc.data());
//           doctors.add(model.toEntity());
//           _hiveDoctorsBox.put(doc.id, doc.data()); // Cache in Hive
//         }
//       } catch (e) {
//         print('Error fetching doctors from Firestore: $e');
//         // You might want to throw an exception or return an empty list
//       }
//     }
//     return doctors;
//   }

//   @override
//   Future<List<Doctor>> getAvailableDoctorsForDate(DateTime date) async {
//     final String dayOfWeek = DateFormat('EEEE').format(date);
//     final allDoctors = await getAllDoctors(); // Get all doctors first
//     return allDoctors.where((doctor) => doctor.availableDays.contains(dayOfWeek)).toList()
//       ..sort((a, b) => a.name.compareTo(b.name));
//   }
// }