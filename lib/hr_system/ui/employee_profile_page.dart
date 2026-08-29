import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physioone/core/app_colors.dart';
import 'package:physioone/core/permissions.dart';
import 'package:physioone/hr_system/model/employee_model.dart';
import 'package:physioone/ui/LoginPage/models/user_model.dart';

class EmployeeProfilePage extends StatefulWidget {
  final EmployeeModel employee;
  final UserModel currentUser;
  final Function(EmployeeModel) onEditEmployee;
  final Function(String) onDeleteEmployee;

  const EmployeeProfilePage({
    super.key,
    required this.employee,
    required this.currentUser,
    required this.onEditEmployee,
    required this.onDeleteEmployee,
  });

  @override
  State<EmployeeProfilePage> createState() => _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends State<EmployeeProfilePage> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController _experienceController;
  late TextEditingController _allowancesController;
  late TextEditingController _deductionsController;
  late TextEditingController _annualLeaveController;
  late TextEditingController _sickLeaveController;

  // Dropdown/Picker values
  String? _selectedPosition;
  String? _selectedDepartment;
  String? _selectedStatus;
  String? _selectedManagerId;
  DateTime? _joinDate;
  List<String> _selectedDays = [];

  // Available options for dropdowns
  final List<String> _availablePositions = [
    'doctor',
    'reception',
    'admin',
    'it',
    'design',
  ];
  final List<String> _availableDepartments = [
    'Medical',
    'Administration',
    'IT',
    'Reception',
    'General',
    'Design',
  ];
  final List<String> _availableStatuses = ['Active', 'On Leave', 'Terminated'];
  final List<String> _allDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _experienceController.dispose();
    _allowancesController.dispose();
    _deductionsController.dispose();
    _annualLeaveController.dispose();
    _sickLeaveController.dispose();
    super.dispose();
  }

  void _initializeState() {
    final employee = widget.employee;
    _nameController = TextEditingController(text: employee.name);
    _emailController = TextEditingController(text: employee.email);
    _usernameController = TextEditingController(text: employee.username);
    _experienceController = TextEditingController(
      text: employee.yearsOfExperience.toString(),
    );
    _allowancesController = TextEditingController(
      text: employee.allowances.toString(),
    );
    _deductionsController = TextEditingController(
      text: employee.deductions.toString(),
    );
    _annualLeaveController = TextEditingController(
      text: employee.annualLeaveQuota.toString(),
    );
    _sickLeaveController = TextEditingController(
      text: employee.sickLeaveQuota.toString(),
    );
    _selectedPosition = employee.position;
    _selectedDepartment = employee.department;
    _selectedStatus = employee.status;
    _selectedManagerId = employee.managerId;
    _joinDate = employee.joinDate;
    _selectedDays = List<String>.from(employee.availableDays ?? []);
  }

  // ✅ دالة لمعرفة صلاحية التعديل
  bool _canEdit() {
    final role = Permissions.fromString(widget.currentUser.role ?? 'employee');
    final currentUserId = widget.currentUser.id ?? '';
    switch (role) {
      case UserRole.admin:
      case UserRole.hrManager:
        return true;
      case UserRole.departmentManager:
        return widget.employee.id == currentUserId ||
            widget.employee.managerId == currentUserId;
      default:
        return false;
    }
  }

  // ✅ دالة لمعرفة صلاحية الحذف
  bool _canDelete() {
    final role = Permissions.fromString(widget.currentUser.role ?? 'employee');
    switch (role) {
      case UserRole.admin:
      case UserRole.hrManager:
        return true;
      default:
        return false;
    }
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final updatedEmployee = widget.employee.copyWith(
        name: _nameController.text,
        email: _emailController.text,
        username: _usernameController.text,
        position: _selectedPosition!,
        department: _selectedDepartment!,
        status: _selectedStatus!,
        yearsOfExperience: int.tryParse(_experienceController.text) ?? 0,
        allowances: int.tryParse(_allowancesController.text) ?? 0,
        deductions: int.tryParse(_deductionsController.text) ?? 0,
        annualLeaveQuota: int.tryParse(_annualLeaveController.text) ?? 15,
        sickLeaveQuota: int.tryParse(_sickLeaveController.text) ?? 7,
        joinDate: _joinDate,
        availableDays: _selectedDays.isNotEmpty ? _selectedDays : null,
        managerId: _selectedManagerId,
      );

      widget.onEditEmployee(updatedEmployee);

      setState(() {
        _isEditing = false;
        _initializeState(); // تحديث القيم الأصلية
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Employee updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _handleCancel() {
    setState(() {
      _isEditing = false;
      _initializeState(); // إعادة تعيين القيم
    });
  }

  @override
  Widget build(BuildContext context) {
    final employee = widget.employee;
    final bool isMedicalStaff =
        _selectedPosition?.toLowerCase() == 'doctor' ||
        _selectedDepartment?.toLowerCase() == 'medical';

    return Scaffold(
      appBar: AppBar(
        title: Text(employee.name),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions:
            _isEditing
                ? [
                  IconButton(
                    icon: const Icon(Icons.cancel_rounded, size: 24),
                    onPressed: _handleCancel,
                    tooltip: 'Cancel',
                  ),
                  IconButton(
                    icon: const Icon(Icons.save_rounded, size: 24),
                    onPressed: _handleSave,
                    tooltip: 'Save Changes',
                  ),
                ]
                : [
                  if (_canEdit())
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 24),
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                      tooltip: 'Edit Employee',
                    ),
                  if (_canDelete())
                    IconButton(
                      icon: const Icon(Icons.delete_rounded, size: 24),
                      onPressed: () => _showDeleteConfirmDialog(context),
                      tooltip: 'Delete Employee',
                    ),
                ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Header Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(
                          employee.name.isNotEmpty ? employee.name[0] : '?',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _isEditing
                                ? TextFormField(
                                  controller: _nameController,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Full Name',
                                    border: InputBorder.none,
                                  ),
                                  validator:
                                      (v) =>
                                          v!.isEmpty
                                              ? 'Name is required'
                                              : null,
                                )
                                : Text(
                                  employee.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            const SizedBox(height: 12),
                            _isEditing
                                ? DropdownButtonFormField<String>(
                                  value: _selectedPosition,
                                  items:
                                      _availablePositions.map((p) {
                                        return DropdownMenuItem(
                                          value: p,
                                          child: Text(
                                            p[0].toUpperCase() + p.substring(1),
                                          ),
                                        );
                                      }).toList(),
                                  onChanged:
                                      (v) =>
                                          setState(() => _selectedPosition = v),
                                  decoration: const InputDecoration(
                                    labelText: 'Position',
                                    border: InputBorder.none,
                                  ),
                                  validator:
                                      (v) =>
                                          v == null
                                              ? 'Position is required'
                                              : null,
                                )
                                : Text(
                                  employee.position.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            const SizedBox(height: 12),
                            _isEditing
                                ? DropdownButtonFormField<String>(
                                  value: _selectedStatus,
                                  items:
                                      _availableStatuses.map((s) {
                                        return DropdownMenuItem(
                                          value: s,
                                          child: Text(s),
                                        );
                                      }).toList(),
                                  onChanged:
                                      (v) =>
                                          setState(() => _selectedStatus = v),
                                  decoration: const InputDecoration(
                                    labelText: 'Status',
                                    border: InputBorder.none,
                                  ),
                                  validator:
                                      (v) =>
                                          v == null
                                              ? 'Status is required'
                                              : null,
                                )
                                : Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        employee.status == 'Active'
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    employee.status,
                                    style: TextStyle(
                                      color:
                                          employee.status == 'Active'
                                              ? Colors.green[700]
                                              : Colors.red[700],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ Personal Information
              _buildSection(
                title: 'Personal Information',
                icon: Icons.person_outline,
                children: [
                  _buildInfoRow('Employee ID', employee.id),
                  SizedBox(height: 12),

                  _buildEditableInfoRow('Email', _emailController),
                  SizedBox(height: 12),

                  _buildEditableInfoRow('Username', _usernameController),
                  SizedBox(height: 12),

                  _buildEditableDropdown(
                    'Department',
                    _selectedDepartment,
                    _availableDepartments,
                    (v) => setState(() => _selectedDepartment = v),
                  ),
                  SizedBox(height: 12),

                  _buildEditableDropdown(
                    'Position',
                    _selectedPosition,
                    _availablePositions,
                    (v) => setState(() => _selectedPosition = v),
                  ),
                  SizedBox(height: 12),
                  _buildEditableDateRow('Join Date', _joinDate, (date) {
                    setState(() => _joinDate = date);
                  }),
                  SizedBox(height: 12),
                  _buildEditableInfoRow(
                    'Years of Experience',
                    _experienceController,
                    isNumeric: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ✅ Leave Summary
              _buildSection(
                title: 'Leave Summary',
                icon: Icons.event_note_rounded,
                children: [
                  SizedBox(height: 4),
                  _buildEditableInfoRow(
                    'Annual Leave Quota',
                    _annualLeaveController,
                    isNumeric: true,
                  ),
                  SizedBox(height: 4),
                  _buildEditableInfoRow(
                    'Sick Leave Quota',
                    _sickLeaveController,
                    isNumeric: true,
                  ),
                  SizedBox(height: 4),

                  _buildInfoRow(
                    'Used Annual Leave',
                    '${_calculateUsedLeave('Annual')} days',
                  ),
                  SizedBox(height: 4),

                  _buildInfoRow(
                    'Used Sick Leave',
                    '${_calculateUsedLeave('Sick')} days',
                  ),
                  SizedBox(height: 4),

                  _buildInfoRow(
                    'Used Unpaid Leave',
                    '${_calculateUsedLeave('Unpaid')} days',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ✅ Financial Summary
              _buildSection(
                title: 'Financial Summary',
                icon: Icons.account_balance_wallet_rounded,
                children: [
                  _buildInfoRow(
                    'Base Salary',
                    'EGP ${employee.baseSalary.toStringAsFixed(0)}',
                  ),
                  SizedBox(height: 12),
                  _buildEditableInfoRow(
                    'Allowances',
                    _allowancesController,
                    isNumeric: true,
                  ),
                  SizedBox(height: 12),
                  _buildEditableInfoRow(
                    'Deductions',
                    _deductionsController,
                    isNumeric: true,
                  ),
                  SizedBox(height: 12),

                  _buildInfoRow(
                    'Net Salary',
                    'EGP ${(employee.baseSalary + employee.allowances - employee.deductions).toStringAsFixed(0)}',
                    isBold: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ✅ Available Days (if medical staff)
              if (isMedicalStaff)
                _buildSection(
                  title: 'Available Days',
                  icon: Icons.calendar_today_rounded,
                  children: [
                    _isEditing
                        ? _buildDaysCheckboxes()
                        : Wrap(
                          spacing: 8,
                          children:
                              (employee.availableDays ?? []).map((day) {
                                return Chip(
                                  label: Text(day),
                                  backgroundColor: AppColors.primary
                                      .withOpacity(0.1),
                                );
                              }).toList(),
                        ),
                  ],
                ),

              // ✅ Manager (if any)
              if (employee.managerId != null || _isEditing)
                _buildSection(
                  title: 'Direct Manager',
                  icon: Icons.people_alt_rounded,
                  children: [
                    _isEditing
                        ? DropdownButtonFormField<String>(
                          value: _selectedManagerId,
                          hint: const Text('Select Manager'),
                          items: const [
                            // في تطبيق حقيقي، ستجلب قائمة المديرين من الـ EmployeeService
                            // هذا مثال فقط
                          ],
                          onChanged:
                              (v) => setState(() => _selectedManagerId = v),
                          decoration: const InputDecoration(
                            labelText: 'Direct Manager',
                            border: InputBorder.none,
                          ),
                        )
                        : _buildInfoRow(
                          'Manager ID',
                          employee.managerId ?? 'N/A',
                        ),
                  ],
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Helper: حساب الإجازات المستخدمة
  int _calculateUsedLeave(String type) {
    int usedDays = 0;
    for (var request in widget.employee.leaveRequests) {
      if (request is Map &&
          request['status'] == 'Approved' &&
          request['type'] == type &&
          request['startDate'] is Timestamp &&
          request['endDate'] is Timestamp) {
        final startDate = (request['startDate'] as Timestamp).toDate();
        final endDate = (request['endDate'] as Timestamp).toDate();
        usedDays += endDate.difference(startDate).inDays + 1;
      }
    }
    return usedDays;
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableInfoRow(
    String label,
    TextEditingController controller, {
    bool isNumeric = false,
  }) {
    if (!_isEditing) {
      return _buildInfoRow(label, controller.text);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        validator: (v) => v!.isEmpty ? '$label is required' : null,
      ),
    );
  }

  Widget _buildEditableDropdown(
    String label,
    String? currentValue,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    if (!_isEditing) {
      return _buildInfoRow(label, currentValue ?? 'N/A');
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: DropdownButtonFormField<String>(
        value: currentValue,
        items:
            items.map((i) {
              return DropdownMenuItem(
                value: i,
                child: Text(i[0].toUpperCase() + i.substring(1)),
              );
            }).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label),
        validator: (v) => v == null ? '$label is required' : null,
      ),
    );
  }

  Widget _buildEditableDateRow(
    String label,
    DateTime? currentDate,
    void Function(DateTime) onDateChanged,
  ) {
    if (!_isEditing) {
      return _buildInfoRow(
        label,
        currentDate != null
            ? DateFormat('MMMM d, yyyy').format(currentDate)
            : 'N/A',
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: TextFormField(
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        controller: TextEditingController(
          text:
              currentDate != null
                  ? DateFormat('MMMM d, yyyy').format(currentDate)
                  : '',
        ),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: currentDate ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null) {
            onDateChanged(picked);
          }
        },
        validator: (v) => currentDate == null ? 'Please select a date' : null,
      ),
    );
  }

  Widget _buildDaysCheckboxes() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children:
          _allDays.map((day) {
            return ChoiceChip(
              label: Text(day),
              selected: _selectedDays.contains(day),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedDays.add(day);
                  } else {
                    _selectedDays.remove(day);
                  }
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
            );
          }).toList(),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Employee'),
          content: Text(
            'Are you sure you want to delete ${widget.employee.name}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                widget.onDeleteEmployee(widget.employee.id);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Employee deleted successfully!'),
                    backgroundColor: AppColors.error,
                  ),
                );
                Navigator.pop(context); // إغلاق صفحة الملف الشخصي
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
