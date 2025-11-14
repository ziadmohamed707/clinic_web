// lib/domain/usecases/get_appointments.dart
import 'package:physioone/domain/entities/appointment.dart';
import 'package:physioone/domain/repositories/appointment_repository.dart';

class GetAppointments {
  final AppointmentRepository repository;

  GetAppointments(this.repository);

  Future<List<Appointment>> call(DateTime date) {
    return repository.getAppointmentsForDate(date);
  }
}
