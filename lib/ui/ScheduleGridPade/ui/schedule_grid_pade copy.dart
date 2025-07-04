import 'package:physioprime/core/app_consts/app_consts.dart';
import 'package:physioprime/main.dart';
import 'package:physioprime/ui/ClientListPage/ui/client_list_page.dart';
import 'package:physioprime/ui/FinancialManagementPage/ui/financial_management_page.dart';
import 'package:physioprime/ui/LoginPage/bloc/auth_bloc.dart';
import 'package:physioprime/ui/LoginPage/bloc/auth_event.dart';
import 'package:physioprime/ui/LoginPage/models/user_model.dart';
import 'package:physioprime/ui/LoginPage/repository/auth_repository.dart';
import 'package:physioprime/ui/LoginPage/ui/login_page.dart';
import 'package:physioprime/ui/ManageDoctorPage/ui/manage_doctors_page.dart';
import 'package:physioprime/ui/ManageUserPage/ui/manage_users_page.dart';
import 'package:physioprime/ui/PackagesPage/ui/packages_page.dart';
import 'package:physioprime/ui/ScheduleGridPade/helper/schedule_grid_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:physioprime/widgets/state_card.dart'; // Ensure this is imported if used
import 'package:restart_app/restart_app.dart';

class ScheduleGridScreen extends StatefulWidget {
  final UserModel user; // Add user parameter

  const ScheduleGridScreen({Key? key, required this.user}) : super(key: key);

  @override
  _ScheduleGridScreenState createState() => _ScheduleGridScreenState();
}

class _ScheduleGridScreenState extends State<ScheduleGridScreen> {
  List<Map<String, dynamic>> _availableDoctorsForSelectedDate = [];
  List<Map<String, dynamic>> _availableDoctorForSelectedDate = [];
  List<Map<String, dynamic>> _selectedClientPackages =
      []; // To store packages selected for this client

  late Box box;
  DateTime selectedDate = DateTime.now();
  bool isDrawerPinned = true;
  late Box _doctorsBox;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late CollectionReference _appointmentsCollection;
  late CollectionReference _clientsCollection;
  late CollectionReference _doctorsCollection;
  late ScheduleGridController controller;

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
    final allDoctorsFromBox =
        _doctorsBox.values
            .map((doc) => Map<String, dynamic>.from(doc as Map))
            .toList();

    Iterable<Map<String, dynamic>> doctorsToDisplay;

    if (widget.user.role == 'doctor') {
      // If the user is a doctor, filter to only show their column.
      doctorsToDisplay = allDoctorsFromBox.where((doctor) {
        return doctor['name'] == widget.user.username;
      });
    } else {
      // For other roles, show all doctors.
      doctorsToDisplay = allDoctorsFromBox;
    }
    setState(() {
      _availableDoctorsForSelectedDate =
          allDoctors.where((doctor) {
            final List<dynamic> availableDays =
                doctor['availableDays'] as List<dynamic>? ?? [];
            return availableDays.contains(dayOfWeek);
          }).toList();
      _availableDoctorForSelectedDate =
          doctorsToDisplay.where((doctor) {
            final List<dynamic> availableDays =
                doctor['availableDays'] as List<dynamic>? ?? [];
            return availableDays.contains(dayOfWeek);
          }).toList();

      // Optionally sort doctors by name
      _availableDoctorsForSelectedDate.sort(
        (a, b) => (a['name'] as String).compareTo(b['name'] as String),
      );
      _availableDoctorForSelectedDate.sort(
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

  // Future<void> _saveClientToFirestore(
  //   String key,
  //   Map<String, dynamic> data,
  // ) async {
  //   try {
  //     await _clientsCollection.doc(key).set(data);
  //     // Only update lastId if it's the latest ID
  //     final currentLastId = Hive.box('clients').get('lastId', defaultValue: 0);
  //     if (data['id'] > currentLastId) {
  //       // await _clientsCollection.doc('metadata').set({'lastId': data['id']});
  //       await _clientsCollection.doc(key).set(data);
  //       final currentLastId = Hive.box(
  //         'clients',
  //       ).get('lastId', defaultValue: 0);
  //       if (data['id'] > currentLastId) {
  //         await _clientsCollection.doc('metadata').set({'lastId': data['id']});
  //       }
  //     }
  //   } catch (e) {
  //     print('Error saving client to Firestore: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Failed to save client: $e'),
  //         backgroundColor: Colors.redAccent,
  //       ),
  //     );
  //   }
  // }

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

  void _editCell(String timeSlot, Map<String, dynamic> doctorData) async {
    final String formattedDateForKey = DateFormat(
      'yyyy-MM-dd',
    ).format(selectedDate);

    final String key = '$formattedDateForKey-$timeSlot-${doctorData['id']}';
    final String columnDoctorName = doctorData['name'] as String;

    // --- COMPLETELY SAFE APPROACH: No defaultValue, no casting ---
    final Map<String, dynamic> defaultValues = {
      'patient': '',
      'doctor': columnDoctorName,
      'phone': '',
      'clientId': null,
      'status': null,
      'serviceType': null,
    };

    Map<String, dynamic> existing = Map<String, dynamic>.from(defaultValues);

    try {
      // Check if key exists first
      if (box.containsKey(key)) {
        final dynamic rawValue = box.get(key);

        if (rawValue != null && rawValue is Map) {
          // Safely convert to Map<String, dynamic>
          final Map<String, dynamic> retrievedData = {};
          rawValue.forEach((k, v) {
            if (k is String) {
              retrievedData[k] = v;
            }
          });

          // Merge with defaults to ensure all required keys exist
          existing = Map<String, dynamic>.from(defaultValues);
          existing.addAll(retrievedData);
        } else {
          // Corrupted data found
          print('WARNING: Corrupted data found for key: $key');
          print('Type: ${rawValue?.runtimeType ?? 'null'}');

          // Remove corrupted data
          box.delete(key);
        }
      }
    } catch (e) {
      print('ERROR: Failed to retrieve data for key: $key - $e');
      // existing already has default values
    }
    // --- END SAFE APPROACH ---

    // Initialize with existing doctor or column doctor
    final doctorController = TextEditingController(
      text: existing['doctor']?.toString() ?? columnDoctorName,
    );

    final clientBox = Hive.box('clients');

    // Safe handling of client data as well
    final allClients =
        clientBox.keys
            .where((key) => key != 'lastId')
            .map((key) {
              try {
                final clientData = clientBox.get(key);
                if (clientData is Map) {
                  return Map<String, dynamic>.from(clientData);
                } else {
                  print(
                    'Warning: Invalid client data for key $key, type: ${clientData.runtimeType}',
                  );
                  return <
                    String,
                    dynamic
                  >{}; // Return empty map for invalid data
                }
              } catch (e) {
                print('Error processing client data for key $key: $e');
                return <String, dynamic>{};
              }
            })
            .where((client) => client.isNotEmpty) // Filter out empty maps
            .toList();

    // Initialize selected client from existing appointment
    Map? selectedClient;
    if (existing['clientId'] != null) {
      try {
        final clientData = clientBox.get(existing['clientId'].toString());
        if (clientData != null && clientData is Map) {
          selectedClient = Map<String, dynamic>.from(clientData);
        }
      } catch (e) {
        print('Error getting client data: $e');
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
              try {
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
              } catch (e) {
                print('Error getting client packages: $e');
                _clientActivePackagesForFollowUp = [];
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
  // void _editCell(String timeSlot, Map<String, dynamic> doctorData) async {
  //   final String formattedDateForKey = DateFormat(
  //     'yyyy-MM-dd',
  //   ).format(selectedDate);

  //   final String key = '$formattedDateForKey-$timeSlot-${doctorData['id']}';
  //   final String columnDoctorName = doctorData['name'] as String;

  //  final Map<String, dynamic> existing = Map<String, dynamic>.from(box.get(
  //     key,
  //     defaultValue: {
  //       'patient': '',
  //       'doctor': columnDoctorName,
  //       'phone': '',
  //       'clientId': null,
  //       'status': null,
  //       'serviceType': null,
  //     },
  //   ) as Map? ??
  //   {});
  //   // Initialize with existing doctor or column doctor
  //   final doctorController = TextEditingController(
  //     text: existing['doctor'] ?? columnDoctorName,
  //   );

  //   final clientBox = Hive.box('clients');
  //   final allClients =
  //       clientBox.keys
  //           .where((key) => key != 'lastId')
  //           .map(
  //             (key) =>
  //                 Map<String, dynamic>.from(clientBox.get(key) as Map? ?? {}),
  //           )
  //           .toList();

  //   // Initialize selected client from existing appointment
  //   Map? selectedClient;
  //   if (existing['clientId'] != null) {
  //     final clientData = clientBox.get(existing['clientId'].toString());
  //     if (clientData != null) {
  //       selectedClient = Map<String, dynamic>.from(clientData as Map);
  //     }
  //   }
  //   // Fallback to patient name if clientId not found but patient name exists
  //   else if (existing['patient'] != null &&
  //       (existing['patient'] as String).isNotEmpty) {
  //     selectedClient = {
  //       'name': existing['patient'],
  //       'phone': existing['phone'] ?? '',
  //       'id': existing['clientId'],
  //     };
  //   }

  //   final searchController = TextEditingController();
  //   List<Map> localFilteredClients = List.from(allClients);
  //   String? _dialogSelectedServiceType = existing['serviceType'] as String?;
  //   String? _dialogSelectedFollowUpPackageName;

  //   final bool? appointmentSaved = await showDialog<bool>(
  //     context: context,
  //     builder: (dialogContext) {
  //       return StatefulBuilder(
  //         builder: (context, setStateDialog) {
  //           void filterClients(String query) {
  //             setStateDialog(() {
  //               if (query.isEmpty) {
  //                 localFilteredClients = List.from(allClients);
  //               } else {
  //                 localFilteredClients =
  //                     allClients.where((client) {
  //                       final name =
  //                           client['name']?.toString().toLowerCase() ?? '';
  //                       final id = client['id']?.toString().toLowerCase() ?? '';
  //                       return name.contains(query.toLowerCase()) ||
  //                           id.contains(query.toLowerCase());
  //                     }).toList();
  //               }
  //             });
  //           }

  //           List<Map<String, dynamic>> _clientActivePackagesForFollowUp = [];
  //           if (selectedClient != null &&
  //               _dialogSelectedServiceType == 'Follow-up Session') {
  //             final clientDataFromBox = clientBox.get(
  //               selectedClient!['id']?.toString(),
  //             );
  //             if (clientDataFromBox is Map) {
  //               final currentClientData = Map<String, dynamic>.from(
  //                 clientDataFromBox,
  //               );
  //               if (currentClientData['bookedPackages'] != null) {
  //                 _clientActivePackagesForFollowUp =
  //                     (currentClientData['bookedPackages'] as List<dynamic>)
  //                         .map((p) => Map<String, dynamic>.from(p as Map))
  //                         .where(
  //                           (pkg) =>
  //                               (pkg['remainingSessions'] as int? ?? 0) > 0,
  //                         )
  //                         .toList();
  //               }
  //             }
  //           }

  //           // Reset follow-up package selection if conditions change
  //           if (_dialogSelectedServiceType != 'Follow-up Session' ||
  //               _clientActivePackagesForFollowUp.isEmpty) {
  //             _dialogSelectedFollowUpPackageName = null;
  //           } else if (_dialogSelectedFollowUpPackageName != null &&
  //               !_clientActivePackagesForFollowUp.any(
  //                 (pkg) => pkg['name'] == _dialogSelectedFollowUpPackageName,
  //               )) {
  //             _dialogSelectedFollowUpPackageName = null;
  //           }

  //           return AlertDialog(
  //             title: Text(
  //               'Edit Appointment on ${DateFormat('MMM d').format(selectedDate)} at $timeSlot',
  //               style: Theme.of(context).textTheme.headlineSmall,
  //             ),
  //             content: PopScope(
  //               canPop: true,
  //               child: SizedBox(
  //                 width: MediaQuery.of(context).size.width * 0.8,
  //                 child: SingleChildScrollView(
  //                   child: Column(
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       // Show current appointment info if exists
  //                       if (existing['patient'] != null &&
  //                           (existing['patient'] as String).isNotEmpty)
  //                         Container(
  //                           padding: const EdgeInsets.all(12),
  //                           margin: const EdgeInsets.only(bottom: 15),
  //                           decoration: BoxDecoration(
  //                             color: Colors.blue.shade50,
  //                             borderRadius: BorderRadius.circular(8),
  //                             border: Border.all(color: Colors.blue.shade200),
  //                           ),
  //                           child: Column(
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                             children: [
  //                               Text(
  //                                 'Current Appointment:',
  //                                 style: TextStyle(
  //                                   fontWeight: FontWeight.bold,
  //                                   color: Colors.blue.shade700,
  //                                 ),
  //                               ),
  //                               const SizedBox(height: 4),
  //                               Text('Patient: ${existing['patient']}'),
  //                               Text('Doctor: ${existing['doctor']}'),
  //                               if (existing['serviceType'] != null)
  //                                 Text('Service: ${existing['serviceType']}'),
  //                               if (existing['status'] != null)
  //                                 Text('Status: ${existing['status']}'),
  //                             ],
  //                           ),
  //                         ),

  //                       // Client Search Field
  //                       TextField(
  //                         controller: searchController,
  //                         decoration: InputDecoration(
  //                           labelText: 'Search Client by Name or ID',
  //                           suffixIcon: const Icon(Icons.search),
  //                           border: OutlineInputBorder(
  //                             borderRadius: BorderRadius.circular(8.0),
  //                           ),
  //                         ),
  //                         autofocus: selectedClient == null,
  //                         onChanged: filterClients,
  //                       ),
  //                       const SizedBox(height: 10),

  //                       // Selected Client Display
  //                       if (selectedClient != null)
  //                         Container(
  //                           padding: const EdgeInsets.all(12),
  //                           margin: const EdgeInsets.only(bottom: 10),
  //                           decoration: BoxDecoration(
  //                             color: Colors.green.shade50,
  //                             borderRadius: BorderRadius.circular(8),
  //                             border: Border.all(color: Colors.green.shade200),
  //                           ),
  //                           child: Row(
  //                             children: [
  //                               Icon(
  //                                 Icons.person,
  //                                 color: Colors.green.shade700,
  //                               ),
  //                               const SizedBox(width: 8),
  //                               Expanded(
  //                                 child: Column(
  //                                   crossAxisAlignment:
  //                                       CrossAxisAlignment.start,
  //                                   children: [
  //                                     Text(
  //                                       'Selected: ${selectedClient!['name']}',
  //                                       style: TextStyle(
  //                                         fontWeight: FontWeight.bold,
  //                                         color: Colors.green.shade700,
  //                                       ),
  //                                     ),
  //                                     Text('ID: ${selectedClient!['id']}'),
  //                                   ],
  //                                 ),
  //                               ),
  //                               IconButton(
  //                                 icon: const Icon(Icons.clear),
  //                                 onPressed: () {
  //                                   setStateDialog(() {
  //                                     selectedClient = null;
  //                                   });
  //                                 },
  //                               ),
  //                             ],
  //                           ),
  //                         ),

  //                       // Client List (only show if no client selected or searching)
  //                       if (selectedClient == null ||
  //                           searchController.text.isNotEmpty)
  //                         Container(
  //                           height: 200,
  //                           width: double.maxFinite,
  //                           decoration: BoxDecoration(
  //                             border: Border.all(color: Colors.grey.shade300),
  //                             borderRadius: BorderRadius.circular(8.0),
  //                           ),
  //                           child:
  //                               localFilteredClients.isEmpty
  //                                   ? const Center(
  //                                     child: Padding(
  //                                       padding: EdgeInsets.all(16.0),
  //                                       child: Text(
  //                                         'No clients found. Add a new client or refine search.',
  //                                         textAlign: TextAlign.center,
  //                                         style: TextStyle(color: Colors.grey),
  //                                       ),
  //                                     ),
  //                                   )
  //                                   : ListView.builder(
  //                                     itemCount: localFilteredClients.length,
  //                                     itemBuilder: (context, index) {
  //                                       final client =
  //                                           localFilteredClients[index];
  //                                       final isSelected =
  //                                           selectedClient != null &&
  //                                           selectedClient!['id'] ==
  //                                               client['id'];

  //                                       return ListTile(
  //                                         title: Text(
  //                                           '${client['name']}',
  //                                           style: TextStyle(
  //                                             fontWeight:
  //                                                 isSelected
  //                                                     ? FontWeight.bold
  //                                                     : FontWeight.normal,
  //                                           ),
  //                                         ),
  //                                         subtitle: Text('ID: ${client['id']}'),
  //                                         trailing:
  //                                             isSelected
  //                                                 ? const Icon(
  //                                                   Icons.check_circle,
  //                                                   color: Colors.green,
  //                                                 )
  //                                                 : null,
  //                                         onTap: () {
  //                                           setStateDialog(() {
  //                                             selectedClient = client;
  //                                             searchController.clear();
  //                                           });
  //                                         },
  //                                         tileColor:
  //                                             isSelected
  //                                                 ? Theme.of(context)
  //                                                     .primaryColor
  //                                                     .withOpacity(0.1)
  //                                                 : null,
  //                                       );
  //                                     },
  //                                   ),
  //                         ),
  //                       const SizedBox(height: 15),

  //                       // Service Type Dropdown
  //                       DropdownButtonFormField<String>(
  //                         value: _dialogSelectedServiceType,
  //                         hint: const Text('Select Service Type'),
  //                         isExpanded: true,
  //                         items:
  //                             AppConsts().kServiceTypes.map((String value) {
  //                               return DropdownMenuItem<String>(
  //                                 value: value,
  //                                 child: Text(value),
  //                               );
  //                             }).toList(),
  //                         onChanged: (String? newValue) {
  //                           setStateDialog(() {
  //                             _dialogSelectedServiceType = newValue;
  //                           });
  //                         },
  //                         decoration: InputDecoration(
  //                           labelText: 'Service Type',
  //                           border: OutlineInputBorder(
  //                             borderRadius: BorderRadius.circular(8.0),
  //                           ),
  //                         ),
  //                       ),
  //                       const SizedBox(height: 15),

  //                       // Follow-up Package Selection (if applicable)
  //                       if (_dialogSelectedServiceType == 'Follow-up Session' &&
  //                           selectedClient != null &&
  //                           _clientActivePackagesForFollowUp.isNotEmpty)
  //                         DropdownButtonFormField<String>(
  //                           value: _dialogSelectedFollowUpPackageName,
  //                           hint: const Text('Select Package for Follow-up'),
  //                           isExpanded: true,
  //                           items:
  //                               _clientActivePackagesForFollowUp.map((package) {
  //                                 return DropdownMenuItem<String>(
  //                                   value: package['name'],
  //                                   child: Text(
  //                                     '${package['name']} (${package['remainingSessions']} sessions left)',
  //                                   ),
  //                                 );
  //                               }).toList(),
  //                           onChanged: (String? newValue) {
  //                             setStateDialog(() {
  //                               _dialogSelectedFollowUpPackageName = newValue;
  //                             });
  //                           },
  //                           decoration: InputDecoration(
  //                             labelText: 'Follow-up Package',
  //                             border: OutlineInputBorder(
  //                               borderRadius: BorderRadius.circular(8.0),
  //                             ),
  //                           ),
  //                         ),
  //                       const SizedBox(height: 15),

  //                       // Doctor Field
  //                       TextField(
  //                         controller: doctorController,
  //                         decoration: InputDecoration(
  //                           labelText: 'Assigned Doctor',
  //                           border: OutlineInputBorder(
  //                             borderRadius: BorderRadius.circular(8.0),
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ),
  //             actions: [
  //               // Cancel Button
  //               TextButton(
  //                 onPressed: () => Navigator.pop(dialogContext, false),
  //                 style: TextButton.styleFrom(
  //                   foregroundColor: Colors.grey[700],
  //                 ),
  //                 child: const Text('Cancel'),
  //               ),

  //               // Delete Appointment Button (if booked)
  //               if (existing['status'] == 'booked')
  //                 TextButton.icon(
  //                   icon: const Icon(Icons.delete, color: Colors.red),
  //                   label: const Text(
  //                     'Delete',
  //                     style: TextStyle(color: Colors.red),
  //                   ),
  //                   onPressed:
  //                       () => _cancelAppointment(
  //                         dialogContext,
  //                         key,
  //                         existing,
  //                         columnDoctorName,
  //                         _dialogSelectedServiceType,
  //                       ),
  //                 ),

  //               // Save Button
  //               ElevatedButton(
  //                 onPressed: () {
  //                   if (_dialogSelectedServiceType == 'Follow-up Session' &&
  //                       selectedClient != null &&
  //                       _clientActivePackagesForFollowUp.isNotEmpty &&
  //                       (_dialogSelectedFollowUpPackageName == null ||
  //                           _dialogSelectedFollowUpPackageName!.isEmpty)) {
  //                     ScaffoldMessenger.of(dialogContext).showSnackBar(
  //                       const SnackBar(
  //                         content: Text(
  //                           'Please select a package for the follow-up session.',
  //                         ),
  //                         backgroundColor: Colors.orange,
  //                       ),
  //                     );
  //                     return;
  //                   }
  //                   _saveAppointment(
  //                     dialogContext,
  //                     key,
  //                     selectedClient,
  //                     doctorController.text,
  //                     _dialogSelectedServiceType,
  //                     _dialogSelectedFollowUpPackageName,
  //                   );
  //                 },
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: Theme.of(context).primaryColor,
  //                   foregroundColor: Colors.white,
  //                 ),
  //                 child: const Text('Save Appointment'),
  //               ),

  //               // WhatsApp Button (if client selected)
  //               if (selectedClient != null)
  //                 TextButton.icon(
  //                   icon: const Icon(Icons.chat, color: Colors.green),
  //                   label: const Text(
  //                     'WhatsApp',
  //                     style: TextStyle(color: Colors.green),
  //                   ),
  //                   onPressed:
  //                       () => _sendWhatsAppMessage(selectedClient!, timeSlot),
  //                 ),
  //             ],
  //           );
  //         },
  //       );
  //     },
  //   );

  //   // Dispose controllers
  //   doctorController.dispose();
  //   searchController.dispose();

  //   if (appointmentSaved == true) {
  //     setState(() {
  //       // Force rebuild to refresh the UI
  //     });
  //   }
  // }

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
            clientBox.get(clientId) as Map<String, dynamic>? ??
                <String, dynamic>{},
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

      // --- SAFE CLIENT DATA RETRIEVAL ---
      Map<String, dynamic> clientData = {};
      try {
        final dynamic rawClientData = clientBox.get(
          selectedClient['id'].toString(),
        );

        if (rawClientData != null && rawClientData is Map) {
          // Safely convert to Map<String, dynamic>
          rawClientData.forEach((k, v) {
            if (k is String) {
              clientData[k] = v;
            }
          });
        } else if (rawClientData != null) {
          // Corrupted client data found
          print(
            'WARNING: Corrupted client data found for ID: ${selectedClient['id']}',
          );
          print('Type: ${rawClientData.runtimeType}');

          // Remove corrupted data
          clientBox.delete(selectedClient['id'].toString());
        }
      } catch (e) {
        print(
          'ERROR: Failed to retrieve client data for ID: ${selectedClient['id']} - $e',
        );
        // clientData remains empty map
      }
      // --- END SAFE CLIENT DATA RETRIEVAL ---

      // Safe handling of bookedPackages
      List<Map<String, dynamic>> bookedPackages = [];
      try {
        if (clientData['bookedPackages'] is List) {
          bookedPackages =
              (clientData['bookedPackages'] as List<dynamic>)
                  .where((p) => p is Map) // Filter out non-Map items
                  .map((p) => Map<String, dynamic>.from(p as Map))
                  .toList();
        }
      } catch (e) {
        print('ERROR: Failed to process bookedPackages: $e');
        bookedPackages = [];
      }

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
        } else if (serviceType.toLowerCase().contains('recovery')) {
          targetCategory = 'Package Recoverys';
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

          // Safe save back to client box
          try {
            clientBox.put(selectedClient['id'].toString(), clientData);
            _updateClientData(
              selectedClient['id'].toString(),
              clientData,
            ); // Use refactored method
          } catch (e) {
            print('ERROR: Failed to save updated client data: $e');
            if (dialogContext.mounted) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  content: Text(
                    'Warning: Appointment saved but failed to update package sessions: $e',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }

        Navigator.pop(dialogContext, true);
      } catch (e) {
        print('ERROR: Failed to save appointment: $e');
        if (dialogContext.mounted) {
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            SnackBar(
              content: Text('Error saving appointment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          const SnackBar(
            content: Text('Please select a client to save.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // // Helper method for saving appointment
  // void _saveAppointment(
  //   BuildContext dialogContext,
  //   String key,
  //   Map? selectedClient,
  //   String doctor, [
  //   String? serviceType,
  //   String? followUpPackageName, // Added missing parameter
  // ]) {
  //   if (selectedClient != null) {
  //     final clientBox = Hive.box('clients');
  //     Map<String, dynamic> clientData = Map<String, dynamic>.from(
  //       clientBox.get(selectedClient['id'].toString()) as Map? ?? {},
  //     );
  //     List<Map<String, dynamic>> bookedPackages =
  //         (clientData['bookedPackages'] as List<dynamic>?)
  //             ?.map((p) => Map<String, dynamic>.from(p as Map))
  //             .toList() ??
  //         [];

  //     String? packageNameUsed;
  //     String? packageCategoryUsed;
  //     bool packageSessionDecremented = false;

  //     if (serviceType == 'Follow-up Session') {
  //       if (followUpPackageName != null && bookedPackages.isNotEmpty) {
  //         bool packageFoundAndDecremented = false;
  //         for (int i = 0; i < bookedPackages.length; i++) {
  //           Map<String, dynamic> pkg = bookedPackages[i];
  //           if (pkg['name'] == followUpPackageName &&
  //               (pkg['remainingSessions'] as int? ?? 0) > 0) {
  //             pkg['remainingSessions'] = (pkg['remainingSessions'] as int) - 1;
  //             packageNameUsed = pkg['name'] as String?;
  //             packageCategoryUsed = pkg['category'] as String?;
  //             bookedPackages[i] = pkg;
  //             packageSessionDecremented = true;
  //             packageFoundAndDecremented = true;
  //             break;
  //           }
  //         }
  //         if (!packageFoundAndDecremented && dialogContext.mounted) {
  //           // It's good practice to check if context is still mounted before showing SnackBar
  //           ScaffoldMessenger.of(dialogContext).showSnackBar(
  //             const SnackBar(
  //               content: Text(
  //                 'Selected follow-up package not found or has no sessions. Booking as non-package session.',
  //               ),
  //               backgroundColor: Colors.orange,
  //             ),
  //           );
  //         }
  //       } else if (dialogContext.mounted) {
  //         // Also check mounted here
  //         ScaffoldMessenger.of(dialogContext).showSnackBar(
  //           const SnackBar(
  //             content: Text(
  //               'Follow-up package not specified. Booking as non-package session.',
  //             ),
  //             backgroundColor: Colors.orange,
  //           ),
  //         );
  //       }
  //     } else if (serviceType != null && bookedPackages.isNotEmpty) {
  //       String? targetCategory;
  //       // Determine target category based on service type
  //       if (serviceType.toLowerCase().contains('physio') ||
  //           serviceType.toLowerCase().contains('recovery')) {
  //         targetCategory = 'Package Physio';
  //       } else if (serviceType.toLowerCase().contains('recovery')) {
  //         targetCategory = 'Package recoverys';
  //       } else if (serviceType.toLowerCase().contains('rehab')) {
  //         targetCategory = 'Package Rehabilitation';
  //       }

  //       if (targetCategory != null) {
  //         for (int i = 0; i < bookedPackages.length; i++) {
  //           Map<String, dynamic> pkg = bookedPackages[i];
  //           if (pkg['category'] == targetCategory &&
  //               (pkg['remainingSessions'] as int? ?? 0) > 0) {
  //             pkg['remainingSessions'] = (pkg['remainingSessions'] as int) - 1;
  //             packageNameUsed = pkg['name'] as String?;
  //             packageCategoryUsed = pkg['category'] as String?;
  //             bookedPackages[i] = pkg;
  //             packageSessionDecremented = true;
  //             break;
  //           }
  //         }
  //       }
  //     }

  //     try {
  //       final appointmentData = {
  //         'patient': selectedClient['name'],
  //         'phone': selectedClient['phone'],
  //         'doctor': doctor,
  //         'clientId': selectedClient['id'],
  //         'status': 'booked',
  //         'serviceType': serviceType,
  //         'packageNameUsed': packageNameUsed,
  //         'packageCategoryUsed': packageCategoryUsed,
  //       };

  //       box.put(key, appointmentData); // Save to Hive
  //       _saveAppointmentToFirestore(key, appointmentData); // Sync to Firestore

  //       if (packageSessionDecremented) {
  //         clientData['bookedPackages'] = bookedPackages;
  //         clientBox.put(selectedClient['id'].toString(), clientData);
  //         _updateClientData(
  //           selectedClient['id'].toString(),
  //           clientData,
  //         ); // Use refactored method
  //       }

  //       Navigator.pop(dialogContext, true);
  //     } catch (e) {
  //       ScaffoldMessenger.of(dialogContext).showSnackBar(
  //         SnackBar(
  //           content: Text('Error saving appointment: $e'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   } else {
  //     ScaffoldMessenger.of(dialogContext).showSnackBar(
  //       const SnackBar(
  //         content: Text('Please select a client to save.'),
  //         backgroundColor: Colors.orange,
  //       ),
  //     );
  //   }
  // }

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
                icon: Icon(Icons.person_add, color: Colors.white),
                label: Text(
                  'Add Client',
                  style: TextStyle(color: Colors.white),
                ),
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
            SizedBox(height: 8),
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
                                '${AppConsts.appName} Menu',
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
                          // This will fully restart the app

                          context.read<AuthBloc>().add(LogoutRequested());

                          // Dispatch logout event

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
                            '${AppConsts.appName} Menu',
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
                        color: Colors.white, // Light color for contrast
                      ),
                      StatCard(
                        // Cancelled Appointments
                        title: "Cancelled Appts.",
                        value: "$cancelledAppointments",
                        icon: Icons.event_busy,
                        color: Colors.white,
                      ),
                      StatCard(
                        // Total Clients
                        title: "Total Clients",
                        value:
                            "${Hive.box('clients').keys.where((k) => k != 'lastId').length}",
                        icon: Icons.people_alt,
                        color: Colors.white,
                      ),
                      StatCard(
                        // Available Slots
                        title: "Available Slots",
                        value:
                            // "${(doctorNames.length * timeSlots.length) - todayAppointments}", // Simplified calculation
                            "${(_availableDoctorsForSelectedDate.length * AppConsts().timeSlots.length) - todayAppointments}", // Use the count of available doctors
                        icon:
                            Icons
                                .event_available_outlined, // Changed icon for variety
                        color: Colors.white, // Use theme color
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
                            AppConsts().timeSlots.map((time) {
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
                                                      Map<String, dynamic>?
                                                      packageUsed;
                                                      try {
                                                        packageUsed =
                                                            bookedPackages.firstWhere(
                                                                  (pkg) =>
                                                                      (pkg
                                                                          as Map<
                                                                            String,
                                                                            dynamic
                                                                          >)['name'] ==
                                                                      data['packageNameUsed'],
                                                                )
                                                                as Map<
                                                                  String,
                                                                  dynamic
                                                                >;
                                                      } catch (e) {
                                                        packageUsed =
                                                            null; // or some default value
                                                      }

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
