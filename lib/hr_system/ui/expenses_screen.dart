import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:physioone/core/app_colors.dart';
import 'package:physioone/core/permissions.dart';
import 'package:physioone/hr_system/model/employee_model.dart';
import 'package:physioone/hr_system/model/expense_request_model.dart';
import 'package:physioone/hr_system/services/expense_service.dart';
import 'package:physioone/ui/LoginPage/models/user_model.dart';
import 'expense_request_dialog.dart';

class ExpensesScreen extends StatefulWidget {
  final List<EmployeeModel> employees;
  final UserModel currentUser;

  const ExpensesScreen({
    Key? key,
    required this.employees,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final ExpenseService _expenseService = ExpenseService();
  List<ExpenseRequest> _expenses = [];
  bool _isLoading = true;
  String _statusFilter = 'All';
  String _searchQuery = '';

  late UserRole _currentUserRole;
  late List<String> _managedEmployeeIds;

  @override
  void initState() {
    super.initState();
    _currentUserRole = Permissions.fromString(widget.currentUser.role ?? 'employee');
    _managedEmployeeIds = _getManagedEmployeeIds();
    _listenToExpenses();
  }

  List<String> _getManagedEmployeeIds() {
    final currentUserId = widget.currentUser.id ?? '';
    switch (_currentUserRole) {
      case UserRole.admin:
      case UserRole.hrManager:
        return widget.employees.map((e) => e.id).toList();
      case UserRole.departmentManager:
        return widget.employees
            .where((e) => e.id == currentUserId || e.managerId == currentUserId)
            .map((e) => e.id)
            .toList();
      case UserRole.employee:
        return [currentUserId];
      default:
        return [];
    }
  }

  void _listenToExpenses() {
    setState(() => _isLoading = true);

    Stream<List<ExpenseRequest>> stream;

    switch (_currentUserRole) {
      case UserRole.admin:
      case UserRole.hrManager:
        stream = _expenseService.getAllExpensesStream();
        break;
      case UserRole.departmentManager:
        stream = _expenseService.getExpensesByManagerStream(_managedEmployeeIds);
        break;
      case UserRole.employee:
        stream = _expenseService.getExpensesStream(widget.currentUser.id!);
        break;
      default:
        stream = Stream.value([]);
    }

    stream.listen((expenses) {
      setState(() {
        _expenses = expenses;
        _isLoading = false;
      });
    }, onError: (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading expenses: $e'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  List<ExpenseRequest> get _filteredExpenses {
    var list = _expenses;

    if (_statusFilter != 'All') {
      list = list.where((e) => e.status == _statusFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((e) {
        final name = e.employeeName.toLowerCase();
        final desc = e.description.toLowerCase();
        final type = e.type.displayName.toLowerCase();
        return name.contains(query) ||
            desc.contains(query) ||
            type.contains(query);
      }).toList();
    }

    return list;
  }

  bool _canApprove() {
    return Permissions.hasPermission(_currentUserRole, Permissions.approveExpense);
  }

  bool _canSubmit() {
    return _currentUserRole == UserRole.employee ||
        _currentUserRole == UserRole.departmentManager;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredExpenses;
    final stats = _calculateStats(filtered);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Expense Requests'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_canSubmit())
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () {
                final currentEmployee = widget.employees.firstWhereOrNull(
                  (e) => e.id == widget.currentUser.id,
                );
                if (currentEmployee != null) {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => ExpenseRequestDialog(
                      currentEmployee: currentEmployee,
                      onSubmitted: () => _listenToExpenses(),
                    ),
                  );
                }
              },
              tooltip: 'New Request',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ إحصائيات سريعة
            Row(
              children: [
                _buildStatCard('Total', stats['total'].toString(), Colors.grey),
                const SizedBox(width: 12),
                _buildStatCard('Pending', stats['pending'].toString(), Colors.orange),
                const SizedBox(width: 12),
                _buildStatCard('Approved', stats['approved'].toString(), Colors.green),
                const SizedBox(width: 12),
                _buildStatCard('Rejected', stats['rejected'].toString(), Colors.red),
              ],
            ),
            const SizedBox(height: 16),

            // ✅ شريط البحث والتصفية
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search by employee, type, or description...',
                      prefixIcon: Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _statusFilter,
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'Approved', child: Text('Approved')),
                    DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _statusFilter = value!;
                    });
                  },
                  underline: const SizedBox(),
                  style: const TextStyle(color: Colors.black),
                  dropdownColor: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ✅ قائمة الطلبات
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty || _statusFilter != 'All'
                                    ? 'No matching requests found.'
                                    : 'No expense requests yet.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (_canSubmit())
                                TextButton(
                                  onPressed: () {
                                    final currentEmployee = widget.employees
                                        .firstWhereOrNull(
                                          (e) => e.id == widget.currentUser.id,
                                        );
                                    if (currentEmployee != null) {
                                      showDialog(
                                        context: context,
                                        builder: (dialogContext) =>
                                            ExpenseRequestDialog(
                                              currentEmployee: currentEmployee,
                                              onSubmitted: () => _listenToExpenses(),
                                            ),
                                      );
                                    }
                                  },
                                  child: const Text('Submit a new request'),
                                ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 8,
                            thickness: 0.5,
                          ),
                          itemBuilder: (context, index) {
                            final request = filtered[index];
                            final isPending = request.status == 'Pending';
                            final isOwn = request.employeeId == widget.currentUser.id;
                            final canApprove = _canApprove() && isPending;

                            Color statusColor;
                            IconData statusIcon;
                            switch (request.status) {
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
                              default:
                                statusColor = Colors.grey;
                                statusIcon = Icons.help;
                            }

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isPending
                                      ? Colors.orange.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // ✅ أيقونة النوع
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _getIconForType(request.type),
                                      size: 24,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // ✅ المعلومات
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          request.employeeName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${request.type.displayName} • EGP ${request.amount.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        if (request.description.isNotEmpty)
                                          Text(
                                            request.description,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        Text(
                                          DateFormat('MMM d, yyyy').format(
                                            request.requestDate,
                                          ),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // ✅ الحالة
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          statusIcon,
                                          size: 14,
                                          color: statusColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          request.status,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // ✅ أزرار الإجراءات
                                  if (canApprove) ...[
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.check_rounded,
                                        size: 18,
                                      ),
                                      color: Colors.green[600],
                                      onPressed: () => _approveExpense(
                                        context,
                                        request.id,
                                      ),
                                      tooltip: 'Approve',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                      ),
                                      color: AppColors.error,
                                      onPressed: () => _rejectExpense(
                                        context,
                                        request.id,
                                      ),
                                      tooltip: 'Reject',
                                    ),
                                  ],
                                  if (isOwn && isPending)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                      ),
                                      color: Colors.grey[500],
                                      onPressed: () => _deleteExpense(
                                        context,
                                        request.id,
                                      ),
                                      tooltip: 'Cancel Request',
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // دوال مساعدة
  // ============================================================

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value == '0' ? Colors.grey.withOpacity(0.1) : color.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
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
    );
  }

  Map<String, int> _calculateStats(List<ExpenseRequest> requests) {
    return {
      'total': requests.length,
      'pending': requests.where((e) => e.status == 'Pending').length,
      'approved': requests.where((e) => e.status == 'Approved').length,
      'rejected': requests.where((e) => e.status == 'Rejected').length,
    };
  }

  IconData _getIconForType(ExpenseType type) {
    switch (type) {
      case ExpenseType.transport:
        return Icons.directions_car_rounded;
      case ExpenseType.advance:
        return Icons.money_rounded;
      case ExpenseType.medical:
        return Icons.medical_services_rounded;
      case ExpenseType.other:
        return Icons.more_horiz_rounded;
    }
  }

  void _approveExpense(BuildContext context, String expenseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve Expense Request'),
        content: const Text('Are you sure you want to approve this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _expenseService.approveExpense(expenseId, widget.currentUser.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Expense approved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _listenToExpenses();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to approve: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _rejectExpense(BuildContext context, String expenseId) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Expense Request'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Rejection Reason',
              hintText: 'Please provide a reason for rejection',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            validator: (value) =>
                value == null || value.isEmpty ? 'Please provide a reason' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _expenseService.rejectExpense(expenseId, reasonController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Expense rejected.'),
            backgroundColor: Colors.orange,
          ),
        );
        _listenToExpenses();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to reject: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteExpense(BuildContext context, String expenseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text(
          'Are you sure you want to cancel this request? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _expenseService.deleteExpense(expenseId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Request cancelled successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        _listenToExpenses();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to cancel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}