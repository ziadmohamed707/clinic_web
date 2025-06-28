// lib/domain/usecases/get_all_clients.dart
import 'package:physioprime/domain/entities/client.dart';
import 'package:physioprime/domain/repositories/client_repository.dart';

class GetAllClients {
  final ClientRepository repository;

  GetAllClients(this.repository);

  Future<List<Client>> call() {
    return repository.getAllClients();
  }
}
