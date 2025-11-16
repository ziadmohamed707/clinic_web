import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physioone/ui/LoginPage/models/user_model.dart';
import 'package:intl/intl.dart';

class UserProfilePage extends StatefulWidget {
  final UserModel user;

  const UserProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late UserModel _user;
  StreamSubscription? _userSubscription;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _listenToUserChanges();
  }

  void _listenToUserChanges() {
    _userSubscription = FirebaseFirestore.instance
        .collection('employees')
        .doc(_user.docId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        setState(() {
          _user = UserModel.fromMap(snapshot.data()!, snapshot.id);
        });
      }
    });
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Employee Profile'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // TODO: Navigate to edit profile
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderSection(context),
            const SizedBox(height: 16),
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildQuickStatsRow(context),
                    const SizedBox(height: 16),
                    _buildLeaveSummaryRow(context),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildPersonalInfoCard(context),
                              const SizedBox(height: 16),
                              _buildEmploymentDetailsCard(context),
                              const SizedBox(height: 16), // Changed
                              _buildAllRequestsCard(context), // Changed
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: _buildFinancialSummaryCard(context)),
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

  Widget _buildHeaderSection(BuildContext context) {
    final statusColor = _user.status == 'Active' ? Colors.green : Colors.red;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
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
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
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
                      _user.status == 'Active' ? Icons.check : Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _user.name ?? _user.username ?? 'N/A',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              (_user.position ?? _user.role ?? 'N/A').toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
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
                    _user.status ?? 'Unknown',
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

  Widget _buildQuickStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.calendar_today,
            label: 'Years of Experience',
            value: _user.yearsOfExperience?.toString() ?? '0',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.work_outline,
            label: 'Department',
            value: _user.department ?? 'N/A',
            color: Colors.purple,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.event_available,
            label: 'Available Days',
            value: _user.availableDays?.length.toString() ?? '0',
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveSummaryRow(BuildContext context) {
    final annualQuota = _user.annualLeaveQuota ?? 0;
    final sickQuota = _user.sickLeaveQuota ?? 0;

    int _calculateUsedLeave(String type) {
      if (_user.leaveRequests == null) return 0;
      int usedDays = 0;
      for (var request in _user.leaveRequests!) {
        if (request is Map &&
            request['status'] == 'Approved' &&
            request['type'] == type &&
            request['startDate'] is Timestamp &&
            request['endDate'] is Timestamp) {
          // Safe casting after checking the type
          final startDate = (request['startDate'] as Timestamp).toDate();
          final endDate = (request['endDate'] as Timestamp).toDate();
          usedDays += endDate.difference(startDate).inDays + 1;
        }
      }
      return usedDays;
    }

    final usedAnnual = _calculateUsedLeave('Annual');
    final usedSick = _calculateUsedLeave('Sick');
    final usedUnpaid = _calculateUsedLeave('Unpaid');
    final remainingAnnual = annualQuota - usedAnnual;
    final remainingSick = sickQuota - usedSick;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.calendar_view_week_rounded,
            label: 'Annual Leave',
            value: '$remainingAnnual / $annualQuota',
            color: Colors.teal,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.medical_services_outlined,
            label: 'Sick Leave',
            value: '$remainingSick / $sickQuota',
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
            value: '${usedAnnual + usedSick + usedUnpaid} Days',
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

  Widget _buildPersonalInfoCard(BuildContext context) {
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
                  color: Theme.of(context).primaryColor,
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
              value: _user.email ?? 'N/A',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              icon: Icons.badge_outlined,
              label: 'Employee ID',
              value: _user.id ?? _user.docId ?? 'N/A',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              icon: Icons.phone_outlined,
              label: 'Contact Number',
              value: 'Not Available',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmploymentDetailsCard(BuildContext context) {
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
                  color: Theme.of(context).primaryColor,
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
              icon: Icons.business_outlined,
              label: 'Department',
              value: _user.department ?? 'N/A',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              icon: Icons.calendar_today_outlined,
              label: 'Join Date',
              value:
                  _user.joinDate != null
                      ? DateFormat('MMMM d, yyyy').format(_user.joinDate!)
                      : 'N/A',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              icon: Icons.schedule_outlined,
              label: 'Available Days',
              value: _user.availableDays?.join(', ') ?? 'Not specified',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllRequestsCard(BuildContext context) {
    // Combine leave and allowance requests into a single list
    final leaveRequests = _user.leaveRequests?.map((r) {
          final req = Map<String, dynamic>.from(r as Map);
          req['requestType'] = 'Leave'; // Add a field to distinguish
          return req;
        }).toList() ?? [];

    final allowanceRequests = _user.allowanceRequests?.map((r) {
          final req = Map<String, dynamic>.from(r as Map);
          req['requestType'] = 'Allowance'; // Add a field to distinguish
          return req;
        }).toList() ?? [];

    final allRequests = [...leaveRequests, ...allowanceRequests];

    // Sort all requests by their requestDate in descending order (most recent first).
    allRequests.sort((a, b) {
      final dateA = a['requestDate'] as Timestamp?;
      final dateB = b['requestDate'] as Timestamp?;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1; // Place items without a date at the end.
      if (dateB == null) return -1;
      return dateB.compareTo(dateA); // Sort descending.
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
                  color: Theme.of(context).primaryColor,
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
                  final request =
                      Map<String, dynamic>.from(allRequests[index] as Map);
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
                    subtitleText =
                        'Amount: EGP ${amount.toStringAsFixed(2)}';
                    title = 'Allowance Request';
                  }

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    leading: Icon(leadingIcon,
                        color: Theme.of(context).primaryColor),
                    title: Text(title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(subtitleText),
                        if (reason != null && reason.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text('Reason: $reason',
                                style: const TextStyle(
                                    fontStyle: FontStyle.italic)),
                          ),
                        if (requestDate != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                                'Requested on: ${DateFormat.yMMMd().format(requestDate.toDate())}'),
                          ),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(status,
                          style: const TextStyle(color: Colors.white)),
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

  Widget _buildFinancialSummaryCard(BuildContext context) {
    final baseSalary = _user.baseSalary ?? 0.0;
    final allowances = _user.allowances ?? 0.0;
    final deductions = _user.deductions ?? 0.0;
    final netSalary = baseSalary + allowances - deductions;

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
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
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
                  color: Colors.white.withOpacity(0.2),
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
                value: 'EGP ${baseSalary.toStringAsFixed(2)}',
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              _buildFinancialDetailRow(
                icon: Icons.add_card_outlined,
                label: 'Allowances',
                value: '+ EGP ${allowances.toStringAsFixed(2)}',
                color: Colors.greenAccent,
              ),
              const SizedBox(height: 12),
              _buildFinancialDetailRow(
                icon: Icons.remove_circle_outline,
                label: 'Deductions',
                value: '- EGP ${deductions.toStringAsFixed(2)}',
                color: Colors.redAccent,
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _showVacationRequestDialog(context, _user),
                  icon: const Icon(Icons.beach_access_outlined),
                  label: const Text('Request Vacation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
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
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Theme.of(context).primaryColor),
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
              color: Colors.white.withOpacity(0.9),
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

  void _showVacationRequestDialog(BuildContext context, UserModel user) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTimeRange? selectedDateRange;
    String? leaveType = 'Annual'; // Default leave type

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Request a New Vacation'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: leaveType,
                      decoration: const InputDecoration(labelText: 'Leave Type'),
                      items: ['Annual', 'Sick', 'Unpaid']
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
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
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            selectedDateRange = picked;
                          });
                        }
                      },
                      validator: (value) {
                        if (selectedDateRange == null) {
                          return 'Please select a date range.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Reason',
                        hintText: 'e.g., Family vacation',
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please provide a reason for the request.';
                        }
                        return null;
                      },
                    ),
                  ],
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
                      final newRequest = {
                        'type': leaveType,
                        'reason': reasonController.text,
                        'startDate': Timestamp.fromDate(selectedDateRange!.start),
                        'endDate': Timestamp.fromDate(selectedDateRange!.end),
                        'dates':
                            '${DateFormat.yMMMd().format(selectedDateRange!.start)} - ${DateFormat.yMMMd().format(selectedDateRange!.end)}',
                        'requestDate': Timestamp.now(),
                        'status': 'Pending',
                      };
                      await FirebaseFirestore.instance
                          .collection('employees')
                          .doc(user.docId)
                          .update({
                        'leaveRequests': FieldValue.arrayUnion([newRequest])
                      });
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vacation request submitted!'),
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
}
