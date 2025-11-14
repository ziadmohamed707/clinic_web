// lib/data/models/doctor_model.dart
import 'package:physioone/domain/entities/doctor.dart';

class DoctorModel {
  final String id;
  final String name;
  final List<String> availableDays;

  DoctorModel({
    required this.id,
    required this.name,
    required this.availableDays,
  });

  factory DoctorModel.fromMap(String id, Map<String, dynamic> map) {
    return DoctorModel(
      id: id,
      name: map['name'] ?? '',
      availableDays:
          (map['availableDays'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'availableDays': availableDays};
  }

  factory DoctorModel.fromEntity(Doctor entity) {
    return DoctorModel(
      id: entity.id,
      name: entity.name,
      availableDays: entity.availableDays,
    );
  }

  Doctor toEntity() {
    return Doctor(id: id, name: name, availableDays: availableDays);
  }
}
