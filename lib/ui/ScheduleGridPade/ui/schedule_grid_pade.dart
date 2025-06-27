// // lib/ui/ScheduleGridPage/ui/schedule_grid_pade.dart
// import 'package:clinic_management_system/data/repositories/appointment_repository_impl.dart';
// import 'package:clinic_management_system/data/repositories/client_repository_impl.dart';
// import 'package:clinic_management_system/domain/usecases/get_appointments.dart';
// import 'package:clinic_management_system/domain/usecases/get_clients.dart';
// import 'package:clinic_management_system/ui/ClientListPage/ui/client_list_page.dart';
// import 'package:clinic_management_system/ui/FinancialManagementPage/ui/financial_management_page.dart';
// import 'package:clinic_management_system/ui/LoginPage/bloc/auth_bloc.dart';
// import 'package:clinic_management_system/ui/LoginPage/bloc/auth_event.dart';
// import 'package:clinic_management_system/ui/LoginPage/models/user_model.dart';
// import 'package:clinic_management_system/ui/LoginPage/ui/login_page.dart';
// import 'package:clinic_management_system/ui/ManageDoctorPage/ui/manage_doctors_page.dart';
// import 'package:clinic_management_system/ui/ManageUserPage/ui/manage_users_page.dart';
// import 'package:clinic_management_system/ui/PackagesPage/ui/packages_page.dart';
// import 'package:clinic_management_system/ui/ScheduleGridPade/bloc/schedule_grid_bloc.dart';
// import 'package:clinic_management_system/ui/ScheduleGridPade/bloc/schedule_grid_event.dart';
// import 'package:clinic_management_system/ui/ScheduleGridPade/bloc/schedule_grid_state.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // Still needed for Firestore types, if passed directly to BlocProvider
// import 'package:firebase_auth/firebase_auth.dart'; // Still needed if passed directly to BlocProvider
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hive_flutter/hive_flutter.dart'; // Still needed if passed directly to BlocProvider
// import 'package:intl/intl.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:clinic_management_system/widgets/state_card.dart';
// import 'package:clinic_management_system/domain/entities/appointment.dart'; // For Appointment entity
// import 'package:clinic_management_system/domain/entities/doctor.dart'; // For Doctor entity
// import 'package:clinic_management_system/domain/entities/client.dart'; // For Client entity
// import 'package:clinic_management_system/domain/entities/client_package.dart'; // For ClientPackage entity


// class ScheduleGridScreen extends StatelessWidget {
//   const ScheduleGridScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // Initial dispatch to load data for today's date when the screen is built
//     // This assumes the BlocProvider is set up higher in the widget tree.
//     // Ensure ScheduleGridBloc is provided via BlocProvider
//     // Example:
    
//     // BlocProvider(
//     //   create: (context) => ScheduleGridBloc(
//     //     getAppointments: GetAppointments(AppointmentRepositoryImpl(Firestore.instance)), // Provide actual implementations
//     //     getClients: GetClients(ClientRepositoryImpl(Firestore.instance, Hive.box('clients'))),
//     //     getDoctors: GetDoctors(DoctorRepositoryImpl(Firestore.instance, Hive.box('doctors'))),
//     //     saveAppointment: SaveAppointment(AppointmentRepositoryImpl(Firestore.instance), ClientRepositoryImpl(Firestore.instance, Hive.box('clients'))),
//     //     cancelAppointment: CancelAppointment(AppointmentRepositoryImpl(Firestore.instance)),
//     //     addClient: AddClient(ClientRepositoryImpl(Firestore.instance, Hive.box('clients'))),
//     //   )..add(LoadSchedule(DateTime.now())), // Dispatch initial event
//     //   child: const ScheduleGridScreen(),
//     // );
    

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Clinic Schedule'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: () {
//               context.read<AuthBloc>().add(AuthLogoutRequested());
//               Navigator.of(context).pushAndRemoveUntil(
//                 MaterialPageRoute(builder: (context) =>  LoginScreen()),
//                 (route) => false,
//               );
//             },
//           ),
//         ],
//       ),
//       drawer: Drawer(
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: <Widget>[
//             const DrawerHeader(
//               decoration: BoxDecoration(
//                 color: Colors.blue,
//               ),
//               child: Text(
//                 'Menu',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 24,
//                 ),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.people),
//               title: const Text('Manage Clients'),
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) =>  ClientListPage()),
//                 );
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.medical_services),
//               title: const Text('Manage Doctors'),
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => const ManageDoctorsPage()),
//                 );
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.account_circle),
//               title: const Text('Manage Users'),
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => const ManageUsersPage()),
//                 );
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.add_box),
//               title: const Text('Manage Packages'),
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) =>  PackagesPage()),
//                 );
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.attach_money),
//               title: const Text('Financial Management'),
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => const FinancialManagementPage()),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//       body: BlocConsumer<ScheduleGridBloc, ScheduleGridState>(
//         listener: (context, state) {
//           // Listen for side effects like showing SnackBars
//           if (state is ScheduleGridLoaded) {
//             if (state.successMessage != null) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text(state.successMessage!)),
//               );
//             }
//             if (state.errorMessage != null) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
//               );
//             }
//           } else if (state is ScheduleGridError) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text(state.message), backgroundColor: Colors.red),
//             );
//           }
//         },
//         builder: (context, state) {
//           if (state is ScheduleGridLoading || state is ScheduleGridInitial) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (state is ScheduleGridLoaded) {
//             final DateTime selectedDate = state.selectedDate;
//             final List<Doctor> availableDoctors = state.availableDoctors;
//             final Map<String, Appointment> appointments = state.appointments;
//             final List<Client> allClients = state.allClients;
//             final int todayAppointmentsCount = state.todayAppointmentsCount;
//             final int cancelledAppointmentsCount = state.cancelledAppointmentsCount;
//             final int totalClientsCount = state.totalClientsCount;
//             final int availableSlotsCount = state.availableSlotsCount;

//             return Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         DateFormat('EEEE, MMM d, yyyy').format(selectedDate),
//                         style: const TextStyle(
//                             fontSize: 18, fontWeight: FontWeight.bold),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.calendar_today),
//                         onPressed: () async {
//                           final DateTime? pickedDate = await showDatePicker(
//                             context: context,
//                             initialDate: selectedDate,
//                             firstDate: DateTime(2000),
//                             lastDate: DateTime(2100),
//                           );
//                           if (pickedDate != null && pickedDate != selectedDate) {
//                             context.read<ScheduleGridBloc>().add(DateSelected(pickedDate));
//                           }
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//                 Expanded(
//                   child: SingleChildScrollView(
//                     child: Padding(
//                       padding: const EdgeInsets.all(8.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.stretch,
//                         children: [
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceAround,
//                             children: [
//                               StateCard(
//                                 title: 'Today\'s Appointments',
//                                 value: todayAppointmentsCount.toString(),
//                                 icon: Icons.event,
//                                 color: Colors.blueAccent,
//                               ),
//                               StateCard(
//                                 title: 'Cancelled Appointments',
//                                 value: cancelledAppointmentsCount.toString(),
//                                 icon: Icons.cancel,
//                                 color: Colors.redAccent,
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceAround,
//                             children: [
//                               StateCard(
//                                 title: 'Total Clients',
//                                 value: totalClientsCount.toString(),
//                                 icon: Icons.people_alt,
//                                 color: Colors.greenAccent,
//                               ),
//                               StateCard(
//                                 title: 'Available Slots',
//                                 value: availableSlotsCount.toString(),
//                                 icon: Icons.access_time,
//                                 color: Colors.orangeAccent,
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//                           ElevatedButton.icon(
//                             onPressed: () => _buildAddClientDialog(context),
//                             icon: const Icon(Icons.person_add),
//                             label: const Text('Add New Client'),
//                           ),
//                           const SizedBox(height: 16),
//                           ...availableDoctors.map((doctor) {
//                             return Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Padding(
//                                   padding:
//                                       const EdgeInsets.symmetric(vertical: 8.0),
//                                   child: Text(
//                                     'Dr. ${doctor.name}',
//                                     style: const TextStyle(
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.bold),
//                                   ),
//                                 ),
//                                 GridView.builder(
//                                   shrinkWrap: true,
//                                   physics: const NeverScrollableScrollPhysics(),
//                                   gridDelegate:
//                                       const SliverGridDelegateWithFixedCrossAxisCount(
//                                     crossAxisCount: 3,
//                                     crossAxisSpacing: 8,
//                                     mainAxisSpacing: 8,
//                                     childAspectRatio: 1.0,
//                                   ),
//                                   itemCount: context.read<ScheduleGridBloc>().timeSlots.length,
//                                   itemBuilder: (context, index) {
//                                     final timeSlot = context.read<ScheduleGridBloc>().timeSlots[index];
//                                     final appointmentKey =
//                                         '${DateFormat('yyyy-MM-dd').format(selectedDate)}-${timeSlot}-${doctor.id}';
//                                     final Appointment? appointment =
//                                         appointments[appointmentKey];

//                                     return GestureDetector(
//                                       onTap: () {
//                                         if (appointment != null) {
//                                           _buildAppointmentDetailsDialog(
//                                               context, appointment);
//                                         } else {
//                                           _buildAppointmentDialog(
//                                             context,
//                                             doctor,
//                                             timeSlot,
//                                             selectedDate,
//                                             allClients, // Pass allClients to the dialog
//                                           );
//                                         }
//                                       },
//                                       child: Container(
//                                         height: 96,
//                                         padding: const EdgeInsets.all(12),
//                                         decoration: BoxDecoration(
//                                           color: appointment != null
//                                               ? (appointment.status == 'cancelled' ? Colors.grey[400] : Colors.blue[100])
//                                               : Colors.white,
//                                           border: Border.all(
//                                             color: Colors.grey[300]!,
//                                           ),
//                                           borderRadius:
//                                               BorderRadius.circular(4),
//                                         ),
//                                         child: Center(
//                                           child: Column(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.center,
//                                             children: [
//                                               Text(
//                                                 timeSlot,
//                                                 style: const TextStyle(
//                                                     fontWeight: FontWeight.bold),
//                                               ),
//                                               if (appointment != null)
//                                                 Text(
//                                                   '${appointment.patientName} ${appointment.status == 'cancelled' ? '(Cancelled)' : ''}',
//                                                   textAlign: TextAlign.center,
//                                                   style: TextStyle(
//                                                     fontSize: 12,
//                                                     color: appointment.status == 'cancelled' ? Colors.black54 : Colors.blue[800],
//                                                   ),
//                                                 ),
//                                             ],
//                                           ),
//                                         ),
//                                       ),
//                                     );
//                                   },
//                                 ),
//                               ],
//                             );
//                           }).toList(),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           } else {
//             return const Center(child: Text('Failed to load schedule.'));
//           }
//         },
//       ),
//     );
//   }

//   // --- Dialogs (updated to dispatch events) ---

//   void _buildAppointmentDialog(
//     BuildContext context,
//     Doctor doctor,
//     String timeSlot,
//     DateTime selectedDate,
//     List<Client> allClients,
//   ) {
//     final TextEditingController patientNameController = TextEditingController();
//     final TextEditingController patientPhoneController =
//         TextEditingController();
//     final TextEditingController serviceTypeController = TextEditingController();
//     final TextEditingController notesController = TextEditingController();

//     Client? selectedClient;
//     String? selectedFollowUpPackage;
//     List<String> clientPackageNames = [];

//     showDialog(
//       context: context,
//       builder: (BuildContext dialogContext) {
//         return StatefulBuilder(
//           builder: (context, setState) {
//             return AlertDialog(
//               title: const Text('Book Appointment'),
//               content: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     TextField(
//                       controller: patientNameController,
//                       decoration: const InputDecoration(labelText: 'Patient Name'),
//                       onChanged: (value) {
//                         setState(() {
//                           selectedClient = allClients.firstWhere(
//                             (client) => client.name == value,
//                             orElse: () => null!, // Will be handled by null check below
//                           );
//                           if (selectedClient != null && selectedClient!.bookedPackages.isNotEmpty) {
//                             clientPackageNames = selectedClient!.bookedPackages.map((pkg) => pkg.name).toList();
//                             selectedFollowUpPackage = null; // Reset selection
//                           } else {
//                             clientPackageNames = [];
//                             selectedFollowUpPackage = null;
//                           }
//                         });
//                       },
//                     ),
//                     if (selectedClient == null) // Only show if no client selected from existing list
//                       TextField(
//                         controller: patientPhoneController,
//                         keyboardType: TextInputType.phone,
//                         decoration:
//                             const InputDecoration(labelText: 'Patient Phone'),
//                       ),
//                     TextField(
//                       controller: serviceTypeController,
//                       decoration: const InputDecoration(labelText: 'Service Type'),
//                     ),
//                     if (selectedClient != null && clientPackageNames.isNotEmpty)
//                       DropdownButtonFormField<String>(
//                         value: selectedFollowUpPackage,
//                         decoration: const InputDecoration(labelText: 'Select Follow-up Package'),
//                         items: clientPackageNames.map((name) {
//                           return DropdownMenuItem(
//                             value: name,
//                             child: Text(name),
//                           );
//                         }).toList(),
//                         onChanged: (value) {
//                           setState(() {
//                             selectedFollowUpPackage = value;
//                           });
//                         },
//                       ),
//                     TextField(
//                       controller: notesController,
//                       decoration: const InputDecoration(labelText: 'Notes'),
//                       maxLines: 3,
//                     ),
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(dialogContext),
//                   child: const Text('Cancel'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () {
//                     if (patientNameController.text.isEmpty ||
//                         serviceTypeController.text.isEmpty) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                             content: Text('Please fill all required fields')),
//                       );
//                       return;
//                     }

//                     final Appointment newAppointment = Appointment(
//                       id:
//                           '${DateFormat('yyyy-MM-dd').format(selectedDate)}-${timeSlot}-${doctor.id}',
//                       patientName: patientNameController.text,
//                       phoneNumber: selectedClient?.phoneNumber ?? patientPhoneController.text,
//                       doctorName: doctor.name,
//                       timeSlot: timeSlot,
//                       date: DateFormat('yyyy-MM-dd').format(selectedDate),
//                       status: AppointmentStatus.booked,
//                       clientId: selectedClient?.id, // Use existing client ID
//                       serviceType: ServiceType.,
//                       // The package information should be derived from selectedFollowUpPackage if applicable
//                       packageNameUsed: selectedFollowUpPackage,
//                     );

//                     context.read<ScheduleGridBloc>().add(
//                           SaveAppointmentEvent(
//                             appointment: newAppointment,
//                             selectedClient: selectedClient,
//                             serviceType: serviceTypeController.text,
//                             followUpPackageName: selectedFollowUpPackage,
//                           ),
//                         );
//                     Navigator.pop(dialogContext);
//                   },
//                   child: const Text('Save'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }

//   void _buildAppointmentDetailsDialog(
//       BuildContext context, Appointment appointment) {
//     showDialog(
//       context: context,
//       builder: (BuildContext dialogContext) {
//         return AlertDialog(
//           title: const Text('Appointment Details'),
//           content: SingleChildScrollView(
//             child: ListBody(
//               children: <Widget>[
//                 Text('Patient: ${appointment.patientName}'),
//                 Text('Doctor: ${appointment.doctorName}'),
//                 Text('Time: ${appointment.timeSlot}'),
//                 Text('Date: ${appointment.date}'),
//                 Text('Service: ${appointment.serviceType ?? 'N/A'}'),
//                 if (appointment.packageNameUsed != null)
//                   Text('Package Used: ${appointment.packageNameUsed}'),
//                 Text('Phone: ${appointment.phoneNumber ?? 'N/A'}'),
//                 Text('Status: ${appointment.status}'),
//               ],
//             ),
//           ),
//           actions: <Widget>[
//             if (appointment.status == 'booked')
//               TextButton(
//                 child: const Text('Cancel Appointment'),
//                 onPressed: () {
//                   Navigator.pop(dialogContext); // Close details dialog
//                   _buildCancelAppointmentDialog(context, appointment);
//                 },
//               ),
//             TextButton(
//               child: const Text('Close'),
//               onPressed: () {
//                 Navigator.of(dialogContext).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _buildCancelAppointmentDialog(
//       BuildContext context, Appointment appointment) {
//     showDialog(
//       context: context,
//       builder: (BuildContext dialogContext) {
//         return AlertDialog(
//           title: const Text('Confirm Cancellation'),
//           content: Text(
//               'Are you sure you want to cancel the appointment for ${appointment.patientName} with Dr. ${appointment.doctorName} on ${appointment.date} at ${appointment.timeSlot}?'),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('No'),
//               onPressed: () {
//                 Navigator.of(dialogContext).pop();
//               },
//             ),
//             ElevatedButton(
//               child: const Text('Yes, Cancel'),
//               onPressed: () {
//                 context.read<ScheduleGridBloc>().add(
//                       CancelAppointmentEvent(
//                         appointmentId: appointment.id,
//                         patientName: appointment.patientName,
//                         patientPhone: appointment.phoneNumber ?? '',
//                         doctorName: appointment.doctorName,
//                         clientId: appointment.clientId,
//                         serviceType: appointment.serviceType.toString() ?? 'N/A',
//                         packageNameUsed: appointment.packageNameUsed,
//                         // packageCategoryUsed: appointment.packageCategoryUsed, // Assuming this field exists if needed for logic
//                       ),
//                     );
//                 Navigator.of(dialogContext).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _buildAddClientDialog(BuildContext context) {
//     final TextEditingController nameController = TextEditingController();
//     final TextEditingController ageController = TextEditingController();
//     final TextEditingController phoneController = TextEditingController();
//     final TextEditingController detailsController = TextEditingController();

//     showDialog(
//       context: context,
//       builder: (BuildContext dialogContext) {
//         return AlertDialog(
//           title: const Text('Add New Client'),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 TextField(
//                   controller: nameController,
//                   decoration: const InputDecoration(labelText: 'Name'),
//                 ),
//                 TextField(
//                   controller: ageController,
//                   keyboardType: TextInputType.number,
//                   decoration: const InputDecoration(labelText: 'Age'),
//                 ),
//                 TextField(
//                   controller: phoneController,
//                   keyboardType: TextInputType.phone,
//                   decoration: const InputDecoration(labelText: 'Phone'),
//                 ),
//                 TextField(
//                   controller: detailsController,
//                   decoration: const InputDecoration(labelText: 'Details'),
//                   maxLines: 3,
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(dialogContext),
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 if (nameController.text.isEmpty ||
//                     phoneController.text.isEmpty) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                         content: Text('Please fill name and phone')),
//                   );
//                   return;
//                 }

//                 context.read<ScheduleGridBloc>().add(
//                       AddClientEvent(
//                         name: nameController.text,
//                         age: int.parse(ageController.text), // You might need to parse this to int
//                         phone: phoneController.text,
//                         details: detailsController.text,
//                         bookedPackages: [], // No packages on initial add
//                       ),
//                     );
//                 Navigator.pop(dialogContext);
//               },
//               child: const Text('Add'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // Helper method for launching calls (moved from original)
//   Future<void> _makeCall(String phoneNumber) async {
//     final Uri launchUri = Uri(
//       scheme: 'tel',
//       path: phoneNumber,
//     );
//     if (await canLaunchUrl(launchUri)) {
//       await launchUrl(launchUri);
//     } else {
//       // Handle error: could not launch
//       if (kDebugMode) {
//         print('Could not launch $launchUri');
//       }
//     }
//   }
// }


import 'package:clinic_management_system/core/app_consts/app_consts.dart';
import 'package:clinic_management_system/ui/ClientListPage/ui/client_list_page.dart';
import 'package:clinic_management_system/ui/FinancialManagementPage/ui/financial_management_page.dart';
import 'package:clinic_management_system/ui/LoginPage/bloc/auth_bloc.dart';
import 'package:clinic_management_system/ui/LoginPage/bloc/auth_event.dart';
import 'package:clinic_management_system/ui/LoginPage/models/user_model.dart';
import 'package:clinic_management_system/ui/LoginPage/ui/login_page.dart';
import 'package:clinic_management_system/ui/ManageDoctorPage/ui/manage_doctors_page.dart';
import 'package:clinic_management_system/ui/ManageUserPage/ui/manage_users_page.dart';
import 'package:clinic_management_system/ui/PackagesPage/ui/packages_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clinic_management_system/widgets/state_card.dart'; // Ensure this is imported if used

class ScheduleGridScreen extends StatefulWidget {
  final UserModel user; // Add user parameter

  const ScheduleGridScreen({Key? key, required this.user}) : super(key: key);

  @override
  _ScheduleGridScreenState createState() => _ScheduleGridScreenState();
}



class _ScheduleGridScreenState extends State<ScheduleGridScreen> {
  // final List<String> doctorNames = [
  //   'Dr. Smith',
  //   'Dr. Jones',
  //   'Dr. Brown',
  //   'Dr. Davis',
  //   'Dr. Wilson',
  // ];

  List<Map<String, dynamic>> _availableDoctorsForSelectedDate = [];
  List<Map<String, dynamic>> _selectedClientPackages =
      []; // To store packages selected for this client
  final List<String> timeSlots = [
    '09:00 AM',
    '09:40 AM',
    '10:20 AM',
    '11:00 AM',
    '11:40 AM',
    '12:20 PM',
    '01:00 PM',
    '01:40 PM',
    '02:20 PM',
    '03:00 PM',
    '03:40 PM',
    '04:20 PM',
    '05:00 PM',
    '05:40 PM',
    '06:20 PM',
    '07:00 PM',
    '07:40 PM',
    '08:20 PM',
    '09:00 PM',
    '09:40 PM',
    '10:20 PM',
    '11:00 PM',
  ];

  late Box box;
  DateTime selectedDate = DateTime.now();
  bool isDrawerPinned = true;
  late Box _doctorsBox;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late CollectionReference _appointmentsCollection;
  late CollectionReference _clientsCollection;
  late CollectionReference _doctorsCollection;

  @override
  void initState() {
    super.initState();
    box = Hive.box('appointments');
    _doctorsBox = Hive.box('doctors');

    _appointmentsCollection = _firestore.collection('appointments');
    _clientsCollection = _firestore.collection('clients');
    _doctorsCollection = _firestore.collection('doctors');

    _syncData();
  }

  Future<void> _syncData() async {
    try {
      // Sync clients
      final clientsSnapshot = await _clientsCollection.get();
      final clientBox = Hive.box('clients');

      final lastIdDoc = await _clientsCollection.doc('metadata').get();
      if (lastIdDoc.exists) {
        clientBox.put(
          'lastId',
          (lastIdDoc.data() as Map<String, dynamic>?)?['lastId'],
        );
      }

      for (var doc in clientsSnapshot.docs) {
        if (doc.id != 'metadata') {
          clientBox.put(doc.id, doc.data());
        }
      }

      // Sync appointments
      final appointmentsSnapshot = await _appointmentsCollection.get();
      for (var doc in appointmentsSnapshot.docs) {
        box.put(doc.id, doc.data());
      }
      // Sync doctors
      final doctorsSnapshot = await _doctorsCollection.get();
      for (var doc in doctorsSnapshot.docs) {
        _doctorsBox.put(doc.id, doc.data());
      }
      _loadAvailableDoctorsForSelectedDate(); // Load doctors for the initial date

      setState(() {
        // Refresh UI after sync
      });
    } catch (e) {
      print('Error syncing data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sync data: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _loadAvailableDoctorsForSelectedDate() {
    final allDoctors =
        _doctorsBox.values
            .map((doc) => Map<String, dynamic>.from(doc as Map))
            .toList();
    final String dayOfWeek = DateFormat(
      'EEEE',
    ).format(selectedDate); // e.g., "Monday"

    setState(() {
      _availableDoctorsForSelectedDate =
          allDoctors.where((doctor) {
            final List<dynamic> availableDays =
                doctor['availableDays'] as List<dynamic>? ?? [];
            return availableDays.contains(dayOfWeek);
          }).toList();
      // Optionally sort doctors by name
      _availableDoctorsForSelectedDate.sort(
        (a, b) => (a['name'] as String).compareTo(b['name'] as String),
      );
    });
  }

  Future<void> _saveAppointmentToFirestore(
    String key,
    Map<String, dynamic> data,
  ) async {
    try {
      await _appointmentsCollection.doc(key).set(data);
    } catch (e) {
      print('Error saving to Firestore: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save appointment: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _saveClientToFirestore(
    String key,
    Map<String, dynamic> data,
  ) async {
    try {
      await _clientsCollection.doc(key).set(data);
      // Only update lastId if it's the latest ID
      final currentLastId = Hive.box('clients').get('lastId', defaultValue: 0);
      if (data['id'] > currentLastId) {
        // await _clientsCollection.doc('metadata').set({'lastId': data['id']});
        await _clientsCollection.doc(key).set(data);
        final currentLastId = Hive.box(
          'clients',
        ).get('lastId', defaultValue: 0);
        if (data['id'] > currentLastId) {
          await _clientsCollection.doc('metadata').set({'lastId': data['id']});
        }
      }
    } catch (e) {
      print('Error saving client to Firestore: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save client: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Centralized method to update client data in Hive and Firestore, including metadata
  Future<void> _updateClientData(
    String clientId,
    Map<String, dynamic> clientData,
  ) async {
    final clientBox = Hive.box('clients');
    try {
      await clientBox.put(clientId, clientData); // Save to Hive
      await _clientsCollection
          .doc(clientId)
          .set(clientData); // Sync to Firestore

      // Update lastId in Firestore metadata if this client's ID is the new highest
      final int currentClientIntId = clientData['id'] as int? ?? 0;
      final firestoreMetadataRef = _clientsCollection.doc('metadata');
      final metadataDoc = await firestoreMetadataRef.get();
      final int currentFirestoreLastId =
          (metadataDoc.data() as Map<String, dynamic>?)?['lastId'] as int? ?? 0;
      if (currentClientIntId > currentFirestoreLastId) {
        await firestoreMetadataRef.set({'lastId': currentClientIntId});
      }
    } catch (e) {
      print('Error updating client data (ID: $clientId): $e');
      if (mounted) {
        // Check if widget is still in the tree
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update client data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  // For web: import 'dart:html' as html;

  void _editCell(String timeSlot, Map<String, dynamic> doctorData) async {
    final String formattedDateForKey = DateFormat(
      'yyyy-MM-dd',
    ).format(selectedDate);

    final String key = '$formattedDateForKey-$timeSlot-${doctorData['id']}';
    final String columnDoctorName = doctorData['name'] as String;

    final existing = box.get(
      key,
      defaultValue: {
        'patient': '',
        'doctor': columnDoctorName,
        'phone': '',
        'clientId': null,
        'status': null,
        'serviceType': null,
      },
    );

    // Initialize with existing doctor or column doctor
    final doctorController = TextEditingController(
      text: existing['doctor'] ?? columnDoctorName,
    );

    final clientBox = Hive.box('clients');
    final allClients =
        clientBox.keys
            .where((key) => key != 'lastId')
            .map(
              (key) =>
                  Map<String, dynamic>.from(clientBox.get(key) as Map? ?? {}),
            )
            .toList();

    // Initialize selected client from existing appointment
    Map? selectedClient;
    if (existing['clientId'] != null) {
      final clientData = clientBox.get(existing['clientId'].toString());
      if (clientData != null) {
        selectedClient = Map<String, dynamic>.from(clientData as Map);
      }
    }
    // Fallback to patient name if clientId not found but patient name exists
    else if (existing['patient'] != null &&
        (existing['patient'] as String).isNotEmpty) {
      selectedClient = {
        'name': existing['patient'],
        'phone': existing['phone'] ?? '',
        'id': existing['clientId'],
      };
    }

    final searchController = TextEditingController();
    List<Map> localFilteredClients = List.from(allClients);
    String? _dialogSelectedServiceType = existing['serviceType'] as String?;
    String? _dialogSelectedFollowUpPackageName;

    final bool? appointmentSaved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            void filterClients(String query) {
              setStateDialog(() {
                if (query.isEmpty) {
                  localFilteredClients = List.from(allClients);
                } else {
                  localFilteredClients =
                      allClients.where((client) {
                        final name =
                            client['name']?.toString().toLowerCase() ?? '';
                        final id = client['id']?.toString().toLowerCase() ?? '';
                        return name.contains(query.toLowerCase()) ||
                            id.contains(query.toLowerCase());
                      }).toList();
                }
              });
            }

            List<Map<String, dynamic>> _clientActivePackagesForFollowUp = [];
            if (selectedClient != null &&
                _dialogSelectedServiceType == 'Follow-up Session') {
              final clientDataFromBox = clientBox.get(
                selectedClient!['id']?.toString(),
              );
              if (clientDataFromBox is Map) {
                final currentClientData = Map<String, dynamic>.from(
                  clientDataFromBox,
                );
                if (currentClientData['bookedPackages'] != null) {
                  _clientActivePackagesForFollowUp =
                      (currentClientData['bookedPackages'] as List<dynamic>)
                          .map((p) => Map<String, dynamic>.from(p as Map))
                          .where(
                            (pkg) =>
                                (pkg['remainingSessions'] as int? ?? 0) > 0,
                          )
                          .toList();
                }
              }
            }

            // Reset follow-up package selection if conditions change
            if (_dialogSelectedServiceType != 'Follow-up Session' ||
                _clientActivePackagesForFollowUp.isEmpty) {
              _dialogSelectedFollowUpPackageName = null;
            } else if (_dialogSelectedFollowUpPackageName != null &&
                !_clientActivePackagesForFollowUp.any(
                  (pkg) => pkg['name'] == _dialogSelectedFollowUpPackageName,
                )) {
              _dialogSelectedFollowUpPackageName = null;
            }

            return AlertDialog(
              title: Text(
                'Edit Appointment on ${DateFormat('MMM d').format(selectedDate)} at $timeSlot',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              content: PopScope(
                canPop: true,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Show current appointment info if exists
                        if (existing['patient'] != null &&
                            (existing['patient'] as String).isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 15),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Appointment:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('Patient: ${existing['patient']}'),
                                Text('Doctor: ${existing['doctor']}'),
                                if (existing['serviceType'] != null)
                                  Text('Service: ${existing['serviceType']}'),
                                if (existing['status'] != null)
                                  Text('Status: ${existing['status']}'),
                              ],
                            ),
                          ),

                        // Client Search Field
                        TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            labelText: 'Search Client by Name or ID',
                            suffixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          autofocus: selectedClient == null,
                          onChanged: filterClients,
                        ),
                        const SizedBox(height: 10),

                        // Selected Client Display
                        if (selectedClient != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Selected: ${selectedClient!['name']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                      Text('ID: ${selectedClient!['id']}'),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setStateDialog(() {
                                      selectedClient = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),

                        // Client List (only show if no client selected or searching)
                        if (selectedClient == null ||
                            searchController.text.isNotEmpty)
                          Container(
                            height: 200,
                            width: double.maxFinite,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child:
                                localFilteredClients.isEmpty
                                    ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text(
                                          'No clients found. Add a new client or refine search.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    )
                                    : ListView.builder(
                                      itemCount: localFilteredClients.length,
                                      itemBuilder: (context, index) {
                                        final client =
                                            localFilteredClients[index];
                                        final isSelected =
                                            selectedClient != null &&
                                            selectedClient!['id'] ==
                                                client['id'];

                                        return ListTile(
                                          title: Text(
                                            '${client['name']}',
                                            style: TextStyle(
                                              fontWeight:
                                                  isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                            ),
                                          ),
                                          subtitle: Text('ID: ${client['id']}'),
                                          trailing:
                                              isSelected
                                                  ? const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.green,
                                                  )
                                                  : null,
                                          onTap: () {
                                            setStateDialog(() {
                                              selectedClient = client;
                                              searchController.clear();
                                            });
                                          },
                                          tileColor:
                                              isSelected
                                                  ? Theme.of(context)
                                                      .primaryColor
                                                      .withOpacity(0.1)
                                                  : null,
                                        );
                                      },
                                    ),
                          ),
                        const SizedBox(height: 15),

                        // Service Type Dropdown
                        DropdownButtonFormField<String>(
                          value: _dialogSelectedServiceType,
                          hint: const Text('Select Service Type'),
                          isExpanded: true,
                          items:
                             AppConsts().kServiceTypes.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                          onChanged: (String? newValue) {
                            setStateDialog(() {
                              _dialogSelectedServiceType = newValue;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Service Type',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Follow-up Package Selection (if applicable)
                        if (_dialogSelectedServiceType == 'Follow-up Session' &&
                            selectedClient != null &&
                            _clientActivePackagesForFollowUp.isNotEmpty)
                          DropdownButtonFormField<String>(
                            value: _dialogSelectedFollowUpPackageName,
                            hint: const Text('Select Package for Follow-up'),
                            isExpanded: true,
                            items:
                                _clientActivePackagesForFollowUp.map((package) {
                                  return DropdownMenuItem<String>(
                                    value: package['name'],
                                    child: Text(
                                      '${package['name']} (${package['remainingSessions']} sessions left)',
                                    ),
                                  );
                                }).toList(),
                            onChanged: (String? newValue) {
                              setStateDialog(() {
                                _dialogSelectedFollowUpPackageName = newValue;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Follow-up Package',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                        const SizedBox(height: 15),

                        // Doctor Field
                        TextField(
                          controller: doctorController,
                          decoration: InputDecoration(
                            labelText: 'Assigned Doctor',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                // Cancel Button
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                  child: const Text('Cancel'),
                ),

                // Delete Appointment Button (if booked)
                if (existing['status'] == 'booked')
                  TextButton.icon(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed:
                        () => _cancelAppointment(
                          dialogContext,
                          key,
                          existing,
                          columnDoctorName,
                          _dialogSelectedServiceType,
                        ),
                  ),

                // Save Button
                ElevatedButton(
                  onPressed: () {
                    if (_dialogSelectedServiceType == 'Follow-up Session' &&
                        selectedClient != null &&
                        _clientActivePackagesForFollowUp.isNotEmpty &&
                        (_dialogSelectedFollowUpPackageName == null ||
                            _dialogSelectedFollowUpPackageName!.isEmpty)) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please select a package for the follow-up session.',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    _saveAppointment(
                      dialogContext,
                      key,
                      selectedClient,
                      doctorController.text,
                      _dialogSelectedServiceType,
                      _dialogSelectedFollowUpPackageName,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Appointment'),
                ),

                // WhatsApp Button (if client selected)
                if (selectedClient != null)
                  TextButton.icon(
                    icon: const Icon(Icons.chat, color: Colors.green),
                    label: const Text(
                      'WhatsApp',
                      style: TextStyle(color: Colors.green),
                    ),
                    onPressed:
                        () => _sendWhatsAppMessage(selectedClient!, timeSlot),
                  ),
              ],
            );
          },
        );
      },
    );

    // Dispose controllers
    doctorController.dispose();
    searchController.dispose();

    if (appointmentSaved == true) {
      setState(() {
        // Force rebuild to refresh the UI
      });
    }
  }

  // Helper method for canceling appointment
  Future<void> _cancelAppointment(
    BuildContext dialogContext,
    String key,
    Map existing,
    String columnDoctorName,
    String? currentSelectedServiceInDialog,
  ) async {
    final bool? confirmRemove = await showDialog<bool>(
      context: dialogContext,
      builder:
          (confirmDialogContext) => AlertDialog(
            title: const Text('Cancel Appointment'),
            content: const Text(
              'Are you sure you want to cancel this appointment? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(confirmDialogContext, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(confirmDialogContext, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Yes, Cancel'),
              ),
            ],
          ),
    );

    if (confirmRemove == true) {
      try {
        final clientBox = Hive.box('clients');
        final String? clientId = existing['clientId']?.toString();
        final String? originalPackageNameUsed =
            existing['packageNameUsed'] as String?;

        bool packageSessionIncremented = false;

        if (clientId != null && originalPackageNameUsed != null) {
          Map<String, dynamic> clientData = Map<String, dynamic>.from(
            clientBox.get(clientId) as Map? ?? {},
          );
          List<Map<String, dynamic>> bookedPackages =
              (clientData['bookedPackages'] as List<dynamic>?)
                  ?.map((p) => Map<String, dynamic>.from(p as Map))
                  .toList() ??
              [];

          for (int i = 0; i < bookedPackages.length; i++) {
            Map<String, dynamic> pkg = bookedPackages[i];
            if (pkg['name'] == originalPackageNameUsed) {
              int currentRemaining = pkg['remainingSessions'] as int? ?? 0;
              int totalSessions = pkg['totalSessions'] as int? ?? 0;
              if (currentRemaining < totalSessions) {
                pkg['remainingSessions'] = currentRemaining + 1;
                bookedPackages[i] = pkg;
                packageSessionIncremented = true;
              }
              break;
            }
          }
          if (packageSessionIncremented) {
            clientData['bookedPackages'] = bookedPackages;
            clientBox.put(clientId, clientData);
            await _updateClientData(
              clientId,
              clientData,
            ); // Use refactored method
          }
        }

        final cancelledAppointment = {
          'patient': existing['patient'] ?? '',
          'phone': existing['phone'] ?? '',
          'clientId': existing['clientId'],
          'doctor': columnDoctorName,
          'status': 'cancelled',
          'serviceType': existing['serviceType'],
          'packageNameUsed':
              existing['packageNameUsed'], // Keep for historical record
          'packageCategoryUsed': existing['packageCategoryUsed'],
        };

        box.put(key, cancelledAppointment);
        await _saveAppointmentToFirestore(key, cancelledAppointment);

        if (dialogContext.mounted) {
          Navigator.pop(dialogContext, true);
        }
      } catch (e) {
        if (dialogContext.mounted) {
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            SnackBar(
              content: Text('Error canceling appointment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Helper method for saving appointment
  void _saveAppointment(
    BuildContext dialogContext,
    String key,
    Map? selectedClient,
    String doctor, [
    String? serviceType,
    String? followUpPackageName, // Added missing parameter
  ]) {
    if (selectedClient != null) {
      final clientBox = Hive.box('clients');
      Map<String, dynamic> clientData = Map<String, dynamic>.from(
        clientBox.get(selectedClient['id'].toString()) as Map? ?? {},
      );
      List<Map<String, dynamic>> bookedPackages =
          (clientData['bookedPackages'] as List<dynamic>?)
              ?.map((p) => Map<String, dynamic>.from(p as Map))
              .toList() ??
          [];

      String? packageNameUsed;
      String? packageCategoryUsed;
      bool packageSessionDecremented = false;

      if (serviceType == 'Follow-up Session') {
        if (followUpPackageName != null && bookedPackages.isNotEmpty) {
          bool packageFoundAndDecremented = false;
          for (int i = 0; i < bookedPackages.length; i++) {
            Map<String, dynamic> pkg = bookedPackages[i];
            if (pkg['name'] == followUpPackageName &&
                (pkg['remainingSessions'] as int? ?? 0) > 0) {
              pkg['remainingSessions'] = (pkg['remainingSessions'] as int) - 1;
              packageNameUsed = pkg['name'] as String?;
              packageCategoryUsed = pkg['category'] as String?;
              bookedPackages[i] = pkg;
              packageSessionDecremented = true;
              packageFoundAndDecremented = true;
              break;
            }
          }
          if (!packageFoundAndDecremented && dialogContext.mounted) {
            // It's good practice to check if context is still mounted before showing SnackBar
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              const SnackBar(
                content: Text(
                  'Selected follow-up package not found or has no sessions. Booking as non-package session.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else if (dialogContext.mounted) {
          // Also check mounted here
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            const SnackBar(
              content: Text(
                'Follow-up package not specified. Booking as non-package session.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else if (serviceType != null && bookedPackages.isNotEmpty) {
        String? targetCategory;
        // Determine target category based on service type
        if (serviceType.toLowerCase().contains('physio') ||
            serviceType.toLowerCase().contains('recovery')) {
          targetCategory = 'Package Physio';
        } else if (serviceType.toLowerCase().contains('machine')) {
          targetCategory = 'Package Machines';
        } else if (serviceType.toLowerCase().contains('rehab')) {
          targetCategory = 'Package Rehabilitation';
        }

        if (targetCategory != null) {
          for (int i = 0; i < bookedPackages.length; i++) {
            Map<String, dynamic> pkg = bookedPackages[i];
            if (pkg['category'] == targetCategory &&
                (pkg['remainingSessions'] as int? ?? 0) > 0) {
              pkg['remainingSessions'] = (pkg['remainingSessions'] as int) - 1;
              packageNameUsed = pkg['name'] as String?;
              packageCategoryUsed = pkg['category'] as String?;
              bookedPackages[i] = pkg;
              packageSessionDecremented = true;
              break;
            }
          }
        }
      }

      try {
        final appointmentData = {
          'patient': selectedClient['name'],
          'phone': selectedClient['phone'],
          'doctor': doctor,
          'clientId': selectedClient['id'],
          'status': 'booked',
          'serviceType': serviceType,
          'packageNameUsed': packageNameUsed,
          'packageCategoryUsed': packageCategoryUsed,
        };

        box.put(key, appointmentData); // Save to Hive
        _saveAppointmentToFirestore(key, appointmentData); // Sync to Firestore

        if (packageSessionDecremented) {
          clientData['bookedPackages'] = bookedPackages;
          clientBox.put(selectedClient['id'].toString(), clientData);
          _updateClientData(
            selectedClient['id'].toString(),
            clientData,
          ); // Use refactored method
        }

        Navigator.pop(dialogContext, true);
      } catch (e) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text('Error saving appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(
          content: Text('Please select a client to save.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // Helper method for WhatsApp messaging
  Future<void> _sendWhatsAppMessage(Map selectedClient, String timeSlot) async {
    try {
      final String appointmentDate = DateFormat(
        'dd-MM-yyyy',
      ).format(selectedDate);
      final String message = '''Hello ${selectedClient['name']},

PHYSIO PRIME CLINIC
Cairo Stadium Club - Squash Stadium Complex https://share.google/zhZWDFS6M3zGSFKWp 
عياده Physio Prime تذكركم بمعادكم يوم $appointmentDate
الساعة $timeSlot

برجاء العلم بأن مدة الانتظار من 0 إلى 15 دقيقه
‎*برجاء العلم ان التاخير عن ميعاد الجلسه يحسب من مده الجلسه* للاعتذار برجاء الاتصال قبل ميعاد الجلسه ب 4 ساعات على الاقل حتى لا يتم احتسابها من الجلسات

في حالة عدم التأكيد قبل الميعاد ب 4 ساعات برجاء الاتصال وتحديد موعد آخر

رقم الفرع

Physio Prime clinic reminds you about your session on $appointmentDate at $timeSlot

Please note that the waiting time ranges from 0 to 15 minutes
Please be informed that any delay will be calculated from the session duration.
For excuse, please call at least 4 hours before that session or it will be canceled from your package.
If you do not confirm 4 hours before your session, please call to reschedule your appointment.

Clinic number 
01558692685
See you & Have a nice day''';

      // Format phone number
      String phone = selectedClient['phone'].toString();
      if (!phone.startsWith('+')) {
        phone = '+2$phone'; // Egypt country code
      }

      final Uri whatsappUri = Uri.parse(
        'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
      );

      if (kIsWeb) {
        // For web platform
        // html.window.open(whatsappUri.toString(), '_blank');
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        // For mobile platforms
        if (await canLaunchUrl(whatsappUri)) {
          await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch WhatsApp';
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening WhatsApp: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addClient() async {
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    final phoneController = TextEditingController();
    final detailsController = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Add New Client',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Age',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number (e.g., 01012345678)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: detailsController,
                    decoration: InputDecoration(
                      labelText: 'Details / Notes',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  if (nameController.text.isEmpty ||
                      phoneController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Name and Phone Number are required.'),
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
                    'bookedPackages': _selectedClientPackages, //
                  };

                  clientBox.put(clientKey, clientData);
                  clientBox.put('lastId', newId);
                  await _updateClientData(
                    clientKey,
                    clientData,
                  ); // Use refactored method to save and sync metadata
                  Navigator.pop(context);
                  setState(
                    () {},
                  ); // Refresh the main screen if a client was added
                },
                icon: Icon(Icons.person_add),
                label: Text('Add Client'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
    );
  }

  void _openClientPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClientListPage()),
    );
  }

  void _openPackagesPage() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PackagesPage()));
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary:
                  Theme.of(context).primaryColor, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black87, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor:
                    Theme.of(context).primaryColor, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _syncData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDateForKey = DateFormat(
      'yyyy-MM-dd',
    ).format(selectedDate);
    const int targetDoctorColumnCount =
        10; // Define the target number of doctor columns
    final int currentDoctorCount = _availableDoctorsForSelectedDate.length;

    // Calculate quick stats for the dashboard
    int todayAppointments = 0;
    int pendingConfirmations = 0; // Placeholder for future feature
    int cancelledAppointments = 0;

    box.keys.forEach((key) {
      if (key.startsWith(formattedDateForKey)) {
        final appointmentData = box.get(key);
        if (appointmentData != null) {
          if (appointmentData['status'] == 'booked') {
            todayAppointments++;
          } else if (appointmentData['status'] == 'cancelled') {
            cancelledAppointments++;
          }
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule for ${DateFormat('EEE, MMM d, yyyy').format(selectedDate)}', // Corrected date format
            ),
            Text(
              'User: ${widget.user.username ?? 'N/A'}', // Display username
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.white70,
              ),
            ),
            Text(
              'Role: ${widget.user.role ?? 'N/A'}', // Display role
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _syncData, // Call the existing _syncData method
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: Icon(Icons.calendar_today, color: Colors.white),
            onPressed: () => _selectDate(context),
            tooltip: 'Select Date',
          ),
          IconButton(
            icon: Icon(
              isDrawerPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: Colors.white,
            ),
            tooltip: isDrawerPinned ? 'Unpin Menu' : 'Pin Menu',
            onPressed: () {
              setState(() {
                isDrawerPinned = !isDrawerPinned;
              });
            },
          ),
        ],
      ),
      drawer:
          isDrawerPinned
              ? null
              : Drawer(
                child: Container(
                  color:
                      Theme.of(
                        context,
                      ).primaryColorDark, // Darker Teal for drawer
                  child: ListView(
                    children: [
                      DrawerHeader(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                        ), // Teal header
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Image.asset(
                                'assets/phsioprime_logo.jpg', // Replace with your logo path
                                height: 200,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Clinic Menu',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(color: Colors.white),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Logged in as: ${widget.user.username}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Logged in as: ${widget.user.username}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ),
                      widget.user.role == 'admin' || widget.user.role == 'desk'
                          ? ListTile(
                            leading: const Icon(
                              Icons.person_add,
                              color: Colors.white,
                            ),
                            title: Text(
                              'Add Client',
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              Navigator.pop(context); // Close drawer
                              _addClient();
                            },
                          )
                          : const SizedBox.shrink(),
                      widget.user.role == 'admin' || widget.user.role == 'desk'
                          ? ListTile(
                            leading: Icon(Icons.people, color: Colors.white),
                            title: Text(
                              'Clients List',
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              Navigator.pop(context); // Close drawer
                              _openClientPage();
                            },
                          )
                          : const SizedBox.shrink(),
                      widget.user.role == 'admin' || widget.user.role == 'desk'
                          ? ListTile(
                            leading: Icon(
                              Icons.medical_services,
                              color: Colors.white,
                            ),
                            title: Text(
                              'Service Packages',
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              Navigator.pop(context); // Close drawer
                              _openPackagesPage();
                            },
                          )
                          : const SizedBox.shrink(),
                      widget.user.role == 'admin' || widget.user.role == 'desk'
                          ? ListTile(
                            leading: Icon(
                              Icons.monetization_on,
                              color: Colors.white,
                            ),
                            title: Text(
                              'Financial Management',
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              Navigator.pop(context); // Close drawer
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FinancialManagementPage(),
                                ),
                              );
                            },
                          )
                          : const SizedBox.shrink(),
                      widget.user.role == 'admin'
                          ? ListTile(
                            leading: Icon(
                              Icons.medical_services_outlined,
                              color: Colors.white,
                            ),
                            title: Text(
                              'Manage Doctors',
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              Navigator.pop(
                                context,
                              ); // Close the standard drawer first
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ManageDoctorsPage(),
                                ),
                              );
                            },
                          )
                          : const SizedBox.shrink(),
                      widget.user.role == 'admin'
                          ? ListTile(
                            leading: Icon(
                              Icons.supervised_user_circle_sharp,
                              color: Colors.white,
                            ),
                            title: Text(
                              'Manage Users',
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              Navigator.pop(
                                context,
                              ); // Close the standard drawer first
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ManageUsersPage(),
                                ),
                              );
                            },
                          )
                          : const SizedBox.shrink(),

                      const Divider(color: Colors.white54),
                      ListTile(
                        leading: Icon(Icons.logout, color: Colors.white),
                        title: Text(
                          'Logout',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () async {
                          context.read<AuthBloc>().add(
                            LogoutRequested(),
                          ); // Dispatch logout event
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => LoginScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
      body: Row(
        children: [
          if (isDrawerPinned)
            Container(
              width: 250,
              height: double.infinity,
              color:
                  Theme.of(context).primaryColorDark, // Darker Teal for drawer
              child: ListView(
                children: [
                  SizedBox(
                    height: 300,
                    child: DrawerHeader(
                      curve: Curves.easeInOut,

                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                      ),
                      child: Column(
                        // Teal header
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start, // Align children to the start
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween, // Distribute space
                        children: [
                          SizedBox(height: 20), // Increased top padding

                          Center(
                            child: Container(
                              // Added Container for rounded border and logo styling
                              width: 100,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(
                                  0.1,
                                ), // Optional: slight background for the logo container
                                borderRadius: BorderRadius.circular(
                                  12,
                                ), // Rounded corners
                                border: Border.symmetric(
                                  horizontal: BorderSide(
                                    color: Colors.white70,
                                    width: 6,
                                  ),
                                  vertical: BorderSide(
                                    color: Colors.white70,
                                    width: 6,
                                  ),
                                ),
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/phsioprime_logo.jpg',
                                  height:
                                      90, // Adjusted height to fit padding and border
                                  width: 110, // Adjusted width
                                  fit:
                                      BoxFit
                                          .fill, // Changed to contain to ensure logo is fully visible
                                  opacity: AlwaysStoppedAnimation(
                                    0.5,
                                  ), // Slightly transparent for better aesthetics
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Clinic Menu',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium // Consistent text style
                                ?.copyWith(color: Colors.white),
                          ),
                          Column(
                            // Group the text elements
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                // Display username
                                'Logged in as: ${widget.user.username}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  widget.user.role == 'admin' || widget.user.role == 'desk'
                      ? ListTile(
                        leading: const Icon(
                          Icons.person_add,
                          color: Colors.white,
                        ),
                        title: Text(
                          'Add Client',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: _addClient,
                      )
                      : const SizedBox.shrink(),
                  widget.user.role == 'admin' || widget.user.role == 'desk'
                      ? ListTile(
                        leading: const Icon(Icons.people, color: Colors.white),
                        title: Text(
                          'Clients List',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: _openClientPage,
                      )
                      : const SizedBox.shrink(),
                  widget.user.role == 'admin' || widget.user.role == 'desk'
                      ? ListTile(
                        leading: const Icon(
                          Icons.medical_services,
                          color: Colors.white,
                        ),
                        title: Text(
                          'Service Packages',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: _openPackagesPage,
                      )
                      : const SizedBox.shrink(),
                  widget.user.role == 'admin' || widget.user.role == 'desk'
                      ? ListTile(
                        leading: const Icon(
                          Icons.monetization_on,
                          color: Colors.white,
                        ),
                        title: Text(
                          'Financial Management',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FinancialManagementPage(),
                            ),
                          );
                        },
                      )
                      : const SizedBox.shrink(),
                  widget.user.role == 'admin'
                      ? ListTile(
                        leading: Icon(
                          Icons.medical_services_outlined,
                          color: Colors.white,
                        ),
                        title: Text(
                          'Manage Doctors',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          // No need to pop drawer if it's pinned
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ManageDoctorsPage(),
                            ),
                          );
                        },
                      )
                      : const SizedBox.shrink(),
                  widget.user.role == 'admin'
                      ? ListTile(
                        leading: Icon(
                          Icons.supervised_user_circle_sharp,
                          color: Colors.white,
                        ),
                        title: Text(
                          'Manage Users',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ManageUsersPage(),
                            ),
                          );
                        },
                      )
                      : const SizedBox.shrink(),
                  const Divider(color: Colors.white54),
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.white),
                    title: Text(
                      'Logout',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () async {
                      context.read<AuthBloc>().add(
                        LogoutRequested(),
                      ); // Dispatch logout event
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dashboard Enhancement: Quick Stats
                Padding(
                  // Stat cards for quick overview
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics:
                        NeverScrollableScrollPhysics(), // Important for nested GridView
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 850
                            ? 4
                            : 2, // Responsive grid
                    childAspectRatio:
                        1.8, // Adjust aspect ratio for better look
                    children: [
                      StatCard(
                        // Today's Appointments
                        title: "Today's Appointments",
                        value: "$todayAppointments",
                        icon: Icons.calendar_today,
                        color: Theme.of(context).primaryColor,
                      ),
                      StatCard(
                        // Cancelled Appointments
                        title: "Cancelled Appts.",
                        value: "$cancelledAppointments",
                        icon: Icons.event_busy,
                        color: Colors.redAccent,
                      ),
                      StatCard(
                        // Total Clients
                        title: "Total Clients",
                        value:
                            "${Hive.box('clients').keys.where((k) => k != 'lastId').length}",
                        icon: Icons.people_alt,
                        color: Colors.blueGrey,
                      ),
                      StatCard(
                        // Available Slots
                        title: "Available Slots",
                        value:
                            // "${(doctorNames.length * timeSlots.length) - todayAppointments}", // Simplified calculation
                            "${(_availableDoctorsForSelectedDate.length * timeSlots.length) - todayAppointments}", // Use the count of available doctors
                        icon:
                            Icons
                                .event_available_outlined, // Changed icon for variety
                        color:
                            Theme.of(
                              context,
                            ).colorScheme.secondary, // Use theme color
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        // Main schedule grid
                        dataRowMinHeight: 60,
                        dataRowMaxHeight: 100,
                        headingRowColor: MaterialStateProperty.resolveWith<
                          Color?
                        >((Set<MaterialState> states) {
                          return Theme.of(context).primaryColorLight
                              .withOpacity(0.1); // Light background for headers
                        }),
                        columns: [
                          DataColumn(
                            headingRowAlignment:
                                MainAxisAlignment
                                    .center, // Center time column header

                            label: Text(
                              'Time',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          // ...doctorNames.map(
                          ..._availableDoctorsForSelectedDate.map(
                            (doctor) => DataColumn(
                              headingRowAlignment:
                                  MainAxisAlignment
                                      .center, // Center doctor name header
                              label: Center(
                                child: Text(
                                  // doctor,
                                  doctor['name'] as String,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          // Add placeholder columns if fewer than targetDoctorColumnCount doctors are available
                          if (currentDoctorCount < targetDoctorColumnCount)
                            ...List.generate(
                              targetDoctorColumnCount - currentDoctorCount,
                              (index) {
                                // Placeholder columns for consistent width
                                return DataColumn(
                                  label: Text(
                                    '', // Empty label for placeholder
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                );
                              },
                            ),
                        ],
                        rows:
                            timeSlots.map((time) {
                              return DataRow(
                                cells: [
                                  // Time slot cell
                                  DataCell(
                                    Container(
                                      width: 150,
                                      height: 96,
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey[400]!,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        color: Colors.grey[50],
                                      ),
                                      child: Center(
                                        child: Text(
                                          time,
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodyLarge,
                                        ),
                                      ),
                                    ),
                                  ),
                                  ..._availableDoctorsForSelectedDate.map((
                                    doctorMap,
                                  ) {
                                    final String columnDoctorId =
                                        doctorMap['id'] as String;
                                    final String columnDoctorName =
                                        doctorMap['name'] as String;
                                    final key =
                                        '$formattedDateForKey-$time-$columnDoctorId';
                                    final data = box.get(
                                      key,
                                      defaultValue: {
                                        'patient': '',
                                        'doctor': columnDoctorName,
                                        'status':
                                            null, // Explicitly set default status
                                        'serviceType': null,
                                      },
                                    );
                                    // Extract data for display
                                    String patientPart =
                                        data['patient']?.toString()?.trim() ??
                                        '';
                                    String doctorInSlotPart =
                                        data['doctor']?.toString()?.trim() ??
                                        '';
                                    String? status = data['status'] as String?;
                                    String serviceTypeDisplay =
                                        data['serviceType'] as String? ?? '';
                                    // Determine cell color based on status
                                    Color? cellColor;
                                    if (status == 'booked') {
                                      cellColor = Theme.of(
                                        context,
                                      ).colorScheme.secondary.withOpacity(
                                        0.2,
                                      ); // Light Green for booked
                                    } else if (status == 'cancelled') {
                                      cellColor = Colors.red.withOpacity(
                                        0.15,
                                      ); // Light Red for cancelled
                                    } else if (patientPart.isNotEmpty) {
                                      // This case might happen if 'status' isn't set, but patient is there
                                      cellColor = Colors.orange.withOpacity(
                                        0.1,
                                      ); // Indicate a potential unconfirmed/pending
                                    } else {
                                      cellColor = Colors.transparent;
                                    }

                                    String
                                    patientDisplay = // Text to display in cell
                                        patientPart.isNotEmpty
                                            ? patientPart
                                            : (status == 'cancelled'
                                                ? 'Cancelled'
                                                : 'Available');

                                    return DataCell(
                                      GestureDetector(
                                        onTap:
                                            () =>
                                                widget.user.role == 'desk' ||
                                                        widget.user.role ==
                                                            'admin'
                                                    ? _editCell(time, doctorMap)
                                                    : null, // Tap to edit appointment
                                        child: Container(
                                          width: 150,
                                          height: 96,
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: cellColor,
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            mainAxisAlignment:
                                                MainAxisAlignment
                                                    .center, // Center content
                                            children: [
                                              Text(
                                                patientDisplay,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodyMedium?.copyWith(
                                                  fontWeight:
                                                      patientPart.isNotEmpty
                                                          ? FontWeight.bold
                                                          : FontWeight.bold,
                                                  color:
                                                      status == 'booked'
                                                          ? Theme.of(
                                                            context,
                                                          ).primaryColorDark
                                                          : (status ==
                                                                  'cancelled'
                                                              ? Colors.red[800]
                                                              : Colors.black87),
                                                ),
                                              ),
                                              if (serviceTypeDisplay
                                                      .isNotEmpty &&
                                                  patientPart.isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 2.0,
                                                      ),
                                                  child: Text(
                                                    '($serviceTypeDisplay)',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color:
                                                              Colors.grey[700],
                                                          fontStyle:
                                                              FontStyle.italic,
                                                        ),
                                                  ),
                                                ),
                                              // Display remaining sessions for follow-ups
                                              // Display remaining sessions for follow-ups
                                              if (serviceTypeDisplay ==
                                                      'Follow-up Session' &&
                                                  data['clientId'] != null &&
                                                  data['packageNameUsed'] !=
                                                      null &&
                                                  patientPart.isNotEmpty &&
                                                  status == 'booked')
                                                Builder(
                                                  builder: (context) {
                                                    final clientBox = Hive.box(
                                                      'clients',
                                                    );
                                                    final clientDataMap =
                                                        clientBox.get(
                                                          data['clientId']
                                                              .toString(),
                                                        );

                                                    // Safely check if clientDataMap is not null and is a Map
                                                    if (clientDataMap != null &&
                                                        clientDataMap is Map) {
                                                      final clientData = Map<
                                                        String,
                                                        dynamic
                                                      >.from(clientDataMap);
                                                      final List<dynamic>
                                                      bookedPackages =
                                                          clientData['bookedPackages']
                                                              as List<
                                                                dynamic
                                                              >? ??
                                                          [];

                                                    
                                                      final packageUsed =
                                                          bookedPackages.firstWhere(
                                                            (pkg) =>
                                                                (pkg
                                                                    as Map)['name'] ==
                                                                data['packageNameUsed'],
                                                            orElse:
                                                                () =>
                                                                    null, // If not found, it returns null
                                                          );

                                                      if (packageUsed != null &&
                                                          packageUsed is Map) {
                                                        return Text(
                                                          'Pkg Rem: ${packageUsed['remainingSessions']}',
                                                          style: Theme.of(
                                                                context,
                                                              )
                                                              .textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                                color:
                                                                    Colors
                                                                        .blueGrey,
                                                                fontStyle:
                                                                    FontStyle
                                                                        .italic,
                                                              ),
                                                        );
                                                      } else {
                                                        // If clientDataMap exists, but packageUsed is not found or not a Map
                                                        return const SizedBox.shrink(); // Return an empty widget
                                                      }
                                                    } else {
                                                      // This is the missing return statement!
                                                      // If clientDataMap is null or not a Map, we must return a Widget.
                                                      // Returning an empty widget is usually appropriate in such cases.
                                                      return const SizedBox.shrink();
                                                    }
                                                  },
                                                ),
                                              if (status == 'cancelled' ||
                                                  status == 'booked')
                                                Text(
                                                  '(${status!.toUpperCase()})',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color:
                                                            status == 'booked'
                                                                ? Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .secondary
                                                                : Colors.red,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  // Add placeholder cells if fewer than targetDoctorColumnCount doctors are available
                                  if (currentDoctorCount <
                                      targetDoctorColumnCount)
                                    ...List.generate(
                                      targetDoctorColumnCount -
                                          currentDoctorCount,
                                      (index) {
                                        return DataCell(
                                          Container(
                                            // Maintain consistent cell structure
                                            width: 150,
                                            height: 96,
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey[300]!,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '-',
                                                style: TextStyle(
                                                  color: Colors.grey.shade400,
                                                ),
                                              ),
                                            ), // Placeholder content
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
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
