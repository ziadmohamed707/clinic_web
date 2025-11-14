// lib/data/models/client_model.dart
import 'package:physioone/domain/entities/client.dart';
import 'package:physioone/data/models/client_package_model.dart';

class ClientModel {
  final int id;
  final String name;
  final int age;
  final String phoneNumber;
  final String details; // Optional field for additional information
  final List<ClientPackageModel> bookedPackages;

  ClientModel({
    required this.id,
    required this.name,
    required this.age, // Assuming age is an integer, defaulting to 0
    required this.phoneNumber,
    required this.details, // Optional field for additional information
    this.bookedPackages = const [],
  });

  factory ClientModel.fromMap(int id, Map<String, dynamic> map) {
    return ClientModel(
      id: id,
      name: map['name'] ?? '',
      age: map['age'] ?? 0, // Defaulting to 0 if age is not provided
      phoneNumber: map['phone'] ?? '',
      details:
          map['details'] ?? '', // Optional field for additional information
      bookedPackages:
          (map['bookedPackages'] as List<dynamic>?)
              ?.map(
                (pkgMap) => ClientPackageModel.fromMap(
                  Map<String, dynamic>.from(pkgMap),
                ),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age, // Assuming age is an integer
      'phone': phoneNumber,
      'details': details, // Optional field for additional information
      'bookedPackages': bookedPackages.map((e) => e.toMap()).toList(),
    };
  }

  factory ClientModel.fromEntity(Client entity) {
    return ClientModel(
      id: entity.id,
      name: entity.name,
      age: entity.age, // Assuming age is an integer
      phoneNumber: entity.phoneNumber,
      details:
          entity.details ?? '', // Optional field for additional information
      bookedPackages:
          entity.bookedPackages
              .map((e) => ClientPackageModel.fromEntity(e))
              .toList(),
    );
  }

  Client toEntity() {
    return Client(
      id: id,
      name: name,
      age: age, // Assuming age is an integer
      phoneNumber: phoneNumber,
      details: details, // Optional field for additional information
      bookedPackages: bookedPackages.map((e) => e.toEntity()).toList(),
    );
  }
}
