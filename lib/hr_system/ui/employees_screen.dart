import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physioone/core/app_colors.dart';
import 'package:physioone/core/permissions.dart';
import 'package:physioone/hr_system/model/employee_model.dart';
import 'package:physioone/hr_system/services/employee_service.dart';
import 'package:physioone/hr_system/ui/employee_profile_page.dart';
import 'package:physioone/ui/LoginPage/models/user_model.dart';

class EmployeesScreen extends StatefulWidget {
  final List<EmployeeModel> employees;
  final UserModel currentUser;
  final Function(EmployeeModel) onAddEmployee;
  final Function(EmployeeModel) onUpdateEmployee;
  final Function(String) onDeleteEmployee;

  const EmployeesScreen({
    super.key,
    required this.employees,
    required this.currentUser,
    required this.onAddEmployee,
    required this.onUpdateEmployee,
    required this.onDeleteEmployee,
  });

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

  late UserRole _currentUserRole;
  final EmployeeService _employeeService = EmployeeService();

  Map<String, double> _baseRatesByPosition = {
    'doctor': 15000.0,
    'reception': 5000.0,
    'admin': 8000.0,
    'it': 9000.0,
    'design': 7500.0,
  };

  double _calculateBaseSalary(String position, int yearsOfExperience) {
    final positionKey = position.toLowerCase();
    final baseRate = _baseRatesByPosition.entries
        .firstWhere(
          (entry) => positionKey.contains(entry.key),
          orElse: () => const MapEntry('default', 4000.0),
        )
        .value;
    final experienceBonus = yearsOfExperience * 250.0;
    return baseRate + experienceBonus;
  }

  // ✅ دالة تصفية الموظفين حسب الصلاحية
  List<EmployeeModel> _filterEmployeesByRole(List<EmployeeModel> allEmployees) {
    final currentUserId = widget.currentUser.id ?? '';

    switch (_currentUserRole) {
      case UserRole.admin:
      case UserRole.hrManager:
        return allEmployees;
      case UserRole.departmentManager:
        return allEmployees.where((emp) =>
            emp.id == currentUserId || emp.managerId == currentUserId).toList();
      case UserRole.employee:
        return allEmployees.where((emp) => emp.id == currentUserId).toList();
      default:
        return [];
    }
  }

  @override
  void initState() {
    super.initState();
    _currentUserRole = Permissions.fromString(widget.currentUser.role ?? 'employee');
    _fetchSalarySettings();
    _filteredEmployees = _filterEmployeesByRole(widget.employees);
    _searchController.addListener(() {
      if (_searchController.text.isEmpty && mounted) {
        setState(() {
          _filteredEmployees = _filterEmployeesByRole(widget.employees);
        });
      }
    });
  }

  Future<void> _fetchSalarySettings() async {
    try {
      final doc = await FirebaseFirestore.instance
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
      if (mounted) {
        debugPrint("Could not fetch salary settings for EmployeesScreen: $e");
      }
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
    List<EmployeeModel> displayedEmployees = _searchController.text.isEmpty
        ? _filterEmployeesByRole(widget.employees)
        : _filterEmployeesByRole(widget.employees).where((emp) {
            final query = _searchController.text.toLowerCase();
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

    _filteredEmployees = displayedEmployees;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Employee Management',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              // ✅ زر الإضافة يظهر فقط للمخوّلين
              if (Permissions.hasPermission(_currentUserRole, Permissions.manageEmployees))
                ElevatedButton.icon(
                  onPressed: () => _showAddEmployeeDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Employee'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {});
              },
              decoration: const InputDecoration(
                hintText: 'Search by ID, Name, Email, Position...',
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Scrollbar(
                  controller: _verticalScrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _verticalScrollController,
                    child: Column(
                      children: displayedEmployees.map((emp) {
                        final name = emp.name;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              // ✅ النقر على الصف يفتح الملف الشخصي
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EmployeeProfilePage(
                                      employee: emp,
                                      currentUser: widget.currentUser,
                                      onEditEmployee: widget.onUpdateEmployee,
                                      onDeleteEmployee: widget.onDeleteEmployee,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // ✅ الصورة الشخصية
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.primary
                                          .withOpacity(0.1),
                                      child: Text(
                                        name.isNotEmpty ? name[0] : '?',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    // ✅ المعلومات الأساسية
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Text(
                                                emp.id.toString(),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        8,
                                                      ),
                                                ),
                                                child: Text(
                                                  emp.status,
                                                  style: TextStyle(
                                                    color: Colors.green[700],
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Text(
                                                emp.position,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                emp.department,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // ✅ زر عرض الملف الشخصي فقط
                                    IconButton(
                                      icon: const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 16,
                                      ),
                                      color: Colors.grey[400],
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EmployeeProfilePage(
                                              employee: emp,
                                              currentUser: widget.currentUser,
                                              onEditEmployee: widget.onUpdateEmployee,
                                              onDeleteEmployee: widget.onDeleteEmployee,
                                            ),
                                          ),
                                        );
                                      },
                                      tooltip: 'View Profile',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // دوال إضافة الموظفين (تستخدم في الحوار)
  // ============================================================

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
    String? selectedManagerId;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Add New Employee',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setStateDialog) {
                final bool isMedicalStaff =
                    (selectedPosition?.toLowerCase() == 'doctor') ||
                    (selectedDepartment?.toLowerCase() == 'medical');
                return SizedBox(
                  width: 500,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Please enter a name' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedPosition,
                          hint: const Text('Select Position'),
                          items: _availablePositions.map((String value) {
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
                          validator: (value) =>
                              value == null ? 'Please select a position' : null,
                          decoration: const InputDecoration(
                            labelText: 'Position',
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedDepartment,
                          hint: const Text('Select Department'),
                          items: availableDepartments.map((String value) {
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
                          validator: (value) =>
                              value == null ? 'Please select a department' : null,
                          decoration: const InputDecoration(
                            labelText: 'Department',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                          ),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter an email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                          ),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter a username';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Financial Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: experienceController,
                          decoration: const InputDecoration(
                            labelText: 'Years of Experience',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter years of experience';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: allowancesController,
                          decoration: const InputDecoration(
                            labelText: 'Allowances (EGP)',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter allowances';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: deductionsController,
                          decoration: const InputDecoration(
                            labelText: 'Deductions (EGP)',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter deductions';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: annualLeaveController,
                                decoration: const InputDecoration(
                                  labelText: 'Annual Quota',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: sickLeaveController,
                                decoration: const InputDecoration(
                                  labelText: 'Sick Quota',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        if (Permissions.hasPermission(
                            _currentUserRole, Permissions.manageEmployees))
                          DropdownButtonFormField<String>(
                            value: selectedManagerId,
                            hint: const Text('Select Manager (Optional)'),
                            items: widget.employees.map((emp) {
                              return DropdownMenuItem<String>(
                                value: emp.id,
                                child: Text(emp.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setStateDialog(() {
                                selectedManagerId = value;
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'Direct Manager',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        if (isMedicalStaff) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'Available Days:',
                            style: TextStyle(fontWeight: FontWeight.bold),
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
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final bool isMedicalStaff = (selectedPosition
                          ?.toLowerCase() ==
                      'doctor') ||
                      (selectedDepartment?.toLowerCase() == 'medical');
                  if (isMedicalStaff && selectedDays.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
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

                  final newEmployee = EmployeeModel(
                    id: '',
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
                    availableDays: isMedicalStaff ? selectedDays : [],
                    annualLeaveQuota:
                        int.tryParse(annualLeaveController.text) ?? 15,
                    sickLeaveQuota: int.tryParse(sickLeaveController.text) ?? 7,
                    source: 'employees',
                    managerId: selectedManagerId,
                  );

                  widget.onAddEmployee(newEmployee);
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Employee added successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Add Employee'),
            ),
          ],
        );
      },
    );
  }
}