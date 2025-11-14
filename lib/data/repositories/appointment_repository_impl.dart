// lib/data/repositories/appointment_repository_impl.dart
import 'package:physioone/domain/entities/appointment.dart';
import 'package:physioone/domain/repositories/appointment_repository.dart';
import 'package:physioone/data/models/appointment_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  final FirebaseFirestore _firestore;
  final Box _hiveAppointmentsBox;

  AppointmentRepositoryImpl(this._firestore, this._hiveAppointmentsBox);

  CollectionReference get _appointmentsCollection =>
      _firestore.collection('appointments');

  @override
  Future<void> saveAppointment(Appointment appointment) async {
    final model = AppointmentModel.fromEntity(appointment);
    try {
      await _hiveAppointmentsBox.put(model.id, model.toMap());
      await _appointmentsCollection.doc(model.id).set(model.toMap());
    } catch (e) {
      throw Exception('Failed to save appointment: $e');
    }
  }

  @override
  Future<Appointment?> getAppointment(String id) async {
    // Try Hive first
    final hiveData = _hiveAppointmentsBox.get(id);
    if (hiveData != null) {
      return AppointmentModel.fromMap(
        id,
        Map<String, dynamic>.from(hiveData as Map),
      ).toEntity();
    }

    // Fallback to Firestore if not found in Hive
    try {
      final doc = await _appointmentsCollection.doc(id).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        // Also save to Hive for future quick access
        _hiveAppointmentsBox.put(id, data);
        return AppointmentModel.fromMap(id, data).toEntity();
      }
      return null;
    } catch (e) {
      print('Error getting appointment from Firestore: $e');
      return null; // Or throw a specific error
    }
  }

  @override
  Future<List<Appointment>> getAppointmentsForDate(DateTime date) async {
    final String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    // Filter from Hive data first
    final List<Appointment> appointments = [];
    _hiveAppointmentsBox.values.forEach((appointmentMap) {
      final model = AppointmentModel.fromMap(
        'id_not_used_for_filtering',
        Map<String, dynamic>.from(appointmentMap),
      );
      if (DateFormat('yyyy-MM-dd').format(model.date) == formattedDate) {
        appointments.add(model.toEntity());
      }
    });
    return appointments;
  }

  @override
  Future<void> deleteAppointment(String id) async {
    try {
      await _hiveAppointmentsBox.delete(id);
      await _appointmentsCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete appointment: $e');
    }
  }
}
