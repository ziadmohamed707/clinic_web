// lib/data/repositories/client_repository_impl.dart
import 'package:clinic_management_system/domain/entities/client.dart';
import 'package:clinic_management_system/domain/repositories/client_repository.dart';
import 'package:clinic_management_system/data/models/client_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ClientRepositoryImpl implements ClientRepository {
  final FirebaseFirestore _firestore;
  final Box _hiveClientsBox;

  ClientRepositoryImpl(this._firestore, this._hiveClientsBox);

  CollectionReference get _clientsCollection => _firestore.collection('clients');

  @override
  Future<void> saveClient(Client client) async {
    final model = ClientModel.fromEntity(client);
    try {
      await _hiveClientsBox.put(model.id, model.toMap());
      await _clientsCollection.doc(model.id.toString()).set(model.toMap());
      // Update metadata for lastId
      if (model.id > (_hiveClientsBox.get('lastId', defaultValue: 0) as int)) {
        await _hiveClientsBox.put('lastId', model.id);
        await _clientsCollection.doc('metadata').set({'lastId': model.id});
      }
    } catch (e) {
      throw Exception('Failed to save client: $e');
    }
  }

  @override
  Future<Client?> getClient(int id) async {
    final hiveData = _hiveClientsBox.get(id.toString());
    if (hiveData != null) {
      return ClientModel.fromMap(id, Map<String, dynamic>.from(hiveData as Map)).toEntity();
    }

    try {
      final doc = await _clientsCollection.doc(id.toString()).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _hiveClientsBox.put(id, data); // Cache in Hive
        return ClientModel.fromMap(id, data).toEntity();
      }
      return null;
    } catch (e) {
      print('Error getting client from Firestore: $e');
      return null;
    }
  }

  @override
  Future<List<Client>> getAllClients() async {
    final List<Client> clients = [];
    // Prioritize Hive for reading
    _hiveClientsBox.keys.where((key) => key != 'lastId').forEach((key) {
      final clientMap = _hiveClientsBox.get(key);
      if (clientMap != null) {
        clients.add(ClientModel.fromMap(key, Map<String, dynamic>.from(clientMap as Map)).toEntity());
      }
    });
    return clients;
  }

  @override
  Future<int> getNextClientId() async {
    // Get from Hive, fallback to Firestore if metadata is not in Hive
    int lastId = _hiveClientsBox.get('lastId', defaultValue: 0) as int;
    if (lastId == 0) {
      try {
        final metadataDoc = await _clientsCollection.doc('metadata').get();
        if (metadataDoc.exists) {
          lastId = (metadataDoc.data() as Map<String, dynamic>?)?['lastId'] as int? ?? 0;
          _hiveClientsBox.put('lastId', lastId); // Cache in Hive
        }
      } catch (e) {
        print('Error getting lastId from Firestore: $e');
      }
    }
    return lastId + 1;
  }

  @override
  Future<void> updateClient(Client client) async {
    final model = ClientModel.fromEntity(client);
    try {
      await _hiveClientsBox.put(model.id, model.toMap());
      await _clientsCollection.doc(model.id.toString()).set(model.toMap());
    } catch (e) {
      throw Exception('Failed to update client: $e');
    }
  }

  @override
  Future<void> updateLastClientId(int lastId) async {
    try {
      await _hiveClientsBox.put('lastId', lastId);
      await _clientsCollection.doc('metadata').set({'lastId': lastId});
    } catch (e) {
      throw Exception('Failed to update last client ID: $e');
    }
  }
}