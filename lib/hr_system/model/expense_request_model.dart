import 'package:cloud_firestore/cloud_firestore.dart';

enum ExpenseType {
  transport, // بدل انتقال
  advance,   // سلفة
  medical,   // مصاريف علاج
  other,     // أخرى
}

extension ExpenseTypeExtension on ExpenseType {
  String get displayName {
    switch (this) {
      case ExpenseType.transport:
        return 'Transport Allowance';
      case ExpenseType.advance:
        return 'Salary Advance';
      case ExpenseType.medical:
        return 'Medical Expenses';
      case ExpenseType.other:
        return 'Other';
    }
  }

  String get arabicName {
    switch (this) {
      case ExpenseType.transport:
        return 'بدل انتقال';
      case ExpenseType.advance:
        return 'سلفة';
      case ExpenseType.medical:
        return 'مصاريف علاج';
      case ExpenseType.other:
        return 'أخرى';
    }
  }
}

class ExpenseRequest {
  final String id;
  final String employeeId;
  final String employeeName;
  final ExpenseType type;
  final double amount;
  final String description;
  final String status; // Pending, Approved, Rejected
  final DateTime requestDate;
  final DateTime? approvedDate;
  final String? approvedBy;
  final String? rejectionReason;
  final String? attachmentUrl; // رابط المرفق (اختياري)

  ExpenseRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.type,
    required this.amount,
    required this.description,
    this.status = 'Pending',
    required this.requestDate,
    this.approvedDate,
    this.approvedBy,
    this.rejectionReason,
    this.attachmentUrl,
  });

  factory ExpenseRequest.fromMap(Map<String, dynamic> map, String docId) {
    return ExpenseRequest(
      id: docId,
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      type: ExpenseType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => ExpenseType.other,
      ),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      status: map['status'] ?? 'Pending',
      requestDate: (map['requestDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedDate: (map['approvedDate'] as Timestamp?)?.toDate(),
      approvedBy: map['approvedBy'],
      rejectionReason: map['rejectionReason'],
      attachmentUrl: map['attachmentUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'type': type.toString(),
      'amount': amount,
      'description': description,
      'status': status,
      'requestDate': Timestamp.fromDate(requestDate),
      'approvedDate': approvedDate != null ? Timestamp.fromDate(approvedDate!) : null,
      'approvedBy': approvedBy,
      'rejectionReason': rejectionReason,
      'attachmentUrl': attachmentUrl,
    };
  }

  ExpenseRequest copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    ExpenseType? type,
    double? amount,
    String? description,
    String? status,
    DateTime? requestDate,
    DateTime? approvedDate,
    String? approvedBy,
    String? rejectionReason,
    String? attachmentUrl,
  }) {
    return ExpenseRequest(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      status: status ?? this.status,
      requestDate: requestDate ?? this.requestDate,
      approvedDate: approvedDate ?? this.approvedDate,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
    );
  }
}