// lib/data/models/client_package_model.dart
import 'package:physioone/domain/entities/client_package.dart';

class ClientPackageModel {
  final String name;
  final int totalSessions;
  final int remainingSessions;
  final String category;

  ClientPackageModel({
    required this.name,
    required this.totalSessions,
    required this.remainingSessions,
    required this.category,
  });

  factory ClientPackageModel.fromMap(Map<String, dynamic> map) {
    return ClientPackageModel(
      name: map['name'] ?? '',
      totalSessions: map['totalSessions'] ?? 0,
      remainingSessions: map['remainingSessions'] ?? 0,
      category: map['category'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'totalSessions': totalSessions,
      'remainingSessions': remainingSessions,
      'category': category,
    };
  }

  factory ClientPackageModel.fromEntity(ClientPackage entity) {
    return ClientPackageModel(
      name: entity.name,
      totalSessions: entity.totalSessions,
      remainingSessions: entity.remainingSessions,
      category: entity.category,
    );
  }

  ClientPackage toEntity() {
    return ClientPackage(
      name: name,
      totalSessions: totalSessions,
      remainingSessions: remainingSessions,
      category: category,
    );
  }
}
