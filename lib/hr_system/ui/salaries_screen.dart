import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physioone/core/app_colors.dart';
import 'package:physioone/core/permissions.dart';
import 'package:physioone/hr_system/model/employee_model.dart';
import 'package:physioone/hr_system/services/employee_service.dart';
import 'package:physioone/hr_system/ui/employee_salary_history_page.dart';
import 'package:physioone/ui/LoginPage/models/user_model.dart';

class SalariesScreen extends StatefulWidget {
  final List<EmployeeModel> employees;
  final UserModel currentUser; // ✅ تمت الإضافة
  final Function(EmployeeModel) onUpdateEmployee;

  const SalariesScreen({
    Key? key,
    required this.employees,
    required this.currentUser, // ✅ تمت الإضافة
    required this.onUpdateEmployee,
  }) : super(key: key);

  @override
  State<SalariesScreen> createState() => _SalariesScreenState();
}

class _SalariesScreenState extends State<SalariesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late UserRole _currentUserRole;

  // ✅ قائمة الموظفين المفلترة حسب الصلاحية والبحث
  List<EmployeeModel> get _filteredEmployees {
    var list = widget.employees;

    // تصفية حسب الصلاحية
    final currentUserId = widget.currentUser.id ?? '';
    switch (_currentUserRole) {
      case UserRole.admin:
      case UserRole.hrManager:
        break; // يرى الكل
      case UserRole.departmentManager:
        list = list.where((emp) =>
            emp.id == currentUserId || emp.managerId == currentUserId).toList();
        break;
      case UserRole.employee:
        list = list.where((emp) => emp.id == currentUserId).toList();
        break;
      default:
        return [];
    }

    // تصفية حسب البحث
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((emp) {
        final name = emp.name.toLowerCase();
        final id = emp.id.toLowerCase();
        final position = emp.position.toLowerCase();
        final department = emp.department.toLowerCase();
        return name.contains(query) ||
            id.contains(query) ||
            position.contains(query) ||
            department.contains(query);
      }).toList();
    }

    // ترتيب حسب الاسم
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  // ✅ حساب صافي الراتب (إرجاع double)
  double _calculateNetSalary(EmployeeModel emp) {
    return (emp.baseSalary + emp.allowances - emp.deductions).toDouble();
  }

  // ✅ التحقق من صلاحية التعديل
  bool _canEditSalary(EmployeeModel employee) {
    final currentUserId = widget.currentUser.id ?? '';
    switch (_currentUserRole) {
      case UserRole.admin:
      case UserRole.hrManager:
        return true;
      case UserRole.departmentManager:
        return employee.id == currentUserId || employee.managerId == currentUserId;
      default:
        return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _currentUserRole = Permissions.fromString(
      widget.currentUser.role ?? 'employee',
    );
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredEmployees = _filteredEmployees;
    final totalPayroll = filteredEmployees.fold(
      0.0,
      (sum, e) => sum + _calculateNetSalary(e),
    );

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ العنوان والإحصائيات
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Salary & Payroll Management',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Total Payroll: EGP ${(totalPayroll / 1000).toStringAsFixed(1)}K',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (Permissions.hasPermission(
                    _currentUserRole,
                    Permissions.editSalary,
                  ))
                    ElevatedButton.icon(
                      onPressed: () => _runPayroll(context),
                      icon: const Icon(Icons.play_circle_filled_rounded),
                      label: const Text('Run Payroll'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ✅ شريط البحث
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
              decoration: const InputDecoration(
                hintText: 'Search by Name, ID, Position, or Department...',
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ✅ قائمة الموظفين
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
                child: filteredEmployees.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No employees match your search.'
                                  : 'No employees found.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columnSpacing: 24,
                            headingRowColor: MaterialStateProperty.all(
                              Colors.grey.withOpacity(0.04),
                            ),
                            columns: const [
                              DataColumn(
                                label: Text(
                                  'Employee',
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
                                  'Net Salary',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                numeric: true,
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
                            rows: filteredEmployees.map((emp) {
                              final netSalary = _calculateNetSalary(emp);
                              final canEdit = _canEditSalary(emp);

                              return DataRow(
                                // ✅ النقر على الصف يفتح تاريخ الرواتب
                                onSelectChanged: (_) {
                                  _navigateToSalaryHistory(context, emp);
                                },
                                cells: [
                                  // ✅ اسم الموظف
                                  DataCell(
                                    InkWell(
                                      onTap: () => _navigateToSalaryHistory(
                                        context,
                                        emp,
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: AppColors.primary
                                                .withOpacity(0.1),
                                            child: Text(
                                              emp.name.isNotEmpty
                                                  ? emp.name[0]
                                                  : '?',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                emp.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                emp.id,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(emp.position)),
                                  DataCell(Text(emp.department)),
                                  DataCell(
                                    Text(
                                      'EGP ${emp.baseSalary.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      'EGP ${emp.allowances.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      'EGP ${emp.deductions.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      'EGP ${netSalary.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: emp.payslipGenerated
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        emp.payslipGenerated
                                            ? 'Generated'
                                            : 'Pending',
                                        style: TextStyle(
                                          color: emp.payslipGenerated
                                              ? Colors.green[700]
                                              : Colors.orange[700],
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // ✅ زر عرض التاريخ
                                        IconButton(
                                          icon: const Icon(
                                            Icons.history_rounded,
                                            size: 18,
                                          ),
                                          color: AppColors.primary,
                                          onPressed: () => _navigateToSalaryHistory(
                                            context,
                                            emp,
                                          ),
                                          tooltip: 'View Salary History',
                                        ),
                                        // ✅ زر تعديل الراتب
                                        if (canEdit)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit_rounded,
                                              size: 18,
                                            ),
                                            color: Colors.grey[600],
                                            onPressed: () =>
                                                _showEditSalaryDialog(
                                                  context,
                                                  emp,
                                                ),
                                            tooltip: 'Edit Salary',
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
          ),
        ],
      ),
    );
  }

  // ============================================================
  // دوال مساعدة
  // ============================================================

  void _navigateToSalaryHistory(BuildContext context, EmployeeModel employee) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeSalaryHistoryPage(employee: employee),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Edit Salary: ${employee.name}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 350,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: allowancesController,
                    decoration: const InputDecoration(
                      labelText: 'Allowances (EGP)',
                      prefixIcon: Icon(Icons.add_card_rounded),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value == null || double.tryParse(value) == null
                            ? 'Enter a valid number'
                            : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: deductionsController,
                    decoration: const InputDecoration(
                      labelText: 'Deductions (EGP)',
                      prefixIcon: Icon(Icons.remove_circle_outline_rounded),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value == null || double.tryParse(value) == null
                            ? 'Enter a valid number'
                            : null,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Base Salary: EGP ${employee.baseSalary.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Salary updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  setState(() {});
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  void _runPayroll(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Confirm Payroll Run'),
        content: const Text(
          'This will compute payroll variables and update deductions based on active attendance tracking. Proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Run Payroll'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // ✅ منطق تشغيل الرواتب
      for (final emp in widget.employees) {
        final salaryComps = _calculateSalaryComponents(emp);
        final totalDeductions = emp.deductions +
            (salaryComps['unpaidLeaveDeduction'] as double).toInt() +
            (salaryComps['lateArrivalDeduction'] as double).toInt();

        final updatedEmployee = emp.copyWith(
          deductions: totalDeductions,
          payslipGenerated: true,
        );
        widget.onUpdateEmployee(updatedEmployee);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Payroll completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {});
    }
  }

  Map<String, dynamic> _calculateSalaryComponents(EmployeeModel emp) {
    const double workingDaysInMonth = 22.0;
    double effectiveBaseSalary = emp.baseSalary.toDouble();

    // حساب أيام الحضور الفعلية
    final daysAttended = (emp.attendance)
        .where((a) => a['status'] == 'Present' || a['status'] == 'Late')
        .length
        .toDouble();

    final attendanceAdjustment = (daysAttended < workingDaysInMonth)
        ? (effectiveBaseSalary / workingDaysInMonth) * daysAttended -
            effectiveBaseSalary
        : 0.0;

    // بونص القسم
    final department = emp.department;
    final departmentBonusRate = {
      'IT': 0.1,
      'Design': 0.05,
      'HR': 0.08,
    };
    final departmentBonus =
        effectiveBaseSalary * (departmentBonusRate[department] ?? 0.0);

    final double dailyRate = effectiveBaseSalary / 22.0;

    // خصم الإجازات غير المدفوعة
    final unpaidLeaveDays = (emp.leaveRequests)
        .where(
          (req) => req['status'] == 'Approved' && req['type'] == 'Unpaid',
        )
        .length;
    final unpaidLeaveDeduction = unpaidLeaveDays * dailyRate;

    // خصم التأخير
    final lateArrivals =
        (emp.attendance).where((att) => att['status'] == 'Late').length;
    final lateArrivalDeduction = lateArrivals * 50.0;

    final totalDeductions =
        emp.deductions.toDouble() + unpaidLeaveDeduction + lateArrivalDeduction;
    final finalNetSalary =
        effectiveBaseSalary + emp.allowances - totalDeductions + departmentBonus;

    return {
      'netSalary': finalNetSalary,
      'departmentBonus': departmentBonus,
      'attendanceAdjustment': attendanceAdjustment,
      'unpaidLeaveDeduction': unpaidLeaveDeduction,
      'lateArrivalDeduction': lateArrivalDeduction,
    };
  }
}