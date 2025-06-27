// lib/domain/entities/doctor.dart
import 'package:equatable/equatable.dart';

class Doctor extends Equatable {
  final String id;
  final String name;
  final List<String> availableDays; // e.g., ['Monday', 'Tuesday']

  const Doctor({
    required this.id,
    required this.name,
    required this.availableDays,
  });

  @override
  List<Object?> get props => [id, name, availableDays];
}
