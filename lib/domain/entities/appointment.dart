// lib/domain/entities/appointment.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class Appointment extends Equatable {
  final String id;
  final String patientName;
  final String doctorName;
  final String timeSlot;
  final DateTime date;
  final String? phoneNumber;
  final int? clientId;
  final String? clinicId; // 🆕 مفتاح العيادة (لتعدد العيادات)
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
    this.clinicId, // 🆕
    this.status = AppointmentStatus.booked,
    required this.serviceType,
    this.packageNameUsed,
    this.packageCategoryUsed,
  });

  // ─────────── Factory constructors ───────────

  /// تحويل من Firestore Document إلى Appointment
  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final dateString = data['date'] as String?;
    DateTime parsedDate;
    if (dateString != null) {
      parsedDate = DateTime.tryParse(dateString) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    final serviceTypeStr = data['serviceType'] as String?;
    final serviceType = serviceTypeFromString(serviceTypeStr) ?? ServiceType.examination;

    // قراءة status كـ String
    final statusStr = data['status'] as String? ?? 'booked';
    AppointmentStatus status;
    switch (statusStr.toLowerCase()) {
      case 'cancelled':
        status = AppointmentStatus.cancelled;
        break;
      case 'completed':
        status = AppointmentStatus.completed;
        break;
      default:
        status = AppointmentStatus.booked;
    }

    return Appointment(
      id: doc.id,
      patientName: data['patient'] ?? data['patientName'] ?? '',
      doctorName: data['doctor'] ?? data['doctorName'] ?? '',
      timeSlot: data['timeSlot'] ?? '',
      date: parsedDate,
      phoneNumber: data['phone'] ?? data['patientPhone'] ?? '',
      clientId: data['clientId'] as int?,
      clinicId: data['clinicId'] as String?, // 🆕
      status: status,
      serviceType: serviceType,
      packageNameUsed: data['packageNameUsed'] ?? data['packageUsed'],
      packageCategoryUsed: data['packageCategoryUsed'],
    );
  }

  /// تحويل الكائن إلى Map جاهز للحفظ في Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientName': patientName,
      'doctorName': doctorName,
      'timeSlot': timeSlot,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'phone': phoneNumber,
      'clientId': clientId,
      'clinicId': clinicId, // 🆕
      'status': status.name, // 'booked', 'cancelled', 'completed'
      'serviceType': serviceTypeToString(serviceType),
      'packageNameUsed': packageNameUsed,
      'packageCategoryUsed': packageCategoryUsed,
    };
  }

  // ─────────── copyWith ───────────

  Appointment copyWith({
    String? id,
    String? patientName,
    String? doctorName,
    String? timeSlot,
    DateTime? date,
    String? phoneNumber,
    int? clientId,
    String? clinicId, // 🆕
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
      clinicId: clinicId ?? this.clinicId,
      status: status ?? this.status,
      serviceType: serviceType ?? this.serviceType,
      packageNameUsed: packageNameUsed ?? this.packageNameUsed,
      packageCategoryUsed: packageCategoryUsed ?? this.packageCategoryUsed,
    );
  }

  // ─────────── Equatable ───────────

  @override
  List<Object?> get props => [
        id,
        patientName,
        doctorName,
        timeSlot,
        date,
        phoneNumber,
        clientId,
        clinicId, // 🆕
        status,
        serviceType,
        packageNameUsed,
        packageCategoryUsed,
      ];
}

// ─────────── Enums ───────────

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

// ─────────── Helper functions ───────────

/// تحويل String إلى ServiceType
ServiceType? serviceTypeFromString(String? value) {
  if (value == null) return null;
  final cleaned = value.replaceAll(' ', '').toLowerCase();
  return ServiceType.values.firstWhere(
    (e) => e.toString().split('.').last == cleaned,
    orElse: () => ServiceType.examination,
  );
}

/// تحويل ServiceType إلى String (للحفظ في Firestore)
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