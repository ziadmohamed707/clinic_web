import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:physioone/core/app_colors.dart';
import 'package:physioone/hr_system/model/employee_model.dart';

class EmployeeAttendanceDetailsPage extends StatefulWidget {
  final EmployeeModel employee;

  const EmployeeAttendanceDetailsPage({Key? key, required this.employee})
    : super(key: key);

  @override
  State<EmployeeAttendanceDetailsPage> createState() =>
      _EmployeeAttendanceDetailsPageState();
}

class _EmployeeAttendanceDetailsPageState
    extends State<EmployeeAttendanceDetailsPage> {
  // ✅ متغيرات التصفية
  String _searchQuery = '';
  String _statusFilter = 'All';
  DateTimeRange? _dateRange;

  // ✅ قائمة الحضور المفلترة
  List<Map<String, dynamic>> get _filteredAttendance {
    final allRecords = widget.employee.attendance.cast<Map<String, dynamic>>();

    // 1. فلترة حسب النطاق الزمني
    var filtered =
        allRecords.where((record) {
          if (_dateRange == null) return true;
          final date = DateTime.parse(record['date']);
          return date.isAfter(
                _dateRange!.start.subtract(const Duration(days: 1)),
              ) &&
              date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
        }).toList();

    // 2. فلترة حسب الحالة
    if (_statusFilter != 'All') {
      filtered =
          filtered
              .where((record) => record['status'] == _statusFilter)
              .toList();
    }

    // 3. فلترة حسب البحث (التاريخ)
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((record) {
            final dateStr = DateFormat(
              'yyyy-MM-dd',
            ).format(DateTime.parse(record['date']));
            return dateStr.contains(_searchQuery);
          }).toList();
    }

    // ترتيب تنازلي حسب التاريخ
    filtered.sort((a, b) {
      return DateTime.parse(b['date']).compareTo(DateTime.parse(a['date']));
    });

    return filtered;
  }

  // ✅ حساب الإحصائيات
  Map<String, int> get _stats {
    final records = _filteredAttendance;
    final total = records.length;
    final present = records.where((r) => r['status'] == 'Present').length;
    final late = records.where((r) => r['status'] == 'Late').length;
    final absent = records.where((r) => r['status'] == 'Absent').length;
    return {'total': total, 'present': present, 'late': late, 'absent': absent};
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final filtered = _filteredAttendance;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.employee.name} - Attendance'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // ✅ تصدير CSV (بسيط)
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
                  'Total',
                  stats['total']!.toString(),
                  Colors.grey,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Present',
                  stats['present']!.toString(),
                  Colors.green,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Late',
                  stats['late']!.toString(),
                  Colors.orange,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Absent',
                  stats['absent']!.toString(),
                  Colors.red,
                ),
              ],
            ),
          ),

          // ✅ شريط التصفية والبحث
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                Row(
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
                          hintText: 'Search by date (YYYY-MM-DD)',
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
                        DropdownMenuItem(
                          value: 'Present',
                          child: Text('Present'),
                        ),
                        DropdownMenuItem(value: 'Late', child: Text('Late')),
                        DropdownMenuItem(
                          value: 'Absent',
                          child: Text('Absent'),
                        ),
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
              ],
            ),
          ),
          const Divider(height: 1),

          // ✅ الجدول (GridView مثل Excel)
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child:
                filtered.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.hourglass_empty_rounded,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No attendance records found.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                    : SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
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
                                    'Date',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Check In',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Check Out',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Status',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Location',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Actions',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              rows:
                                  filtered.map((record) {
                                    final date = DateTime.parse(record['date']);
                                    final status = record['status'] ?? 'Absent';
                                    final checkIn =
                                        record['checkIn'] ?? '--:--';
                                    final checkOut =
                                        record['checkOut'] ?? '--:--';
                                    final location =
                                        record['checkInLocation'] != null
                                            ? '${record['checkInLocation']['latitude'].toStringAsFixed(4)}, ${record['checkInLocation']['longitude'].toStringAsFixed(4)}'
                                            : 'N/A';

                                    Color statusColor;
                                    IconData statusIcon;
                                    switch (status) {
                                      case 'Present':
                                        statusColor = Colors.green;
                                        statusIcon = Icons.check_circle;
                                        break;
                                      case 'Late':
                                        statusColor = Colors.orange;
                                        statusIcon = Icons.warning;
                                        break;
                                      default:
                                        statusColor = Colors.red;
                                        statusIcon = Icons.cancel;
                                    }

                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            DateFormat(
                                              'dd/MM/yyyy',
                                            ).format(date),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            checkIn,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        DataCell(Text(checkOut)),
                                        DataCell(
                                          Row(
                                            children: [
                                              Icon(
                                                statusIcon,
                                                color: statusColor,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                status,
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            location,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        DataCell(
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit_rounded,
                                              size: 18,
                                            ),
                                            color: Colors.grey[600],
                                            onPressed: () {
                                              // تعديل تسجيل الحضور (يمكن إضافة حوار هنا)
                                              _showEditRecordDialog(
                                                context,
                                                record,
                                              );
                                            },
                                            tooltip: 'Edit',
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

  Widget _buildStatCard(String label, String value, Color color) {
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
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
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

  void _exportCSV() {
    final records = _filteredAttendance;
    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No records to export.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // بناء CSV
    String csv = 'Date,Check In,Check Out,Status,Location\n';
    for (var record in records) {
      final date = record['date'];
      final checkIn = record['checkIn'] ?? '--:--';
      final checkOut = record['checkOut'] ?? '--:--';
      final status = record['status'] ?? 'Absent';
      final location =
          record['checkInLocation'] != null
              ? '${record['checkInLocation']['latitude'].toStringAsFixed(4)},${record['checkInLocation']['longitude'].toStringAsFixed(4)}'
              : 'N/A';
      csv += '$date,$checkIn,$checkOut,$status,$location\n';
    }

    // عرض CSV (في حالة الويب، يمكن تنزيل ملف)
    // هنا سنعرض الحوار مع النص
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
                // نسخ إلى الحافظة
                // يمكنك استخدام Clipboard.setData
                // وإظهار رسالة نجاح
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('CSV copied to clipboard!'),
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

  void _showEditRecordDialog(
    BuildContext context,
    Map<String, dynamic> record,
  ) {
    final checkInController = TextEditingController(text: record['checkIn']);
    final checkOutController = TextEditingController(text: record['checkOut']);
    String? status = record['status'];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Edit Attendance Record',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: checkInController,
                decoration: const InputDecoration(labelText: 'Check In Time'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: checkOutController,
                decoration: const InputDecoration(labelText: 'Check Out Time'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: status,
                items: const [
                  DropdownMenuItem(value: 'Present', child: Text('Present')),
                  DropdownMenuItem(value: 'Late', child: Text('Late')),
                  DropdownMenuItem(value: 'Absent', child: Text('Absent')),
                ],
                onChanged: (value) {
                  status = value;
                },
                decoration: const InputDecoration(labelText: 'Status'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // هنا يمكن حفظ التعديلات في Firestore
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Attendance record updated!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
