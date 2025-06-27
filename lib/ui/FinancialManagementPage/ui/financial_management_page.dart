
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class FinancialManagementPage extends StatefulWidget {
  const FinancialManagementPage({Key? key}) : super(key: key);

  @override
  _FinancialManagementScreenState createState() =>
      _FinancialManagementScreenState();
}

class _FinancialManagementScreenState extends State<FinancialManagementPage> {
  DateTime _selectedDate = DateTime.now();
  Box? _financialBox;
  List<Map<String, dynamic>> _dailyEntries = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool _isInitialized = false;

  // Form controllers
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _clientController = TextEditingController();

  // Form variables
  String _selectedType = 'Payment';
  String _selectedPaymentMethod = 'Cash';
  final List<String> _entryTypes = ['Payment', 'Purchase', 'Bill'];
  final List<String> _paymentMethods = ['Cash', 'Card', 'Bank Transfer', 'Check'];
  final List<String> _categories = [
    'Physio Payment',
    'Supplies',
    'Rent',
    'Utilities',
    'Equipment',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    try {
      setState(() => _isLoading = true);
      
      // Check if box is already open
      if (Hive.isBoxOpen('financialEntries')) {
        _financialBox = Hive.box('financialEntries');
      } else {
        // Open the box if not already open
        _financialBox = await Hive.openBox('financialEntries');
      }
      
      setState(() => _isInitialized = true);
      _loadDailyEntries();
      _syncFromFirestore();
    } catch (e) {
      print('Error initializing Hive: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing storage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _clientController.dispose();
    super.dispose();
  }

  void _loadDailyEntries() {
    if (_financialBox == null || !_isInitialized) return;
    
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    _dailyEntries = _financialBox!.values
        .where((entry) {
          // Ensure entry is a Map and has a 'date' key before accessing it
          return entry is Map && entry['date'] == formattedDate;
        })
        .map((dynamicEntry) => Map<String, dynamic>.from(dynamicEntry as Map)) // Explicitly create Map<String, dynamic>
        .toList();
    
    // Sort entries by timestamp
    _dailyEntries.sort((a, b) {
      final aTime = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime.now();
      final bTime = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime.now();
      return bTime.compareTo(aTime);
    });
    
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadDailyEntries();
    }
  }

  Future<void> _syncToFirestore(Map<String, dynamic> entry) async {
    try {
      await _firestore
          .collection('financial_entries')
          .doc(entry['id'])
          .set(entry);
      print('Entry synced to Firestore: ${entry['id']}');
    } catch (e) {
      print('Error syncing to Firestore: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync to cloud: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _syncFromFirestore() async {
    if (_financialBox == null || !_isInitialized) return;
    
    try {
      setState(() => _isLoading = true);
      
      final snapshot = await _firestore
          .collection('financial_entries')
          .orderBy('timestamp', descending: true)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        // Only add if not already in local storage
        if (!_financialBox!.containsKey(data['id'])) {
          await _financialBox!.put(data['id'], data);
        }
      }
      
      _loadDailyEntries();
      print('Synced ${snapshot.docs.length} entries from Firestore');
    } catch (e) {
      print('Error syncing from Firestore: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync from cloud: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteEntry(String entryId) async {
    if (_financialBox == null || !_isInitialized) return;
    
    try {
      // Delete from local storage
      await _financialBox!.delete(entryId);
      
      // Delete from Firestore
      await _firestore
          .collection('financial_entries')
          .doc(entryId)
          .delete();
      
      _loadDailyEntries();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entry deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting entry: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearForm() {
    _descriptionController.clear();
    _amountController.clear();
    _categoryController.clear();
    _clientController.clear();
    _selectedType = 'Payment';
    _selectedPaymentMethod = 'Cash';
  }

  void _addEntry() {
    _clearForm();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Financial Entry'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Entry Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Entry Type',
                  border: OutlineInputBorder(),
                ),
                items: _entryTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Description TextField
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description/Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Amount TextField
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (LE)',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _categories.contains(_categoryController.text) 
                    ? _categoryController.text 
                    : _categories.first,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
                onChanged: (value) {
                  _categoryController.text = value!;
                },
              ),
              const SizedBox(height: 16),

              // Client TextField (for payments)
              if (_selectedType == 'Payment') ...[
                TextField(
                  controller: _clientController,
                  decoration: const InputDecoration(
                    labelText: 'Client Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Payment Method Dropdown
              DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                ),
                items: _paymentMethods.map((method) {
                  return DropdownMenuItem(value: method, child: Text(method));
                }).toList(),
                onChanged: (value) {
                  _selectedPaymentMethod = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_descriptionController.text.isEmpty || 
                  _amountController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in description and amount'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final amount = double.tryParse(_amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final newEntry = {
                'id': const Uuid().v4(),
                'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
                'type': _selectedType,
                'description': _descriptionController.text.trim(),
                'amount': amount,
                'category': _categoryController.text.isNotEmpty 
                    ? _categoryController.text 
                    : _categories.first,
                'clientId': _clientController.text.trim(),
                'paymentMethod': _selectedPaymentMethod,
                'timestamp': DateTime.now().toIso8601String(),
              };

              try {
                // Check if box is initialized
                if (_financialBox == null || !_isInitialized) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Storage not initialized. Please wait...'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                // Save to local storage
                await _financialBox!.put(newEntry['id'], newEntry);
                
                // Sync to Firestore
                await _syncToFirestore(Map<String, dynamic>.from(newEntry)); // Ensure correct map type
                
                _loadDailyEntries();
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Entry added successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error adding entry: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save Entry'),
          ),
        ],
      ),
    );
  }

  void _editEntry(Map<String, dynamic> entry) {
    _descriptionController.text = entry['description'] ?? '';
    _amountController.text = (entry['amount'] ?? 0.0).toString();
    _categoryController.text = entry['category'] ?? _categories.first;
    _clientController.text = entry['clientId'] ?? '';
    _selectedType = entry['type'] ?? 'Payment';
    _selectedPaymentMethod = entry['paymentMethod'] ?? 'Cash';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Financial Entry'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Same form fields as _addEntry but with pre-filled values
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Entry Type',
                  border: OutlineInputBorder(),
                ),
                items: _entryTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description/Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (\$)',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _categories.contains(_categoryController.text) 
                    ? _categoryController.text 
                    : _categories.first,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
                onChanged: (value) {
                  _categoryController.text = value!;
                },
              ),
              const SizedBox(height: 16),

              if (_selectedType == 'Payment') ...[
                TextField(
                  controller: _clientController,
                  decoration: const InputDecoration(
                    labelText: 'Client Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                ),
                items: _paymentMethods.map((method) {
                  return DropdownMenuItem(value: method, child: Text(method));
                }).toList(),
                onChanged: (value) {
                  _selectedPaymentMethod = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_descriptionController.text.isEmpty || 
                  _amountController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in description and amount'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final amount = double.tryParse(_amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final updatedEntry = {
                ...entry,
                'type': _selectedType,
                'description': _descriptionController.text.trim(),
                'amount': amount,
                'category': _categoryController.text.isNotEmpty 
                    ? _categoryController.text 
                    : _categories.first,
                'clientId': _clientController.text.trim(),
                'paymentMethod': _selectedPaymentMethod,
                'updatedAt': DateTime.now().toIso8601String(),
              };

              try {
                // Check if box is initialized
                if (_financialBox == null || !_isInitialized) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Storage not initialized. Please wait...'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                // Update local storage
                await _financialBox!.put(updatedEntry['id'], updatedEntry);
                
                // Sync to Firestore
                await _syncToFirestore(Map<String, dynamic>.from(updatedEntry)); // Ensure correct map type
                
                _loadDailyEntries();
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Entry updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating entry: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Update Entry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate daily summaries
    double totalPayments = 0;
    double totalPurchases = 0;
    double totalBills = 0;

    for (var entry in _dailyEntries) {
      final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
      switch (entry['type']) {
        case 'Payment':
          totalPayments += amount;
          break;
        case 'Purchase':
          totalPurchases += amount;
          break;
        case 'Bill':
          totalBills += amount;
          break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Management'),
        actions: [
          if (_isInitialized) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _syncFromFirestore,
              tooltip: 'Sync from Cloud',
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () => _selectDate(context),
              tooltip: 'Select Date',
            ),
          ],
        ],
      ),
      body: !_isInitialized
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing storage...'),
                ],
              ),
            )
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Entries for ${DateFormat('EEE, MMM d, yyyy').format(_selectedDate)}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  
                  // Daily Summary Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Daily Summary:', 
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Payments: ${totalPayments.toStringAsFixed(2)} LE',
                                      style: const TextStyle(color: Colors.green)),
                                  Text('Purchases: ${totalPurchases.toStringAsFixed(2)} LE',
                                      style: const TextStyle(color: Colors.orange)),
                                  Text('Bills: ${totalBills.toStringAsFixed(2)} LE',
                                      style: const TextStyle(color: Colors.red)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Net: ${(totalPayments - totalPurchases - totalBills).toStringAsFixed(2) } LE',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: (totalPayments - totalPurchases - totalBills) >= 0 
                                            ? Colors.green 
                                            : Colors.red,
                                      )),
                                  Text('${_dailyEntries.length} entries'),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Text('Entries:', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  
                  // Entries List
                  Expanded(
                    child: _dailyEntries.isEmpty
                        ? const Center(child: Text('No entries for this date.'))
                        : ListView.builder(
                            itemCount: _dailyEntries.length,
                            itemBuilder: (context, index) {
                              final entry = _dailyEntries[index];
                              final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
                              
                              Color typeColor = Colors.grey;
                              IconData typeIcon = Icons.monetization_on;
                              
                              switch (entry['type']) {
                                case 'Payment':
                                  typeColor = Colors.green;
                                  typeIcon = Icons.payment;
                                  break;
                                case 'Purchase':
                                  typeColor = Colors.orange;
                                  typeIcon = Icons.shopping_cart;
                                  break;
                                case 'Bill':
                                  typeColor = Colors.red;
                                  typeIcon = Icons.receipt;
                                  break;
                              }

                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: typeColor.withOpacity(0.1),
                                    child: Icon(typeIcon, color: typeColor),
                                  ),
                                  title: Text(
                                    '${entry['type']}: ${entry['description']}',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Amount: ${amount.toStringAsFixed(2)} LE',
                                          style: TextStyle(
                                            color: typeColor,
                                            fontWeight: FontWeight.bold,
                                          )),
                                      if (entry['category'] != null)
                                        Text('Category: ${entry['category']}'),
                                      if (entry['clientId'] != null && entry['clientId'].toString().isNotEmpty)
                                        Text('Client: ${entry['clientId']}'),
                                      if (entry['paymentMethod'] != null)
                                        Text('Method: ${entry['paymentMethod']}'),
                                    ],
                                  ),
                                  trailing: PopupMenuButton(
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _editEntry(entry);
                                      } else if (value == 'delete') {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Delete Entry'),
                                            content: const Text('Are you sure you want to delete this entry?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _deleteEntry(entry['id']);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                ),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  onTap: () => _editEntry(entry),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: _isInitialized ? FloatingActionButton(
        onPressed: _addEntry,
        tooltip: 'Add Financial Entry',
        child: const Icon(Icons.add),
      ) : null,
    );
  }
}