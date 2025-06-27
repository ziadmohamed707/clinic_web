// lib/domain/usecases/get_appointments.dart
import 'package:clinic_management_system/domain/entities/appointment.dart';
import 'package:clinic_management_system/domain/repositories/appointment_repository.dart';

class GetAppointments {
  final AppointmentRepository repository;

  GetAppointments(this.repository);

  Future<List<Appointment>> call(DateTime date) {
    return repository.getAppointmentsForDate(date);
  }
}