//   import 'package:flutter/material.dart';

// void _editClient(Map<String, dynamic> client, String clientKey ,conte) async {
//     final nameController = TextEditingController(
//       text: client['name']?.toString() ?? '',
//     );
//     final ageController = TextEditingController(
//       text: client['age']?.toString() ?? '',
//     );
//     final phoneController = TextEditingController(
//       text: client['phone']?.toString() ?? '',
//     );
//     final detailsController = TextEditingController(
//       text: client['details']?.toString() ?? '',
//     );

//     List<Map<String, dynamic>> _dialogSelectedClientPackages = [];
//     String? _dialogSelectedPackageCategory;
//     String? _dialogSelectedPackageItem;

//     await showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: Text(
//               'Edit Client',
//               style: Theme.of(context).textTheme.headlineSmall,
//             ),
//             content: Container(
//               width: double.maxFinite,
//               constraints: BoxConstraints(
//                 maxHeight: MediaQuery.of(context).size.height * 0.8,
//                 maxWidth: MediaQuery.of(context).size.width * 0.9,
//               ),
//               child: StatefulBuilder(
//                 builder: (BuildContext context, StateSetter setStateDialog) {
//                   // Initialize dialog's package list when dialog is first built
//                   if (_dialogSelectedClientPackages.isEmpty &&
//                       (client['bookedPackages'] as List?)?.isNotEmpty == true) {
//                     _dialogSelectedClientPackages =
//                         List<Map<String, dynamic>>.from(
//                           client['bookedPackages'],
//                         );
//                   }

//                   return SingleChildScrollView(
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         TextField(
//                           controller: nameController,
//                           decoration: InputDecoration(
//                             labelText: 'Name',
//                             border: OutlineInputBorder(),
//                           ),
//                         ),
//                         SizedBox(height: 16),
//                         TextField(
//                           controller: ageController,
//                           keyboardType: TextInputType.number,
//                           decoration: InputDecoration(
//                             labelText: 'Age',
//                             border: OutlineInputBorder(),
//                           ),
//                         ),
//                         SizedBox(height: 16),
//                         TextField(
//                           controller: phoneController,
//                           keyboardType: TextInputType.phone,
//                           decoration: InputDecoration(
//                             labelText: 'Phone Number',
//                             border: OutlineInputBorder(),
//                           ),
//                         ),
//                         SizedBox(height: 16),
//                         TextField(
//                           controller: detailsController,
//                           decoration: InputDecoration(
//                             labelText: 'Details',
//                             border: OutlineInputBorder(),
//                           ),
//                           maxLines: 3,
//                         ),
//                         SizedBox(height: 24),
//                         Text(
//                           'Service Packages:',
//                           style: Theme.of(context).textTheme.titleMedium,
//                         ),
//                         SizedBox(height: 8),
//                         // Dropdown for Package Category
//                         DropdownButtonFormField<String>(
//                           value: _dialogSelectedPackageCategory,
//                           hint: Text('Select Package Category'),
//                           isExpanded: true,
//                           items:
//                               PackagesPage.packagesData.keys.map((
//                                 String category,
//                               ) {
//                                 return DropdownMenuItem<String>(
//                                   value: category,
//                                   child: Text(category),
//                                 );
//                               }).toList(),
//                           onChanged: (String? newValue) {
//                             setStateDialog(() {
//                               _dialogSelectedPackageCategory = newValue;
//                               _dialogSelectedPackageItem = null;
//                             });
//                           },
//                           decoration: InputDecoration(
//                             border: OutlineInputBorder(),
//                           ),
//                         ),
//                         SizedBox(height: 16),
//                         // Dropdown for Specific Package Item
//                         if (_dialogSelectedPackageCategory != null)
//                           DropdownButtonFormField<String>(
//                             value: _dialogSelectedPackageItem,
//                             hint: Text('Select Package Item'),
//                             isExpanded: true,
//                             items:
//                                 (PackagesPage
//                                             .packagesData[_dialogSelectedPackageCategory!] ??
//                                         [])
//                                     .map((String item) {
//                                       return DropdownMenuItem<String>(
//                                         value: item,
//                                         child: Text(item),
//                                       );
//                                     })
//                                     .toList(),
//                             onChanged: (String? newValue) {
//                               setStateDialog(() {
//                                 _dialogSelectedPackageItem = newValue;
//                               });
//                             },
//                             decoration: InputDecoration(
//                               border: OutlineInputBorder(),
//                             ),
//                           ),
//                         SizedBox(height: 16),
//                         ElevatedButton.icon(
//                           icon: Icon(Icons.add_shopping_cart),
//                           label: Text('Add Selected Package'),
//                           onPressed:
//                               (_dialogSelectedPackageCategory != null &&
//                                       _dialogSelectedPackageItem != null)
//                                   ? () {
//                                     final String itemName =
//                                         _dialogSelectedPackageItem!;
//                                     int sessions = 1;
//                                     final match = RegExp(
//                                       r'(\d+)',
//                                     ).firstMatch(itemName);
//                                     if (match != null) {
//                                       sessions =
//                                           int.tryParse(match.group(1)!) ?? 1;
//                                     }
//                                     final newPackage = {
//                                       'name': itemName,
//                                       'totalSessions': sessions,
//                                       'remainingSessions': sessions,
//                                       'category':
//                                           _dialogSelectedPackageCategory!,
//                                     };
//                                     setStateDialog(() {
//                                       if (!_dialogSelectedClientPackages.any(
//                                         (p) => p['name'] == newPackage['name'],
//                                       )) {
//                                         _dialogSelectedClientPackages.add(
//                                           newPackage,
//                                         );
//                                       } else {
//                                         ScaffoldMessenger.of(
//                                           context,
//                                         ).showSnackBar(
//                                           SnackBar(
//                                             content: Text(
//                                               '$itemName is already added.',
//                                             ),
//                                           ),
//                                         );
//                                       }
//                                     });
//                                   }
//                                   : null,
//                         ),
//                         SizedBox(height: 16),
//                         Text(
//                           'Client\'s Booked Packages:',
//                           style: Theme.of(context).textTheme.titleSmall,
//                         ),
//                         SizedBox(height: 8),
//                         _dialogSelectedClientPackages.isEmpty
//                             ? Container(
//                               padding: EdgeInsets.all(16),
//                               child: Text('No packages booked yet.'),
//                             )
//                             : Container(
//                               constraints: BoxConstraints(maxHeight: 200),
//                               child: ListView.builder(
//                                 shrinkWrap: true,
//                                 itemCount: _dialogSelectedClientPackages.length,
//                                 itemBuilder: (context, index) {
//                                   final package =
//                                       _dialogSelectedClientPackages[index];
//                                   return Card(
//                                     margin: EdgeInsets.symmetric(vertical: 4),
//                                     child: ListTile(
//                                       dense: true,
//                                       title: Text(
//                                         package['name'] ?? 'Unknown Package',
//                                         style: TextStyle(fontSize: 14),
//                                       ),
//                                       trailing: IconButton(
//                                         icon: Icon(
//                                           Icons.remove_circle_outline,
//                                           color: Colors.redAccent,
//                                           size: 20,
//                                         ),
//                                         onPressed: () {
//                                           setStateDialog(() {
//                                             _dialogSelectedClientPackages
//                                                 .removeAt(index);
//                                           });
//                                         },
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: Text('Cancel'),
//                 style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
//               ),
//               TextButton.icon(
//                 icon: Icon(Icons.delete, color: Colors.red),
//                 label: Text('Delete', style: TextStyle(color: Colors.red)),
//                 onPressed: () async {
//                   Navigator.pop(context); // Close edit dialog
//                   await _deleteClient(clientKey);
//                   _filterClients(
//                     _searchController.text,
//                   ); // Re-filter to update list
//                 },
//               ),
//               ElevatedButton(
//                 onPressed: () async {
//                   if (nameController.text.trim().isEmpty ||
//                       phoneController.text.trim().isEmpty) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text('Name and Phone Number are required.'),
//                         backgroundColor: Colors.orange,
//                       ),
//                     );
//                     return;
//                   }

//                   final updatedClient = {
//                     'id': client['id'],
//                     'name': nameController.text.trim(),
//                     'age': ageController.text.trim(),
//                     'phone': phoneController.text.trim(),
//                     'details': detailsController.text.trim(),
//                     'bookedPackages':
//                         _dialogSelectedClientPackages, // Fixed: Added this line
//                   };

//                   try {
//                     await clientBox.put(clientKey, updatedClient);
//                     await _firestore
//                         .collection('clients')
//                         .doc(clientKey)
//                         .set(updatedClient);

//                     Navigator.pop(context);
//                     _filterClients(
//                       _searchController.text,
//                     ); // Re-filter to update list

//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text('Client updated successfully.'),
//                         backgroundColor: Colors.green,
//                       ),
//                     );
//                   } catch (e) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text('Failed to update client: $e'),
//                         backgroundColor: Colors.red,
//                       ),
//                     );
//                   }
//                 },
//                 child: Text('Save'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Theme.of(context).primaryColor,
//                 ),
//               ),
//             ],
//           ),
//     );
//   }