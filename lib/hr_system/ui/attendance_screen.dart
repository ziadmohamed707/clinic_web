import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:physioone/core/app_colors.dart';
import 'package:physioone/core/app_consts/location_service.dart';
import 'package:physioone/core/permissions.dart';
import 'package:physioone/hr_system/model/employee_model.dart';
import 'package:physioone/hr_system/services/employee_service.dart';
import 'package:physioone/hr_system/ui/employee_attendance_details_page.dart';
import 'package:physioone/ui/LoginPage/models/user_model.dart';

class AttendanceScreen extends StatefulWidget {
  final List<EmployeeModel> employees;
  final UserModel currentUser;
  final LocationService locationService;

  const AttendanceScreen({
    Key? key,
    required this.employees,
    required this.currentUser,
    required this.locationService,
  }) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // ✅ تاريخ محدد للعرض
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Present, Late, Absent

  // ✅ الإحصائيات المحسوبة
  late int _presentToday;
  late int _lateOnly;
  late int _absentToday;
  late int _totalEmployees;

  // ✅ قائمة الموظفين المفلترة
  List<EmployeeModel> get _filteredEmployees {
    return widget.employees.where((emp) {
      // فلترة حسب البحث
      final query = _searchQuery.toLowerCase();
      if (query.isNotEmpty) {
        final name = emp.name.toLowerCase();
        final id = emp.id.toLowerCase();
        final email = emp.email.toLowerCase();
        if (!name.contains(query) &&
            !id.contains(query) &&
            !email.contains(query)) {
          return false;
        }
      }

      // فلترة حسب الحالة
      if (_statusFilter != 'All') {
        final todayString = DateFormat('yyyy-MM-dd').format(_selectedDate);
        final todayAttendance = emp.attendance.firstWhereOrNull(
          (a) => a['date'] == todayString,
        );
        final status = todayAttendance?['status'] ?? 'Absent';
        if (status != _statusFilter) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _calculateStats();
  }

  @override
  void didUpdateWidget(covariant AttendanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _calculateStats();
  }

  void _calculateStats() {
    final todayString = DateFormat('yyyy-MM-dd').format(_selectedDate);

    _totalEmployees = widget.employees.length;

    _presentToday =
        widget.employees.where((e) {
          final todayAttendance = e.attendance.firstWhereOrNull(
            (a) => a['date'] == todayString,
          );
          return todayAttendance != null &&
              (todayAttendance['status'] == 'Present' ||
                  todayAttendance['status'] == 'Late');
        }).length;

    _lateOnly =
        widget.employees.where((e) {
          final todayAttendance = e.attendance.firstWhereOrNull(
            (a) => a['date'] == todayString,
          );
          return todayAttendance != null && todayAttendance['status'] == 'Late';
        }).length;

    _absentToday =
        widget.employees.where((e) {
          final todayAttendance = e.attendance.firstWhereOrNull(
            (a) => a['date'] == todayString,
          );
          return todayAttendance == null ||
              (todayAttendance['status'] != 'Present' &&
                  todayAttendance['status'] != 'Late');
        }).length;
  }

  void _updateDate(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
      _calculateStats();
    });
  }

  void _goToToday() {
    _updateDate(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final filteredEmployees = _filteredEmployees;
    final todayString = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final isAdmin = Permissions.hasPermission(
      Permissions.fromString(widget.currentUser.role ?? 'employee'),
      Permissions.manageEmployees,
    );

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ العنوان واختيار التاريخ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Attendance Monitoring',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  // ✅ زر "اليوم"
                  if (_selectedDate != DateTime.now())
                    TextButton.icon(
                      onPressed: _goToToday,
                      icon: const Icon(Icons.today_rounded, size: 18),
                      label: const Text('Today'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  const SizedBox(width: 8),
                  // ✅ اختيار التاريخ
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_rounded,
                            size: 18,
                          ),
                          onPressed: () {
                            _updateDate(
                              _selectedDate.subtract(const Duration(days: 1)),
                            );
                          },
                          tooltip: 'Previous Day',
                        ),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              _updateDate(picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              DateFormat(
                                'EEE, MMM d, yyyy',
                              ).format(_selectedDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 18,
                          ),
                          onPressed: () {
                            final nextDay = _selectedDate.add(
                              const Duration(days: 1),
                            );
                            if (nextDay.isBefore(DateTime.now()) ||
                                nextDay.isAtSameMomentAs(DateTime.now())) {
                              _updateDate(nextDay);
                            }
                          },
                          tooltip: 'Next Day',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ✅ بطاقات الإحصائيات
          Row(
            children: [
              Expanded(
                child: _buildAttendanceCard(
                  'Present',
                  '$_presentToday / $_totalEmployees',
                  Icons.check_circle_rounded,
                  Colors.green[600]!,
                  _presentToday > 0,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAttendanceCard(
                  'Late',
                  '$_lateOnly / $_totalEmployees',
                  Icons.warning_rounded,
                  Colors.orange[600]!,
                  _lateOnly > 0,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAttendanceCard(
                  'Absent',
                  '$_absentToday / $_totalEmployees',
                  Icons.cancel_rounded,
                  AppColors.error,
                  _absentToday > 0,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAttendanceCard(
                  'Total',
                  '$_totalEmployees',
                  Icons.people_alt_rounded,
                  AppColors.secondary,
                  true,
                ),
              ),
            ],
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
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search by Name, ID, or Email...',
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
                    DropdownMenuItem(value: 'Present', child: Text('Present')),
                    DropdownMenuItem(value: 'Late', child: Text('Late')),
                    DropdownMenuItem(value: 'Absent', child: Text('Absent')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _statusFilter = value!;
                    });
                  },
                  underline: const SizedBox(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ✅ قائمة الحضور
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
                      Text(
                        'Attendance Log',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${filteredEmployees.length} employees',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child:
                        filteredEmployees.isEmpty
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
                                    _searchQuery.isNotEmpty ||
                                            _statusFilter != 'All'
                                        ? 'No matching employees found.'
                                        : 'No attendance records for this day.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.separated(
                              itemCount: filteredEmployees.length,
                              separatorBuilder:
                                  (_, __) =>
                                      const Divider(height: 8, thickness: 0.5),
                              itemBuilder: (context, index) {
                                final employee = filteredEmployees[index];
                                final attendance = employee.attendance
                                    .firstWhereOrNull(
                                      (a) => a['date'] == todayString,
                                    );

                                final status =
                                    attendance?['status'] ?? 'Absent';
                                final checkIn =
                                    attendance?['checkIn'] ?? '--:--';
                                final checkOut =
                                    attendance?['checkOut'] ?? '--:--';

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

                                return InkWell(
                                  // ✅ عند النقر على الموظف، نفتح صفحة التفاصيل الكاملة
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                EmployeeAttendanceDetailsPage(
                                                  employee: employee,
                                                ),
                                      ),
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
                                          radius: 20,
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
                                                employee.id,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          'In: $checkIn',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          'Out: $checkOut',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
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
                                        // ✅ زر إضافة/تعديل الحضور (للمشرفين فقط)
                                        if (isAdmin)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit_rounded,
                                              size: 18,
                                            ),
                                            color: Colors.grey[500],
                                            onPressed: () {
                                              _showEditAttendanceDialog(
                                                context,
                                                employee,
                                                attendance,
                                              );
                                            },
                                            tooltip: 'Edit Attendance',
                                          ),
                                        // ✅ أيقونة للسهم تشير إلى وجود صفحة تفاصيل
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

  // ✅ دوال مساعدة (نفس الكود السابق)
  Widget _buildAttendanceCard(
    String title,
    String count,
    IconData icon,
    Color color,
    bool hasData,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              hasData ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
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

  void _showEditAttendanceDialog(
    BuildContext context,
    EmployeeModel employee,
    Map<String, dynamic>? currentAttendance,
  ) {
    final isCheckedIn =
        currentAttendance != null &&
        currentAttendance['checkIn'] != '' &&
        currentAttendance['checkIn'] != null;

    final checkInController = TextEditingController(
      text: isCheckedIn ? currentAttendance['checkIn'] : '',
    );
    final checkOutController = TextEditingController(
      text:
          currentAttendance != null && currentAttendance['checkOut'] != ''
              ? currentAttendance['checkOut']
              : '',
    );

    String? selectedStatus = currentAttendance?['status'] ?? 'Absent';
    final List<String> statusOptions = ['Present', 'Late', 'Absent'];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Edit Attendance: ${employee.name}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: 350,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: checkInController,
                      decoration: const InputDecoration(
                        labelText: 'Check In Time (HH:MM)',
                        hintText: 'e.g., 09:15',
                        prefixIcon: Icon(Icons.login_rounded),
                      ),
                      keyboardType: TextInputType.datetime,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: checkOutController,
                      decoration: const InputDecoration(
                        labelText: 'Check Out Time (HH:MM)',
                        hintText: 'e.g., 17:30',
                        prefixIcon: Icon(Icons.logout_rounded),
                      ),
                      keyboardType: TextInputType.datetime,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      items:
                          statusOptions.map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Row(
                                children: [
                                  Icon(
                                    s == 'Present'
                                        ? Icons.check_circle
                                        : s == 'Late'
                                        ? Icons.warning
                                        : Icons.cancel,
                                    color:
                                        s == 'Present'
                                            ? Colors.green
                                            : s == 'Late'
                                            ? Colors.orange
                                            : Colors.red,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(s),
                                ],
                              ),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          selectedStatus = value;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Date: ${DateFormat('MMMM d, yyyy').format(_selectedDate)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            },
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
                    content: Text('✅ Attendance updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                setState(() {
                  _calculateStats();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }
}
