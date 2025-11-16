import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:physioone/core/app_colors.dart';
import 'package:collection/collection.dart';
import 'package:physioone/hr_system/ui/employee_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart'
    show FirebaseFirestore, SetOptions, Timestamp;
import 'dart:async';
import 'package:physioone/ui/LoginPage/models/user_model.dart';
import 'package:physioone/hr_system/ui/employee_service.dart';
import 'package:physioone/hr_system/ui/location_service.dart';
import 'package:geolocator/geolocator.dart';

class HRMainScreen extends StatefulWidget {
  final UserModel user;
  const HRMainScreen({super.key, required this.user});
  @override
  _HRMainScreenState createState() => _HRMainScreenState();
}

class _HRMainScreenState extends State<HRMainScreen> {
  int _selectedIndex = 0;
  List<EmployeeModel> _employees = [];
  bool _isLoading = true;
  StreamSubscription? _employeesSubscription;
  StreamSubscription? _usersSubscription;
  StreamSubscription? _doctorsSubscription;
  final EmployeeService _employeeService = EmployeeService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _horizontalScrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    _listenToAllPersonnel();
  }

  @override
  void dispose() {
    _employeesSubscription?.cancel();
    _usersSubscription?.cancel();
    _doctorsSubscription?.cancel();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _listenToAllPersonnel() {
    List<EmployeeModel> hrEmployees = [];
    List<EmployeeModel> usersAsEmployees = [];
    List<EmployeeModel> doctorsAsEmployees = [];

    _employeesSubscription = _employeeService.employeesStream().listen((
      employees,
    ) {
      hrEmployees = employees;
      _mergeAndSetState(hrEmployees, usersAsEmployees, doctorsAsEmployees);
    }, onError: _handleError);

    _usersSubscription = _firestore.collection('users').snapshots().listen((
      snapshot,
    ) {
      usersAsEmployees =
          snapshot.docs
              .map((doc) {
                return _adaptUserToEmployee(doc.data(), doc.id);
              })
              .where((e) => e.email.isNotEmpty)
              .toList();
      _mergeAndSetState(hrEmployees, usersAsEmployees, doctorsAsEmployees);
    }, onError: _handleError);

    _doctorsSubscription = _firestore.collection('doctors').snapshots().listen((
      snapshot,
    ) {
      doctorsAsEmployees =
          snapshot.docs
              .map((doc) {
                return _adaptDoctorToEmployee(doc.data(), doc.id);
              })
              .where((e) => e.email.isNotEmpty)
              .toList();
      _mergeAndSetState(hrEmployees, usersAsEmployees, doctorsAsEmployees);
    }, onError: _handleError);
  }

  void _mergeAndSetState(
    List<EmployeeModel> hr,
    List<EmployeeModel> users,
    List<EmployeeModel> doctors,
  ) {
    if (!mounted) return;

    // Combine all lists and remove duplicates, giving priority to HR-specific employee data.
    final allPersonnel = <String, EmployeeModel>{};
    // Process doctors, then users, then full HR employees to ensure HR data overwrites basic data.
    for (var p in [...doctors, ...users, ...hr]) {
      if (p.email.isNotEmpty) {
        allPersonnel[p.email] = p;
      }
    }

    setState(() {
      _employees = allPersonnel.values.toList();
      _isLoading = false;
    });
  }

  void _handleError(error) {
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching data: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Generates a new sequential and formatted ID (e.g., DR0001) for a given role.
  /// Uses a Firestore transaction to prevent race conditions.
  Future<String> _generateNextId(String rolePrefix) async {
    final counterRef = _firestore.collection('counters').doc(rolePrefix);
    late int newIdNumber;

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);
      if (!snapshot.exists) {
        newIdNumber = 1;
      } else {
        newIdNumber = (snapshot.data()!['lastId'] as int) + 1;
      }
      transaction.set(counterRef, {'lastId': newIdNumber});
    });

    return '$rolePrefix${newIdNumber.toString().padLeft(4, '0')}';
  }

  EmployeeModel _adaptUserToEmployee(
    Map<String, dynamic> userData,
    String docId,
  ) {
    return EmployeeModel(
      id: userData['id'] as String? ?? docId,
      name: userData['username'] as String? ?? 'N/A',
      username: userData['username'] as String? ?? '',
      password: userData['password'] as String? ?? '',
      email: userData['email'] as String? ?? '',
      position:
          (userData['role'] as String? ?? 'reception').toLowerCase() ==
                      'user' ||
                  (userData['role'] as String? ?? '').toLowerCase() == 'desk'
              ? 'reception'
              : (userData['role'] as String? ?? 'reception'),
      department: 'General',
      status: 'Active',
      baseSalary: (userData['baseSalary'] as num? ?? 0).toInt(),
      allowances: (userData['allowances'] as num? ?? 0).toInt(),
      deductions: (userData['deductions'] as num? ?? 0).toInt(),
      payslipGenerated: false,
      attendance: [],
      joinDate: DateTime.now(),
      yearsOfExperience: 0,
      leaveRequests: [],
      annualLeaveQuota: 15, // Default value
      sickLeaveQuota: 7, // Default value
      source: 'users',
    );
  }

  EmployeeModel _adaptDoctorToEmployee(
    Map<String, dynamic> doctorData,
    String docId,
  ) {
    return EmployeeModel(
      id: doctorData['id'] as String? ?? docId,
      name: doctorData['name'] as String? ?? 'N/A',
      username: doctorData['name'] as String? ?? '', // Default username to name
      password: '', // Password should be set manually
      email: doctorData['email'] as String? ?? '',
      position: 'doctor', // Ensure position is stored in lowercase
      department: doctorData['specialization'] as String? ?? 'Medical',

      status: 'Active',
      payslipGenerated: false,
      attendance: [],
      joinDate: DateTime.now(),
      yearsOfExperience: 0,
      leaveRequests: [],
      annualLeaveQuota: 15, // Default value
      sickLeaveQuota: 7, // Default value
      baseSalary: (doctorData['baseSalary'] as num? ?? 0).toInt(),
      source: 'doctors',
      allowances: (doctorData['allowances'] as num? ?? 0).toInt(),
      deductions: (doctorData['deductions'] as num? ?? 0).toInt(),
      availableDays:
          (doctorData['availableDays'] as List?)?.cast<String>() ?? [],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            backgroundColor: AppColors.surface,
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.business, size: 40, color: AppColors.primary),
                  SizedBox(height: 8),
                  Text(
                    'HR System',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Employees'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.access_time_outlined),
                selectedIcon: Icon(Icons.access_time),
                label: Text('Attendance'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.event_note_outlined),
                selectedIcon: Icon(Icons.event_note),
                label: Text('Leave'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.monetization_on_outlined),
                selectedIcon: Icon(Icons.monetization_on),
                label: Text('Salaries'),
              ),
            ],
          ),
          VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : Scrollbar(
                    controller: _horizontalScrollController, // Connect controller
                    // Added Scrollbar
                    thumbVisibility: true, // Make scrollbar always visible
                    child: SingleChildScrollView(
                      // Added SingleChildScrollView for horizontal scrolling
                      controller: _horizontalScrollController, // Connect controller
                      scrollDirection: Axis.horizontal,
                      child: _buildScreen(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreen() {
    return Container(
      height: double.infinity,
      width: 1200, // Set a minimum width for the content area
      child: Builder(builder: (context) {
        // Pass the central employee list to each screen.
        switch (_selectedIndex) {
          case 0:
            return DashboardScreen(employees: _employees);
          case 1:
            return EmployeesScreen(
              employees: _employees,
              onAddEmployee: (employeeToAdd) async {
                // Determine prefix based on position
                String position = employeeToAdd.position.toLowerCase();
                String department = employeeToAdd.department.toLowerCase();
                final bool isMedicalStaff =
                    position.contains('doctor') || department == 'medical';

                String prefix = isMedicalStaff ? 'DR'
                    : position.contains('reception') ? 'RS' : 'EM';

                String newId = await _generateNextId(prefix);
                final finalEmployee = employeeToAdd.copyWith(id: newId);

                await _employeeService.addEmployee(finalEmployee);

                // If it's a doctor, also add them to the doctors collection for other parts of the app
                if (isMedicalStaff) {
                  final batch = _firestore.batch();
                  final doctorData = {
                    'id': newId,
                    'name': finalEmployee.name,
                    'availableDays': finalEmployee.availableDays,
                    'email': finalEmployee
                        .email, // Add email to the doctor-specific record
                    'baseSalary': finalEmployee.baseSalary,
                    'allowances': finalEmployee.allowances,
                    'deductions': finalEmployee.deductions,
                  };
                  batch.set(
                    _firestore.collection('doctors').doc(newId),
                    doctorData,
                  );
                  await batch.commit();
                }

                // Also add the new employee to the 'users' collection for authentication
                try {
                  final userData = {
                    'id': newId,
                    'username': finalEmployee.username,
                    'password': finalEmployee.password,
                    'role': finalEmployee.position.toLowerCase(),
                  };
                  await _firestore.collection('users').doc(newId).set(userData);
                } catch (e) {
                  // Handle potential error of adding to users collection
                  print('Error adding employee to users collection: $e');
                }
              },
              onUpdateEmployee: (updatedEmployee) async {
                final isExistingHrEmployee =
                    updatedEmployee.source == 'employees';

                if (isExistingHrEmployee) {
                  // This is a regular update for an existing HR employee.
                  final batch = _firestore.batch();
                  final docId = updatedEmployee.id;
                  await _employeeService.updateEmployee(updatedEmployee);

                  // If they are a doctor, update the doctors collection as well
                  if (updatedEmployee.position
                      .toLowerCase()
                      .contains('doctor')) {
                    final doctorData = {
                      'name': updatedEmployee.name,
                      'availableDays': updatedEmployee.availableDays,
                      'email':
                          updatedEmployee.email, // Also update the email here
                      'baseSalary': updatedEmployee.baseSalary,
                      'allowances': updatedEmployee.allowances,
                      'deductions': updatedEmployee.deductions,
                    };
                    batch.update(
                      _firestore.collection('doctors').doc(docId),
                      doctorData,
                    );
                  }
                  // Also update the user record if name/role changed
                  final userUpdateData = {
                    'username': updatedEmployee.username,
                    'password': updatedEmployee.password,
                    'role': updatedEmployee.position.toLowerCase(),
                  };
                  if (userUpdateData['password'] == '') {
                    userUpdateData
                        .remove('password'); // Don't update password if it's empty
                  }
                  batch.update(
                      _firestore.collection('users').doc(docId), userUpdateData);

                  await batch.commit();
                } else {
                  // This is a user/doctor being "promoted" to a full employee. Generate a new, formatted ID.
                  String position = updatedEmployee.position.toLowerCase();
                  String prefix = position.contains('doctor')
                      ? 'DR' // If position is 'reception', use 'RS' prefix
                      : position.contains('reception')
                          ? 'RS'
                          : 'EM';

                  String newId = await _generateNextId(prefix);
                  String oldDocId = updatedEmployee.id;
                  String sourceCollection = updatedEmployee.source;

                  final promotedEmployee = updatedEmployee.copyWith(
                    id: newId,
                    source: 'employees',
                  );

                  // Use a batch write to perform multiple operations atomically.
                  await _employeeService.addEmployee(promotedEmployee);

                  if (sourceCollection == 'users' ||
                      sourceCollection == 'doctors') {
                    // 2. Re-create the original user/doctor record using the new formatted ID as the document ID,
                    // and delete the old record that used the UUID. This standardizes the keys.
                    final batch = _firestore.batch();
                    final originalData = promotedEmployee.toMap();
                    batch.set(
                      _firestore.collection(sourceCollection).doc(newId),
                      originalData,
                    );
                    batch.delete(
                      _firestore.collection(sourceCollection).doc(oldDocId),
                    );
                    await batch.commit();
                  }
                }
              },
              onDeleteEmployee: (employeeId) async {
                // Use a batch to delete from both collections if necessary
                await _employeeService.deleteEmployee(employeeId);
                final batch = _firestore.batch();

                // If the ID belongs to a doctor, delete from the doctors collection too.
                if (employeeId.startsWith('DR')) {
                  batch.delete(_firestore.collection('doctors').doc(employeeId));
                }

                await batch.commit();
              },
            );
          case 2:
            return AttendanceScreen(
                employees: _employees, currentUser: widget.user);
          case 3:
            return LeaveManagementScreen(employees: _employees);
          case 4:
            return SalariesScreen(
              employees: _employees,
              onUpdateEmployee: (EmployeeModel updatedEmployee) async {
                final isExistingHrEmployee =
                    updatedEmployee.source == 'employees';

                if (isExistingHrEmployee) {
                  // This is a regular update for an existing HR employee.
                  final batch = _firestore.batch();
                  final docId = updatedEmployee.id;
                  await _employeeService.updateEmployee(updatedEmployee);

                  // If they are a doctor, update the doctors collection as well
                  if (updatedEmployee.position
                      .toLowerCase()
                      .contains('doctor')) {
                    // When updating salary, we need to update the doctor record too.
                    final doctorUpdateData = {
                      'baseSalary': updatedEmployee.baseSalary,
                      'allowances': updatedEmployee.allowances,
                      'deductions': updatedEmployee.deductions,
                    };
                    batch.update(
                      _firestore.collection('doctors').doc(docId),
                      doctorUpdateData,
                    );
                  }
                  await batch.commit();
                } else {
                  // This is a user/doctor being "promoted" to a full employee. Generate a new, formatted ID.
                  String position = updatedEmployee.position.toLowerCase();
                  String prefix = position.contains('doctor')
                      ? 'DR' // If position is 'reception', use 'RS' prefix
                      : position.contains('reception')
                          ? 'RS'
                          : 'EM';

                  String newId = await _generateNextId(prefix);
                  String oldDocId = updatedEmployee
                      .id; // This is the original Firestore doc ID (the UUID)
                  String sourceCollection =
                      updatedEmployee.source; // 'users' or 'doctors'
                  final promotedEmployee = updatedEmployee.copyWith(
                    id: newId,
                    source: 'employees',
                  );

                  // Use a batch write to perform multiple operations atomically.
                  final batch = _firestore.batch();

                  // 1. Create the new, detailed employee record with the formatted ID.
                  batch.set(
                    _firestore.collection('employees').doc(newId),
                    promotedEmployee.toMap(),
                  );

                  // 2. Re-create the original user/doctor record using the new formatted ID as the document ID,
                  // and delete the old record that used the UUID. This standardizes the keys.
                  if (sourceCollection == 'users' ||
                      sourceCollection == 'doctors') {
                    final originalData = promotedEmployee.toMap();
                    originalData['id'] =
                        newId; // Ensure the inner ID field is also updated.
                    batch.set(
                      _firestore.collection(sourceCollection).doc(newId),
                      originalData,
                    );
                    batch.delete(
                      _firestore.collection(sourceCollection).doc(oldDocId),
                    );
                  }

                  await batch.commit();
                }
              },
            );
          default:
            return DashboardScreen(employees: _employees);
        }
      }),
    );
  }
}

// Dashboard Screen
class DashboardScreen extends StatelessWidget {
  final List<EmployeeModel> employees;
  const DashboardScreen({Key? key, required this.employees}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalEmployees = employees.length;
    final presentToday =
        employees
            .where(
              (e) => e.attendance.any(
                (a) => a['status'] == 'Present' || a['status'] == 'Late',
              ),
            )
            .length;
    final onLeave = employees.where((e) => e.status == 'On Leave').length;
    final absent = employees.where((e) => e.status == 'Absent').length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Employees',
                  totalEmployees.toString(),
                  Icons.people,
                  AppColors.secondary,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Present Today',
                  presentToday.toString(),
                  Icons.check_circle,
                  Colors.green[600]!,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'On Leave',
                  onLeave.toString(),
                  Icons.event_busy,
                  Colors.orange[600]!,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Absent',
                  absent.toString(),
                  Icons.cancel,
                  AppColors.error,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildRecentActivities(context)),
              SizedBox(width: 16),
              Expanded(child: _buildUpcomingLeaves(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 32),
              Text(
                value,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildRecentActivities(BuildContext context) {
    // Get the latest 4 activities from all employees
    final recentActivities =
        employees
            .expand((emp) {
              final List<Map<String, dynamic>> activities = [];
              if (emp.attendance.isNotEmpty) {
                activities.add({
                  'type': 'attendance',
                  'employee': emp,
                  'data': emp.attendance.first,
                });
              }
              if (emp.leaveRequests.isNotEmpty) {
                activities.add({
                  'type': 'leave',
                  'employee': emp,
                  'data': emp.leaveRequests.first,
                });
              }
              return activities;
            })
            .take(4)
            .toList();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activities',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          if (recentActivities.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'No recent activities.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...recentActivities.map((activity) {
              if (activity['type'] == 'attendance') {
                final EmployeeModel emp = activity['employee'];
                return _buildActivityItem(
                  '${emp.name} checked in',
                  'Today',
                  Icons.login,
                  Colors.green[600]!,
                );
              }
              final EmployeeModel emp = activity['employee'];
              return _buildActivityItem(
                '${emp.name} applied for leave',
                'Today',
                Icons.event,
                Colors.orange[600]!,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String text,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: TextStyle(fontWeight: FontWeight.w500)),
                Text(time, style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingLeaves(BuildContext context) {
    // Get all pending leave requests
    final upcomingLeaves =
        employees
            .where(
              (emp) =>
                  emp.leaveRequests.any((req) => req['status'] == 'Pending'),
            )
            .toList();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming Leaves',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          if (upcomingLeaves.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'No upcoming leaves.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...upcomingLeaves.map(
              (emp) =>
                  _buildLeaveItem(emp.name, (emp.leaveRequests).first['dates']),
            ),
        ],
      ),
    );
  }

  Widget _buildLeaveItem(String name, String dates) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            child: Text(name[0]),
            backgroundColor: AppColors.primary,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.w500)),
                Text(dates, style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Employees Screen
class EmployeesScreen extends StatefulWidget {
  final List<EmployeeModel> employees;
  final Function(EmployeeModel) onAddEmployee;
  final Function(EmployeeModel) onUpdateEmployee;
  final Function(String) onDeleteEmployee;

  const EmployeesScreen({
    Key? key,
    required this.employees,
    required this.onAddEmployee,
    required this.onUpdateEmployee,
    required this.onDeleteEmployee,
  }) : super(key: key);

  @override
  _EmployeesScreenState createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  List<EmployeeModel> _filteredEmployees = [];
  final ScrollController _verticalScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final List<String> _availablePositions = [
    'doctor',
    'reception',
    'admin',
    'it',
    'design',
  ];
  final List<String> availableDepartments = [
    'Medical',
    'Administration',
    'IT',
    'Reception',
    'General',
    'Design',
  ];

  // Base salary rates per position. Fetched from Firestore.
  Map<String, double> _baseRatesByPosition = {
    'doctor': 15000.0, // Base salary for doctors
    'reception': 5000.0, // Consolidated salary for reception
    'admin': 8000.0, // Base salary for admin
    'it': 9000.0, // Base salary for IT
    'design': 7500.0, // Base salary for design
  };
  double _calculateBaseSalary(String position, int yearsOfExperience) {
    final positionKey = position.toLowerCase();
    final baseRate = _baseRatesByPosition.entries
        .firstWhere(
          (entry) => positionKey.contains(entry.key),
          orElse: () => const MapEntry('default', 4000.0),
        )
        .value;
    final experienceBonus = yearsOfExperience * 250.0; // EGP 250 bonus per year
    return baseRate + experienceBonus;
  }
  @override
  void initState() {
    super.initState();
    _fetchSalarySettings();
    _filteredEmployees = widget.employees;
    _searchController.addListener(() {
      if (_searchController.text.isEmpty && mounted) {
        setState(() {
          _filteredEmployees = widget.employees;
        });
      }
    });
  }
  Future<void> _fetchSalarySettings() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('hr_settings')
              .doc('salary_rules')
              .get();
      if (doc.exists && doc.data() != null) {
        if (mounted) {
          setState(() {
            final ratesFromFirestore = doc.data()!['baseRatesByPosition'];
            if (ratesFromFirestore is Map) {
              _baseRatesByPosition = Map<String, double>.from(
                ratesFromFirestore.map(
                  (key, value) => MapEntry(key, (value as num).toDouble()),
                ),
              );
            }
          });
        }
      }
    } catch (e) {
      print("Could not fetch salary settings for EmployeesScreen: $e");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Employees',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEmployeeDialog(context),
                icon: Icon(Icons.add),
                label: Text('Add Employee'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _filteredEmployees =
                      widget.employees.where((emp) {
                        final query = value.toLowerCase();
                        final id = emp.id.toLowerCase();
                        final email = emp.email.toLowerCase();
                        final name = emp.name.toLowerCase();
                        final position = emp.position.toLowerCase();
                        final department = emp.department.toLowerCase();
                        return id.contains(query) ||
                            email.contains(query) ||
                            name.contains(query) ||
                            position.contains(query) ||
                            department.contains(query);
                      }).toList();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by ID, Name, Email, Position...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: Scrollbar(
              controller: _verticalScrollController,
              thumbVisibility: true,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: _verticalScrollController,
                  child: DataTable(
                    columnSpacing: 30,
                    headingRowColor: MaterialStateProperty.all(
                      Colors.grey[100],
                    ),
                    columns: [
                      DataColumn(
                        label: Text(
                          'ID',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Name',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Position',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Department',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Email',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Status',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Actions',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows:
                        (_searchController.text.isEmpty
                                ? widget.employees
                                : _filteredEmployees)
                            .map((emp) {
                              final name = emp.name;
                              return DataRow(
                                cells: [
                                  DataCell(Text(emp.id.toString())),
                                  DataCell(
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          child: Text(
                                            name.isNotEmpty ? name[0] : '?',
                                          ),
                                          radius: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Text(name),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(emp.position)),
                                  DataCell(Text(emp.department)),
                                  DataCell(Text(emp.email)),
                                  DataCell(
                                    Chip(
                                      label: Text(emp.status),
                                      backgroundColor: Colors.green[100],
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            color: AppColors.primary,
                                          ),
                                          onPressed:
                                              () => _showEditEmployeeDialog(
                                                context,
                                                emp,
                                              ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color: AppColors.error,
                                          ),
                                          onPressed:
                                              () => _showDeleteConfirmDialog(
                                                context,
                                                emp,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            })
                            .toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEmployeeDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    String? selectedPosition;
    String? selectedDepartment;
    final emailController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final allowancesController = TextEditingController(text: '0');
    final experienceController = TextEditingController(text: '0');
    final deductionsController = TextEditingController(text: '0');
    final annualLeaveController = TextEditingController(text: '15');
    final sickLeaveController = TextEditingController(text: '7');
    List<String> selectedDays = [];
    DateTime? _joinDate = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Add New Employee'),
          content: Form(
            key: formKey,
            child: StatefulBuilder(
              builder: (context, setStateDialog) {
                bool isMedicalStaff =
                    selectedPosition?.toLowerCase() == 'doctor' ||
                    selectedDepartment?.toLowerCase() == 'medical';
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(labelText: 'Full Name'),
                        validator:
                            (value) =>
                                value!.isEmpty ? 'Please enter a name' : null,
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedPosition,
                        hint: Text('Select Position'),
                        items:
                            _availablePositions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value[0].toUpperCase() + value.substring(1),
                                ),
                              );
                            }).toList(),
                        onChanged: (newValue) {
                          setStateDialog(() {
                            selectedPosition = newValue;
                          });
                        },
                        validator:
                            (value) =>
                                value == null
                                    ? 'Please select a position'
                                    : null,
                        decoration: InputDecoration(labelText: 'Position'),
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedDepartment,
                        hint: Text('Select Department'),
                        items:
                            availableDepartments.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                        onChanged: (newValue) {
                          setStateDialog(() {
                            selectedDepartment = newValue;
                          });
                        },
                        validator:
                            (value) =>
                                value == null
                                    ? 'Please select a department'
                                    : null,
                        decoration: InputDecoration(labelText: 'Department'),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(labelText: 'Email'),
                        validator: (value) {
                          if (value!.isEmpty) return 'Please enter an email';
                          if (!value.contains('@'))
                            return 'Please enter a valid email';
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: usernameController,
                        decoration: InputDecoration(labelText: 'Username'),
                        validator: (value) {
                          if (value!.isEmpty) return 'Please enter a username';
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        decoration: InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        validator: (value) {
                          if (value!.isEmpty) return 'Please enter a password';
                          if (value.length < 6)
                            return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Financial Information',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: experienceController,
                        decoration: InputDecoration(
                          labelText: 'Years of Experience',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Please enter years of experience (0 if none)';
                          if (int.tryParse(value) == null)
                            return 'Enter a valid number';
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: allowancesController,
                        decoration: InputDecoration(
                          labelText: 'Allowances (EGP)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Please enter allowances (0 if none)';
                          if (double.tryParse(value) == null)
                            return 'Enter a valid number';
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: deductionsController,
                        decoration: InputDecoration(
                          labelText: 'Deductions (EGP)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Please enter deductions (0 if none)';
                          if (double.tryParse(value) == null)
                            return 'Enter a valid number';
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: annualLeaveController,
                        decoration: InputDecoration(
                          labelText: 'Annual Leave Quota (days)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || int.tryParse(value) == null)
                            return 'Enter a valid number';
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: sickLeaveController,
                        decoration: InputDecoration(
                          labelText: 'Sick Leave Quota (days)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => (value == null || int.tryParse(value) == null) ? 'Enter a valid number' : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(
                          text:
                              _joinDate == null
                                  ? ''
                                  : '${_joinDate!.day}/${_joinDate!.month}/${_joinDate!.year}',
                        ),
                        decoration: InputDecoration(
                          labelText: 'Joining Date',
                          suffixIcon: IconButton(
                            icon: Icon(Icons.calendar_today),
                            onPressed: () async {
                              _joinDate =
                                  await showDatePicker(
                                    context: context,
                                    initialDate: _joinDate ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime.now(),
                                  ) ??
                                  _joinDate;
                              setStateDialog(() {});
                            },
                          ),
                        ),
                      ),
                      if (isMedicalStaff) ...[
                        SizedBox(height: 20),
                        Text(
                          'Available Days:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        ...[
                          'Monday',
                          'Tuesday',
                          'Wednesday',
                          'Thursday',
                          'Friday',
                          'Saturday',
                          'Sunday',
                        ].map((day) {
                          return CheckboxListTile(
                            title: Text(day),
                            value: selectedDays.contains(day),
                            onChanged: (bool? value) {
                              setStateDialog(() {
                                if (value == true) {
                                  selectedDays.add(day);
                                } else {
                                  selectedDays.remove(day);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  bool isMedicalStaff =
                      selectedPosition?.toLowerCase() == 'doctor' ||
                      selectedDepartment?.toLowerCase() == 'medical';
                  if (isMedicalStaff && selectedDays.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please select at least one available day for the doctor.',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  final yearsOfExperience =
                      int.tryParse(experienceController.text) ?? 0;
                  final calculatedBaseSalary = _calculateBaseSalary(
                    selectedPosition!,
                    yearsOfExperience,
                  );

                  // The ID is now generated in the onAddEmployee callback.
                  final newEmployee = EmployeeModel(
                    id: '', // Will be generated in the callback
                    name: nameController.text,
                    username: usernameController.text,
                    password: passwordController.text,
                    position: selectedPosition!,
                    department: selectedDepartment!,
                    email: emailController.text,
                    status: 'Active',
                    baseSalary: calculatedBaseSalary.toInt(),
                    allowances: int.tryParse(allowancesController.text) ?? 0,
                    yearsOfExperience: yearsOfExperience,
                    deductions: int.tryParse(deductionsController.text) ?? 0,
                    payslipGenerated: false,
                    attendance: [],
                    leaveRequests: [],
                    joinDate: _joinDate ?? DateTime.now(),
                    availableDays: isMedicalStaff ? selectedDays : null,
                    annualLeaveQuota: int.tryParse(annualLeaveController.text) ?? 15,
                    sickLeaveQuota: int.tryParse(sickLeaveController.text) ?? 7,
                    source: 'employees', // Mark as a native HR employee
                  );

                  widget.onAddEmployee(newEmployee);

                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Employee added successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Text('Add Employee'),
            ),
          ],
        );
      },
    );
  }

  void _showEditEmployeeDialog(BuildContext context, EmployeeModel employee) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: employee.name);
    // State variables for dropdowns
    String? selectedPosition =
        employee.position.toLowerCase().isEmpty
            ? employee.position
            : employee.position
                .toLowerCase(); // Normalize to lowercase to match available positions
    String? selectedDepartment = availableDepartments.firstWhereOrNull(
      (d) => d.toLowerCase() == employee.department.toLowerCase(),
    ); // Use firstWhereOrNull for safety

    final emailController = TextEditingController(text: employee.email);
    final usernameController = TextEditingController(text: employee.username);
    final oldPasswordController = TextEditingController();
    final passwordController =
        TextEditingController(); // Leave blank for security

    List<String> selectedDays = List<String>.from(employee.availableDays ?? []);
    final experienceController = TextEditingController(
      text: employee.yearsOfExperience.toString(),
    );
    final allowancesController = TextEditingController(
      text: employee.allowances.toString(),
    );
    final deductionsController = TextEditingController(
      text: employee.deductions.toString(),
    );
    final annualLeaveController = TextEditingController(
      text: employee.annualLeaveQuota.toString(),
    );
    final sickLeaveController = TextEditingController(
      text: employee.sickLeaveQuota.toString(),
    );
    String? selectedStatus = employee.status;
    final List<String> availableStatuses = ['Active', 'On Leave', 'Terminated'];

    DateTime? _joinDate = employee.joinDate;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Edit Employee: ${employee.name}'),
          content: Form(
            key: formKey,
            child: StatefulBuilder(
              builder: (context, setStateDialog) {
                bool isMedicalStaff =
                    selectedPosition?.toLowerCase() == 'doctor' ||
                    selectedDepartment?.toLowerCase() == 'medical';
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(labelText: 'Full Name'),
                        validator:
                            (value) =>
                                value!.isEmpty ? 'Please enter a name' : null,
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedPosition,
                        hint: Text('Select Position'),
                        items:
                            _availablePositions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value[0].toUpperCase() + value.substring(1),
                                ),
                              );
                            }).toList(),
                        onChanged: (newValue) {
                          setStateDialog(() {
                            selectedPosition = newValue;
                          });
                        },
                        validator:
                            (value) =>
                                value == null
                                    ? 'Please select a position'
                                    : null,
                        decoration: InputDecoration(labelText: 'Position'),
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedDepartment,
                        hint: Text('Select Department'),
                        items:
                            availableDepartments.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                        onChanged: (newValue) {
                          setStateDialog(() {
                            selectedDepartment = newValue;
                          });
                        },
                        validator:
                            (value) =>
                                value == null
                                    ? 'Please select a department'
                                    : null,
                        decoration: InputDecoration(labelText: 'Department'),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(labelText: 'Email'),
                        validator: (value) {
                          if (value!.isEmpty) return 'Please enter an email';
                          if (!value.contains('@'))
                            return 'Please enter a valid email';
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: experienceController,
                        decoration: InputDecoration(
                          labelText: 'Years of Experience',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Please enter years of experience';
                          if (int.tryParse(value) == null)
                            return 'Enter a valid number';
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: usernameController,
                        decoration: InputDecoration(labelText: 'Username'),
                        validator: (value) {
                          if (value!.isEmpty) return 'Please enter a username';
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: oldPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Old Password',
                          hintText: 'Required to set a new password',
                        ),
                        obscureText: true,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          hintText: 'Leave blank to keep current',
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value != null && value.isNotEmpty && value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(
                          text:
                              _joinDate == null
                                  ? ''
                                  : '${_joinDate!.day}/${_joinDate!.month}/${_joinDate!.year}',
                        ),
                        decoration: InputDecoration(
                          labelText: 'Joining Date',
                          suffixIcon: IconButton(
                            icon: Icon(Icons.calendar_today),
                            onPressed: () async {
                              _joinDate =
                                  await showDatePicker(
                                    context: context,
                                    initialDate: _joinDate ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime.now(),
                                  ) ??
                                  _joinDate;
                              setStateDialog(() {});
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        hint: Text('Select Status'),
                        items:
                            availableStatuses.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                        onChanged: (newValue) {
                          setStateDialog(() {
                            selectedStatus = newValue;
                          });
                        },
                        validator:
                            (value) =>
                                value == null ? 'Please select a status' : null,
                        decoration: InputDecoration(labelText: 'Status'),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: allowancesController,
                        decoration: InputDecoration(
                          labelText: 'Allowances (EGP)',
                        ),
                        keyboardType: TextInputType.number,
                        validator:
                            (value) =>
                                (value == null || int.tryParse(value) == null)
                                    ? 'Enter a valid number'
                                    : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: deductionsController,
                        decoration: InputDecoration(
                          labelText: 'Deductions (EGP)',
                        ),
                        keyboardType: TextInputType.number,
                        validator:
                            (value) =>
                                (value == null || int.tryParse(value) == null)
                                    ? 'Enter a valid number'
                                    : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: annualLeaveController,
                        decoration: InputDecoration(
                          labelText: 'Annual Leave Quota (days)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            (value == null || int.tryParse(value) == null)
                                ? 'Enter a valid number'
                                : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: sickLeaveController,
                        decoration: InputDecoration(
                          labelText: 'Sick Leave Quota (days)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            (value == null || int.tryParse(value) == null) ? 'Enter a valid number' : null,
                      ),
                      if (isMedicalStaff) ...[
                        SizedBox(height: 20),
                        Text(
                          'Available Days:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        ...[
                          'Monday',
                          'Tuesday',
                          'Wednesday',
                          'Thursday',
                          'Friday',
                          'Saturday',
                          'Sunday',
                        ].map((day) {
                          return CheckboxListTile(
                            title: Text(day),
                            value: selectedDays.contains(day),
                            onChanged: (bool? value) {
                              setStateDialog(() {
                                if (value == true) {
                                  selectedDays.add(day);
                                } else {
                                  selectedDays.remove(day);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  bool isMedicalStaff =
                      selectedPosition?.toLowerCase() == 'doctor' ||
                      selectedDepartment?.toLowerCase() == 'medical';
                  if (isMedicalStaff && selectedDays.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please select at least one available day for the doctor.',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  // Password change validation
                  final oldPassword = oldPasswordController.text;
                  final newPassword = passwordController.text;
                  String finalPassword = employee.password; // Default to old password

                  if (newPassword.isNotEmpty) {
                    if (oldPassword.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enter the old password to set a new one.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    if (oldPassword != employee.password) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('The old password you entered is incorrect.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    finalPassword = newPassword; // If all checks pass, set the new password
                  }

                  var updatedEmployee = employee.copyWith(
                    name: nameController.text,
                    username: usernameController.text,
                    // Use the validated final password
                    password: finalPassword,
                    position: selectedPosition!,
                    department: selectedDepartment!,
                    email: emailController.text,
                    yearsOfExperience:
                        int.tryParse(experienceController.text) ?? 0,
                    availableDays: isMedicalStaff ? selectedDays : null,
                    status: selectedStatus!,
                    allowances: int.tryParse(allowancesController.text) ?? 0,
                    deductions: int.tryParse(deductionsController.text) ?? 0,
                    annualLeaveQuota: int.tryParse(annualLeaveController.text) ?? 15,
                    sickLeaveQuota: int.tryParse(sickLeaveController.text) ?? 7,
                    joinDate: _joinDate ?? employee.joinDate,
                  );

                  // This logic ensures we don't send an empty password to Firestore
                  // if the user was just created and had no password.
                  if (newPassword.isEmpty && employee.password.isEmpty) {
                    updatedEmployee = updatedEmployee.copyWith(password: '');
                  }

                  widget.onUpdateEmployee(updatedEmployee);

                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Employee updated successfully!'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              },
              child: Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, EmployeeModel employee) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Delete Employee'),
          content: Text(
            'Are you sure you want to delete ${employee.name}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                widget.onDeleteEmployee(employee.id);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Employee deleted successfully!'),
                    backgroundColor: AppColors.error,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
              ),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

// Attendance Screen
class AttendanceScreen extends StatefulWidget {
  final List<EmployeeModel> employees;
  final UserModel currentUser;
  const AttendanceScreen(
      {Key? key, required this.employees, required this.currentUser}) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final LocationService _locationService = LocationService();
  final EmployeeService _employeeService = EmployeeService();

  @override
  void initState() {
    super.initState();
    // Automatically attempt to check in the current user when the screen loads.
    _automaticCheckIn();
  }

  void _automaticCheckIn() {
    // Find the EmployeeModel corresponding to the logged-in user.
    final currentUserEmployee = widget.employees.firstWhereOrNull(
      (emp) => emp.id == widget.currentUser.id,
    );

    if (currentUserEmployee != null) {
      // Check if the user has already checked in today.
      final today = DateTime.now();
      final todayString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final hasCheckedInToday = currentUserEmployee.attendance.any(
        (record) => record['date'] == todayString && record['checkIn'] != '',
      );

      if (!hasCheckedInToday) {
        // Use a post-frame callback to ensure context is available for dialogs.
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _handleCheckIn(context, currentUserEmployee));
      }
    }
  }

  Future<void> _handleCheckIn(BuildContext context, EmployeeModel employee) async {
    try {
      // Show a loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      final Position position = await _locationService.validateLocationAndGetPosition();

      // Location is valid, proceed with check-in logic
      final now = DateTime.now();
      final checkInTime = TimeOfDay.fromDateTime(now);
      final officialStartTime = TimeOfDay(hour: 9, minute: 0); // 9:00 AM

      String status = 'Present';
      if (checkInTime.hour > officialStartTime.hour ||
          (checkInTime.hour == officialStartTime.hour && checkInTime.minute > officialStartTime.minute)) {
        status = 'Late';
      }

      // Create the new attendance record with location data
      final newAttendanceRecord = {
        'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        'checkIn': '${checkInTime.hour.toString().padLeft(2, '0')}:${checkInTime.minute.toString().padLeft(2, '0')}',
        'checkOut': '',
        'status': status,
        'checkInLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
      };

      // Add the new record to the employee's attendance list
      final updatedAttendance = List<Map<String, dynamic>>.from(employee.attendance);
      updatedAttendance.add(newAttendanceRecord);

      final updatedEmployee = employee.copyWith(attendance: updatedAttendance);

      // Update the employee in Firestore
      await _employeeService.updateEmployee(updatedEmployee);

      Navigator.pop(context); // Hide loading indicator

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checked in successfully! Status: $status'), backgroundColor: Colors.green),
      );
    } catch (e) {
      Navigator.pop(context); // Hide loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Check-in failed: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              // The "Check In" button is no longer needed as it's automatic.
              // You can keep it for manual check-in if you prefer.
            ],
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 48,
                        color: AppColors.primary,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'November 10, 2025',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('Monday', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildAttendanceCard(
                        'Present', // Includes 'Late'
                        widget.employees
                            .where(
                              (e) => e.attendance.any(
                                (a) =>
                                    a['status'] == 'Present' ||
                                    a['status'] == 'Late',
                              ),
                            )
                            .length
                            .toString(),
                        Colors.green[600]!,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildAttendanceCard(
                        'Late Only',
                        widget.employees
                            .where(
                              (e) => e.attendance.any(
                                (a) => a['status'] == 'Late',
                              ),
                            )
                            .length
                            .toString(),
                        Colors.orange[600]!,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildAttendanceCard(
                        'Absent Today',
                        widget.employees
                            .where(
                              (e) => e.attendance.any(
                                (a) => a['status'] == 'Absent',
                              ),
                            )
                            .length
                            .toString(),
                        AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s Attendance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: widget.employees.map((employee) {
                        final today = DateTime.now();
                        final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
                            final attendance = (employee.attendance)
                                .firstWhereOrNull(
                                  (a) => a['date'] == todayString,
                                );
                            if (attendance == null) return SizedBox.shrink();
                            final color =
                                attendance['status'] == 'Present'
                                    ? Colors.green[600]!
                                    : attendance['status'] == 'Late'
                                    ? Colors.orange[600]!
                                    : AppColors.error;
                            return _buildAttendanceRecord(
                              employee.name,
                              attendance['checkIn'],
                              attendance['checkOut'],
                              attendance['status'],
                              color,
                            );
                          }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(String title, String count, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAttendanceRecord(
    String name,
    String checkIn,
    String checkOut,
    String status,
    Color color,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            child: Text(name[0]),
            backgroundColor: AppColors.primary,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(name, style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          SizedBox(width: 16),
          Text('In: $checkIn', style: TextStyle(color: Colors.grey[600])),
          SizedBox(width: 16),
          Text('Out: $checkOut', style: TextStyle(color: Colors.grey[600])),
          SizedBox(width: 16),
          Chip(label: Text(status), backgroundColor: color.withOpacity(0.2)),
        ],
      ),
    );
  }
}

// Leave Management Screen
class LeaveManagementScreen extends StatelessWidget {
  final EmployeeService employeeService = EmployeeService();
  final List<EmployeeModel> employees;
  LeaveManagementScreen({
    // ignore: use_super_parameters
    Key? key,
    required this.employees,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Leave Management',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.add),
                label: Text('Apply Leave'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildLeaveTypeCard(
                  'Annual Leave',
                  '12 days',
                  AppColors.secondary,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildLeaveTypeCard(
                  'Sick Leave',
                  '8 days',
                  Colors.orange[600]!,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildLeaveTypeCard('Used', '5 days', AppColors.error),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildLeaveTypeCard(
                  'Remaining',
                  '15 days',
                  Colors.green[600]!,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Leave Requests',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children:
                          employees.expand((employee) {
                            return employee.leaveRequests.map((request) {
                              return _buildLeaveRequest(
                                context,
                                employee,
                                Map<String, dynamic>.from(request),
                              );
                            }).toList();
                          }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveTypeCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.event_note, color: color, size: 32),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildLeaveRequest(
    BuildContext context,
    EmployeeModel employee,
    Map<String, dynamic> request,
  ) {
    final requestDate = request['requestDate'] as Timestamp?;
    final reason = request['reason'] as String?;
    final status = request['status'] as String? ?? 'Pending';
    final color = status == 'Pending'
        ? Colors.orange[600]!
        : status == 'Approved' ? Colors.green[600]! : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            child: Text(employee.name.isNotEmpty ? employee.name[0] : '?'),
            backgroundColor: AppColors.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employee.name,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('${request['type'] ?? 'Leave'} • ${request['dates']}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                if (reason != null && reason.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text('Reason: $reason',
                        style: const TextStyle(
                            fontStyle: FontStyle.italic, fontSize: 13)),
                  ),
                if (requestDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                        'Requested on: ${DateFormat.yMMMd().format(requestDate.toDate())}',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
              ],
            ),
          ),
          Chip(
            label: Text(status),
            backgroundColor: color.withOpacity(0.2),
          ),
          const SizedBox(width: 8),
          if (status == 'Pending') ...[
            IconButton(
              icon: Icon(Icons.check, color: Colors.green[600]!),
              onPressed: () =>
                  _updateLeaveStatus(context, employee, request, 'Approved'),
            ),
            IconButton(
              icon: Icon(Icons.close, color: AppColors.error),
              onPressed: () =>
                  _updateLeaveStatus(context, employee, request, 'Rejected'),
            ),
          ],
        ],
      ),
    );
  }

  void _updateLeaveStatus(
    BuildContext context,
    EmployeeModel employee,
    Map<String, dynamic> requestToUpdate,
    String newStatus,
  ) async {
    try {
      final updatedLeaveRequests =
          List<Map<String, dynamic>>.from(employee.leaveRequests);

      // Find the index of the request to update. Comparing by request date for uniqueness.
      final requestIndex = updatedLeaveRequests.indexWhere(
        (req) => req['requestDate'] == requestToUpdate['requestDate'],
      );

      if (requestIndex != -1) {
        updatedLeaveRequests[requestIndex]['status'] = newStatus;
        final updatedEmployee =
            employee.copyWith(leaveRequests: updatedLeaveRequests);

        await employeeService.updateEmployee(updatedEmployee);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Leave request has been $newStatus.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update leave status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Salaries Screen
class SalariesScreen extends StatelessWidget {
  final List<EmployeeModel> employees;
  final Function(EmployeeModel) onUpdateEmployee;

  const SalariesScreen({
    Key? key,
    required this.employees,
    required this.onUpdateEmployee,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _SalariesScreenView(
      employees: employees,
      onUpdateEmployee: onUpdateEmployee,
    );
  }
}

class _SalariesScreenView extends StatefulWidget {
  final List<EmployeeModel> employees;
  final Function(EmployeeModel) onUpdateEmployee;

  const _SalariesScreenView({
    required this.employees,
    required this.onUpdateEmployee,
  });

  @override
  State<_SalariesScreenView> createState() => _SalariesScreenViewState();
}

class _SalariesScreenViewState extends State<_SalariesScreenView> {
  // Base salary rates per position. This can be moved to Firestore for more dynamic control.
  Map<String, double> _baseRatesByPosition = {
    'doctor': 15000.0, // Base salary for doctors
    'reception': 5000.0, // Consolidated salary for reception
    'admin': 8000.0, // Base salary for admin
    'it': 9000.0, // Base salary for IT
    'design': 7500.0, // Base salary for design
  };

  @override
  void initState() {
    super.initState();
    _fetchSalarySettings();
  }

  Future<void> _fetchSalarySettings() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('hr_settings')
              .doc('salary_rules')
              .get();
      if (doc.exists && doc.data() != null) {
        if (mounted) {
          setState(() {
            // Fetch base rates from Firestore
            final ratesFromFirestore = doc.data()!['baseRatesByPosition'];
            if (ratesFromFirestore is Map) {
              _baseRatesByPosition = Map<String, double>.from(
                ratesFromFirestore.map(
                  (key, value) => MapEntry(key, (value as num).toDouble()),
                ),
              );
            }
          });
        }
      }
    } catch (e) {
      // Use default if settings don't exist or fail to load
      print("Could not fetch salary settings: $e");
    }
  }

  double _calculateBaseSalary(EmployeeModel emp) {
    // 1. Find the base rate for the position.
    final positionKey = emp.position.toLowerCase();
    final baseRate =
        _baseRatesByPosition.entries
            .firstWhere(
              (entry) => positionKey.contains(entry.key),
              orElse: () => MapEntry('default', 4000.0), // Default salary
            )
            .value;

    // 2. Calculate experience bonus.
    double experienceBonus = 0.0;
    // Use the new yearsOfExperience field
    experienceBonus =
        emp.yearsOfExperience * 250; // EGP 250 bonus per year of experience

    return baseRate + experienceBonus;
  }

  // --- Salary Calculation Logic ---
  Map<String, dynamic> _calculateSalaryComponents(EmployeeModel emp) {
    const double workingDaysInMonth = 22.0;
    double effectiveBaseSalary = _calculateBaseSalary(emp);

    // 1. Attendance Adjustment
    final daysAttended =
        (emp.attendance)
            .where((a) => a['status'] == 'Present' || a['status'] == 'Late')
            .length
            .toDouble();
    final attendanceAdjustment =
        (daysAttended < workingDaysInMonth)
            ? (effectiveBaseSalary / workingDaysInMonth) * daysAttended -
                effectiveBaseSalary
            : 0.0;

    // 2. Department Bonus
    final department = emp.department;
    final departmentBonusRate = {
      'IT': 0.1,
      'Design': 0.05,
      'HR': 0.08,
    }; // 10%, 5%, 8% bonus
    final departmentBonus =
        effectiveBaseSalary * (departmentBonusRate[department] ?? 0.0);

    // 3. Experience Bonus (re-added to this scope for display)
    double experienceBonus = emp.yearsOfExperience * 250.0;

    final netSalary =
        effectiveBaseSalary +
        emp.allowances -
        emp.deductions +
        departmentBonus;

    // --- New Deduction Logic ---
    final double dailyRate = effectiveBaseSalary / 22.0; // Assuming 22 working days

    // 1. Unpaid Leave Deduction
    final unpaidLeaveDays = (emp.leaveRequests)
        .where((req) =>
            req['status'] == 'Approved' && req['type'] == 'Unpaid')
        .length;
    final unpaidLeaveDeduction = unpaidLeaveDays * dailyRate;

    // 2. Late Arrival Deduction
    final lateArrivals = (emp.attendance)
        .where((att) => att['status'] == 'Late')
        .length;
    final lateArrivalDeduction = lateArrivals * 50.0; // EGP 50 per late day

    final totalDeductions =
        emp.deductions + unpaidLeaveDeduction + lateArrivalDeduction;
    final finalNetSalary = effectiveBaseSalary + emp.allowances - totalDeductions;

    return {
      'netSalary': finalNetSalary,
      'departmentBonus': departmentBonus,
      'attendanceAdjustment': attendanceAdjustment,
      'calculatedBaseSalary': effectiveBaseSalary,
      'experienceBonus': experienceBonus,
      'unpaidLeaveDeduction': unpaidLeaveDeduction, // Add to return map
      'lateArrivalDeduction': lateArrivalDeduction, // Add to return map
    };
  }

  Widget build(BuildContext context) {
    double totalPayroll = widget.employees.fold(
      0,
      (sum, e) =>
          sum + (_calculateSalaryComponents(e)['netSalary'] as double? ?? 0.0),
    );
    final pendingPayslips =
        widget.employees.where((e) => e.payslipGenerated == false).length;

    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Salary Management',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.settings, color: AppColors.primary),
                onPressed: () => _showSalarySettingsDialog(context),
                tooltip: 'Salary Settings',
              ),
              SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  // Show a confirmation dialog before running payroll
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Confirm Payroll Run'),
                      content: const Text(
                          'This will calculate and update deductions for all employees based on the current month\'s data. This action cannot be undone. Proceed?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Yes, Run Payroll'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    for (final emp in widget.employees) {
                      final salaryComps = _calculateSalaryComponents(emp);
                      final totalDeductions = emp.deductions +
                          (salaryComps['unpaidLeaveDeduction'] as double) +
                          (salaryComps['lateArrivalDeduction'] as double);
                      final updatedEmployee =
                          emp.copyWith(deductions: totalDeductions.toInt());
                      widget.onUpdateEmployee(updatedEmployee);
                    }
                  }
                },
                icon: Icon(Icons.play_circle_fill),
                label: Text('Run Payroll for November'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSalaryStatCard(
                  'Total Payroll',
                  '\$${(totalPayroll / 1000).toStringAsFixed(1)}K',
                  Icons.account_balance_wallet,
                  AppColors.primary,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildSalaryStatCard(
                  'Total Employees',
                  widget.employees.length.toString(),
                  Icons.people,
                  AppColors.secondary,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildSalaryStatCard(
                  'Pending Payslips',
                  pendingPayslips.toString(),
                  Icons.hourglass_top,
                  Colors.orange[600]!,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowColor: MaterialStateProperty.all(
                      Colors.grey[100],
                    ),
                    columns: [
                      DataColumn(
                        label: Text(
                          'Employee',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Base Salary',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(
                          'Allowances',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(
                          'Deductions',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(
                          'Dept. Bonus',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(
                          'Experience Bonus',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(
                          'Net Salary',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(
                          'Payslip',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Actions',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows:
                        widget.employees.map((EmployeeModel emp) {
                          final salaryComps = _calculateSalaryComponents(emp);
                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    CircleAvatar(
                                      child: Text(
                                        emp.name.isNotEmpty ? emp.name[0] : '?',
                                      ),
                                      radius: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Text(emp.name),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  'EGP ${salaryComps['calculatedBaseSalary'].toStringAsFixed(0)}',
                                ),
                              ),
                              DataCell(
                                Text(
                                  'EGP ${emp.allowances.toStringAsFixed(0)}',
                                ),
                              ),
                              DataCell(
                                Text(
                                  'EGP ${(emp.deductions + (salaryComps['unpaidLeaveDeduction'] ?? 0) + (salaryComps['lateArrivalDeduction'] ?? 0)).toStringAsFixed(0)}',
                                  style: TextStyle(color: AppColors.error),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '+EGP ${salaryComps['departmentBonus'].toStringAsFixed(0)}',
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '+EGP ${salaryComps['experienceBonus'].toStringAsFixed(0)}',
                                  style: TextStyle(color: Colors.purple),
                                ),
                              ),
                              DataCell(
                                Text(
                                  'EGP ${salaryComps['netSalary'].toStringAsFixed(0)}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataCell(
                                emp.payslipGenerated
                                    ? ActionChip(
                                      avatar: Icon(
                                        Icons.check_circle,
                                        color: Colors.green[600]!,
                                        size: 16,
                                      ),
                                      label: Text('View'),
                                      onPressed: () {},
                                    )
                                    : ActionChip(
                                      avatar: Icon(
                                        Icons.hourglass_empty,
                                        color: Colors.orange[600]!,
                                        size: 16,
                                      ),
                                      label: Text('Generate'),
                                      onPressed: () {},
                                    ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: AppColors.primary,
                                      ),
                                      onPressed:
                                          () => _showEditSalaryDialog(
                                            context,
                                            emp,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }

  void _showEditSalaryDialog(BuildContext context, EmployeeModel employee) {
    final formKey = GlobalKey<FormState>();
    final allowancesController = TextEditingController(
      text: employee.allowances.toString(),
    );
    final deductionsController = TextEditingController(
      text: employee.deductions.toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Edit Salary for ${employee.name}'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: allowancesController,
                    decoration: InputDecoration(
                      labelText: 'Allowances',
                      prefixText: '\$',
                    ),
                    keyboardType: TextInputType.number,
                    validator:
                        (value) =>
                            (value == null || double.tryParse(value) == null)
                                ? 'Enter a valid number'
                                : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: deductionsController,
                    decoration: InputDecoration(
                      labelText: 'Deductions',
                      prefixText: '\$',
                    ),
                    keyboardType: TextInputType.number,
                    validator:
                        (value) =>
                            (value == null || double.tryParse(value) == null)
                                ? 'Enter a valid number'
                                : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final updatedEmployee = employee.copyWith(
                    allowances: int.parse(allowancesController.text),
                    deductions: int.parse(deductionsController.text),
                  );
                  widget.onUpdateEmployee(updatedEmployee);
                  Navigator.pop(dialogContext);
                }
              },
              child: Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  void _showSalarySettingsDialog(BuildContext context) {
    // Create controllers for each position's salary
    final Map<String, TextEditingController> _rateControllers = {
      'doctor': TextEditingController(
        text: (_baseRatesByPosition['doctor'] ?? 15000).toStringAsFixed(0),
      ),
      'reception': TextEditingController(
        text: (_baseRatesByPosition['reception'] ?? 5000).toStringAsFixed(0),
      ),
      'admin': TextEditingController(
        text: (_baseRatesByPosition['admin'] ?? 8000).toStringAsFixed(0),
      ),
      'it': TextEditingController(
        text: (_baseRatesByPosition['it'] ?? 9000).toStringAsFixed(0),
      ),
      'design': TextEditingController(
        text: (_baseRatesByPosition['design'] ?? 7500).toStringAsFixed(0),
      ),
    };

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          // Cannot be const
          title: const Text('Salary Settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set the base salary for each position.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ..._rateControllers.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: TextFormField(
                      controller: entry.value,
                      decoration: InputDecoration(
                        labelText:
                            '${entry.key[0].toUpperCase()}${entry.key.substring(1)} Base Salary',
                        prefixText: 'EGP ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final Map<String, double> newBaseRates = {};
                bool allValid = true;

                _rateControllers.forEach((key, controller) {
                  final rate = double.tryParse(controller.text);
                  if (rate != null) {
                    newBaseRates[key] = rate;
                  } else {
                    allValid = false;
                  }
                });

                if (allValid) {
                  await FirebaseFirestore.instance
                      .collection('hr_settings')
                      .doc('salary_rules')
                      .set(
                        {'baseRatesByPosition': newBaseRates},
                        SetOptions(merge: true),
                      ); // Use merge to avoid overwriting other settings

                  await _fetchSalarySettings(); // Re-fetch and update state
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Salary settings updated!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Save Settings'),
            ),
          ],
        );
      },
    );
  }
}
