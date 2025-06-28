import 'package:physioprime/ui/PackagesPage/ui/packages_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AddClientPage extends StatefulWidget {
  @override
  _AddClientPageState createState() => _AddClientPageState();
}

class _AddClientPageState extends State<AddClientPage> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final phoneController = TextEditingController();
  final detailsController = TextEditingController();
  String? _selectedPackageCategory;
  String? _selectedPackageItem;
  List<Map<String, dynamic>> _selectedClientPackages =
      []; // To store packages selected for this client
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add New Client')),
      body: Padding(
        padding: EdgeInsets.all(24), // Consistent padding
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.cake),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number (e.g., 01012345678)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: detailsController,
              decoration: InputDecoration(
                labelText: 'Details / Notes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info_outline),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 24),
            Text(
              'Service Packages:',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            SizedBox(height: 8),

            // Dropdown for Package Category
            DropdownButtonFormField<String>(
              value: _selectedPackageCategory,
              hint: Text('Select Package Category'),
              isExpanded: true,
              items:
                  PackagesPage.packagesData.keys.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPackageCategory = newValue;
                  _selectedPackageItem = null;
                });
              },
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),
            SizedBox(height: 16),
            // Dropdown for Specific Package Item
            if (_selectedPackageCategory != null)
              DropdownButtonFormField<String>(
                value: _selectedPackageItem,
                hint: Text('Select Package Item'),
                isExpanded: true,
                items:
                    (PackagesPage.packagesData[_selectedPackageCategory!] ?? [])
                        .map((Map<String, dynamic> packageMap) {
                          // Changed from (String item)
                          final String itemName =
                              packageMap['name'] as String; // Extract the name
                          return DropdownMenuItem<String>(
                            value: itemName, // Use the extracted name
                            child: Text(itemName), // Display the extracted name
                          );
                        })
                        .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedPackageItem = newValue;
                  });
                },
                decoration: InputDecoration(border: OutlineInputBorder()),
              ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.add_shopping_cart),
              label: Text('Add Selected Package'),
              onPressed:
                  (_selectedPackageCategory != null &&
                          _selectedPackageItem != null)
                      ? () {
                        final String itemName = _selectedPackageItem!;
                        final List<Map<String, dynamic>> packagesInCategory =
                            PackagesPage
                                .packagesData[_selectedPackageCategory!] ??
                            [];

                        final Map<String, dynamic>? packageToAdd =
                            packagesInCategory.firstWhere(
                              (pkg) => pkg['name'] == itemName,
                              orElse:
                                  () =>
                                      <
                                        String,
                                        dynamic
                                      >{}, // Return null if not found
                            );
                        setState(() {
                          if (packageToAdd != null) {
                            final newPackageForClient = {
                              'name': packageToAdd['name'],
                              'totalSessions': packageToAdd['totalSessions'],
                              'remainingSessions':
                                  packageToAdd['totalSessions'], // New booking starts with full sessions
                              'category': packageToAdd['category'],
                            };

                            if (!_selectedClientPackages.any(
                              (p) => p['name'] == newPackageForClient['name'],
                            )) {
                              _selectedClientPackages.add(newPackageForClient);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$itemName is already added.'),
                                ),
                              );
                            }
                          }
                        });
                      }
                      : null,
            ),
            SizedBox(height: 16),
            Text(
              'Client\'s Booked Packages:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            _selectedClientPackages.isEmpty
                ? Text('No packages booked yet.')
                : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _selectedClientPackages.length,
                  itemBuilder: (context, index) {
                    final package = _selectedClientPackages[index];
                    return ListTile(
                      title: Text(package['name'] ?? 'Unknown Package'),
                      // You could add more details here like sessions
                      trailing: IconButton(
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedClientPackages.removeAt(index);
                          });
                        },
                      ),
                    );
                  },
                ),
            SizedBox(height: 8),
            // TextButton.icon(
            //   icon: Icon(Icons.add_shopping_cart),
            //   label: Text('Add Package'),
            //   onPressed: () async {
            //     final selectedPackage =
            //         await Navigator.push<Map<String, dynamic>>(
            //           context,
            //           MaterialPageRoute(
            //             builder: (_) => SelectPackagePage(),
            //           ), // A new page to select packages
            //         );
            //     if (selectedPackage != null) {
            //       setState(() {
            //         // Prevent adding duplicate packages by name for simplicity
            //         if (!_selectedClientPackages.any(
            //           (p) => p['name'] == selectedPackage['name'],
            //         )) {
            //           _selectedClientPackages.add(selectedPackage);
            //         } else {
            //           ScaffoldMessenger.of(context).showSnackBar(
            //             SnackBar(
            //               content: Text(
            //                 '${selectedPackage['name']} is already added.',
            //               ),
            //             ),
            //           );
            //         }
            //       });
            //     }
            //   },
            // ),
            SizedBox(height: 32), // Increased spacing
            ElevatedButton.icon(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    phoneController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Name and Phone Number are required to add a client.',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                final clientBox = Hive.box('clients');
                final lastId = clientBox.get('lastId', defaultValue: 0);
                final newId = lastId + 1;
                final clientKey = newId.toString();

                final clientData = {
                  'id': newId,
                  'name': nameController.text.trim(),
                  'age': ageController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'details': detailsController.text.trim(),
                  'bookedPackages':
                      _selectedClientPackages, // Save booked packages
                };

                clientBox.put(clientKey, clientData);
                clientBox.put('lastId', newId);
                await _firestore
                    .collection('clients')
                    .doc(clientKey)
                    .set(clientData);
                await _firestore.collection('clients').doc('metadata').set({
                  'lastId': newId,
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Client added successfully! ID: $newId'),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                );
                Navigator.pop(context);
              },
              icon: Icon(Icons.check),
              label: Text('Add Client'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
              ), // Full width button
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    phoneController.dispose();
    detailsController.dispose();
    // It's good practice to clear the list if the page is stateful and might be reused,
    // though in this push/pop navigation, it might not be strictly necessary.
    // _selectedClientPackages.clear();
    super.dispose();
  }
}

// lib/screens/financial_management_screen.dart
