// lib/domain/repositories/doctor_repository.dart
import 'package:physioone/domain/entities/doctor.dart';

abstract class DoctorRepository {
  Future<List<Doctor>> getAllDoctors();
  Future<List<Doctor>> getAvailableDoctorsForDate(DateTime date);
  // Add other doctor-related methods if needed
}
