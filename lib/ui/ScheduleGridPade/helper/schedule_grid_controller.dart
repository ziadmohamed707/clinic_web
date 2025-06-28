
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class ScheduleGridController {
  final CollectionReference appointmentsCollection;
  final CollectionReference clientsCollection;
  final CollectionReference doctorsCollection;
  final Box appointmentsBox;
  final Box clientsBox;
  final Box doctorsBox;
  final DateTime selectedDate;

  ScheduleGridController({
    required this.appointmentsCollection,
    required this.clientsCollection,
    required this.doctorsCollection,
    required this.appointmentsBox,
    required this.clientsBox,
    required this.doctorsBox,
    required this.selectedDate,
  });

  Future<void> syncData() async {
    try {
      final clientsSnapshot = await clientsCollection.get();
      final lastIdDoc = await clientsCollection.doc('metadata').get();
      if (lastIdDoc.exists) {
        clientsBox.put(
          'lastId',
          (lastIdDoc.data() as Map<String, dynamic>?)?['lastId'],
        );
      }
      for (var doc in clientsSnapshot.docs) {
        if (doc.id != 'metadata') {
          clientsBox.put(doc.id, doc.data());
        }
      }
    } catch (e) {
      print("Error syncing data: \$e");
    }
  }

  Future<void> saveAppointmentToFirestore(String key, Map<String, dynamic> data) async {
    try {
      await appointmentsCollection.doc(key).set(data);
    } catch (e) {
      print("Error saving appointment: \$e");
    }
  }

  Future<void> saveClientToFirestore(String key, Map<String, dynamic> data) async {
    try {
      await clientsCollection.doc(key).set(data);
      final currentLastId = clientsBox.get('lastId', defaultValue: 0);
      if (data['id'] > currentLastId) {
        await clientsCollection.doc('metadata').set({'lastId': data['id']});
      }
    } catch (e) {
      print("Error saving client: \$e");
    }
  }

  Future<void> updateClientData(String clientId, Map<String, dynamic> clientData) async {
    try {
      await clientsBox.put(clientId, clientData);
      await clientsCollection.doc(clientId).set(clientData);

      final int currentClientIntId = clientData['id'] as int? ?? 0;
      final firestoreMetadataRef = clientsCollection.doc('metadata');
      final metadataDoc = await firestoreMetadataRef.get();
      final int currentFirestoreLastId =
          (metadataDoc.data() as Map<String, dynamic>?)?['lastId'] as int? ?? 0;
      if (currentClientIntId > currentFirestoreLastId) {
        await firestoreMetadataRef.set({'lastId': currentClientIntId});
      }
    } catch (e) {
      print("Error updating client: \$e");
    }
  }

  // void editCell(String timeSlot, Map<String, dynamic> doctorData) {
  //   final String formattedDateForKey = DateFormat('yyyy-MM-dd').format(selectedDate);
  //   final String key = '\$formattedDateForKey-\$timeSlot-\${doctorData['id']}';
  //   print("Edit cell logic with key: \$key");
  //   // Add edit logic here
  // }
}
