import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physioone/hr_system/model/expense_request_model.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'expense_requests';

  // ✅ جلب طلبات مصروفات موظف معين
  Stream<List<ExpenseRequest>> getExpensesStream(String employeeId) {
    return _firestore
        .collection(_collectionName)
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('requestDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ExpenseRequest.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // ✅ جلب جميع طلبات المصروفات (للمشرفين)
  Stream<List<ExpenseRequest>> getAllExpensesStream() {
    return _firestore
        .collection(_collectionName)
        .orderBy('requestDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ExpenseRequest.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // ✅ جلب طلبات المصروفات الخاصة بموظفين تحت مدير معين
  Stream<List<ExpenseRequest>> getExpensesByManagerStream(List<String> employeeIds) {
    if (employeeIds.isEmpty) {
      return Stream.value([]);
    }
    return _firestore
        .collection(_collectionName)
        .where('employeeId', whereIn: employeeIds)
        .orderBy('requestDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ExpenseRequest.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // ✅ تقديم طلب مصروفات جديد
  Future<void> submitExpense(ExpenseRequest expense) async {
    await _firestore.collection(_collectionName).add(expense.toMap());
  }

  // ✅ الموافقة على طلب
  Future<void> approveExpense(String expenseId, String approvedBy) async {
    await _firestore
        .collection(_collectionName)
        .doc(expenseId)
        .update({
          'status': 'Approved',
          'approvedDate': Timestamp.now(),
          'approvedBy': approvedBy,
        });
  }

  // ✅ رفض الطلب مع سبب
  Future<void> rejectExpense(String expenseId, String rejectionReason) async {
    await _firestore
        .collection(_collectionName)
        .doc(expenseId)
        .update({
          'status': 'Rejected',
          'rejectionReason': rejectionReason,
        });
  }

  // ✅ حذف طلب (للموظف نفسه قبل الموافقة)
  Future<void> deleteExpense(String expenseId) async {
    await _firestore.collection(_collectionName).doc(expenseId).delete();
  }
}