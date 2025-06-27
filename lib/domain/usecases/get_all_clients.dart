// lib/domain/usecases/get_all_clients.dart
import 'package:clinic_management_system/domain/entities/client.dart';
import 'package:clinic_management_system/domain/repositories/client_repository.dart';

class GetAllClients {
  final ClientRepository repository;

  GetAllClients(this.repository);

  Future<List<Client>> call() {
    return repository.getAllClients();
  }
}