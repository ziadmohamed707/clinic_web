import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeModel {
  final String id;
  final String name;
  final String username;
  final String password;
  final String position;
  final String department;
  final String email;
  final String status;
  final int baseSalary;
  final int allowances;
  final int deductions;
  final bool payslipGenerated;
  final List<dynamic> attendance;
  final DateTime joinDate;
  final int yearsOfExperience;
  final List<dynamic> leaveRequests;
  final String source;
  final List<String>? availableDays;

  EmployeeModel({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    required this.position,
    required this.department,
    required this.email,
    required this.status,
    required this.baseSalary,
    required this.allowances,
    required this.deductions,
    required this.payslipGenerated,
    required this.attendance,
    required this.joinDate,
    required this.yearsOfExperience,
    required this.leaveRequests,
    required this.source,
    this.availableDays,
  });

  // Factory method to create an EmployeeModel from a map (Firestore document)
  factory EmployeeModel.fromMap(Map<String, dynamic> map) {
    return EmployeeModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      position: map['position'] ?? '',
      department: map['department'] ?? '',
      email: map['email'] ?? '',
      status: map['status'] ?? '',
      baseSalary: map['baseSalary'] ?? 0,
      allowances: map['allowances'] ?? 0,
      deductions: map['deductions'] ?? 0,
      payslipGenerated: map['payslipGenerated'] ?? false,
      attendance: map['attendance'] ?? [],
      joinDate: (map['joinDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      yearsOfExperience: map['yearsOfExperience'] as int? ?? 0,
      leaveRequests: map['leaveRequests'] ?? [],
      source: map['source'] ?? '',
      availableDays: map['availableDays']?.cast<String>(),
    );
  }

  // Method to convert the EmployeeModel to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'password': password,
      'position': position,
      'department': department,
      'email': email,
      'status': status,
      'baseSalary': baseSalary,
      'allowances': allowances,
      'deductions': deductions,
      'payslipGenerated': payslipGenerated,
      'attendance': attendance,
      'joinDate': joinDate,
      'yearsOfExperience': yearsOfExperience,
      'leaveRequests': leaveRequests,
      'source': source,
      'availableDays': availableDays,
    };
  }

  // Method to create a copy of the instance with some updated fields
  EmployeeModel copyWith({
    String? id,
    String? name,
    String? username,
    String? password,
    String? position,
    String? department,
    String? email,
    String? status,
    int? baseSalary,
    int? allowances,
    int? deductions,
    bool? payslipGenerated,
    List<dynamic>? attendance,
    DateTime? joinDate,
    int? yearsOfExperience,
    List<dynamic>? leaveRequests,
    String? source,
    List<String>? availableDays,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      password: password ?? this.password,
      position: position ?? this.position,
      department: department ?? this.department,
      email: email ?? this.email,
      status: status ?? this.status,
      baseSalary: baseSalary ?? this.baseSalary,
      allowances: allowances ?? this.allowances,
      deductions: deductions ?? this.deductions,
      payslipGenerated: payslipGenerated ?? this.payslipGenerated,
      attendance: attendance ?? this.attendance,
      joinDate: joinDate ?? this.joinDate,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      leaveRequests: leaveRequests ?? this.leaveRequests,
      source: source ?? this.source,
      availableDays: availableDays ?? this.availableDays,
    );
  }
}
