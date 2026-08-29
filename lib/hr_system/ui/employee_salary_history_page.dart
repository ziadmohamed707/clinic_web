import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:physioone/core/app_colors.dart';
import 'package:physioone/hr_system/model/employee_model.dart';

class EmployeeSalaryHistoryPage extends StatefulWidget {
  final EmployeeModel employee;

  const EmployeeSalaryHistoryPage({
    Key? key,
    required this.employee,
  }) : super(key: key);

  @override
  State<EmployeeSalaryHistoryPage> createState() =>
      _EmployeeSalaryHistoryPageState();
}

class _EmployeeSalaryHistoryPageState
    extends State<EmployeeSalaryHistoryPage> {
  // ✅ متغيرات التصفية
  String _searchQuery = '';
  DateTimeRange? _dateRange;
  String _statusFilter = 'All';

  // ✅ قائمة تاريخ الرواتب
  List<Map<String, dynamic>> get _filteredHistory {
    // محاكاة تاريخ الرواتب (في التطبيق الحقيقي، ستجلب من Firestore)
    final allRecords = _generateMockSalaryHistory();

    // 1. فلترة حسب النطاق الزمني
    var filtered = allRecords.where((record) {
      if (_dateRange == null) return true;
      final date = DateTime.parse(record['date']);
      return date.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
          date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
    }).toList();

    // 2. فلترة حسب الحالة
    if (_statusFilter != 'All') {
      filtered = filtered
          .where((record) => record['status'] == _statusFilter)
          .toList();
    }

    // 3. فلترة حسب البحث
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((record) {
        final month = record['month'] as String;
        final dateStr = record['date'] as String;
        return month.contains(_searchQuery) || dateStr.contains(_searchQuery);
      }).toList();
    }

    // ترتيب تنازلي حسب التاريخ
    filtered.sort((a, b) {
      return DateTime.parse(b['date']).compareTo(DateTime.parse(a['date']));
    });

    return filtered;
  }

  // ✅ حساب الإحصائيات
  Map<String, dynamic> get _stats {
    final records = _filteredHistory;
    final total = records.length;
    final totalSalary = records.fold(
      0.0,
      (sum, r) => sum + (r['netSalary'] as double),
    );
    final avgSalary = total > 0 ? totalSalary / total : 0;
    final statusCounts = {
      'Generated': records.where((r) => r['status'] == 'Generated').length,
      'Pending': records.where((r) => r['status'] == 'Pending').length,
    };

    return {
      'total': total,
      'totalSalary': totalSalary,
      'avgSalary': avgSalary,
      'generated': statusCounts['Generated'],
      'pending': statusCounts['Pending'],
    };
  }

  // ✅ توليد بيانات تاريخية وهمية (يمكن استبدالها ببيانات حقيقية من Firestore)
  List<Map<String, dynamic>> _generateMockSalaryHistory() {
    final List<Map<String, dynamic>> history = [];
    final now = DateTime.now();

    for (int i = 0; i < 12; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      final baseSalary = widget.employee.baseSalary;
      final allowances = widget.employee.allowances;
      final deductions = widget.employee.deductions;
      final netSalary = baseSalary + allowances - deductions;
      final status = i < 3 ? 'Generated' : 'Pending';

      history.add({
        'id': 'SAL-${DateFormat('yyyyMM').format(date)}-${widget.employee.id}',
        'month': DateFormat('MMMM yyyy').format(date),
        'date': date.toIso8601String(),
        'baseSalary': baseSalary.toDouble(),
        'allowances': allowances.toDouble(),
        'deductions': deductions.toDouble(),
        'netSalary': netSalary.toDouble(),
        'status': status,
        'payslipUrl': status == 'Generated'
            ? 'payslip_${widget.employee.id}_${DateFormat('yyyyMM').format(date)}.pdf'
            : null,
      });
    }

    return history;
  }

  @override
  Widget build(BuildContext context) {
    final employee = widget.employee;
    final stats = _stats;
    final filtered = _filteredHistory;

    return Scaffold(
      appBar: AppBar(
        title: Text('${employee.name} - Salary History'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () => _exportCSV(),
            tooltip: 'Export CSV',
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ بطاقات الإحصائيات
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              children: [
                _buildStatCard(
                  'Total Entries',
                  stats['total'].toString(),
                  Icons.receipt_long_rounded,
                  Colors.grey,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Total Paid',
                  'EGP ${(stats['totalSalary'] as double).toStringAsFixed(0)}',
                  Icons.paid_rounded,
                  Colors.green[600]!,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Average',
                  'EGP ${(stats['avgSalary'] as double).toStringAsFixed(0)}',
                  Icons.trending_up_rounded,
                  AppColors.primary,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Generated',
                  '${stats['generated']}',
                  Icons.check_circle_rounded,
                  Colors.blue,
                ),
              ],
            ),
          ),

          // ✅ شريط التصفية والبحث
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // ✅ البحث
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search by month or year...',
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
                // ✅ تصفية الحالة
                DropdownButton<String>(
                  value: _statusFilter,
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'Generated', child: Text('Generated')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
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
                const SizedBox(width: 12),
                // ✅ نطاق التاريخ
                TextButton.icon(
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
                    }
                  },
                  icon: const Icon(Icons.date_range_rounded),
                  label: Text(
                    _dateRange == null
                        ? 'All Dates'
                        : '${DateFormat('dd/MM/yy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yy').format(_dateRange!.end)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    backgroundColor: AppColors.primary.withOpacity(0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                if (_dateRange != null)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      setState(() {
                        _dateRange = null;
                      });
                    },
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ✅ جدول تاريخ الرواتب (مثل Excel)
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.hourglass_empty_rounded,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No salary records found.',
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
                        columnSpacing: 20,
                        headingRowColor: MaterialStateProperty.all(
                          AppColors.primary.withOpacity(0.05),
                        ),
                        dataRowMaxHeight: 48,
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Month',
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
                        rows: filtered.map((record) {
                          final status = record['status'] as String;
                          final statusColor = status == 'Generated'
                              ? Colors.green
                              : Colors.orange;

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  record['month'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  'EGP ${(record['baseSalary'] as double).toStringAsFixed(0)}',
                                ),
                              ),
                              DataCell(
                                Text(
                                  'EGP ${(record['allowances'] as double).toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  'EGP ${(record['deductions'] as double).toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  'EGP ${(record['netSalary'] as double).toStringAsFixed(0)}',
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
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (record['payslipUrl'] != null)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.picture_as_pdf_rounded,
                                          size: 18,
                                        ),
                                        color: Colors.red[700],
                                        onPressed: () {
                                          // عرض كشف الراتب (يمكن فتح PDF)
                                          _showPayslipDialog(
                                            context,
                                            record,
                                          );
                                        },
                                        tooltip: 'View Payslip',
                                      ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.info_outline_rounded,
                                        size: 18,
                                      ),
                                      color: Colors.grey[600],
                                      onPressed: () {
                                        _showSalaryDetailsDialog(
                                          context,
                                          record,
                                        );
                                      },
                                      tooltip: 'Details',
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
        ],
      ),
    );
  }

  // ============================================================
  // دوال مساعدة
  // ============================================================

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showSalaryDetailsDialog(
    BuildContext context,
    Map<String, dynamic> record,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Salary Details - ${record['month']}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Month', record['month']),
              _buildDetailRow(
                'Base Salary',
                'EGP ${(record['baseSalary'] as double).toStringAsFixed(0)}',
              ),
              _buildDetailRow(
                'Allowances',
                'EGP ${(record['allowances'] as double).toStringAsFixed(0)}',
              ),
              _buildDetailRow(
                'Deductions',
                'EGP ${(record['deductions'] as double).toStringAsFixed(0)}',
              ),
              const Divider(),
              _buildDetailRow(
                'Net Salary',
                'EGP ${(record['netSalary'] as double).toStringAsFixed(0)}',
                isBold: true,
              ),
              _buildDetailRow('Status', record['status']),
              if (record['payslipUrl'] != null)
                _buildDetailRow('Payslip', record['payslipUrl']),
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

  void _showPayslipDialog(BuildContext context, Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Payslip Preview',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Container(
            width: 400,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ شعار العيادة وبياناتها
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.medical_services_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Physio One Clinic',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Employee Payslip',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                // ✅ تفاصيل الراتب
                _buildDetailRow('Employee', widget.employee.name),
                _buildDetailRow('Employee ID', widget.employee.id),
                _buildDetailRow('Month', record['month']),
                _buildDetailRow(
                  'Net Salary',
                  'EGP ${(record['netSalary'] as double).toStringAsFixed(0)}',
                  isBold: true,
                ),
                const Divider(),
                const Text(
                  'This is a computer-generated payslip.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // تحميل PDF (يمكن إضافة logic هنا)
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payslip downloaded!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Download PDF'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _exportCSV() {
    final records = _filteredHistory;
    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No records to export.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String csv = 'Month,Base Salary,Allowances,Deductions,Net Salary,Status\n';
    for (var record in records) {
      csv +=
          '${record['month']},${record['baseSalary']},${record['allowances']},${record['deductions']},${record['netSalary']},${record['status']}\n';
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Export CSV'),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(
              child: SelectableText(
                csv,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('CSV exported successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copy to Clipboard'),
            ),
          ],
        );
      },
    );
  }
}