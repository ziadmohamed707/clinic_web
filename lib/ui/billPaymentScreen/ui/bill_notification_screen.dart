import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class BillNotificationScreen extends StatefulWidget {
  // Optional client to pre-select

  const BillNotificationScreen({Key? key}) : super(key: key);

  @override
  _BillNotificationScreenState createState() => _BillNotificationScreenState();
}

class _BillNotificationScreenState extends State<BillNotificationScreen> {
  late Box _billsBox;
  bool isLoading = false;
  String selectedFilter = 'all'; // all, pending, paid, overdue
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late CollectionReference _systemBillsCollection;
  StreamSubscription? _billsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _billsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      setState(() => isLoading = true);
      _billsBox = await Hive.openBox('system_bills');
      _systemBillsCollection = _firestore.collection('system_bills');
      await _ensureBillsCollectionExists();
      _listenToFirestoreChanges();
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  /// Checks if the 'system_bills' collection has any documents.
  /// If not, it creates a sample bill to initialize the collection.
  Future<void> _ensureBillsCollectionExists() async {
    final snapshot = await _systemBillsCollection.limit(1).get();
    if (snapshot.docs.isEmpty) {
      // Collection is empty, let's add a sample bill.
      final sampleBill = {
        'id': 'initial-bill-${DateTime.now().millisecondsSinceEpoch}',
        'serviceName': 'Welcome to PhysioPrime Billing',
        'description':
            'This is your system billing area. Your bills for services like hosting, support, and updates will appear here.',
        'totalAmount': 0.00,
        'status': 'paid', // 'paid' so it doesn't show as pending
        'issueDate': DateTime.now().toIso8601String(),
        'dueDate':
            DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'paidDate': DateTime.now().toIso8601String(),
        'paymentUrl': '',
      };

      // Add to Firestore and local Hive box
      await _systemBillsCollection
          .doc(sampleBill['id'] as String?)
          .set(sampleBill);
      await _billsBox.put(sampleBill['id'], sampleBill);
    }
  }

  void _listenToFirestoreChanges() {
    _billsSubscription = _systemBillsCollection.snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          _billsBox.delete(change.doc.id);
        } else {
          _billsBox.put(change.doc.id, change.doc.data());
        }
      }
      if (mounted) setState(() {});
    }, onError: (e) => _showSnackBar('Bill sync error: $e', Colors.red));
  }

  List<Map<String, dynamic>> get _filteredBills {
    final allBills =
        _billsBox.values
            .map((bill) => Map<String, dynamic>.from(bill as Map))
            .toList();

    allBills.sort((a, b) {
      final dateA = DateTime.parse(
        a['dueDate'] ?? DateTime.now().toIso8601String(),
      );
      final dateB = DateTime.parse(
        b['dueDate'] ?? DateTime.now().toIso8601String(),
      );
      return dateB.compareTo(dateA);
    });

    if (selectedFilter == 'all') return allBills;

    return allBills.where((bill) {
      final status = bill['status'] as String?;
      final dueDate = DateTime.parse(
        bill['dueDate'] ?? DateTime.now().toIso8601String(),
      );

      switch (selectedFilter) {
        case 'pending':
          return status == 'pending';
        case 'paid':
          return status == 'paid';
        case 'overdue':
          return status == 'pending' && dueDate.isBefore(DateTime.now());
        default:
          return true;
      }
    }).toList();
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
    }
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'All Bills', 'icon': Icons.receipt_long},
      {'key': 'pending', 'label': 'Pending', 'icon': Icons.pending},
      {'key': 'paid', 'label': 'Paid', 'icon': Icons.check_circle},
      {'key': 'overdue', 'label': 'Overdue', 'icon': Icons.warning},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            filters.map((filter) {
              final isSelected = selectedFilter == filter['key'];
              return Container(
                margin: EdgeInsets.only(right: 12),
                child: FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        filter['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                      ),
                      SizedBox(width: 8),
                      Text(
                        filter['label'] as String,
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  selectedColor: Theme.of(context).primaryColor,
                  backgroundColor: Colors.grey.shade100,
                  onSelected: (selected) {
                    setState(() {
                      selectedFilter = filter['key'] as String;
                    });
                  },
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildStatsCard() {
    final bills =
        _billsBox.values
            .map((bill) => Map<String, dynamic>.from(bill as Map))
            .toList();

    final pendingBills = bills.where((b) => b['status'] == 'pending').length;
    final paidBills = bills.where((b) => b['status'] == 'paid').length;
    final overdueBills =
        bills.where((b) {
          final status = b['status'] as String?;
          final dueDate = DateTime.parse(
            b['dueDate'] ?? DateTime.now().toIso8601String(),
          );
          return status == 'pending' && dueDate.isBefore(DateTime.now());
        }).length;

    final totalRevenue = bills
        .where((b) => b['status'] == 'paid')
        .fold<double>(
          0,
          (sum, bill) => sum + (bill['totalAmount'] as num? ?? 0).toDouble(),
        );

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Pending',
                pendingBills.toString(),
                Icons.pending,
                Colors.orange,
              ),
              _buildStatItem(
                'Paid',
                paidBills.toString(),
                Icons.check_circle,
                Colors.green,
              ),
              _buildStatItem(
                'Overdue',
                overdueBills.toString(),
                Icons.warning,
                Colors.red,
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Column(
                  children: [
                    Text(
                      'Total Revenue',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'EGP ${NumberFormat('#,###.00').format(totalRevenue)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(title, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildBillCard(Map<String, dynamic> bill) {
    final dueDate = DateTime.parse(
      bill['dueDate'] ?? DateTime.now().toIso8601String(),
    );
    final isOverdue =
        bill['status'] == 'pending' && dueDate.isBefore(DateTime.now());
    final daysDifference = DateTime.now().difference(dueDate).inDays;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (bill['status'] as String?) {
      case 'paid':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Paid';
        break;
      case 'pending':
        if (isOverdue) {
          statusColor = Colors.red;
          statusIcon = Icons.warning;
          statusText = 'Overdue';
        } else {
          statusColor = Colors.orange;
          statusIcon = Icons.pending;
          statusText = 'Pending';
        }
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Unknown';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border:
            isOverdue
                ? Border.all(color: Colors.red.withOpacity(0.3), width: 2)
                : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bill['serviceName'] ?? 'System Service',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Bill #${bill['id'] ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 16, color: statusColor),
                            SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          Icons.calendar_today,
                          'Due Date',
                          DateFormat('MMM d, yyyy').format(dueDate),
                          isOverdue ? Colors.red : Colors.grey.shade600,
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          Icons.attach_money,
                          'Amount',
                          'EGP ${NumberFormat('#,###.00').format(bill['totalAmount'] ?? 0)}',
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),

                  if (isOverdue) ...[
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Overdue by ${daysDifference.abs()} day${daysDifference.abs() != 1 ? 's' : ''}',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (bill['services'] != null) ...[
                    SizedBox(height: 16),
                    Text(
                      'Services:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey.shade500,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              bill['description'],
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  if (bill['paymentUrl'] != null &&
                      (bill['paymentUrl'] as String).isNotEmpty) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _payBill(bill['paymentUrl']),
                        icon: Icon(Icons.payment, size: 18),
                        label: Text('Pay Bill'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                  ],

                  if (bill['status'] == 'pending') ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _markAsPaid(bill),
                        icon: Icon(Icons.check, size: 18),
                        label: Text('Mark Paid'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                  ],

                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showBillDetails(bill),
                      icon: Icon(Icons.visibility, size: 18),
                      label: Text('View'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _payBill(String url) async {
    final Uri paymentUri = Uri.parse(url);
    try {
      await launchUrl(paymentUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _showSnackBar('Could not open payment link', Colors.red);
    }
  }

  void _markAsPaid(Map<String, dynamic> bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Confirm Payment'),
            content: Text('Mark this bill as paid?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Mark Paid'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        final updatedBill = Map<String, dynamic>.from(bill);
        updatedBill['status'] = 'paid';
        updatedBill['paidDate'] = DateTime.now().toIso8601String();

        await _billsBox.put(bill['id'].toString(), updatedBill);
        await _systemBillsCollection
            .doc(bill['id'].toString())
            .set(updatedBill);

        _showSnackBar('Bill marked as paid!', Colors.green);
        setState(() {});
      } catch (e) {
        _showSnackBar('Error updating bill: $e', Colors.red);
      }
    }
  }

  void _showBillDetails(Map<String, dynamic> bill) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: EdgeInsets.all(24),
              constraints: BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Bill Details',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  _buildDetailRow('Bill Number', bill['id'] ?? 'N/A'),
                  _buildDetailRow(
                    'Service Name',
                    bill['serviceName'] ?? 'System Service',
                  ),
                  _buildDetailRow(
                    'Issue Date',
                    DateFormat('MMM d, yyyy').format(
                      DateTime.parse(
                        bill['issueDate'] ?? DateTime.now().toIso8601String(),
                      ),
                    ),
                  ),
                  _buildDetailRow(
                    'Due Date',
                    DateFormat('MMM d, yyyy').format(
                      DateTime.parse(
                        bill['dueDate'] ?? DateTime.now().toIso8601String(),
                      ),
                    ),
                  ),
                  _buildDetailRow('Status', bill['status'] ?? 'Unknown'),
                  _buildDetailRow(
                    'Total Amount',
                    'EGP ${NumberFormat('#,###.00').format(bill['totalAmount'] ?? 0)}',
                  ),

                  if (bill['description'] != null) ...[
                    SizedBox(height: 20),
                    Text(
                      'Description:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      bill['description'],
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey.shade800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final filteredBills = _filteredBills;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Bill Notifications'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Stats Card
              Padding(padding: EdgeInsets.all(16), child: _buildStatsCard()),

              // Filter Chips
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _buildFilterChips(),
              ),

              SizedBox(height: 16),

              // Bills List
              Expanded(
                child:
                    filteredBills.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              SizedBox(height: 16),
                              Text(
                                selectedFilter == 'all'
                                    ? 'No bills found'
                                    : 'No ${selectedFilter} bills found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                selectedFilter == 'all'
                                    ? 'Create your first bill to get started'
                                    : 'Try changing the filter to see more bills',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredBills.length,
                          itemBuilder: (context, index) {
                            return _buildBillCard(filteredBills[index]);
                          },
                        ),
              ),
            ],
          ),
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade700,
                  Colors.green.shade800.withOpacity(0.1),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Text(
                  'Coming Soon!',
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'More services and features will be available soon. Stay tuned!',
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      const Text(
                        'Developed by zyverse.dev',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Crafting Digital Realities | 01024375442',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
