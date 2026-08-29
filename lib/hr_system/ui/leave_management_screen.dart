import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'
    show Timestamp, FieldValue, FirebaseFirestore;
import 'package:physioone/core/app_colors.dart';
import 'package:physioone/core/permissions.dart';
import 'package:physioone/hr_system/model/employee_model.dart';
import 'package:physioone/hr_system/services/employee_service.dart';
import 'package:physioone/ui/LoginPage/models/user_model.dart';

class LeaveManagementScreen extends StatefulWidget {
  final List<EmployeeModel> employees;
  final UserModel currentUser;

  const LeaveManagementScreen({
    super.key,
    required this.employees,
    required this.currentUser,
  });

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  final EmployeeService employeeService = EmployeeService();
  final TextEditingController _searchController = TextEditingController();

  // ✅ متغيرات التصفية
  String _statusFilter = 'All';
  String _searchQuery = '';
  DateTimeRange? _dateRange;

  // ✅ دور المستخدم الحالي
  late UserRole _currentUserRole;

  // ✅ قائمة الموظفين المفلترة حسب الصلاحية
  List<EmployeeModel> get _filteredEmployees {
    final currentUserId = widget.currentUser.id ?? '';

    switch (_currentUserRole) {
      case UserRole.admin:
      case UserRole.hrManager:
        return widget.employees;
      case UserRole.departmentManager:
        return widget.employees
            .where(
              (emp) =>
                  emp.id == currentUserId || emp.managerId == currentUserId,
            )
            .toList();
      case UserRole.employee:
        return widget.employees
            .where((emp) => emp.id == currentUserId)
            .toList();
      default:
        return [];
    }
  }

  // ✅ قائمة طلبات الإجازات المفلترة
  List<Map<String, dynamic>> get _filteredRequests {
    final allRequests = <Map<String, dynamic>>[];

    for (var emp in _filteredEmployees) {
      for (var request in emp.leaveRequests) {
        final req = Map<String, dynamic>.from(request);
        req['employee'] = emp;
        allRequests.add(req);
      }
    }

    // 1. فلترة حسب البحث
    if (_searchQuery.isNotEmpty) {
      allRequests.removeWhere((req) {
        final name = (req['employee'] as EmployeeModel).name.toLowerCase();
        final type = (req['type'] as String? ?? '').toLowerCase();
        final dates = (req['dates'] as String? ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return !name.contains(query) &&
            !type.contains(query) &&
            !dates.contains(query);
      });
    }

    // 2. فلترة حسب الحالة
    if (_statusFilter != 'All') {
      allRequests.removeWhere((req) {
        final status = req['status'] as String? ?? 'Pending';
        return status != _statusFilter;
      });
    }

    // 3. فلترة حسب التاريخ
    if (_dateRange != null) {
      allRequests.removeWhere((req) {
        final requestDate = (req['requestDate'] as Timestamp?)?.toDate();
        if (requestDate == null) return true;
        return !requestDate.isAfter(
              _dateRange!.start.subtract(const Duration(days: 1)),
            ) ||
            !requestDate.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      });
    }

    // ترتيب تنازلي حسب تاريخ الطلب
    allRequests.sort((a, b) {
      final dateA =
          (a['requestDate'] as Timestamp?)?.toDate() ?? DateTime.now();
      final dateB =
          (b['requestDate'] as Timestamp?)?.toDate() ?? DateTime.now();
      return dateB.compareTo(dateA);
    });

    return allRequests;
  }

  // ✅ حساب الإحصائيات
  Map<String, dynamic> _calculateStats() {
    final requests = _filteredRequests;
    final total = requests.length;
    final pending = requests.where((r) => r['status'] == 'Pending').length;
    final approved = requests.where((r) => r['status'] == 'Approved').length;
    final rejected = requests.where((r) => r['status'] == 'Rejected').length;
    final cancelled = requests.where((r) => r['status'] == 'Cancelled').length;

    // حساب الإجازات المستخدمة للموظف الحالي (إذا كان موظفاً عادياً)
    int usedAnnual = 0;
    int usedSick = 0;
    int usedUnpaid = 0;

    if (_currentUserRole == UserRole.employee ||
        _currentUserRole == UserRole.departmentManager) {
      final currentEmployee = widget.employees.firstWhereOrNull(
        (emp) => emp.id == widget.currentUser.id,
      );
      if (currentEmployee != null) {
        usedAnnual = _calculateUsedLeave(currentEmployee, 'Annual');
        usedSick = _calculateUsedLeave(currentEmployee, 'Sick');
        usedUnpaid = _calculateUsedLeave(currentEmployee, 'Unpaid');
      }
    }

    return {
      'total': total,
      'pending': pending,
      'approved': approved,
      'rejected': rejected,
      'cancelled': cancelled,
      'usedAnnual': usedAnnual,
      'usedSick': usedSick,
      'usedUnpaid': usedUnpaid,
    };
  }

  int _calculateUsedLeave(EmployeeModel employee, String type) {
    int usedDays = 0;
    for (var request in employee.leaveRequests) {
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

  Map<String, dynamic> _calculateLeaveBalances(EmployeeModel employee) {
    final usedAnnual = _calculateUsedLeave(employee, 'Annual');
    final usedSick = _calculateUsedLeave(employee, 'Sick');
    final usedUnpaid = _calculateUsedLeave(employee, 'Unpaid');
    final remainingAnnual = employee.annualLeaveQuota - usedAnnual;
    final remainingSick = employee.sickLeaveQuota - usedSick;
    final totalUsed = usedAnnual + usedSick + usedUnpaid;

    return {
      'usedAnnual': usedAnnual,
      'usedSick': usedSick,
      'usedUnpaid': usedUnpaid,
      'remainingAnnual': remainingAnnual,
      'remainingSick': remainingSick,
      'totalUsed': totalUsed,
      'totalQuota': employee.annualLeaveQuota + employee.sickLeaveQuota,
    };
  }

  // ✅ التحقق من صلاحية الموافقة
  bool _canApprove() {
    return Permissions.hasPermission(
      _currentUserRole,
      Permissions.approveLeave,
    );
  }

  @override
  void initState() {
    super.initState();
    _currentUserRole = Permissions.fromString(
      widget.currentUser.role ?? 'employee',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showApplyLeaveDialog(BuildContext context, EmployeeModel employee) {
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
                        items:
                            ['Annual', 'Sick', 'Unpaid']
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
                          hintText:
                              selectedDateRange == null
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
                        validator:
                            (value) =>
                                selectedDateRange == null
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
                        validator:
                            (value) =>
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

                      if (leaveType == 'Annual') {
                        final usedAnnual = _calculateUsedLeave(
                          employee,
                          'Annual',
                        );
                        final remaining =
                            employee.annualLeaveQuota - usedAnnual;
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
                        final usedSick = _calculateUsedLeave(employee, 'Sick');
                        final remaining = employee.sickLeaveQuota - usedSick;
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
                          .doc(employee.id)
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

  void _updateLeaveStatus(
    BuildContext context,
    EmployeeModel employee,
    Map<String, dynamic> requestToUpdate,
    String newStatus,
  ) async {
    try {
      if (newStatus == 'Approved') {
        final leaveType = requestToUpdate['type'] as String?;
        final startDate = (requestToUpdate['startDate'] as Timestamp).toDate();
        final endDate = (requestToUpdate['endDate'] as Timestamp).toDate();
        final requestedDays = endDate.difference(startDate).inDays + 1;

        if (leaveType == 'Annual') {
          final usedAnnual = _calculateUsedLeave(employee, 'Annual');
          final remaining = employee.annualLeaveQuota - usedAnnual;
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
          final usedSick = _calculateUsedLeave(employee, 'Sick');
          final remaining = employee.sickLeaveQuota - usedSick;
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
      }

      final updatedLeaveRequests = List<Map<String, dynamic>>.from(
        employee.leaveRequests,
      );
      final requestIndex = updatedLeaveRequests.indexWhere(
        (req) => req['requestDate'] == requestToUpdate['requestDate'],
      );

      if (requestIndex != -1) {
        updatedLeaveRequests[requestIndex]['status'] = newStatus;
        final updatedEmployee = employee.copyWith(
          leaveRequests: updatedLeaveRequests,
        );
        await employeeService.updateEmployee(updatedEmployee);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Leave request has been $newStatus.'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to update leave status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentEmployee = widget.employees.firstWhereOrNull(
      (emp) => emp.id == widget.currentUser.id,
    );

    final stats = _calculateStats();
    final filteredRequests = _filteredRequests;

    // ✅ حساب أرصدة الموظف الحالي
    final balances =
        currentEmployee != null
            ? _calculateLeaveBalances(currentEmployee)
            : {
              'usedAnnual': 0,
              'usedSick': 0,
              'usedUnpaid': 0,
              'remainingAnnual': 15,
              'remainingSick': 7,
              'totalUsed': 0,
              'totalQuota': 22,
            };

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ العنوان وزر التقديم
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Leave Management',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              // ✅ زر تقديم إجازة (يظهر للجميع)
              ElevatedButton.icon(
                onPressed: () {
                  if (currentEmployee != null) {
                    _showApplyLeaveDialog(context, currentEmployee);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Employee record not found.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Apply Leave'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ✅ بطاقات الإحصائيات
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Pending',
                  stats['pending'].toString(),
                  Icons.hourglass_top_rounded,
                  Colors.orange[600]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Approved',
                  stats['approved'].toString(),
                  Icons.check_circle_rounded,
                  Colors.green[600]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Rejected',
                  stats['rejected'].toString(),
                  Icons.cancel_rounded,
                  AppColors.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total',
                  stats['total'].toString(),
                  Icons.receipt_long_rounded,
                  AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ✅ أرصدة الإجازات للموظف الحالي
          if (_currentUserRole == UserRole.employee ||
              _currentUserRole == UserRole.departmentManager)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_note_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Leave Balance',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildBalanceChip(
                              'Annual',
                              '${balances['remainingAnnual']}',
                              Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            _buildBalanceChip(
                              'Sick',
                              '${balances['remainingSick']}',
                              Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            _buildBalanceChip(
                              'Used',
                              '${balances['totalUsed']}',
                              Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // ✅ شريط البحث والتصفية
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
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search by employee, type, or dates...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  ),
                Container(
                  height: 30,
                  width: 1,
                  color: Colors.grey.withOpacity(0.2),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                DropdownButton<String>(
                  value: _statusFilter,
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(
                      value: 'Approved',
                      child: Text('Approved'),
                    ),
                    DropdownMenuItem(
                      value: 'Rejected',
                      child: Text('Rejected'),
                    ),
                    DropdownMenuItem(
                      value: 'Cancelled',
                      child: Text('Cancelled'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _statusFilter = value!;
                    });
                  },
                  underline: const SizedBox(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _dateRange == null
                        ? Icons.filter_alt_outlined
                        : Icons.filter_alt_rounded,
                    color:
                        _dateRange == null
                            ? Colors.grey[400]
                            : AppColors.primary,
                    size: 20,
                  ),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      initialDateRange: _dateRange,
                    );
                    if (picked != null) {
                      setState(() {
                        _dateRange = picked;
                      });
                    } else if (_dateRange != null) {
                      setState(() {
                        _dateRange = null;
                      });
                    }
                  },
                  tooltip: 'Filter by date',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ✅ قائمة طلبات الإجازات
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Leave Requests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${filteredRequests.length} requests',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child:
                        filteredRequests.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_note_outlined,
                                    size: 60,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty ||
                                            _statusFilter != 'All' ||
                                            _dateRange != null
                                        ? 'No matching leave requests found.'
                                        : 'No leave requests submitted yet.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (_searchQuery.isNotEmpty ||
                                      _statusFilter != 'All' ||
                                      _dateRange != null)
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = '';
                                          _searchController.clear();
                                          _statusFilter = 'All';
                                          _dateRange = null;
                                        });
                                      },
                                      child: const Text('Clear Filters'),
                                    ),
                                ],
                              ),
                            )
                            : ListView.separated(
                              itemCount: filteredRequests.length,
                              separatorBuilder:
                                  (_, __) =>
                                      const Divider(height: 8, thickness: 0.5),
                              itemBuilder: (context, index) {
                                final request = filteredRequests[index];
                                final employee =
                                    request['employee'] as EmployeeModel;
                                final status =
                                    request['status'] as String? ?? 'Pending';
                                final reason = request['reason'] as String?;
                                final dates =
                                    request['dates'] as String? ?? 'N/A';
                                final type =
                                    request['type'] as String? ?? 'Leave';
                                final requestDate =
                                    (request['requestDate'] as Timestamp?)
                                        ?.toDate();

                                Color statusColor;
                                IconData statusIcon;
                                switch (status) {
                                  case 'Approved':
                                    statusColor = Colors.green;
                                    statusIcon = Icons.check_circle;
                                    break;
                                  case 'Pending':
                                    statusColor = Colors.orange;
                                    statusIcon = Icons.hourglass_top;
                                    break;
                                  case 'Rejected':
                                    statusColor = Colors.red;
                                    statusIcon = Icons.cancel;
                                    break;
                                  case 'Cancelled':
                                    statusColor = Colors.grey;
                                    statusIcon = Icons.remove_circle;
                                    break;
                                  default:
                                    statusColor = Colors.grey;
                                    statusIcon = Icons.help;
                                }

                                final isOwnRequest =
                                    employee.id == widget.currentUser.id;
                                final canApprove =
                                    _canApprove() && status == 'Pending';

                                return InkWell(
                                  onTap: () {
                                    _showLeaveDetailsDialog(
                                      context,
                                      request,
                                      employee,
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: AppColors.primary
                                              .withOpacity(0.1),
                                          child: Text(
                                            employee.name.isNotEmpty
                                                ? employee.name[0]
                                                : '?',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                employee.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '$type • $dates',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              if (reason != null &&
                                                  reason.isNotEmpty)
                                                Text(
                                                  reason,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontStyle: FontStyle.italic,
                                                    color: Colors.grey[500],
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                statusIcon,
                                                size: 14,
                                                color: statusColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                status,
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // ✅ أزرار الموافقة والرفض (للمخوّلين فقط)
                                        if (canApprove) ...[
                                          const SizedBox(width: 4),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.check_rounded,
                                              size: 18,
                                            ),
                                            color: Colors.green[600],
                                            onPressed:
                                                () => _updateLeaveStatus(
                                                  context,
                                                  employee,
                                                  request,
                                                  'Approved',
                                                ),
                                            tooltip: 'Approve',
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              size: 18,
                                            ),
                                            color: AppColors.error,
                                            onPressed:
                                                () => _updateLeaveStatus(
                                                  context,
                                                  employee,
                                                  request,
                                                  'Rejected',
                                                ),
                                            tooltip: 'Reject',
                                          ),
                                        ],
                                        // ✅ زر إلغاء الطلب (للموظف نفسه فقط)
                                        if (isOwnRequest && status == 'Pending')
                                          IconButton(
                                            icon: const Icon(
                                              Icons.cancel_outlined,
                                              size: 18,
                                            ),
                                            color: Colors.grey[500],
                                            onPressed:
                                                () => _updateLeaveStatus(
                                                  context,
                                                  employee,
                                                  request,
                                                  'Cancelled',
                                                ),
                                            tooltip: 'Cancel Request',
                                          ),
                                        Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 14,
                                          color: Colors.grey[400],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
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

  // ============================================================
  // دوال مساعدة
  // ============================================================

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              value == '0'
                  ? Colors.grey.withOpacity(0.1)
                  : color.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showLeaveDetailsDialog(
    BuildContext context,
    Map<String, dynamic> request,
    EmployeeModel employee,
  ) {
    final status = request['status'] as String? ?? 'Pending';
    final type = request['type'] as String? ?? 'Leave';
    final dates = request['dates'] as String? ?? 'N/A';
    final reason = request['reason'] as String?;
    final requestDate = (request['requestDate'] as Timestamp?)?.toDate();

    Color statusColor;
    switch (status) {
      case 'Approved':
        statusColor = Colors.green;
        break;
      case 'Pending':
        statusColor = Colors.orange;
        break;
      case 'Rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  'Leave Details',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Employee', employee.name),
              _buildDetailRow('Type', type),
              _buildDetailRow('Dates', dates),
              if (requestDate != null)
                _buildDetailRow(
                  'Requested On',
                  DateFormat('MMMM d, yyyy h:mm a').format(requestDate),
                ),
              if (reason != null && reason.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reason:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reason,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
