import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physioone/core/app_colors.dart';
import 'package:physioone/core/permissions.dart';
import 'package:physioone/hr_system/model/employee_model.dart';
import 'package:physioone/hr_system/services/employee_service.dart';
import 'package:physioone/hr_system/ui/expense_request_dialog.dart';
import 'package:physioone/ui/LoginPage/models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

class UserProfilePage extends StatefulWidget {
  final UserModel user;

  const UserProfilePage({super.key, required this.user});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late EmployeeModel _employee;
  bool _isLoading = true;
  StreamSubscription<EmployeeModel?>? _employeeSubscription;
  final EmployeeService _employeeService = EmployeeService();

  // ✅ تحديد دور المستخدم الحالي
  late UserRole _currentUserRole;

  @override
  void initState() {
    super.initState();
    _currentUserRole = Permissions.fromString(widget.user.role ?? 'employee');
    _listenToEmployeeChanges();
  }

  void _listenToEmployeeChanges() {
    final employeeId = widget.user.id;
    if (employeeId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    _employeeSubscription = _employeeService.employeeStream(employeeId).listen(
      (employee) {
        if (employee != null && mounted) {
          setState(() {
            _employee = employee;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading profile: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _employeeSubscription?.cancel();
    super.dispose();
  }

  // ✅ حساب الإجازات المستخدمة
  int _calculateUsedLeave(String type) {
    int usedDays = 0;
    for (var request in _employee.leaveRequests) {
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

  // ✅ حساب صافي الراتب
  double _calculateNetSalary() {
    return (_employee.baseSalary + _employee.allowances - _employee.deductions)
        .toDouble();
  }

  // ✅ التحقق من صلاحية التعديل (للمشرفين فقط)
  bool _canEdit() {
    switch (_currentUserRole) {
      case UserRole.admin:
      case UserRole.hrManager:
        return true;
      case UserRole.departmentManager:
        return _employee.id == widget.user.id;
      default:
        return false;
    }
  }

  // ✅ التحقق من صلاحية تقديم طلب مصروفات
  bool _canRequestExpense() {
    return _currentUserRole == UserRole.employee ||
        _currentUserRole == UserRole.departmentManager;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final employee = _employee;
    final usedAnnual = _calculateUsedLeave('Annual');
    final usedSick = _calculateUsedLeave('Sick');
    final usedUnpaid = _calculateUsedLeave('Unpaid');
    final remainingAnnual = employee.annualLeaveQuota - usedAnnual;
    final remainingSick = employee.sickLeaveQuota - usedSick;
    final netSalary = _calculateNetSalary();

    // ✅ البحث عن اسم المدير المباشر
    String managerName = 'N/A';
    if (employee.managerId != null) {
      // يمكن جلب اسم المدير من قائمة الموظفين (سيتم تمريرها من الـ parent)
      // حالياً نعرض المعرف فقط، يمكن تحسينه لاحقاً
      managerName = employee.managerId!;
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // ✅ زر تعديل (للمشرفين فقط)
          if (_canEdit())
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                // TODO: فتح صفحة تعديل الملف الشخصي
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Edit profile feature coming soon!'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              tooltip: 'Edit Profile',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ✅ Header Section (محدث)
            _buildHeaderSection(context, employee),
            const SizedBox(height: 16),

            // ✅ المحتوى الرئيسي
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // ✅ إحصائيات سريعة
                    _buildQuickStatsRow(context, employee),
                    const SizedBox(height: 16),

                    // ✅ ملخص الإجازات (ديناميكي)
                    _buildLeaveSummaryRow(
                      context,
                      remainingAnnual,
                      remainingSick,
                      usedUnpaid,
                      usedAnnual + usedSick + usedUnpaid,
                    ),
                    const SizedBox(height: 16),

                    // ✅ أزرار الإجراءات السريعة
                    _buildActionButtons(context, employee),
                    const SizedBox(height: 16),

                    // ✅ المعلومات الشخصية والمالية
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildPersonalInfoCard(context, employee),
                              const SizedBox(height: 16),
                              _buildEmploymentDetailsCard(context, employee),
                              const SizedBox(height: 16),
                              _buildAllRequestsCard(context, employee),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFinancialSummaryCard(
                            context,
                            employee,
                            netSalary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // دوال بناء الواجهات
  // ============================================================

  Widget _buildHeaderSection(BuildContext context, EmployeeModel employee) {
    final statusColor = employee.status == 'Active' ? Colors.green : Colors.red;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: Colors.white.withAlpha(51),
                    child: Text(
                      employee.name.isNotEmpty ? employee.name[0] : '?',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Icon(
                      employee.status == 'Active' ? Icons.check : Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              employee.name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              employee.position.toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withAlpha(230),
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withAlpha(77)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    employee.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsRow(BuildContext context, EmployeeModel employee) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.calendar_today,
            label: 'Years of Experience',
            value: employee.yearsOfExperience.toString(),
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.work_outline,
            label: 'Department',
            value: employee.department,
            color: Colors.purple,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.event_available,
            label: 'Available Days',
            value: (employee.availableDays?.length ?? 0).toString(),
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveSummaryRow(
    BuildContext context,
    int remainingAnnual,
    int remainingSick,
    int usedUnpaid,
    int totalUsed,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.calendar_view_week_rounded,
            label: 'Annual Leave',
            value: '$remainingAnnual / ${_employee.annualLeaveQuota}',
            color: Colors.teal,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.medical_services_outlined,
            label: 'Sick Leave',
            value: '$remainingSick / ${_employee.sickLeaveQuota}',
            color: Colors.amber,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.money_off_csred_outlined,
            label: 'Unpaid Leave',
            value: '$usedUnpaid Days',
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.outbox_rounded,
            label: 'Used Leaves',
            value: '$totalUsed Days',
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, EmployeeModel employee) {
    return Row(
      children: [
        // ✅ زر تقديم إجازة
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showVacationRequestDialog(context),
            icon: const Icon(Icons.beach_access_outlined, size: 18),
            label: const Text('Request Vacation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // ✅ زر تقديم طلب مصروفات
        if (_canRequestExpense())
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (dialogContext) => ExpenseRequestDialog(
                    currentEmployee: employee,
                    onSubmitted: () {
                      // تحديث البيانات بعد تقديم الطلب
                      _listenToEmployeeChanges();
                    },
                  ),
                );
              },
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: const Text('Request Expense'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPersonalInfoCard(BuildContext context, EmployeeModel employee) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              context,
              icon: Icons.email_outlined,
              label: 'Email Address',
              value: employee.email,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              icon: Icons.badge_outlined,
              label: 'Employee ID',
              value: employee.id,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              icon: Icons.business_outlined,
              label: 'Department',
              value: employee.department,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              icon: Icons.work_outline,
              label: 'Position',
              value: employee.position,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmploymentDetailsCard(BuildContext context, EmployeeModel employee) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.work_outline_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Employment Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              context,
              icon: Icons.calendar_today_outlined,
              label: 'Join Date',
              value: DateFormat('MMMM d, yyyy').format(employee.joinDate),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              icon: Icons.schedule_outlined,
              label: 'Years of Experience',
              value: '${employee.yearsOfExperience} years',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              icon: Icons.people_alt_rounded,
              label: 'Manager',
              value: employee.managerId ?? 'N/A',
            ),
            if (employee.availableDays != null &&
                employee.availableDays!.isNotEmpty) ...[
              const Divider(height: 24),
              _buildInfoRow(
                context,
                icon: Icons.event_available_rounded,
                label: 'Available Days',
                value: employee.availableDays!.join(', '),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAllRequestsCard(BuildContext context, EmployeeModel employee) {
    final allRequests = <Map<String, dynamic>>[];

    // إضافة طلبات الإجازات
    for (var req in employee.leaveRequests) {
      final request = Map<String, dynamic>.from(req as Map);
      request['requestType'] = 'Leave';
      allRequests.add(request);
    }

    // إضافة طلبات المصروفات (سيتم جلبها من خدمة منفصلة في المستقبل)
    // حالياً نعرض فقط طلبات الإجازات

    // ترتيب تنازلي حسب التاريخ
    allRequests.sort((a, b) {
      final dateA = a['requestDate'] as Timestamp?;
      final dateB = b['requestDate'] as Timestamp?;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history_toggle_off_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'My Requests',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            if (allRequests.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Text(
                    'No requests submitted yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: allRequests.length,
                itemBuilder: (context, index) {
                  final request = allRequests[index];
                  final status = request['status'] as String? ?? 'Pending';
                  final Color statusColor;
                  switch (status) {
                    case 'Approved':
                      statusColor = Colors.green;
                      break;
                    case 'Rejected':
                      statusColor = Colors.red;
                      break;
                    default:
                      statusColor = Colors.orange;
                  }

                  final requestType = request['requestType'] as String;
                  final requestDate = request['requestDate'] as Timestamp?;
                  final reason = request['reason'] as String?;

                  String title = '${request['type'] ?? requestType} Request';
                  String subtitleText;
                  IconData leadingIcon;

                  if (requestType == 'Leave') {
                    leadingIcon = Icons.date_range_outlined;
                    subtitleText = 'Dates: ${request['dates'] ?? 'N/A'}';
                  } else {
                    leadingIcon = Icons.monetization_on_outlined;
                    final amount = request['amount'] as num? ?? 0;
                    subtitleText = 'Amount: EGP ${amount.toStringAsFixed(2)}';
                    title = 'Allowance Request';
                  }

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    leading: Icon(
                      leadingIcon,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(subtitleText),
                        if (reason != null && reason.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Reason: $reason',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        if (requestDate != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Requested on: ${DateFormat.yMMMd().format(requestDate.toDate())}',
                            ),
                          ),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(
                        status,
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: statusColor,
                    ),
                  );
                },
                separatorBuilder: (context, index) => const Divider(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummaryCard(
    BuildContext context,
    EmployeeModel employee,
    double netSalary,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.8),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Financial Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'NET SALARY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'EGP ${netSalary.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildFinancialDetailRow(
                icon: Icons.add_circle_outline,
                label: 'Base Salary',
                value: 'EGP ${employee.baseSalary.toStringAsFixed(2)}',
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              _buildFinancialDetailRow(
                icon: Icons.add_card_outlined,
                label: 'Allowances',
                value: '+ EGP ${employee.allowances.toStringAsFixed(2)}',
                color: Colors.greenAccent,
              ),
              const SizedBox(height: 12),
              _buildFinancialDetailRow(
                icon: Icons.remove_circle_outline,
                label: 'Deductions',
                value: '- EGP ${employee.deductions.toStringAsFixed(2)}',
                color: Colors.redAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(230),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // دوال تقديم الطلبات
  // ============================================================

  void _showVacationRequestDialog(BuildContext context) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTimeRange? selectedDateRange;
    String? leaveType = 'Annual';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Request a New Vacation',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: leaveType,
                        decoration: const InputDecoration(
                          labelText: 'Leave Type',
                        ),
                        items: ['Annual', 'Sick', 'Unpaid']
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setStateDialog(() {
                            leaveType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Vacation Dates',
                          hintText: selectedDateRange == null
                              ? 'Select date range'
                              : '${DateFormat.yMMMd().format(selectedDateRange!.start)} - ${DateFormat.yMMMd().format(selectedDateRange!.end)}',
                          suffixIcon: const Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                          ),
                        ),
                        onTap: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            setStateDialog(() {
                              selectedDateRange = picked;
                            });
                          }
                        },
                        validator: (value) => selectedDateRange == null
                            ? 'Please select a date range.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: reasonController,
                        decoration: const InputDecoration(
                          labelText: 'Reason',
                          hintText: 'e.g., Family vacation',
                        ),
                        maxLines: 2,
                        validator: (value) =>
                            value == null || value.isEmpty
                                ? 'Please provide a reason.'
                                : null,
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
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final startDate = selectedDateRange!.start;
                      final endDate = selectedDateRange!.end;
                      final requestedDays =
                          endDate.difference(startDate).inDays + 1;

                      // التحقق من الرصيد
                      if (leaveType == 'Annual') {
                        final usedAnnual = _calculateUsedLeave('Annual');
                        final remaining = _employee.annualLeaveQuota - usedAnnual;
                        if (requestedDays > remaining) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Insufficient balance! Remaining: $remaining days.',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                      } else if (leaveType == 'Sick') {
                        final usedSick = _calculateUsedLeave('Sick');
                        final remaining = _employee.sickLeaveQuota - usedSick;
                        if (requestedDays > remaining) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Insufficient balance! Remaining: $remaining days.',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                      }

                      final newRequest = {
                        'type': leaveType,
                        'reason': reasonController.text,
                        'startDate': Timestamp.fromDate(startDate),
                        'endDate': Timestamp.fromDate(endDate),
                        'dates':
                            '${DateFormat.yMMMd().format(startDate)} - ${DateFormat.yMMMd().format(endDate)}',
                        'requestDate': Timestamp.now(),
                        'status': 'Pending',
                      };

                      await FirebaseFirestore.instance
                          .collection('employees')
                          .doc(_employee.id)
                          .update({
                            'leaveRequests': FieldValue.arrayUnion([
                              newRequest,
                            ]),
                          });

                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Vacation request submitted!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // تحديث البيانات
                      _listenToEmployeeChanges();
                    }
                  },
                  child: const Text('Submit Request'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}