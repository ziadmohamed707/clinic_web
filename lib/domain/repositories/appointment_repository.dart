// lib/domain/repositories/appointment_repository.dart
import 'package:clinic_management_system/domain/entities/appointment.dart';

abstract class AppointmentRepository {
  Future<void> saveAppointment(Appointment appointment);
  Future<Appointment?> getAppointment(String id);
  Future<List<Appointment>> getAppointmentsForDate(DateTime date);
  Future<void> deleteAppointment(String id);
}
