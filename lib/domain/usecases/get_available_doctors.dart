// lib/domain/usecases/get_available_doctors.dart
import 'package:clinic_management_system/domain/entities/doctor.dart';
import 'package:clinic_management_system/domain/repositories/doctor_repository.dart';

class GetAvailableDoctors {
  final DoctorRepository repository;

  GetAvailableDoctors(this.repository);

  Future<List<Doctor>> call(DateTime date) {
    return repository.getAvailableDoctorsForDate(date);
  }
}