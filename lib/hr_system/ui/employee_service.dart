import 'package:cloud_firestore/cloud_firestore.dart';

import 'employee_model.dart';

class EmployeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'employees';

  /// Get a single employee by ID
  Future<EmployeeModel?> getEmployeeById(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      if (doc.exists && doc.data() != null) {
        return EmployeeModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting employee by ID: $e');
      return null;
    }
  }

  /// Get all employees
  Future<List<EmployeeModel>> getAllEmployees() async {
    try {
      final snapshot = await _firestore.collection(_collectionName).get();
      return snapshot.docs
          .map(
            (doc) => EmployeeModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('Error getting all employees: $e');
      return [];
    }
  }

  /// Get employees by department
  Future<List<EmployeeModel>> getEmployeesByDepartment(
    String department,
  ) async {
    try {
      final snapshot =
          await _firestore
              .collection(_collectionName)
              .where('department', isEqualTo: department)
              .get();
      return snapshot.docs
          .map(
            (doc) => EmployeeModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('Error getting employees by department: $e');
      return [];
    }
  }

  /// Stream for real-time updates for all employees
  Stream<List<EmployeeModel>> employeesStream() {
    return _firestore.collection(_collectionName).snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => EmployeeModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    });
  }

  /// Stream for real-time updates for a single employee
  Stream<EmployeeModel?> employeeStream(String id) {
    return _firestore.collection(_collectionName).doc(id).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists && snapshot.data() != null) {
        return EmployeeModel.fromMap(snapshot.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  /// Add a new employee
  Future<void> addEmployee(EmployeeModel employee) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(employee.id)
          .set(employee.toMap());
    } catch (e) {
      print('Error adding employee: $e');
    }
  }

  /// Update employee data
  Future<void> updateEmployee(EmployeeModel employee) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(employee.id)
          .update(employee.toMap());
    } catch (e) {
      print('Error updating employee: $e');
    }
  }

  /// Delete an employee
  Future<void> deleteEmployee(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      print('Error deleting employee: $e');
    }
  }
}
