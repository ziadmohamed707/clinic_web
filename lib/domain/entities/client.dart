// lib/domain/entities/client.dart
import 'package:physioone/domain/entities/client_package.dart';
import 'package:equatable/equatable.dart';

class Client extends Equatable {
  final int id;
  final String name;
  final int age; // Assuming age is an integer
  final String phoneNumber;
  final String? details; // Optional field for additional informatio
  final List<ClientPackage> bookedPackages;

  const Client({
    required this.id,
    required this.name,
    required this.age, // Assuming age is an integer
    required this.phoneNumber,
    this.details, // Optional field for additional information
    this.bookedPackages = const [],
  });

  @override
  List<Object?> get props => [
    id,
    name,
    age,
    phoneNumber,
    details,
    bookedPackages,
  ];

  Client copyWith({
    int? id,
    String? name,
    int? age, // Assuming age is an integer
    String? phoneNumber,
    String? details, // Optional field for additional information
    List<ClientPackage>? bookedPackages,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age, // Assuming age is an integer
      phoneNumber: phoneNumber ?? this.phoneNumber,
      details:
          details ?? this.details, // Optional field for additional information
      bookedPackages: bookedPackages ?? this.bookedPackages,
    );
  }
}
