// lib/ui/manage_doctors_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class ManageDoctorsPage extends StatefulWidget {
  const ManageDoctorsPage({Key? key}) : super(key: key);

  @override
  State<ManageDoctorsPage> createState() => _ManageDoctorsPageState();
}

class _ManageDoctorsPageState extends State<ManageDoctorsPage> {
  late Box _doctorsBox;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _doctors = [];
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<String> _allDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  List<String> _selectedDays = [];

  @override
  void initState() {
    super.initState();
    _doctorsBox = Hive.box('doctors');
    _loadDoctors();
  }

  void _loadDoctors() {
    final doctorsData = _doctorsBox.values.toList();
    setState(() {
      _doctors = doctorsData
          .map((doctor) => Map<String, dynamic>.from(doctor as Map))
          .toList();
    });
  }

  Future<void> _saveDoctorToFirestore(Map<String, dynamic> doctorData) async {
    try {
      await _firestore
          .collection('doctors')
          .doc(doctorData['id'] as String)
          .set(doctorData);
    } catch (e) {
      print('Error saving doctor to Firestore: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to sync doctor to cloud: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _showAddDoctorDialog({Map<String, dynamic>? doctorToEdit}) {
    bool isEditing = doctorToEdit != null;
    if (isEditing) {
      _nameController.text = doctorToEdit['name'] as String;
      _selectedDays = List<String>.from(doctorToEdit['availableDays'] as List);
    } else {
      _nameController.clear();
      _selectedDays.clear();
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Use StatefulBuilder for dialog's own state
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Doctor' : 'Add New Doctor'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(labelText: 'Doctor\'s Name'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter doctor\'s name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      Text('Available Days:', style: Theme.of(context).textTheme.titleMedium),
                      ..._allDays.map((day) {
                        return CheckboxListTile(
                          title: Text(day),
                          value: _selectedDays.contains(day),
                          onChanged: (bool? value) {
                            setStateDialog(() { // Update dialog state
                              if (value == true) {
                                _selectedDays.add(day);
                              } else {
                                _selectedDays.remove(day);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      if (_selectedDays.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please select at least one available day.'), backgroundColor: Colors.orange),
                        );
                        return;
                      }

                      final doctorData = {
                        'id': isEditing ? doctorToEdit['id'] as String : Uuid().v4(),
                        'name': _nameController.text.trim(),
                        'availableDays': List<String>.from(_selectedDays), // Create a new list
                      };

                      if (isEditing) {
                        await _doctorsBox.put(doctorData['id'], doctorData);
                      } else {
                        await _doctorsBox.put(doctorData['id'], doctorData);
                      }
                      await _saveDoctorToFirestore(doctorData);
                      _loadDoctors(); // Refresh the list
                      Navigator.pop(context); // Close dialog
                    }
                  },
                  child: Text(isEditing ? 'Save Changes' : 'Add Doctor'),
                ),
              ],
            );
          }
        );
      },
    ).then((_) {
      // Reset fields when dialog is dismissed, regardless of how
      _nameController.clear();
      _selectedDays.clear();
    });
  }

  Future<void> _deleteDoctor(String doctorId) async {
     bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Doctor?'),
        content: Text('Are you sure you want to delete this doctor? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      await _doctorsBox.delete(doctorId);
      try {
        await _firestore.collection('doctors').doc(doctorId).delete();
      } catch (e) {
        print('Error deleting doctor from Firestore: $e');
        // Optionally show a snackbar for Firestore deletion failure
      }
      _loadDoctors();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Doctors'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline),
            onPressed: () => _showAddDoctorDialog(),
            tooltip: 'Add New Doctor',
          ),
        ],
      ),
      body: _doctors.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medical_services_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('No doctors added yet.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('Add First Doctor'),
                    onPressed: () => _showAddDoctorDialog(),
                  )
                ],
              ),
            )
          : ListView.builder(
              itemCount: _doctors.length,
              itemBuilder: (context, index) {
                final doctor = _doctors[index];
                final String doctorName = doctor['name'] as String? ?? 'Unnamed Doctor';
                final List<String> availableDays = List<String>.from(doctor['availableDays'] as List? ?? []);

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(Icons.person_outline),
                      backgroundColor: Theme.of(context).primaryColorLight,
                    ),
                    title: Text(doctorName, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Available: ${availableDays.join(", ")}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit_outlined, color: Theme.of(context).primaryColor),
                          onPressed: () => _showAddDoctorDialog(doctorToEdit: doctor),
                          tooltip: 'Edit Doctor',
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _deleteDoctor(doctor['id'] as String),
                          tooltip: 'Delete Doctor',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
