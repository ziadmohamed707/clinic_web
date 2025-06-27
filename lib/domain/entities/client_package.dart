// lib/domain/entities/client_package.dart
import 'package:equatable/equatable.dart';

class ClientPackage extends Equatable {
  final String name;
  final int totalSessions;
  final int remainingSessions;
  final String category;

  const ClientPackage({
    required this.name,
    required this.totalSessions,
    required this.remainingSessions,
    required this.category,
  });

  @override
  List<Object?> get props => [name, totalSessions, remainingSessions, category];

  ClientPackage copyWith({
    String? name,
    int? totalSessions,
    int? remainingSessions,
    String? category,
  }) {
    return ClientPackage(
      name: name ?? this.name,
      totalSessions: totalSessions ?? this.totalSessions,
      remainingSessions: remainingSessions ?? this.remainingSessions,
      category: category ?? this.category,
    );
  }
}