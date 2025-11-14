// lib/domain/repositories/client_repository.dart
import 'package:physioone/domain/entities/client.dart';

abstract class ClientRepository {
  Future<void> saveClient(Client client);
  Future<Client?> getClient(int id);
  Future<List<Client>> getAllClients();
  Future<int> getNextClientId();
  Future<void> updateClient(Client client);
  Future<void> updateLastClientId(int lastId);
}
