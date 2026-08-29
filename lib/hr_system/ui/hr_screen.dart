import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physioone/core/app_colors.dart';
import 'package:physioone/core/app_consts/location_service.dart';
import 'package:physioone/core/permissions.dart';
import 'package:physioone/hr_system/model/employee_model.dart';
import 'package:physioone/hr_system/services/employee_service.dart';
import 'package:physioone/hr_system/ui/dashboard_screen.dart';
import 'package:physioone/hr_system/ui/employees_screen.dart';
import 'package:physioone/hr_system/ui/attendance_screen.dart';
import 'package:physioone/hr_system/ui/leave_management_screen.dart';
import 'package:physioone/hr_system/ui/salaries_screen.dart';
import 'package:physioone/hr_system/ui/expenses_screen.dart';
import 'package:physioone/ui/LoginPage/models/user_model.dart';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
  final LocationService _locationService = LocationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _verticalScrollController = ScrollController();

  late UserRole _currentUserRole;

  @override
  void initState() {
    super.initState();
    _currentUserRole = Permissions.fromString(widget.user.role ?? 'employee');
    _listenToAllPersonnel();
    _resetAnnualLeaveQuotasIfNeeded(); // ✅ تم تفعيل تحديث الرصيد التلقائي
  }

  // ✅ دالة تحديث أرصدة الإجازات تلقائياً
  Future<void> _resetAnnualLeaveQuotasIfNeeded() async {
    try {
      final now = DateTime.now();
      final currentYear = now.year;

      final settingsBox = await Hive.openBox('hr_settings');
      final lastResetYear = settingsBox.get('lastResetYear', defaultValue: 0);

      if (lastResetYear < currentYear) {
        debugPrint('🔄 جاري تحديث أرصدة الإجازات للعام $currentYear...');

        final employees = await _employeeService.getAllEmployees();

        for (var emp in employees) {
          final updated = emp.copyWith(annualLeaveQuota: 15, sickLeaveQuota: 7);
          await _employeeService.updateEmployee(updated);
        }

        await settingsBox.put('lastResetYear', currentYear);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم تحديث أرصدة الإجازات للعام الجديد بنجاح!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        debugPrint('✅ تم تحديث أرصدة الإجازات لـ ${employees.length} موظف.');
      } else {
        debugPrint(
          'ℹ️ تم تحديث الأرصدة مسبقاً في السنة $lastResetYear، لا حاجة للتحديث.',
        );
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحديث أرصدة الإجازات: $e');
    }
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
              .map((doc) => _adaptUserToEmployee(doc.data(), doc.id))
              .where((e) => e.email.isNotEmpty)
              .toList();
      _mergeAndSetState(hrEmployees, usersAsEmployees, doctorsAsEmployees);
    }, onError: _handleError);

    _doctorsSubscription = _firestore.collection('doctors').snapshots().listen((
      snapshot,
    ) {
      doctorsAsEmployees =
          snapshot.docs
              .map((doc) => _adaptDoctorToEmployee(doc.data(), doc.id))
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

    final allPersonnel = <String, EmployeeModel>{};
    for (var p in [...doctors, ...users, ...hr]) {
      if (p.email.isNotEmpty) {
        allPersonnel[p.email] = p;
      }
    }

    final filteredEmployees = _filterEmployeesByRole(
      allPersonnel.values.toList(),
    );

    setState(() {
      _employees = filteredEmployees;
      _isLoading = false;
    });
  }

  List<EmployeeModel> _filterEmployeesByRole(List<EmployeeModel> allEmployees) {
    final currentUserId = widget.user.id ?? '';

    switch (_currentUserRole) {
      case UserRole.admin:
      case UserRole.hrManager:
        return allEmployees;
      case UserRole.departmentManager:
        return allEmployees
            .where(
              (emp) =>
                  emp.id == currentUserId || emp.managerId == currentUserId,
            )
            .toList();
      case UserRole.employee:
        return allEmployees.where((emp) => emp.id == currentUserId).toList();
      default:
        return [];
    }
  }

  void _handleError(error) {
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching data: $error'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

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
      annualLeaveQuota: 15,
      sickLeaveQuota: 7,
      source: 'users',
      managerId: userData['managerId'],
    );
  }

  EmployeeModel _adaptDoctorToEmployee(
    Map<String, dynamic> doctorData,
    String docId,
  ) {
    return EmployeeModel(
      id: doctorData['id'] as String? ?? docId,
      name: doctorData['name'] as String? ?? 'N/A',
      username: doctorData['name'] as String? ?? '',
      password: '',
      email: doctorData['email'] as String? ?? '',
      position: 'doctor',
      department: doctorData['specialization'] as String? ?? 'Medical',
      status: 'Active',
      payslipGenerated: false,
      attendance: [],
      joinDate: DateTime.now(),
      yearsOfExperience: 0,
      leaveRequests: [],
      annualLeaveQuota: 15,
      sickLeaveQuota: 7,
      baseSalary: (doctorData['baseSalary'] as num? ?? 0).toInt(),
      source: 'doctors',
      allowances: (doctorData['allowances'] as num? ?? 0).toInt(),
      deductions: (doctorData['deductions'] as num? ?? 0).toInt(),
      availableDays:
          (doctorData['availableDays'] as List?)?.cast<String>() ?? [],
      managerId: doctorData['managerId'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                right: BorderSide(
                  color: Colors.grey.withOpacity(0.15),
                  width: 1,
                ),
              ),
            ),
            child: NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              backgroundColor: Colors.transparent,
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: IconThemeData(
                color: AppColors.secondary,
                size: 24,
              ),
              unselectedIconTheme: IconThemeData(
                color: Colors.grey[500],
                size: 22,
              ),
              selectedLabelTextStyle: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              leading: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24.0,
                  horizontal: 12.0,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.business_center_rounded,
                        size: 28,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'HR Portal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people_rounded),
                  label: Text('Employees'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.access_time_outlined),
                  selectedIcon: Icon(Icons.access_time_filled_rounded),
                  label: Text('Attendance'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.event_note_outlined),
                  selectedIcon: Icon(Icons.event_note_rounded),
                  label: Text('Leave'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.monetization_on_outlined),
                  selectedIcon: Icon(Icons.monetization_on_rounded),
                  label: Text('Salaries'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: Text('Expenses'),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                    : _buildScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildScreen() {
    return Builder(
      builder: (context) {
        switch (_selectedIndex) {
          case 0:
            return DashboardScreen(employees: _employees);
          case 1:
            return EmployeesScreen(
              employees: _employees,
              currentUser: widget.user,
              onAddEmployee: (employeeToAdd) async {
                // منطق الإضافة (نفس الكود السابق)
                // ...
              },
              onUpdateEmployee: (updatedEmployee) async {
                // منطق التعديل (نفس الكود السابق)
                // ...
              },
              onDeleteEmployee: (employeeId) async {
                // منطق الحذف (نفس الكود السابق)
                // ...
              },
            );
          case 2:
            return AttendanceScreen(
              employees: _employees,
              currentUser: widget.user,
              locationService: _locationService,
            );
          case 3:
            return LeaveManagementScreen(
              employees: _employees,
              currentUser: widget.user,
            );
          case 4:
            return SalariesScreen(
              employees: _employees,
              currentUser: widget.user,
              onUpdateEmployee: (EmployeeModel updatedEmployee) async {
                // منطق تحديث الراتب
                // ...
              },
            );
          case 5:
            return ExpensesScreen(
              employees: _employees,
              currentUser: widget.user,
            );
          default:
            return DashboardScreen(employees: _employees);
        }
      },
    );
  }
}
