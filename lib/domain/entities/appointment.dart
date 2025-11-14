import 'package:physioone/domain/entities/client_package.dart';
import 'package:equatable/equatable.dart'; // For easier comparison if needed

class Appointment extends Equatable {
  final String id;
  final String patientName;
  final String doctorName;
  final String timeSlot;
  final DateTime date;
  final String? phoneNumber;
  final int? clientId;
  final AppointmentStatus status;
  final ServiceType serviceType;
  final String? packageNameUsed;
  final String? packageCategoryUsed;

  const Appointment({
    required this.id,
    required this.patientName,
    required this.doctorName,
    required this.timeSlot,
    required this.date,
    this.phoneNumber,
    this.clientId,
    this.status = AppointmentStatus.booked, // Default status
    required this.serviceType,
    this.packageNameUsed,
    this.packageCategoryUsed,
  });

  Appointment copyWith({
    String? id,
    String? patientName,
    String? doctorName,
    String? timeSlot,
    DateTime? date,
    String? phoneNumber,
    int? clientId,
    AppointmentStatus? status,
    ServiceType? serviceType,
    String? packageNameUsed,
    String? packageCategoryUsed,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      doctorName: doctorName ?? this.doctorName,
      timeSlot: timeSlot ?? this.timeSlot,
      date: date ?? this.date,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      clientId: clientId ?? this.clientId,
      status: status ?? this.status,
      serviceType: serviceType ?? this.serviceType,
      packageNameUsed: packageNameUsed ?? this.packageNameUsed,
      packageCategoryUsed: packageCategoryUsed ?? this.packageCategoryUsed,
    );
  }

  @override
  List<Object?> get props => [
    id,
    patientName,
    doctorName,
    timeSlot,
    date,
    phoneNumber,
    clientId,
    status,
    serviceType,
    packageNameUsed,
    packageCategoryUsed,
  ];
}

enum AppointmentStatus { booked, cancelled, completed }

enum ServiceType {
  examination,
  consultation,
  recoveryFullBody,
  recoveryUpper,
  recoveryLower,
  cupping,
  followUpSession,
}

// Helper to convert string to enum
ServiceType? serviceTypeFromString(String? value) {
  if (value == null) return null;
  return ServiceType.values.firstWhere(
    (e) =>
        e.toString().split('.').last == value.replaceAll(' ', '').toLowerCase(),
    orElse: () => ServiceType.examination, // Default or handle error
  );
}

String serviceTypeToString(ServiceType type) {
  switch (type) {
    case ServiceType.examination:
      return 'Examination';
    case ServiceType.consultation:
      return 'Consultation';
    case ServiceType.recoveryFullBody:
      return 'Recovery (Full Body)';
    case ServiceType.recoveryUpper:
      return 'Recovery (Upper)';
    case ServiceType.recoveryLower:
      return 'Recovery (Lower)';
    case ServiceType.cupping:
      return 'Cupping';
    case ServiceType.followUpSession:
      return 'Follow-up Session';
  }
}
