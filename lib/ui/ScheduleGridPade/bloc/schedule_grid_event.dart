import 'package:physioone/domain/entities/client.dart';
import 'package:physioone/domain/entities/client_package.dart';
import 'package:equatable/equatable.dart';
import '/domain/entities/appointment.dart';

abstract class ScheduleGridEvent extends Equatable {
  const ScheduleGridEvent();

  @override
  List<Object?> get props => [];
}

class LoadSchedule extends ScheduleGridEvent {
  final DateTime date;
  const LoadSchedule(this.date);

  @override
  List<Object> get props => [date];
}

class DateSelected extends ScheduleGridEvent {
  final DateTime newDate;
  const DateSelected(this.newDate);

  @override
  List<Object> get props => [newDate];
}

class SyncData extends ScheduleGridEvent {}

class SaveAppointmentEvent extends ScheduleGridEvent {
  final Appointment appointment;
  final Client? selectedClient;
  final String? serviceType;
  final String? followUpPackageName;

  const SaveAppointmentEvent({
    required this.appointment,
    this.selectedClient,
    this.serviceType,
    this.followUpPackageName,
  });

  @override
  List<Object?> get props => [
    appointment,
    selectedClient,
    serviceType,
    followUpPackageName,
  ];
}

class CancelAppointmentEvent extends ScheduleGridEvent {
  final String appointmentId;
  final String patientName;
  final String patientPhone;
  final String doctorName;
  final int? clientId;
  final String serviceType;
  final String? packageNameUsed;
  final String? packageCategoryUsed;

  const CancelAppointmentEvent({
    required this.appointmentId,
    required this.patientName,
    required this.patientPhone,
    required this.doctorName,
    this.clientId,
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

class AddClientEvent extends ScheduleGridEvent {
  final String name;
  final int age;
  final String phone;
  final String details;
  final List<ClientPackage> bookedPackages;

  const AddClientEvent({
    required this.name,
    required this.age,
    required this.phone,
    required this.details,
    this.bookedPackages = const [],
  });

  @override
  List<Object> get props => [name, age, phone, details, bookedPackages];
}