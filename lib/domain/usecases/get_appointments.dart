// lib/domain/usecases/get_appointments.dart
import 'package:physioprime/domain/entities/appointment.dart';
import 'package:physioprime/domain/repositories/appointment_repository.dart';

class GetAppointments {
  final AppointmentRepository repository;

  GetAppointments(this.repository);

  Future<List<Appointment>> call(DateTime date) {
    return repository.getAppointmentsForDate(date);
  }
}
