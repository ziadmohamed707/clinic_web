import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:physioone/core/app_colors.dart';
import 'package:physioone/hr_system/model/employee_model.dart';

class DashboardScreen extends StatelessWidget {
  final List<EmployeeModel> employees;
  const DashboardScreen({Key? key, required this.employees}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalEmployees = employees.length;
    final today = DateTime.now();
    final todayString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // ✅ تصحيح الإحصائيات - استخدام اليوم فقط
    final presentToday =
        employees.where((e) {
          final todayAttendance = e.attendance.firstWhereOrNull(
            (a) => a['date'] == todayString,
          );
          return todayAttendance != null &&
              (todayAttendance['status'] == 'Present' ||
                  todayAttendance['status'] == 'Late');
        }).length;

    final lateOnly =
        employees.where((e) {
          final todayAttendance = e.attendance.firstWhereOrNull(
            (a) => a['date'] == todayString,
          );
          return todayAttendance != null && todayAttendance['status'] == 'Late';
        }).length;

    final absentToday =
        employees.where((e) {
          final todayAttendance = e.attendance.firstWhereOrNull(
            (a) => a['date'] == todayString,
          );
          return todayAttendance == null ||
              (todayAttendance['status'] != 'Present' &&
                  todayAttendance['status'] != 'Late');
        }).length;

    final onLeave = employees.where((e) => e.status == 'On Leave').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'HR Dashboard',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Welcome back, overview of today’s personnel activity.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  DateFormat('EEEE, MMM d, yyyy').format(today),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Employees',
                  totalEmployees.toString(),
                  Icons.people_alt_rounded,
                  context,
                  AppColors.secondary,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildStatCard(
                  'Present Today',
                  presentToday.toString(),
                  Icons.check_circle_rounded,
                  context,
                  Colors.green[600]!,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildStatCard(
                  'Late Today',
                  lateOnly.toString(),
                  Icons.warning_rounded,
                  context,
                  Colors.orange[600]!,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildStatCard(
                  'Absent Today',
                  absentToday.toString(),
                  Icons.cancel_rounded,
                  context,
                  AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildRecentActivities(context)),
              const SizedBox(width: 20),
              Expanded(child: _buildUpcomingLeaves(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    BuildContext context,
    Color color,
  ) {
    return Container(
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities(BuildContext context) {
    final recentActivities =
        employees
            .expand((emp) {
              final List<Map<String, dynamic>> activities = [];
              if (emp.attendance.isNotEmpty) {
                activities.add({
                  'type': 'attendance',
                  'employee': emp,
                  'data': emp.attendance.first,
                });
              }
              if (emp.leaveRequests.isNotEmpty) {
                activities.add({
                  'type': 'leave',
                  'employee': emp,
                  'data': emp.leaveRequests.first,
                });
              }
              return activities;
            })
            .take(4)
            .toList();

    return Container(
      padding: const EdgeInsets.all(24),
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
          const Text(
            'Recent Activities',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (recentActivities.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  'No recent activities recorded.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...recentActivities.map((activity) {
              if (activity['type'] == 'attendance') {
                final EmployeeModel emp = activity['employee'];
                return _buildActivityItem(
                  '${emp.name} checked in',
                  'Today',
                  Icons.login_rounded,
                  Colors.green[600]!,
                );
              }
              final EmployeeModel emp = activity['employee'];
              return _buildActivityItem(
                '${emp.name} applied for leave',
                'Today',
                Icons.event_rounded,
                Colors.orange[600]!,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String text,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingLeaves(BuildContext context) {
    final upcomingLeaves =
        employees
            .where(
              (emp) =>
                  emp.leaveRequests.any((req) => req['status'] == 'Pending'),
            )
            .toList();

    return Container(
      padding: const EdgeInsets.all(24),
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
          const Text(
            'Pending Leaves',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (upcomingLeaves.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  'No pending leave requests.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...upcomingLeaves.map(
              (emp) =>
                  _buildLeaveItem(emp.name, (emp.leaveRequests).first['dates']),
            ),
        ],
      ),
    );
  }

  Widget _buildLeaveItem(String name, String dates) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              name[0],
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dates,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
