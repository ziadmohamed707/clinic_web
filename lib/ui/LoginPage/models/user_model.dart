import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  // Core fields
  final String? docId; // Firestore document ID
  final String? id; // Employee ID (e.g., "DR0004")
  final String? username;
  final String? name;
  final String? email;
  final String? password;
  final String? role;
  final String? position;

  // New Employee fields
  final num? allowances;
  final List<dynamic>? attendance;
  final List<String>? availableDays;
  final num? baseSalary;
  final num? deductions;
  final String? department;
  final DateTime? joinDate;
  final List<dynamic>? leaveRequests;
  final List<dynamic>? allowanceRequests;
  final bool? payslipGenerated;
  final String? status;
  final String? source;
  final num? yearsOfExperience;
  final int? annualLeaveQuota;
  final int? sickLeaveQuota;

  const UserModel({
    this.docId,
    this.id,
    this.username,
    this.name,
    this.email,
    this.password,
    this.role,
    this.position,
    this.allowances,
    this.attendance,
    this.availableDays,
    this.baseSalary,
    this.deductions,
    this.department,
    this.joinDate,
    this.leaveRequests,
    this.allowanceRequests,
    this.payslipGenerated,
    this.status,
    this.source,
    this.yearsOfExperience,
    this.annualLeaveQuota,
    this.sickLeaveQuota,
  });

  // Factory constructor to create a UserModel from a map
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      docId: map['docId'] as String?,
      id: map['id'] as String?,
      username: map['username'] as String?,
      name: map['name'] as String?,
      email: map['email'] as String?,
      password: map['password'] as String?,
      role: map['role'] as String?,
      position: map['position'] as String?,
      allowances: map['allowances'] as num?,
      baseSalary: map['baseSalary'] as num?,
      deductions: map['deductions'] as num?,
      department: map['department'] as String?,
      joinDate: map['joinDate'] != null
          // Handle both Timestamp (from Firestore) and String (from toMap)
          ? (map['joinDate'] is Timestamp
              ? (map['joinDate'] as Timestamp).toDate()
              : (map['joinDate'] is String
                  ? DateTime.tryParse(map['joinDate'])
                  : null))
          : null,
      status: map['status'] as String?,
      availableDays: (map['availableDays'] as List<dynamic>?)?.cast<String>(),
      payslipGenerated: map['payslipGenerated'] as bool?,
      attendance: map['attendance'] as List<dynamic>?,
      leaveRequests: map['leaveRequests'] as List<dynamic>?,
      allowanceRequests: map['allowanceRequests'] as List<dynamic>?,
      source: map['source'] as String?,
      yearsOfExperience: map['yearsOfExperience'] as num?,
      annualLeaveQuota: map['annualLeaveQuota'] as int?,
      sickLeaveQuota: map['sickLeaveQuota'] as int?,
    );
  }

  // Factory constructor to create a UserModel from a Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      docId: doc.id,
      id: data['id'] as String?,
      username: data['username'] as String?,
      name: data['name'] as String?,
      email: data['email'] as String?,
      password: data['password'] as String?,
      role: (data['position'] as String?)?.toLowerCase() ?? data['role'] as String?,
      position: data['position'] as String?,
      allowances: data['allowances'] as num?,
      baseSalary: data['baseSalary'] as num?,
      deductions: data['deductions'] as num?,
      department: data['department'] as String?,
      joinDate: data['joinDate'] != null
          ? (data['joinDate'] as Timestamp).toDate()
          : null,
      status: data['status'] as String?,
      availableDays: (data['availableDays'] as List<dynamic>?)?.cast<String>(),
      payslipGenerated: data['payslipGenerated'] as bool?,
      attendance: data['attendance'] as List<dynamic>?,
      leaveRequests: data['leaveRequests'] as List<dynamic>?,
      allowanceRequests: data['allowanceRequests'] as List<dynamic>?,
      source: data['source'] as String?,
      yearsOfExperience: data['yearsOfExperience'] as num?,
      annualLeaveQuota: data['annualLeaveQuota'] as int?,
      sickLeaveQuota: data['sickLeaveQuota'] as int?,
    );
  }

  // Method to convert UserModel to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      if (docId != null) 'docId': docId,
      'id': id,
      'username': username,
      'name': name,
      if (email != null) 'email': email,
      if (password != null) 'password': password,
      'role': role,
      'position': position,
      if (allowances != null) 'allowances': allowances,
      if (baseSalary != null) 'baseSalary': baseSalary,
      if (deductions != null) 'deductions': deductions,
      if (department != null) 'department': department,
      if (joinDate != null) 'joinDate': joinDate!.toIso8601String(),
      if (status != null) 'status': status,
      if (availableDays != null) 'availableDays': availableDays,
      if (payslipGenerated != null) 'payslipGenerated': payslipGenerated,
      if (attendance != null) 'attendance': attendance,
      if (leaveRequests != null) 'leaveRequests': leaveRequests,
      if (allowanceRequests != null) 'allowanceRequests': allowanceRequests,
      if (source != null) 'source': source,
      if (yearsOfExperience != null) 'yearsOfExperience': yearsOfExperience,
      if (annualLeaveQuota != null) 'annualLeaveQuota': annualLeaveQuota,
      if (sickLeaveQuota != null) 'sickLeaveQuota': sickLeaveQuota,
    };
  }
}