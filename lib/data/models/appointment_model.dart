// lib/data/models/appointment_model.dart
import 'package:clinic_management_system/domain/entities/appointment.dart';
import 'package:clinic_management_system/domain/entities/client.dart';
import 'package:clinic_management_system/domain/entities/doctor.dart';

class AppointmentModel {
  final String id;
  final String patientName;
  final String doctorName;
  final String timeSlot;
  final DateTime date;
  final String? phoneNumber;
  final int? clientId;
  final String status; // Stored as string
  final String serviceType; // Stored as string
  final String? packageNameUsed;
  final String? packageCategoryUsed;

  AppointmentModel({
    required this.id,
    required this.patientName,
    required this.doctorName,
    required this.timeSlot,
    required this.date,
    this.phoneNumber,
    this.clientId,
    required this.status,
    required this.serviceType,
    this.packageNameUsed,
    this.packageCategoryUsed,
  });

  factory AppointmentModel.fromMap(String id, Map<String, dynamic> map) {
    return AppointmentModel(
      id: id,
      patientName: map['patient'] ?? '',
      doctorName: map['doctor'] ?? '',
      timeSlot: map['timeSlot'] ?? '',
      date: (map['date'] is String)
          ? DateTime.parse(map['date'])
          : (map['date']?.toDate() ?? DateTime.now()), // For Firestore Timestamp
      phoneNumber: map['phone'],
      clientId: map['clientId'],
      status: map['status'] ?? 'booked',
      serviceType: map['serviceType'] ?? 'Examination',
      packageNameUsed: map['packageNameUsed'],
      packageCategoryUsed: map['packageCategoryUsed'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patient': patientName,
      'doctor': doctorName,
      'timeSlot': timeSlot,
      'date': date.toIso8601String(), // Store as ISO string for consistency
      'phone': phoneNumber,
      'clientId': clientId,
      'status': status,
      'serviceType': serviceType,
      'packageNameUsed': packageNameUsed,
      'packageCategoryUsed': packageCategoryUsed,
    };
  }

  // Convert from domain entity to data model
  factory AppointmentModel.fromEntity(Appointment entity) {
    return AppointmentModel(
      id: entity.id,
      patientName: entity.patientName,
      doctorName: entity.doctorName,
      timeSlot: entity.timeSlot,
      date: entity.date,
      phoneNumber: entity.phoneNumber,
      clientId: entity.clientId,
      status: entity.status.toString().split('.').last, // Convert enum to string
      serviceType: serviceTypeToString(entity.serviceType), // Convert enum to string
      packageNameUsed: entity.packageNameUsed,
      packageCategoryUsed: entity.packageCategoryUsed,
    );
  }

  // Convert from data model to domain entity
  Appointment toEntity() {
    return Appointment(
      id: id,
      patientName: patientName,
      doctorName: doctorName,
      timeSlot: timeSlot,
      date: date,
      phoneNumber: phoneNumber,
      clientId: clientId,
      status: AppointmentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == status,
        orElse: () => AppointmentStatus.booked,
      ),
      serviceType: serviceTypeFromString(serviceType)!,
      packageNameUsed: packageNameUsed,
      packageCategoryUsed: packageCategoryUsed,
    );
  }
}