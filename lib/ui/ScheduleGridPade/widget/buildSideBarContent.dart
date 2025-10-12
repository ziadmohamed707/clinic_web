//   import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:physioprime/core/app_consts/app_consts.dart';
// import 'package:physioprime/ui/FinancialManagementPage/ui/financial_management_page.dart';
// import 'package:physioprime/ui/LoginPage/models/user_model.dart';
// import 'package:physioprime/ui/ManageDoctorPage/ui/manage_doctors_page.dart';
// import 'package:physioprime/ui/ManageUserPage/ui/manage_users_page.dart';
// import 'package:physioprime/ui/ScheduleGridPade/widget/buildModernSidebarItem.dart';
// import 'package:physioprime/ui/billPaymentScreen/ui/bill_notification_screen.dart';
// import 'package:physioprime/ui/billPaymentScreen/ui/system_services_page.dart';

//  _buildSidebarContent(
//     BuildContext context,

//     UserModel user,
// ) {
//     return Container(
//       width: 300,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             Theme.of(context).primaryColor.withOpacity(0.95),
//             Theme.of(context).primaryColorDark.withOpacity(0.9),
//             Colors.black.withOpacity(0.8),
//           ],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.only(
//           topRight: Radius.circular(24), // Cannot be const
//           bottomRight: Radius.circular(24),
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.3),
//             blurRadius: 20, // Cannot be
//             offset: Offset(5, 0),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.only(
//           // Cannot be const
//           topRight: Radius.circular(24),
//           bottomRight: Radius.circular(24),
//         ),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//           child: Container(
//             decoration: BoxDecoration(
//               // Cannot be const
//               gradient: LinearGradient(
//                 colors: [
//                   Colors.white.withOpacity(0.1),
//                   Colors.white.withOpacity(0.05),
//                 ],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               border: Border.all(
//                 color: Colors.white.withOpacity(0.2),
//                 width: 1,
//               ),
//             ),
//             child: Column(
//               children: [
//                 // Header Section
//                 Padding(
//                   // Cannot be const
//                   padding: const EdgeInsets.all(32),
//                   child: Column(
//                     children: [
//                       // Logo Container
//                       TweenAnimationBuilder(
//                         duration: Duration(milliseconds: 1500),
//                         tween: Tween<double>(begin: 0, end: 1),
//                         builder: (context, double value, child) {
//                           return Transform.scale(
//                             scale: 0.8 + (0.2 * value),
//                             child: Container(
//                               width: 90,
//                               height: 90,
//                               decoration: BoxDecoration(
//                                 // Cannot be const
//                                 shape: BoxShape.circle,
//                                 gradient: RadialGradient(
//                                   colors: [
//                                     Colors.white.withOpacity(0.3 * value),
//                                     Colors.white.withOpacity(0.1 * value),
//                                     Colors.transparent,
//                                   ],
//                                 ),
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: Colors.white.withOpacity(
//                                       0.3 * value,
//                                     ),
//                                     blurRadius: 20 * value,
//                                     spreadRadius: 5 * value,
//                                   ),
//                                 ],
//                               ),
//                               child: Container(
//                                 margin: const EdgeInsets.all(3),
//                                 decoration: BoxDecoration(
//                                   shape: BoxShape.circle,
//                                   border: Border.all(
//                                     color: Colors.white.withOpacity(0.4),
//                                     width: 2,
//                                   ),
//                                 ),
//                                 child: ClipRRect(
//                                   borderRadius: BorderRadius.circular(45),
//                                   child: Image.asset(
//                                     'assets/phsioprime_logo.jpg',
//                                     fit: BoxFit.cover,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                       SizedBox(height: 20),
//                       // App Name
//                       ShaderMask(
//                         shaderCallback:
//                             (bounds) => LinearGradient(
//                               colors: [
//                                 Colors.white,
//                                 Colors.white.withOpacity(0.8),
//                                 Colors.cyan.withOpacity(0.9),
//                               ],
//                             ).createShader(bounds),
//                         child: Text(
//                           AppConsts.appName,
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 22,
//                             fontWeight: FontWeight.w800,
//                             letterSpacing: 1.2,
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 12),
//                       // User Badge
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 16,
//                           vertical: 8,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.15),
//                           borderRadius: BorderRadius.circular(25),
//                           border: Border.all(
//                             color: Colors.white.withOpacity(0.3),
//                             width: 1,
//                           ),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.1),
//                               blurRadius: 10,
//                             ),
//                           ],
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Container(
//                               width: 8,
//                               height: 8,
//                               decoration: BoxDecoration(
//                                 color: Colors.green.withOpacity(0.8),
//                                 shape: BoxShape.circle,
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: Colors.green.withOpacity(0.6),
//                                     blurRadius: 8,
//                                     spreadRadius: 2,
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             SizedBox(width: 8),
//                             Text(
//                               user.username ?? '',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                             SizedBox(width: 8),
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 8,
//                                 vertical: 2,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: Colors.amber.withOpacity(0.2),
//                                 borderRadius: BorderRadius.circular(10),
//                                 border: Border.all(
//                                   color: Colors.amber.withOpacity(0.5),
//                                   width: 1,
//                                 ),
//                               ),
//                               child: Text(
//                                 (user.role ?? '').toUpperCase(),
//                                 style: TextStyle(
//                                   color: Colors.amber.shade200,
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.w700,
//                                   letterSpacing: 0.5,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 // Navigation Menu
//                 Expanded(
//                   child: ListView(
//                     // Cannot be const
//                     padding: const EdgeInsets.symmetric(horizontal: 20),
//                     children: [
//                       if (user.role == 'admin' ||
//                           user.role == 'desk') ...[
//                         buildModernSidebarItem(
//                           icon: Icons.person_add_alt_1_rounded,
//                           title: 'Add Client',
//                           subtitle: 'Register new clients',
//                           gradient: [
//                             Colors.blue.shade400,
//                             Colors.blue.shade600,
//                           ],
//                           onTap: _addClient,
//                         ),
//                         SizedBox(height: 12),
//                         buildModernSidebarItem(
//                           icon: Icons.groups_rounded,
//                           title: 'Clients List',
//                           subtitle: 'Manage all clients',
//                           gradient: [
//                             Colors.purple.shade400,
//                             Colors.purple.shade600,
//                           ],
//                           onTap: _openClientPage,
//                         ),
//                         SizedBox(height: 12),
//                         buildModernSidebarItem(
//                           icon: Icons.medical_services_rounded,
//                           title: 'Service Packages',
//                           subtitle: 'Healthcare plans',
//                           gradient: [
//                             Colors.green.shade400,
//                             Colors.green.shade600,
//                           ],
//                           onTap: _openPackagesPage,
//                         ),
//                         SizedBox(height: 12),
//                         buildModernSidebarItem(
//                           icon: Icons.account_balance_wallet_rounded,
//                           title: 'Financial Management',
//                           subtitle: 'Revenue & expenses',
//                           gradient: [
//                             Colors.orange.shade400,
//                             Colors.orange.shade600,
//                           ],
//                           onTap:
//                               () => Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (_) => FinancialManagementPage(),
//                                 ),
//                               ),
//                         ),
//                       ],
//                       if (user.role == 'admin') ...[
//                         // Cannot be const
//                         const SizedBox(height: 20),
//                         // Admin Section Divider
//                         Row(
//                           children: [
//                             Expanded(
//                               child: Container(
//                                 height: 1,
//                                 decoration: BoxDecoration(
//                                   gradient: LinearGradient(
//                                     colors: [
//                                       Colors.transparent,
//                                       Colors.white.withOpacity(0.3),
//                                       Colors.transparent,
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             Padding(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                               ),
//                               child: Text(
//                                 'ADMIN PANEL',
//                                 style: TextStyle(
//                                   color: Colors.white.withOpacity(0.7),
//                                   fontSize: 11,
//                                   fontWeight: FontWeight.w600,
//                                   letterSpacing: 1,
//                                 ),
//                               ),
//                             ),
//                             Expanded(
//                               child: Container(
//                                 height: 1,
//                                 decoration: BoxDecoration(
//                                   gradient: LinearGradient(
//                                     colors: [
//                                       Colors.transparent,
//                                       Colors.white.withOpacity(0.3),
//                                       Colors.transparent,
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 20),
//                         buildModernSidebarItem(
//                           icon: Icons.local_hospital_rounded,
//                           title: 'Manage Doctors',
//                           subtitle: 'Doctor profiles',
//                           gradient: [
//                             Colors.teal.shade400,
//                             Colors.teal.shade600,
//                           ],
//                           onTap:
//                               () => Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (_) => ManageDoctorsPage(),
//                                 ),
//                               ),
//                         ),
//                         SizedBox(height: 12),
//                         buildModernSidebarItem(
//                           icon: Icons.admin_panel_settings_rounded,
//                           title: 'Manage Users',
//                           subtitle: 'System users',
//                           gradient: [
//                             Colors.indigo.shade400,
//                             Colors.indigo.shade600,
//                           ],
//                           onTap:
//                               () => Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (_) => ManageUsersPage(),
//                                 ),
//                               ),
//                         ),
//                         SizedBox(height: 12),
//                         buildModernSidebarItem(
//                           icon: Icons.miscellaneous_services_rounded,
//                           title: 'System Services',
//                           subtitle: 'Request new features',
//                           gradient: [
//                             Colors.cyan.shade400,
//                             Colors.cyan.shade600,
//                           ],
//                           onTap:
//                               () => Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (_) => SystemServicesPage(),
//                                 ),
//                               ),
//                         ),
//                         SizedBox(height: 12),
//                         buildModernSidebarItem(
//                           icon: Icons.payment_rounded,
//                           title: 'Bills & Payments',
//                           subtitle: 'Manage your bills',
//                           gradient: [
//                             Colors.grey.shade600,
//                             Colors.grey.shade800,
//                           ],
//                           onTap:
//                               () => Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (_) => BillNotificationScreen(),
//                                 ),
//                               ),
//                         ),
//                       ],
//                       SizedBox(height: 40),
//                       // Logout Button
//                       _buildLogoutButton(),
//                       SizedBox(height: 20),
//                       Padding(
//                         padding: EdgeInsets.only(bottom: 20.0),
//                         child: Column(
//                           children: [
//                             const Text(
//                               'Developed by zyverse.dev',
//                               style: TextStyle(
//                                 fontSize: 11,
//                                 color: Colors.white,
//                               ),
//                             ),
//                             SizedBox(height: 4),
//                             Text(
//                               'Crafting Digital Realities | 01024375442',
//                               style: TextStyle(
//                                 fontSize: 10,
//                                 color: Colors.white.withOpacity(0.5),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//     Future<void> _cancelAppointment(
//     BuildContext dialogContext,
//     String key,
//     Map existing,
//     String columnDoctorName,
//   ) async {
//     final bool? confirmRemove = await showDialog<bool>(
//       context: dialogContext,
//       builder:
//           (confirmDialogContext) => AlertDialog(
//             // Cannot be const
//             title: const Text('Cancel Appointment'),
//             content: const Text(
//               'Are you sure you want to cancel this appointment? This will return a session if it was part of a package.',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(confirmDialogContext, false),
//                 child: const Text('No'),
//               ),
//               ElevatedButton(
//                 onPressed: () => Navigator.pop(confirmDialogContext, true),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.red,
//                 ), // Cannot be
//                 child: Text('Yes, Cancel'),
//               ),
//             ],
//           ),
//     );

//     if (confirmRemove != true) return;

//     try {
//       // If it was a package session, increment the remaining sessions
//       final String? clientId = existing['clientId']?.toString();
//       final String? packageNameUsed = existing['packageNameUsed'] as String?;

//       if (clientId != null && packageNameUsed != null) {
//         final clientBox = Hive.box('clients');
//         final clientData = Map<String, dynamic>.from(
//           clientBox.get(clientId) as Map? ?? {},
//         );
//         if (clientData.isNotEmpty) {
//           final bookedPackages =
//               (clientData['bookedPackages'] as List<dynamic>?)
//                   ?.map((p) => Map<String, dynamic>.from(p as Map))
//                   .toList() ??
//               [];

//           final packageIndex = bookedPackages.indexWhere(
//             (pkg) => pkg['name'] == packageNameUsed,
//           );

//           if (packageIndex != -1) {
//             final package = bookedPackages[packageIndex];
//             final remaining = (package['remainingSessions'] as int? ?? 0) + 1;
//             final total = package['totalSessions'] as int? ?? 0;

//             if (remaining <= total) {
//               package['remainingSessions'] = remaining;
//               clientData['bookedPackages'] = bookedPackages;
//               await _updateClientData(clientId, clientData);
//             }
//           }
//         }
//       }

//       // Update the appointment to 'cancelled'
//       final Map<String, dynamic> cancelledData = Map<String, dynamic>.from(
//         existing as Map,
//       );
//       cancelledData['status'] = 'cancelled';

//       box.put(key, cancelledData);
//       await _saveAppointmentToFirestore(key, cancelledData);

//       if (dialogContext.mounted) {
//         Navigator.pop(dialogContext, true); // Close the edit dialog
//       }
//     } catch (e) {
//       _showSnackBar('Error canceling appointment: $e', Colors.red);
//     }
//   }

//   void _addClient(
//     BuildContext context,
//   ) async {
//     final nameController = TextEditingController();
//     final ageController = TextEditingController();
//     final phoneController = TextEditingController();
//     final detailsController = TextEditingController();

//     await showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             // Cannot be const
//             title: Text(
//               'Add New Client',
//               style: Theme.of(context).textTheme.headlineSmall,
//             ),
//             content: SingleChildScrollView(
//               child: Column(
//                 // Cannot be const
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   TextField(
//                     controller: nameController,
//                     decoration: InputDecoration(
//                       labelText: 'Name',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   TextField(
//                     controller: ageController,
//                     keyboardType: TextInputType.number,
//                     decoration: InputDecoration(
//                       labelText: 'Age',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   TextField(
//                     controller: phoneController,
//                     keyboardType: TextInputType.phone,
//                     decoration: InputDecoration(
//                       labelText: 'Phone Number (e.g., 01012345678)',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   TextField(
//                     controller: detailsController,
//                     decoration: InputDecoration(
//                       labelText: 'Details / Notes',
//                       border: OutlineInputBorder(),
//                     ),
//                     maxLines: 3,
//                   ),
//                 ],
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: Text(
//                   'Cancel',
//                   style: TextStyle(color: Colors.grey.shade700),
//                 ),
//               ),
//               ElevatedButton.icon(
//                 onPressed: () async {
//                   if (nameController.text.isEmpty ||
//                       phoneController.text.isEmpty) {
//                     _showSnackBar(
//                       'Name and Phone Number are required.',
//                       Colors.orange,
//                     );
//                     return;
//                   }

//                   final clientBox = Hive.box('clients');
//                   final lastId = clientBox.get('lastId', defaultValue: 0);
//                   final newId = lastId + 1;
//                   final clientKey = newId.toString();

//                   final clientData = {
//                     'id': newId,
//                     'name': nameController.text.trim(),
//                     'age': ageController.text.trim(),
//                     'phone': phoneController.text.trim(),
//                     'details': detailsController.text.trim(),
//                     'bookedPackages': [],
//                   };

//                   await _updateClientData(clientKey, clientData);
//                   clientBox.put('lastId', newId);

//                   Navigator.pop(context);
//                   _showSnackBar('Client added successfully!', Colors.green);
//                   setState(() {});
//                 },
//                 icon: const Icon(Icons.person_add),
//                 label: const Text('Add Client'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Theme.of(context).primaryColor,
//                   foregroundColor: Colors.white,
//                 ),
//               ),
//             ],
//           ),
//     );
//   }

//   void _openClientPage() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => ClientListPage()),
//     );
//   }

//   void _openPackagesPage() {
//     Navigator.push(context, MaterialPageRoute(builder: (_) => PackagesPage()));
//   }
// Future<void> _updateClientData(
//     String clientId,
//     Map<String, dynamic> clientData,
//   ) async {
//     final clientBox = Hive.box('clients');
//     try {
//       await clientBox.put(clientId, clientData);
//       await _clientsCollection.doc(clientId).set(clientData);

//       final int currentClientIntId = clientData['id'] as int? ?? 0;
//       final firestoreMetadataRef = _clientsCollection.doc('metadata');
//       final metadataDoc = await firestoreMetadataRef.get();
//       final int currentFirestoreLastId =
//           (metadataDoc.data() as Map<String, dynamic>?)?['lastId'] as int? ?? 0;

//       if (currentClientIntId > currentFirestoreLastId) {
//         await firestoreMetadataRef.set({'lastId': currentClientIntId});
//       }
//     } catch (e) {
//       if (mounted) {
//         _showSnackBar('Failed to update client data: $e', Colors.red);
//       }
//     }
//   }