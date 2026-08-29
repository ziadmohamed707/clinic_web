import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physioone/core/app_colors.dart';
import 'package:physioone/hr_system/model/expense_request_model.dart';
import 'package:physioone/hr_system/services/expense_service.dart';
import 'package:physioone/hr_system/model/employee_model.dart';

class ExpenseRequestDialog extends StatefulWidget {
  final EmployeeModel currentEmployee;
  final Function onSubmitted;

  const ExpenseRequestDialog({
    Key? key,
    required this.currentEmployee,
    required this.onSubmitted,
  }) : super(key: key);

  @override
  State<ExpenseRequestDialog> createState() => _ExpenseRequestDialogState();
}

class _ExpenseRequestDialogState extends State<ExpenseRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final ExpenseService _expenseService = ExpenseService();

  ExpenseType? _selectedType;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final expense = ExpenseRequest(
        id: '',
        employeeId: widget.currentEmployee.id,
        employeeName: widget.currentEmployee.name,
        type: _selectedType!,
        amount: double.parse(_amountController.text),
        description: _descriptionController.text,
        requestDate: DateTime.now(),
      );

      _expenseService.submitExpense(expense).then((_) {
        widget.onSubmitted();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Expense request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }).catchError((e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to submit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        'Request Expense / Allowance',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ExpenseType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Expense Type',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: ExpenseType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(
                          _getIconForType(type),
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(type.displayName),
                            Text(
                              type.arabicName,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a type' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (EGP)',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description / Reason',
                  prefixIcon: Icon(Icons.description_rounded),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please provide a reason' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Submit Request'),
        ),
      ],
    );
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
}