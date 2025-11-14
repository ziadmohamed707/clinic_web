// lib/domain/usecases/get_all_clients.dart
import 'package:physioone/domain/entities/client.dart';
import 'package:physioone/domain/repositories/client_repository.dart';

class GetAllClients {
  final ClientRepository repository;

  GetAllClients(this.repository);

  Future<List<Client>> call() {
    return repository.getAllClients();
  }
}
