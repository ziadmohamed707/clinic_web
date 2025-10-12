import 'dart:async';
import 'dart:math';
import 'dart:ui';

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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:physioprime/ui/ScheduleGridPade/widget/buildStatsCard.dart';
import 'package:physioprime/ui/billPaymentScreen/ui/bill_notification_screen.dart';
import 'package:physioprime/ui/billPaymentScreen/ui/system_services_page.dart';
import 'package:url_launcher/url_launcher.dart';

class ScheduleGridScreen extends StatefulWidget {
  final UserModel user;

  const ScheduleGridScreen({Key? key, required this.user}) : super(key: key);

  @override
  _ScheduleGridScreenState createState() => _ScheduleGridScreenState();
}

class _ScheduleGridScreenState extends State<ScheduleGridScreen> {
  List<Map<String, dynamic>> _availableDoctorsForSelectedDate = [];
  List<Map<String, dynamic>> _selectedClientPackages = [];

  late Box box;
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  late Box _doctorsBox;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late CollectionReference _appointmentsCollection;
  late CollectionReference _clientsCollection;
  late CollectionReference _doctorsCollection;

  StreamSubscription? _appointmentsSubscription;
  StreamSubscription? _clientsSubscription;
  StreamSubscription? _doctorsSubscription;

  Timer? _timer;
  DateTime _currentTime = DateTime.now();
  String _storageUsage = 'Loading...';

  @override
  void initState() {
    super.initState();
    _initializeData();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
    _listenToStorageUsage();
  }

  @override
  void dispose() {
    _appointmentsSubscription?.cancel();
    _clientsSubscription?.cancel();
    _doctorsSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      setState(() => isLoading = true);
      box = Hive.box('appointments');
      _doctorsBox = await Hive.openBox('doctors');
      _appointmentsCollection = _firestore.collection('appointments');
      _clientsCollection = _firestore.collection('clients');
      _doctorsCollection = _firestore.collection('doctors');
      await _syncAndListen();
      // await _uploadOfflineData(); // This can be intensive, consider a more targeted sync strategy
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _syncAndListen() async {
    final clientBox = Hive.box('clients');

    // Initial sync for clients
    final clientSnapshot = await _clientsCollection.get();
    for (var doc in clientSnapshot.docs) {
      clientBox.put(doc.id, doc.data());
    }

    // Initial sync for appointments
    final appointmentSnapshot = await _appointmentsCollection.get();
    for (var doc in appointmentSnapshot.docs) {
      box.put(doc.id, doc.data());
    }

    // Initial sync for doctors
    final doctorSnapshot = await _doctorsCollection.get();
    for (var doc in doctorSnapshot.docs) {
      _doctorsBox.put(doc.id, doc.data());
    }

    // Now, set up listeners for real-time updates
    _clientsSubscription = _clientsCollection.snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          clientBox.delete(change.doc.id);
        } else {
          clientBox.put(
            change.doc.id,
            change.doc.data() as Map<dynamic, dynamic>,
          );
        }
      }
      if (mounted) setState(() {});
    }, onError: (e) => _showSnackBar('Client sync error: $e', Colors.red));

    _appointmentsSubscription = _appointmentsCollection.snapshots().listen((
      snapshot,
    ) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          box.delete(change.doc.id);
        } else {
          box.put(change.doc.id, change.doc.data() as Map<dynamic, dynamic>);
        }
      }
      if (mounted) setState(() {});
    }, onError: (e) => _showSnackBar('Appointment sync error: $e', Colors.red));

    // Listen to doctors
    _doctorsSubscription = _doctorsCollection.snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          _doctorsBox.delete(change.doc.id);
        } else {
          _doctorsBox.put(
            change.doc.id,
            change.doc.data() as Map<dynamic, dynamic>,
          );
        }
      }
      _loadAvailableDoctorsForSelectedDate();
    }, onError: (e) => _showSnackBar('Doctor sync error: $e', Colors.red));
  }

  void _listenToStorageUsage() {
    _firestore.collection('usage_stats').doc('storage').snapshots().listen(
      (snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          final sizeInBytes = data['totalSize'] as int? ?? 0;
          if (mounted) {
            setState(() {
              _storageUsage = _formatBytes(sizeInBytes);
            });
          }
        } else {
          // Handle case where the document doesn't exist
          if (mounted) {
            setState(() {
              _storageUsage = 'N/A';
            });
          }
        }
      },
      onError:
          (e) => _showSnackBar('Storage usage sync error: $e', Colors.orange),
    );
  }

  Future<void> _uploadOfflineData() async {
    try {
      // Upload offline appointments
      final appointmentBox = Hive.box('appointments');
      for (var key in appointmentBox.keys) {
        final appointmentData = Map<String, dynamic>.from(
          appointmentBox.get(key) as Map,
        );
        final doc = await _appointmentsCollection.doc(key.toString()).get();
        if (!doc.exists) {
          await _saveAppointmentToFirestore(key.toString(), appointmentData);
        }
      }

      // Upload offline clients
      final clientBox = Hive.box('clients');
      for (var key in clientBox.keys) {
        if (key == 'lastId') continue;
        final clientData = Map<String, dynamic>.from(clientBox.get(key) as Map);
        final doc = await _clientsCollection.doc(key.toString()).get();
        if (!doc.exists) {
          await _updateClientData(key.toString(), clientData);
        }
      }
    } catch (e) {
      _showSnackBar('Error uploading offline data: $e', Colors.orange);
    }
  }

  Future<void> _saveAppointmentToFirestore(
    String key,
    Map<String, dynamic> data,
  ) async {
    await _appointmentsCollection.doc(key).set(data);
  }

  Future<void> _updateClientData(
    String clientId,
    Map<String, dynamic> clientData,
  ) async {
    final clientBox = Hive.box('clients');
    try {
      await clientBox.put(clientId, clientData);
      await _clientsCollection.doc(clientId).set(clientData);

      final int currentClientIntId = clientData['id'] as int? ?? 0;
      final firestoreMetadataRef = _clientsCollection.doc('metadata');
      final metadataDoc = await firestoreMetadataRef.get();
      final int currentFirestoreLastId =
          (metadataDoc.data() as Map<String, dynamic>?)?['lastId'] as int? ?? 0;

      if (currentClientIntId > currentFirestoreLastId) {
        await firestoreMetadataRef.set({'lastId': currentClientIntId});
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to update client data: $e', Colors.red);
      }
    }
  }

  // Fix in _loadAvailableDoctorsForSelectedDate method
  void _loadAvailableDoctorsForSelectedDate() {
    final allDoctorsFromBox =
        _doctorsBox.values
            .map((doc) => Map<String, dynamic>.from(doc as Map))
            .toList();

    Iterable<Map<String, dynamic>> doctorsFilteredByRole;
    if (widget.user.role == 'doctor') {
      // Fix: Use the correct field for doctor identification
      doctorsFilteredByRole = allDoctorsFromBox.where((doctor) {
        // Try matching by both ID and name to be safe
        return doctor['id']?.toString() == widget.user.id?.toString() ||
            doctor['name']?.toString() == widget.user.username?.toString() ||
            doctor['name']?.toString() == widget.user.id?.toString();
      });
    } else {
      doctorsFilteredByRole = allDoctorsFromBox;
    }

    final String dayOfWeek = DateFormat('EEEE').format(selectedDate);

    setState(() {
      _availableDoctorsForSelectedDate =
          doctorsFilteredByRole.where((doctor) {
            final List<dynamic> availableDays =
                doctor['availableDays'] as List<dynamic>? ?? [];
            return availableDays.contains(dayOfWeek);
          }).toList();

      _availableDoctorsForSelectedDate.sort(
        (a, b) => (a['name'] as String).compareTo(b['name'] as String),
      );
    });
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
    }
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
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _loadAvailableDoctorsForSelectedDate(); // Reload doctors for the new date
    }
  }

  double _getCellHeight(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;

    if (screenWidth < 600) {
      return size.height * 0.13; // 12% من ارتفاع الشاشة
    } else if (screenWidth < 1200) {
      return size.height * 0.13;
    } else {
      return size.height * 0.13;
    }
  }

  Widget _buildAppointmentCell({
    required String timeSlot,
    required Map<String, dynamic> doctorData,
    required String formattedDateForKey,
  }) {
    final String key = '$formattedDateForKey-$timeSlot-${doctorData['id']}';
    final String columnDoctorName = doctorData['name'] as String;

    final data = box.get(
      key,
      defaultValue: {
        'patient': '',
        'doctor': columnDoctorName,
        'status': null,
        'serviceType': null,
      },
    );

    String patientPart = data['patient']?.toString().trim() ?? '';
    String? status = data['status'] as String?;
    String serviceTypeDisplay = data['serviceType'] as String? ?? '';
    String remainingSessionsDisplay = '';

    if (status == 'booked' &&
        data['clientId'] != null &&
        data['packageNameUsed'] != null) {
      final clientBox = Hive.box('clients');
      final clientData = clientBox.get(data['clientId'].toString());
      if (clientData != null && clientData is Map) {
        final bookedPackages =
            (clientData['bookedPackages'] as List<dynamic>?)
                ?.map((p) => Map<String, dynamic>.from(p as Map))
                .toList() ??
            [];

        final packageUsed = bookedPackages.firstWhere(
          (pkg) => pkg['name'] == data['packageNameUsed'],
          orElse: () => {},
        );

        if (packageUsed.isNotEmpty) {
          remainingSessionsDisplay = 'Rem: ${packageUsed['remainingSessions']}';
        }
      }
    }

    Color? cellColor;
    IconData? statusIcon;

    if (status == 'booked') {
      cellColor = Colors.green.withOpacity(0.2);
      statusIcon = Icons.check_circle;
    } else if (status == 'cancelled') {
      cellColor = Colors.red.withOpacity(0.2);
      statusIcon = Icons.cancel;
    } else {
      cellColor = Colors.grey.withOpacity(0.1);
    }

    String patientDisplay =
        patientPart.isNotEmpty
            ? patientPart
            : (status == 'cancelled' ? 'Cancelled' : 'Available');

    // 🔹 Responsive sizes
    final width = MediaQuery.of(context).size.width;
    double cellWidth, iconSize, titleFontSize, subFontSize, padding, spacing;

    if (width < 600) {
      // Mobile
      cellWidth = MediaQuery.of(context).size.width * 0.12;
      iconSize = 14;
      titleFontSize = 11;
      subFontSize = 9;
      padding = 8;
      spacing = 2;
    } else if (width < 1024) {
      // Tablet
      cellWidth = MediaQuery.of(context).size.width * 0.12;
      iconSize = 16;
      titleFontSize = 13;
      subFontSize = 10;
      padding = 10;
      spacing = 4;
    } else if (width < 1600) {
      // Laptop
      cellWidth = MediaQuery.of(context).size.width * 0.12;
      iconSize = 18;
      titleFontSize = 14;
      subFontSize = 11;
      padding = 8;
      spacing = 2;
    } else {
      // Large screens
      cellWidth = MediaQuery.of(context).size.width * 0.12;
      iconSize = 20;
      titleFontSize = 14;
      subFontSize = 12;
      padding = 8;
      spacing = 2;
    }

    return GestureDetector(
      onTap: () {
        if (widget.user.role == 'desk' || widget.user.role == 'admin') {
          _editCell(timeSlot, doctorData);
        }
      },
      child: Container(
        height: _getCellHeight(context),
        width: cellWidth,
        margin: const EdgeInsets.all(2),
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: cellColor,
          border: Border.all(
            color:
                status == 'booked'
                    ? Colors.green.withOpacity(0.5)
                    : status == 'cancelled'
                    ? Colors.red.withOpacity(0.5)
                    : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow:
              status != null
                  ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (statusIcon != null)
              Icon(
                statusIcon,
                size: iconSize,
                color: status == 'booked' ? Colors.green : Colors.red,
              ),
            SizedBox(height: spacing),
            Text(
              patientDisplay,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: titleFontSize,
                overflow: TextOverflow.clip,

                color:
                    status == 'booked'
                        ? Colors.green.shade800
                        : status == 'cancelled'
                        ? Colors.red.shade800
                        : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            if (serviceTypeDisplay.isNotEmpty && patientPart.isNotEmpty) ...[
              SizedBox(height: spacing),
              Text(
                serviceTypeDisplay,
                style: TextStyle(
                  fontSize: subFontSize,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: spacing),
              Text(
                remainingSessionsDisplay,
                style: TextStyle(
                  fontSize: subFontSize - 1,
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.white, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ), // Cannot be const
      hoverColor: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildMainContent() {
    final String formattedDateForKey = DateFormat(
      'yyyy-MM-dd',
    ).format(selectedDate);

    // Calculate stats
    int todayAppointments = 0;
    int cancelledAppointments = 0;

    if (box.isOpen) {
      for (var key in box.keys) {
        if (key.toString().startsWith(formattedDateForKey)) {
          final appointmentData = box.get(key);
          if (appointmentData != null) {
            if (appointmentData is Map &&
                appointmentData['status'] == 'booked') {
              todayAppointments++;
            } else if (appointmentData is Map &&
                appointmentData['status'] == 'cancelled') {
              cancelledAppointments++;
            }
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Moved from outer scaffold
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Schedule Overview',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    DateFormat(
                                      'EEEE, MMMM d, yyyy',
                                    ).format(selectedDate),
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat(
                                      'h:mm:ss a',
                                    ).format(_currentTime),
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _selectDate(context),
                              icon: Icon(Icons.calendar_today, size: 18),
                              label: Text('Select Date'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 5,
                                shadowColor: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double width = constraints.maxWidth;

                  // 🔹 Breakpoints
                  int crossAxisCount;
                  double childAspectRatio;

                  if (width < 600) {
                    // موبايل
                    crossAxisCount = 2;
                    childAspectRatio = 2.0;
                  } else if (width < 1024) {
                    // تابلت
                    crossAxisCount = 2;
                    childAspectRatio = 2.2;
                  } else if (width < 1600) {
                    // لابتوب
                    crossAxisCount = 4;
                    childAspectRatio = 2;
                  } else {
                    // شاشات كبيرة
                    crossAxisCount = 4;
                    childAspectRatio = 2.5;
                  }

                  return GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: childAspectRatio,
                    ),
                    children: [
                      buildStatsCard(
                        title: "Today's Appointments",
                        value: "$todayAppointments",
                        icon: Icons.calendar_today,
                        color: Colors.blue.shade400,
                        context: context,
                      ),
                      buildStatsCard(
                        title: "Cancelled Appointments",
                        value: "$cancelledAppointments",
                        icon: Icons.event_busy,
                        color: Colors.red.shade400,
                        context: context,
                      ),
                      buildStatsCard(
                        title: "Total Clients",
                        value:
                            "${Hive.box('clients').keys.where((k) => k != 'lastId').length}",
                        icon: Icons.people,
                        color: Colors.green.shade400,
                        context: context,
                      ),
                      buildStatsCard(
                        title: "Available Slots",
                        value:
                            "${(_availableDoctorsForSelectedDate.length * (AppConsts.timeSlots.length)) - todayAppointments}",
                        icon: Icons.event_available,
                        color: Colors.orange.shade400,
                        context: context,
                      ),
                      buildStatsCard(
                        title: "Storage Usage",
                        value: _storageUsage,
                        icon: Icons.storage_rounded,
                        color: Colors.purple.shade400,
                        context: context,
                      ),
                    ],
                  );
                },
              ),
            ),

            // Schedule Grid
            IntrinsicHeight(
              child: Container(
                // Cannot be const
                width: double.infinity, // Cannot be const
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appointment Schedule',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 20), // This was missing a const
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // Header Row
                              Row(
                                children: [
                                  Container(
                                    width: 100,
                                    height: _getCellHeight(context) * 0.5,
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Time',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  ..._availableDoctorsForSelectedDate.map((
                                    doctor,
                                  ) {
                                    return Container(
                                      width: 175,
                                      margin: EdgeInsets.only(right: 8),
                                      height: _getCellHeight(context) * 0.5,
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          doctor['name'] as String,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Theme.of(context).primaryColor,
                                            fontSize: 16,
                                          ),
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Time Slots
                              ...(AppConsts.timeSlots).map((timeSlot) {
                                return Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 100,
                                        height: _getCellHeight(context),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            timeSlot,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      ..._availableDoctorsForSelectedDate.map((
                                        doctor,
                                      ) {
                                        return Container(
                                          height: _getCellHeight(context),
                                          width: 175,
                                          margin: EdgeInsets.only(right: 8),
                                          child: _buildAppointmentCell(
                                            timeSlot: timeSlot,
                                            doctorData: doctor,
                                            formattedDateForKey:
                                                formattedDateForKey,
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  const Text(
                    'Developed by zyverse.dev',
                    style: TextStyle(fontSize: 11, color: Colors.black),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Crafting Digital Realities | 01024375442',
                    style: TextStyle(fontSize: 10, color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the sidebar content.
  /// Reused by the desktop fixed sidebar and the mobile drawer.
  Widget _buildSidebarContent() {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.95),
            Theme.of(context).primaryColorDark.withOpacity(0.9),
            Colors.black.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24), // Cannot be const
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20, // Cannot be
            offset: Offset(5, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          // Cannot be const
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              // Cannot be const
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Header Section
                Padding(
                  // Cannot be const
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      // Logo Container
                      TweenAnimationBuilder(
                        duration: Duration(milliseconds: 1500),
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, double value, child) {
                          return Transform.scale(
                            scale: 0.8 + (0.2 * value),
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                // Cannot be const
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.3 * value),
                                    Colors.white.withOpacity(0.1 * value),
                                    Colors.transparent,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(
                                      0.3 * value,
                                    ),
                                    blurRadius: 20 * value,
                                    spreadRadius: 5 * value,
                                  ),
                                ],
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                    width: 2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(45),
                                  child: Image.asset(
                                    'assets/phsioprime_logo.jpg',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      // App Name
                      ShaderMask(
                        shaderCallback:
                            (bounds) => LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.white.withOpacity(0.8),
                                Colors.cyan.withOpacity(0.9),
                              ],
                            ).createShader(bounds),
                        child: Text(
                          AppConsts.appName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      // User Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.8),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.6),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              widget.user.username ?? '',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.amber.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                (widget.user.role ?? '').toUpperCase(),
                                style: TextStyle(
                                  color: Colors.amber.shade200,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Navigation Menu
                Expanded(
                  child: ListView(
                    // Cannot be const
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      if (widget.user.role == 'admin' ||
                          widget.user.role == 'desk') ...[
                        _buildModernSidebarItem(
                          icon: Icons.person_add_alt_1_rounded,
                          title: 'Add Client',
                          subtitle: 'Register new clients',
                          gradient: [
                            Colors.blue.shade400,
                            Colors.blue.shade600,
                          ],
                          onTap: _addClient,
                        ),
                        SizedBox(height: 12),
                        _buildModernSidebarItem(
                          icon: Icons.groups_rounded,
                          title: 'Clients List',
                          subtitle: 'Manage all clients',
                          gradient: [
                            Colors.purple.shade400,
                            Colors.purple.shade600,
                          ],
                          onTap: _openClientPage,
                        ),
                        SizedBox(height: 12),
                        _buildModernSidebarItem(
                          icon: Icons.medical_services_rounded,
                          title: 'Service Packages',
                          subtitle: 'Healthcare plans',
                          gradient: [
                            Colors.green.shade400,
                            Colors.green.shade600,
                          ],
                          onTap: _openPackagesPage,
                        ),
                        SizedBox(height: 12),
                        _buildModernSidebarItem(
                          icon: Icons.account_balance_wallet_rounded,
                          title: 'Financial Management',
                          subtitle: 'Revenue & expenses',
                          gradient: [
                            Colors.orange.shade400,
                            Colors.orange.shade600,
                          ],
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FinancialManagementPage(),
                                ),
                              ),
                        ),
                      ],
                      if (widget.user.role == 'admin') ...[
                        // Cannot be const
                        const SizedBox(height: 20),
                        // Admin Section Divider
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withOpacity(0.3),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'ADMIN PANEL',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withOpacity(0.3),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildModernSidebarItem(
                          icon: Icons.local_hospital_rounded,
                          title: 'Manage Doctors',
                          subtitle: 'Doctor profiles',
                          gradient: [
                            Colors.teal.shade400,
                            Colors.teal.shade600,
                          ],
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ManageDoctorsPage(),
                                ),
                              ),
                        ),
                        SizedBox(height: 12),
                        _buildModernSidebarItem(
                          icon: Icons.admin_panel_settings_rounded,
                          title: 'Manage Users',
                          subtitle: 'System users',
                          gradient: [
                            Colors.indigo.shade400,
                            Colors.indigo.shade600,
                          ],
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ManageUsersPage(),
                                ),
                              ),
                        ),
                        SizedBox(height: 12),
                        _buildModernSidebarItem(
                          icon: Icons.miscellaneous_services_rounded,
                          title: 'System Services',
                          subtitle: 'Request new features',
                          gradient: [
                            Colors.cyan.shade400,
                            Colors.cyan.shade600,
                          ],
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SystemServicesPage(),
                                ),
                              ),
                        ),
                        SizedBox(height: 12),
                        _buildModernSidebarItem(
                          icon: Icons.payment_rounded,
                          title: 'Bills & Payments',
                          subtitle: 'Manage your bills',
                          gradient: [
                            Colors.grey.shade600,
                            Colors.grey.shade800,
                          ],
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BillNotificationScreen(),
                                ),
                              ),
                        ),
                      ],
                      SizedBox(height: 40),
                      // Logout Button
                      _buildLogoutButton(),
                      SizedBox(height: 20),
                      Padding(
                        padding: EdgeInsets.only(bottom: 20.0),
                        child: Column(
                          children: [
                            const Text(
                              'Developed by zyverse.dev',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Crafting Digital Realities | 01024375442',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.5),
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
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      // Cannot be const
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const double mobileBreakpoint = 850;
        final bool isMobile = constraints.maxWidth < mobileBreakpoint;

        if (isMobile) {
          // Mobile Layout
          return Scaffold(
            appBar: AppBar(
              title: Text(AppConsts.appName),
              backgroundColor: Theme.of(context).primaryColor,
            ),
            drawer: Drawer(child: _buildSidebarContent()),
            body: _buildMainContent(),
          );
        } else {
          // Desktop/Tablet Layout
          return Scaffold(
            backgroundColor: Colors.grey.shade50,
            body: Row(
              children: [
                // Sidebar
                _buildSidebarContent(),
                // Main Content
                Expanded(child: _buildMainContent()),
              ],
            ),
          );
        }
      },
    );
  }

  /// Fetches a list of clients specifically for the logged-in doctor.
  List<Map<String, dynamic>> _getClientsForDoctor(String doctorId) {
    final clientBox = Hive.box('clients');
    final appointmentBox = Hive.box('appointments');
    final clientIds = <String>{};

    // Find all unique client IDs from appointments with this doctor
    for (var key in appointmentBox.keys) {
      final appointment = appointmentBox.get(key);

      if (appointment is Map && appointment['status'] == 'booked') {
        // Check multiple possible doctor identification fields
        final appointmentDoctorId = appointment['doctorId']?.toString();
        final appointmentDoctorName = appointment['doctor']?.toString();

        // Match by doctorId or doctor name
        if ((appointmentDoctorId != null && appointmentDoctorId == doctorId) ||
            (appointmentDoctorName != null &&
                appointmentDoctorName == doctorId)) {
          if (appointment['clientId'] != null) {
            clientIds.add(appointment['clientId'].toString());
          }
        }
      }
    }

    // Retrieve the full client data for each unique ID
    final clients =
        clientIds
            .map((id) => clientBox.get(id))
            .where((client) => client != null)
            .map((client) => Map<String, dynamic>.from(client as Map))
            .toList();

    return clients;
  }

  // Dialog and interaction methods
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

    final doctorController = TextEditingController(
      text: existing['doctor'] ?? columnDoctorName,
    );
    final clientBox = Hive.box('clients');
    List<Map<String, dynamic>> allClients;
    if (widget.user.role == 'doctor') {
      allClients = _getClientsForDoctor(doctorData['id'].toString());
    } else {
      allClients =
          clientBox.keys
              .where((key) => key != 'lastId')
              .map(
                (key) => Map<String, dynamic>.from(clientBox.get(key) as Map),
              )
              .toList();
    }

    Map? selectedClient;
    if (existing['clientId'] != null) {
      final clientData = clientBox.get(existing['clientId'].toString());
      if (clientData != null) {
        selectedClient = Map<String, dynamic>.from(clientData as Map);
      }
    }

    final searchController = TextEditingController();
    List<Map> localFilteredClients = List.from(allClients);
    String? dialogSelectedServiceType = existing['serviceType'] as String?;
    String? dialogSelectedPackageName;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                'Edit Appointment on ${DateFormat('MMM d').format(selectedDate)} at $timeSlot',
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Client Search
                      TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          labelText: 'Search Client',
                          icon: Icon(Icons.search),
                        ),
                        onChanged: (query) {
                          setStateDialog(() {
                            if (query.isEmpty) {
                              localFilteredClients = List.from(allClients);
                            } else {
                              localFilteredClients =
                                  allClients.where((client) {
                                    final name =
                                        client['name']
                                            ?.toString()
                                            .toLowerCase() ??
                                        '';
                                    final id =
                                        client['id']
                                            ?.toString()
                                            .toLowerCase() ??
                                        '';
                                    return name.contains(query.toLowerCase()) ||
                                        id.contains(query.toLowerCase());
                                  }).toList();
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // Client List
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: localFilteredClients.length,
                          itemBuilder: (context, index) {
                            final client = localFilteredClients[index];
                            return ListTile(
                              title: Text(client['name'] ?? 'Unknown'),
                              subtitle: Text('ID: ${client['id']}'),
                              onTap: () {
                                setStateDialog(() {
                                  selectedClient = client;
                                });
                              },
                              tileColor:
                                  selectedClient != null &&
                                          selectedClient!['id'] == client['id']
                                      ? Colors.blue.withOpacity(0.2)
                                      : null,
                            );
                          },
                        ),
                      ),
                      if (selectedClient != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Selected: ${selectedClient!['name']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (selectedClient!['bookedPackages'] != null &&
                            (selectedClient!['bookedPackages'] as List)
                                .isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12.0),
                            margin: const EdgeInsets.only(bottom: 16.0),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.teal.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Active Packages:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColorDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ...(selectedClient!['bookedPackages'] as List).map((
                                  pkg,
                                ) {
                                  final package = Map<String, dynamic>.from(
                                    pkg as Map,
                                  );
                                  return Text(
                                    '• ${package['name']}: ${package['remainingSessions']} sessions remaining',
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                      ],

                      // Service Type
                      DropdownButtonFormField<String>(
                        value: dialogSelectedServiceType,
                        hint: Text('Select Service Type'),
                        items:
                            (AppConsts.kServiceTypes ?? [])
                                .map(
                                  (service) => DropdownMenuItem(
                                    value: service,
                                    child: Text(service),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setStateDialog(() {
                            dialogSelectedServiceType = value;
                          });
                        },
                      ),
                      if (dialogSelectedServiceType == 'Follow-up Session' &&
                          selectedClient != null &&
                          (selectedClient!['bookedPackages'] as List?)
                                  ?.isNotEmpty ==
                              true) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: dialogSelectedPackageName,
                          hint: const Text('Select Package to Use'),
                          isExpanded: true,
                          items:
                              (selectedClient!['bookedPackages'] as List).map((
                                pkg,
                              ) {
                                final package = Map<String, dynamic>.from(
                                  pkg as Map,
                                );
                                final remaining =
                                    package['remainingSessions'] ?? 0;
                                return DropdownMenuItem<String>(
                                  value: package['name'],
                                  enabled: remaining > 0,
                                  child: Text(
                                    '${package['name']} ($remaining sessions left)',
                                    style: TextStyle(
                                      color:
                                          remaining > 0
                                              ? Colors.black
                                              : Colors.grey,
                                    ),
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setStateDialog(
                              () => dialogSelectedPackageName = value,
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Doctor
                      TextField(
                        // Cannot be const
                        controller: doctorController,
                        decoration: InputDecoration(labelText: 'Doctor'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  // Cannot be const
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                if (existing['status'] == 'booked')
                  TextButton.icon(
                    icon: Icon(Icons.event_busy, color: Colors.orange),
                    label: Text(
                      'Cancel Appt.',
                      style: TextStyle(color: Colors.orange),
                    ),
                    onPressed:
                        () => _cancelAppointment(
                          dialogContext,
                          key,
                          existing,
                          columnDoctorName,
                        ),
                  ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedClient != null) {
                      final clientBox = Hive.box('clients');
                      Map<String, dynamic> clientData =
                          Map<String, dynamic>.from(
                            clientBox.get(selectedClient!['id'].toString())
                                    as Map? ??
                                {},
                          );
                      List<Map<String, dynamic>> bookedPackages =
                          (clientData['bookedPackages'] as List<dynamic>?)
                              ?.map((p) => Map<String, dynamic>.from(p as Map))
                              .toList() ??
                          [];

                      bool packageSessionDecremented = false;
                      String? packageCategoryUsed;

                      if (dialogSelectedPackageName != null &&
                          bookedPackages.isNotEmpty) {
                        final packageIndex = bookedPackages.indexWhere(
                          (pkg) => pkg['name'] == dialogSelectedPackageName,
                        );

                        if (packageIndex != -1) {
                          final package = bookedPackages[packageIndex];
                          final remaining =
                              (package['remainingSessions'] as int? ?? 0);
                          if (remaining > 0) {
                            package['remainingSessions'] = remaining - 1;
                            packageCategoryUsed =
                                package['category'] as String?;
                            packageSessionDecremented = true;
                          } else {
                            _showSnackBar(
                              'Selected package has no sessions left.',
                              Colors.orange,
                            );
                            return;
                          }
                        }
                      }

                      final appointmentData = {
                        'patient': selectedClient!['name'],
                        'phone': selectedClient!['phone'],
                        'doctorId': doctorData['id'],
                        'doctor': doctorController.text,
                        'clientId': selectedClient!['id'],
                        'packageNameUsed': dialogSelectedPackageName,
                        'packageCategoryUsed': packageCategoryUsed,
                        'status': 'booked',
                        'serviceType': dialogSelectedServiceType,
                      };

                      await box.put(key, appointmentData);
                      await _saveAppointmentToFirestore(key, appointmentData);

                      if (packageSessionDecremented) {
                        clientData['bookedPackages'] = bookedPackages;
                        await _updateClientData(
                          selectedClient!['id'].toString(),
                          clientData,
                        );
                      }

                      Navigator.pop(dialogContext, true);
                    } else {
                      _showSnackBar(
                        'Please select a client.',
                        Colors.orangeAccent,
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
                if (selectedClient != null)
                  TextButton.icon(
                    icon: const Icon(Icons.chat, color: Colors.green),
                    label: const Text(
                      'WhatsApp',
                      style: TextStyle(color: Colors.green),
                    ),
                    onPressed: () {
                      _sendWhatsAppMessage(selectedClient!, timeSlot);
                    },
                  ),
              ],
            );
          },
        );
      },
    ).then((saved) {
      if (saved == true) {
        setState(() {}); // Refresh UI
      }
    });
  }

  Future<void> _sendWhatsAppMessage(Map client, String timeSlot) async {
    final String phone = client['phone']?.toString() ?? '';
    if (phone.isEmpty) {
      _showSnackBar('Client does not have a phone number.', Colors.orange);
      return;
    }

    final String clientName = client['name']?.toString() ?? 'Valued Client';
    final String formattedDate = DateFormat(
      'EEEE, dd MMMM yyyy',
    ).format(selectedDate);

    // Using the pre-formatted message from AppConsts
    final String message = AppConsts.getWhatsAppMessage(
      clientName,
      formattedDate,
      timeSlot,
    );

    // Ensure phone number is in international format for wa.me link
    final String internationalPhone =
        phone.startsWith('+') ? phone : '+2$phone';

    final Uri whatsappUri = Uri.parse(
      'https://wa.me/$internationalPhone?text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not launch WhatsApp.', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error launching WhatsApp: $e', Colors.red);
    }
  }

  Future<void> _cancelAppointment(
    BuildContext dialogContext,
    String key,
    Map existing,
    String columnDoctorName,
  ) async {
    final bool? confirmRemove = await showDialog<bool>(
      context: dialogContext,
      builder:
          (confirmDialogContext) => AlertDialog(
            // Cannot be const
            title: const Text('Cancel Appointment'),
            content: const Text(
              'Are you sure you want to cancel this appointment? This will return a session if it was part of a package.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(confirmDialogContext, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(confirmDialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ), // Cannot be
                child: Text('Yes, Cancel'),
              ),
            ],
          ),
    );

    if (confirmRemove != true) return;

    try {
      // If it was a package session, increment the remaining sessions
      final String? clientId = existing['clientId']?.toString();
      final String? packageNameUsed = existing['packageNameUsed'] as String?;

      if (clientId != null && packageNameUsed != null) {
        final clientBox = Hive.box('clients');
        final clientData = Map<String, dynamic>.from(
          clientBox.get(clientId) as Map? ?? {},
        );
        if (clientData.isNotEmpty) {
          final bookedPackages =
              (clientData['bookedPackages'] as List<dynamic>?)
                  ?.map((p) => Map<String, dynamic>.from(p as Map))
                  .toList() ??
              [];

          final packageIndex = bookedPackages.indexWhere(
            (pkg) => pkg['name'] == packageNameUsed,
          );

          if (packageIndex != -1) {
            final package = bookedPackages[packageIndex];
            final remaining = (package['remainingSessions'] as int? ?? 0) + 1;
            final total = package['totalSessions'] as int? ?? 0;

            if (remaining <= total) {
              package['remainingSessions'] = remaining;
              clientData['bookedPackages'] = bookedPackages;
              await _updateClientData(clientId, clientData);
            }
          }
        }
      }

      // Update the appointment to 'cancelled'
      final Map<String, dynamic> cancelledData = Map<String, dynamic>.from(
        existing as Map,
      );
      cancelledData['status'] = 'cancelled';

      box.put(key, cancelledData);
      await _saveAppointmentToFirestore(key, cancelledData);

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext, true); // Close the edit dialog
      }
    } catch (e) {
      _showSnackBar('Error canceling appointment: $e', Colors.red);
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
            // Cannot be const
            title: Text(
              'Add New Client',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            content: SingleChildScrollView(
              child: Column(
                // Cannot be const
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Age',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number (e.g., 01012345678)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  if (nameController.text.isEmpty ||
                      phoneController.text.isEmpty) {
                    _showSnackBar(
                      'Name and Phone Number are required.',
                      Colors.orange,
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
                    'bookedPackages': [],
                  };

                  await _updateClientData(clientKey, clientData);
                  clientBox.put('lastId', newId);

                  Navigator.pop(context);
                  _showSnackBar('Client added successfully!', Colors.green);
                  setState(() {});
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Add Client'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
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

  // Helper Methods
  Widget _buildModernSidebarItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 200),
      tween: Tween<double>(begin: 1, end: 1),
      builder: (context, double scale, child) {
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTapDown: (_) => setState(() {}), // This might not be needed
            onTapUp: (_) => setState(() {}), // This might not be needed
            onTap: onTap, // Cannot be const
            child: Container(
              // Cannot be const
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.first.withOpacity(0.4),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withOpacity(0.5),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () {
        context.read<AuthBloc>().add(LogoutRequested());
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red.shade400.withOpacity(0.8),
              Colors.red.shade600.withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.white, size: 22),
            SizedBox(width: 12),
            Text(
              'Logout',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes, [int decimals = 2]) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) +
        ' ' +
        suffixes[i];
  }
}
