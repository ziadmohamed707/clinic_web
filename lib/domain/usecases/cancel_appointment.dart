// lib/domain/usecases/cancel_appointment.dart
import 'package:physioprime/domain/entities/appointment.dart';
import 'package:physioprime/domain/entities/client.dart';
import 'package:physioprime/domain/entities/client_package.dart';
import 'package:physioprime/domain/repositories/appointment_repository.dart';
import 'package:physioprime/domain/repositories/client_repository.dart';
import 'package:equatable/equatable.dart';

class CancelAppointment {
  final AppointmentRepository appointmentRepository;
  final ClientRepository clientRepository;

  CancelAppointment(this.appointmentRepository, this.clientRepository);

  Future<void> call(CancelAppointmentParams params) async {
    // First, retrieve the existing appointment to get full details
    final existingAppointment = await appointmentRepository.getAppointment(
      params.appointmentId,
    );

    if (existingAppointment != null) {
      final cancelledAppointment = existingAppointment.copyWith(
        status: AppointmentStatus.cancelled,
      );
      await appointmentRepository.saveAppointment(cancelledAppointment);

      // If it was a follow-up, increment session count back
      if (existingAppointment.serviceType == ServiceType.followUpSession &&
          params.clientId != null &&
          params.packageNameUsed != null) {
        final client = await clientRepository.getClient(params.clientId);
        if (client != null) {
          final updatedPackages =
              client.bookedPackages.map((pkg) {
                if (pkg.name == params.packageNameUsed &&
                    pkg.remainingSessions < pkg.totalSessions) {
                  return pkg.copyWith(
                    remainingSessions: pkg.remainingSessions + 1,
                  );
                }
                return pkg;
              }).toList();
          await clientRepository.updateClient(
            client.copyWith(bookedPackages: updatedPackages),
          );
        }
      }
    } else {
      throw Exception('Appointment not found for cancellation.');
    }
  }
}

class CancelAppointmentParams extends Equatable {
  final String appointmentId;
  final String patientName;
  final String patientPhone;
  final String doctorName;
  final int clientId;
  final String serviceType;
  final String? packageNameUsed;
  final String? packageCategoryUsed;

  const CancelAppointmentParams({
    required this.appointmentId,
    required this.patientName,
    required this.patientPhone,
    required this.doctorName,
    required this.clientId,
    required this.serviceType,
    this.packageNameUsed,
    this.packageCategoryUsed,
  });

  @override
  List<Object?> get props => [
    appointmentId,
    patientName,
    patientPhone,
    doctorName,
    clientId,
    serviceType,
    packageNameUsed,
    packageCategoryUsed,
  ];
}
