import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:geocoding/geocoding.dart';
import 'package:physioone/core/app_consts/app_consts.dart';
import 'package:physioone/ui/ClientListPage/ui/client_list_page.dart';
import 'package:physioone/ui/FinancialManagementPage/ui/financial_management_page.dart';
import 'package:physioone/ui/LoginPage/bloc/auth_bloc.dart';
import 'package:physioone/ui/LoginPage/bloc/auth_event.dart';
import 'package:physioone/ui/LoginPage/models/user_model.dart';
import 'package:physioone/ui/LoginPage/ui/login_page.dart';
import 'package:physioone/ui/ManageDoctorPage/ui/manage_doctors_page.dart';
import 'package:physioone/ui/ManageUserPage/ui/manage_users_page.dart';
import 'package:physioone/main.dart';
import 'package:physioone/ui/PackagesPage/ui/packages_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:html' as html;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:physioone/ui/ScheduleGridPade/ui/user_profile_page.dart';
import 'package:physioone/ui/ScheduleGridPade/widget/buildStatsCard.dart';
import 'package:physioone/ui/billPaymentScreen/ui/bill_notification_screen.dart';
import 'package:physioone/ui/billPaymentScreen/ui/system_services_page.dart';
import 'package:physioone/hr_system/ui/hr_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:physioone/core/app_consts/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:physioone/hr_system/services/employee_service.dart';
import 'package:physioone/hr_system/model/employee_model.dart';
import 'package:collection/collection.dart';

class ScheduleGridScreen extends StatefulWidget {
  final UserModel user;

  const ScheduleGridScreen({super.key, required this.user});

  @override
  _ScheduleGridScreenState createState() => _ScheduleGridScreenState();
}

class _ScheduleGridScreenState extends State<ScheduleGridScreen> {
  List<Map<String, dynamic>> _availableDoctorsForSelectedDate = [];

  late Box box;
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  late Box _doctorsBox;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late CollectionReference _appointmentsCollection;
  late CollectionReference _clientsCollection;
  late CollectionReference _doctorsCollection;
  late CollectionReference _doctorProfileCollection;

  StreamSubscription? _appointmentsSubscription;
  StreamSubscription? _clientsSubscription;
  StreamSubscription? _doctorsSubscription;

  StreamSubscription? _employeeSubscription;

  Timer? _timer;
  Timer? _locationTimer;
  DateTime _currentTime = DateTime.now();
  String _storageUsage = 'Loading...';
  final LocationService _locationService = LocationService();
  String _currentLocationStatus = 'Fetching location...';
  final EmployeeService _employeeService = EmployeeService();
  Position? _currentPosition;
  bool _isFetchingLocation = false;

  final ScrollController _horizontalScrollController = ScrollController();

  // متغيرات Check-In/Out
  EmployeeModel? _currentUserEmployee;
  bool _isProcessingCheckIn = false;

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
    _getCurrentLocation();
    _locationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) _getCurrentLocation();
    });
    _listenToCurrentUserEmployee();
  }

  @override
  void dispose() {
    _appointmentsSubscription?.cancel();
    _clientsSubscription?.cancel();
    _doctorsSubscription?.cancel();
    _timer?.cancel();
    _locationTimer?.cancel();
    _employeeSubscription?.cancel();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // دوال Check-In / Check-Out
  // ============================================================

  bool get _hasCheckedInToday {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayRecord = _currentUserEmployee?.attendance.firstWhereOrNull(
      (record) => record['date'] == today,
    );
    return todayRecord != null && todayRecord['checkIn'] != '';
  }

  bool get _hasCheckedOutToday {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayRecord = _currentUserEmployee?.attendance.firstWhereOrNull(
      (record) => record['date'] == today,
    );
    return todayRecord != null && todayRecord['checkOut'] != '';
  }

  void _listenToCurrentUserEmployee() {
    _employeeSubscription = _employeeService
        .employeeStream(widget.user.id!)
        .listen(
          (employee) {
            if (mounted) {
              setState(() {
                _currentUserEmployee = employee;
              });
            }
          },
          onError: (e) {
            print("Failed to listen to current user's employee data: $e");
          },
        );
  }

  Future<void> _handleCheckIn(
    BuildContext context,
    EmployeeModel employee,
  ) async {
    if (_isProcessingCheckIn) return;
    setState(() => _isProcessingCheckIn = true);

    try {
      // 1. التحقق من الموقع
      final (isWithinRadius, messageOrError) =
          await _locationService.isUserWithinClinicRadius();

      if (!isWithinRadius) {
        throw Exception(messageOrError);
      }

      // 2. تسجيل الحضور
      final now = DateTime.now();
      final checkInTime = TimeOfDay.fromDateTime(now);
      final officialStartTime = TimeOfDay(hour: 9, minute: 0);

      String status = 'Present';
      if (checkInTime.hour > officialStartTime.hour ||
          (checkInTime.hour == officialStartTime.hour &&
              checkInTime.minute > officialStartTime.minute)) {
        status = 'Late';
      }

      final userPosition = await _locationService.getCurrentPosition();
      final newAttendanceRecord = {
        'date': DateFormat('yyyy-MM-dd').format(now),
        'checkIn':
            '${checkInTime.hour.toString().padLeft(2, '0')}:${checkInTime.minute.toString().padLeft(2, '0')}',
        'checkOut': '',
        'status': status,
        'checkInLocation': {
          'latitude': userPosition.latitude,
          'longitude': userPosition.longitude,
        },
      };

      final updatedAttendance = List<Map<String, dynamic>>.from(
        employee.attendance,
      );
      updatedAttendance.add(newAttendanceRecord);

      final updatedEmployee = employee.copyWith(attendance: updatedAttendance);
      await _employeeService.updateEmployee(updatedEmployee);

      if (mounted) {
        _showSnackBar(
          '✅ Checked in successfully! Status: $status',
          Colors.green,
        );
        setState(() {}); // تحديث حالة الأزرار
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          '❌ Check-in failed: ${e.toString().replaceFirst("Exception: ", "")}',
          Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingCheckIn = false);
      }
    }
  }

  Future<void> _handleCheckOut(
    BuildContext context,
    EmployeeModel employee,
  ) async {
    if (_isProcessingCheckIn) return;
    setState(() => _isProcessingCheckIn = true);

    try {
      final now = DateTime.now();
      final checkOutTime = TimeOfDay.fromDateTime(now);
      final todayString = DateFormat('yyyy-MM-dd').format(now);

      final updatedAttendance = List<Map<String, dynamic>>.from(
        employee.attendance,
      );
      final todayRecordIndex = updatedAttendance.indexWhere(
        (rec) => rec['date'] == todayString,
      );

      if (todayRecordIndex == -1) {
        throw Exception('Cannot check out without checking in first.');
      }

      if (updatedAttendance[todayRecordIndex]['checkOut'] != '') {
        _showSnackBar(
          '✅ You already checked out at ${updatedAttendance[todayRecordIndex]['checkOut']}',
          Colors.orange,
        );
        setState(() => _isProcessingCheckIn = false);
        return;
      }

      final userPosition = await _locationService.getCurrentPosition();

      updatedAttendance[todayRecordIndex]['checkOut'] =
          '${checkOutTime.hour.toString().padLeft(2, '0')}:${checkOutTime.minute.toString().padLeft(2, '0')}';
      updatedAttendance[todayRecordIndex]['checkOutLocation'] = {
        'latitude': userPosition.latitude,
        'longitude': userPosition.longitude,
      };

      final updatedEmployee = employee.copyWith(attendance: updatedAttendance);
      await _employeeService.updateEmployee(updatedEmployee);

      if (mounted) {
        _showSnackBar('✅ Checked out successfully!', Colors.blue);
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          '❌ Check-out failed: ${e.toString().replaceFirst("Exception: ", "")}',
          Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingCheckIn = false);
      }
    }
  }

  // ============================================================
  // باقي دوال ScheduleGridScreen (بنفس الكود السابق)
  // ============================================================

  Future<void> _initializeData() async {
    try {
      setState(() => isLoading = true);
      box = Hive.box('appointments');
      _doctorsBox = await Hive.openBox('doctors');
      _appointmentsCollection = _firestore.collection('appointments');
      _clientsCollection = _firestore.collection('clients');
      _doctorsCollection = _firestore.collection('doctors');
      _doctorProfileCollection = _firestore.collection('employees');
      await _syncAndListen();
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _syncAndListen() async {
    final clientBox = Hive.box('clients');

    final clientSnapshot = await _clientsCollection.get();
    for (var doc in clientSnapshot.docs) {
      clientBox.put(doc.id, doc.data());
    }

    final appointmentSnapshot = await _appointmentsCollection.get();
    for (var doc in appointmentSnapshot.docs) {
      box.put(doc.id, doc.data());
    }

    final doctorSnapshot = await _doctorsCollection.get();
    for (var doc in doctorSnapshot.docs) {
      _doctorsBox.put(doc.id, doc.data());
    }

    final doctorProfileSnapshot = await _doctorProfileCollection.get();
    doctorProfileSnapshot.docs.forEach((doc) {
      _doctorsBox.put(doc.id, doc.data());
    });

    _clientsSubscription = _clientsCollection.snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          final data = change.doc.data() as Map<dynamic, dynamic>?;
          clientBox.delete(data?['id']?.toString() ?? change.doc.id);
        } else {
          final data = change.doc.data() as Map<String, dynamic>?;
          clientBox.put(data?['id']?.toString() ?? change.doc.id, data ?? {});
        }
      }
      if (mounted) setState(() {});
    }, onError: (e) => _showSnackBar('Client sync error: $e', Colors.red));

    _appointmentsSubscription = _appointmentsCollection.snapshots().listen((
      snapshot,
    ) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          final data = change.doc.data() as Map<dynamic, dynamic>?;
          box.delete(data?['id']?.toString() ?? change.doc.id);
        } else {
          box.put(change.doc.id, change.doc.data() as Map<dynamic, dynamic>);
        }
      }
      if (mounted) setState(() {});
    }, onError: (e) => _showSnackBar('Appointment sync error: $e', Colors.red));

    _doctorsSubscription = _doctorsCollection.snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          final data = change.doc.data() as Map<dynamic, dynamic>?;
          _doctorsBox.delete(data?['id']?.toString() ?? change.doc.id);
        } else {
          final data = change.doc.data() as Map<String, dynamic>?;
          _doctorsBox.put(data?['id']?.toString() ?? change.doc.id, data ?? {});
        }
      }
      _loadAvailableDoctorsForSelectedDate();
    }, onError: (e) => _showSnackBar('Doctor sync error: $e', Colors.red));
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar(
        'Location services are disabled. Please enable them.',
        Colors.orange,
      );
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('Location permissions are denied.', Colors.red);
        return false;
      }
    }
    return true;
  }

  Future<void> _getCurrentLocation() async {
    if (_isFetchingLocation) return;
    setState(() {
      _isFetchingLocation = true;
      _currentLocationStatus = 'Fetching location...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentLocationStatus =
              'GPS services are disabled. Please enable them.';
          _isFetchingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentLocationStatus =
                'Location permission denied. Please grant permission.';
            _isFetchingLocation = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocationStatus =
              'Location permission permanently denied. Please enable from settings.';
          _isFetchingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Location request timed out.');
        },
      );

      String address = 'Unknown location';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          address =
              placemarks.first.street ??
              '${placemarks.first.locality}, ${placemarks.first.country}';
        }
      } catch (geocodeError) {
        address =
            'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
      }

      if (mounted) {
        setState(() {
          _currentLocationStatus =
              '$address (Accuracy: ${position.accuracy.toStringAsFixed(0)}m)';
          _currentPosition = position;
          _isFetchingLocation = false;
        });
      }
    } catch (e) {
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      if (errorMsg.contains('permission')) {
        errorMsg = 'Location permission denied. Please grant permission.';
      } else if (errorMsg.contains('service')) {
        errorMsg = 'Location services are disabled. Please enable GPS.';
      }
      if (mounted) {
        setState(() {
          _currentLocationStatus = 'Location unavailable. $errorMsg';
          _currentPosition = null;
          _isFetchingLocation = false;
        });
      }
    }
  }

  Future<void> _openLocationInMap() async {
    if (_currentPosition != null) {
      final lat = _currentPosition!.latitude;
      final lng = _currentPosition!.longitude;
      final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
      if (kIsWeb) {
        html.window.open(url, '_blank');
      } else {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _showSnackBar('Could not open map.', Colors.red);
        }
      }
    } else {
      _showSnackBar('Location not available to show on map.', Colors.orange);
    }
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

  void _loadAvailableDoctorsForSelectedDate() {
    final allDoctorsFromBox =
        _doctorsBox.values
            .map((doc) => Map<String, dynamic>.from(doc as Map))
            .toList();

    Iterable<Map<String, dynamic>> doctorsFilteredByRole;
    if (widget.user.role == 'doctor') {
      doctorsFilteredByRole = allDoctorsFromBox.where((doctor) {
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
      _loadAvailableDoctorsForSelectedDate();
    }
  }

  double _getCellHeight(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;

    if (screenWidth < 600) {
      return size.height * 0.13;
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

    final width = MediaQuery.of(context).size.width;
    double cellWidth, iconSize, titleFontSize, subFontSize, padding, spacing;

    if (width < 600) {
      cellWidth = MediaQuery.of(context).size.width * 0.12;
      iconSize = 14;
      titleFontSize = 11;
      subFontSize = 9;
      padding = 8;
      spacing = 2;
    } else if (width < 1024) {
      cellWidth = MediaQuery.of(context).size.width * 0.12;
      iconSize = 16;
      titleFontSize = 13;
      subFontSize = 10;
      padding = 10;
      spacing = 4;
    } else if (width < 1600) {
      cellWidth = MediaQuery.of(context).size.width * 0.12;
      iconSize = 18;
      titleFontSize = 14;
      subFontSize = 11;
      padding = 8;
      spacing = 2;
    } else {
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ============================================================
            // Top Bar (مع أزرار Check-In/Out)
            // ============================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    height: 120,
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
                                  Expanded(
                                    child: Text(
                                      DateFormat(
                                        'EEEE, MMMM d, yyyy',
                                      ).format(selectedDate),
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
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
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: _openLocationInMap,
                                borderRadius: BorderRadius.circular(4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: Colors.grey.shade600,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _currentLocationStatus,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            // ✅ Check-In Button
                            if (_currentUserEmployee != null) ...[
                              if (!_hasCheckedInToday)
                                ElevatedButton.icon(
                                  onPressed:
                                      _isProcessingCheckIn
                                          ? null
                                          : () => _handleCheckIn(
                                            context,
                                            _currentUserEmployee!,
                                          ),
                                  icon:
                                      _isProcessingCheckIn
                                          ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                          : const Icon(
                                            Icons.login_rounded,
                                            size: 18,
                                          ),
                                  label: Text(
                                    _isProcessingCheckIn
                                        ? 'Processing...'
                                        : 'Check In',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    elevation: 5,
                                    shadowColor: Colors.green.withOpacity(0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              // ✅ Check-Out Button
                              if (_hasCheckedInToday && !_hasCheckedOutToday)
                                ElevatedButton.icon(
                                  onPressed:
                                      _isProcessingCheckIn
                                          ? null
                                          : () => _handleCheckOut(
                                            context,
                                            _currentUserEmployee!,
                                          ),
                                  icon:
                                      _isProcessingCheckIn
                                          ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                          : const Icon(
                                            Icons.logout_rounded,
                                            size: 18,
                                          ),
                                  label: Text(
                                    _isProcessingCheckIn
                                        ? 'Processing...'
                                        : 'Check Out',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                    elevation: 5,
                                    shadowColor: Colors.redAccent.withOpacity(
                                      0.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              // ✅ Status Badge
                              if (_hasCheckedInToday)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _hasCheckedOutToday
                                            ? Colors.grey.withOpacity(0.2)
                                            : Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color:
                                          _hasCheckedOutToday
                                              ? Colors.grey.withOpacity(0.3)
                                              : Colors.green.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    _hasCheckedOutToday
                                        ? '✅ Completed'
                                        : '🟢 Checked In',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          _hasCheckedOutToday
                                              ? Colors.grey[600]
                                              : Colors.green[700],
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                            ],
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

            // ============================================================
            // باقي المحتوى (Stats Cards & Schedule Grid)
            // ============================================================
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double width = constraints.maxWidth;
                  int crossAxisCount;
                  double childAspectRatio;

                  if (width < 600) {
                    crossAxisCount = 2;
                    childAspectRatio = 2.0;
                  } else if (width < 1024) {
                    crossAxisCount = 2;
                    childAspectRatio = 2.2;
                  } else if (width < 1600) {
                    crossAxisCount = 4;
                    childAspectRatio = 2;
                  } else {
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
                width: double.infinity,
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
                    const SizedBox(height: 20),
                    Expanded(
                      child: Scrollbar(
                        controller: _horizontalScrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _horizontalScrollController,
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                            color:
                                                Theme.of(context).primaryColor,
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            doctor['name'] as String,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).primaryColor,
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
                                        ..._availableDoctorsForSelectedDate.map(
                                          (doctor) {
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
                                          },
                                        ).toList(),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
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

  // ============================================================
  // باقي دوال ScheduleGridScreen (بدون تغيير)
  // ============================================================

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
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(color: Colors.white, blurRadius: 20, offset: Offset(5, 0)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
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
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
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
                                    'assets/physioone_logo.jpg',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 20),
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
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => UserProfilePage(user: widget.user),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(25),
                        child: Container(
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
                      ),
                    ],
                  ),
                ),
                // Navigation Menu
                Expanded(
                  child: ListView(
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
                        const SizedBox(height: 20),
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
                          icon: Icons.groups_3_rounded,
                          title: 'HR Management',
                          subtitle: 'Employee & Payroll System',
                          gradient: [
                            Colors.pink.shade400,
                            Colors.pink.shade600,
                          ],
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) {
                                    return HRMainScreen(user: widget.user);
                                  },
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const double mobileBreakpoint = 850;
        final bool isMobile = constraints.maxWidth < mobileBreakpoint;

        if (isMobile) {
          return Scaffold(
            appBar: AppBar(
              title: Text(AppConsts.appName),
              backgroundColor: Theme.of(context).primaryColor,
            ),
            drawer: Drawer(child: _buildSidebarContent()),
            body: _buildMainContent(),
          );
        } else {
          return Scaffold(
            backgroundColor: Colors.grey.shade50,
            body: Row(
              children: [
                _buildSidebarContent(),
                Expanded(child: _buildMainContent()),
              ],
            ),
          );
        }
      },
    );
  }

  List<Map<String, dynamic>> _getClientsForDoctor(String doctorId) {
    final clientBox = Hive.box('clients');
    final appointmentBox = Hive.box('appointments');
    final clientIds = <String>{};

    for (var key in appointmentBox.keys) {
      final appointment = appointmentBox.get(key);

      if (appointment is Map && appointment['status'] == 'booked') {
        final appointmentDoctorId = appointment['doctorId']?.toString();
        final appointmentDoctorName = appointment['doctor']?.toString();

        if ((appointmentDoctorId != null && appointmentDoctorId == doctorId) ||
            (appointmentDoctorName != null &&
                appointmentDoctorName == doctorId)) {
          if (appointment['clientId'] != null) {
            clientIds.add(appointment['clientId'].toString());
          }
        }
      }
    }

    final clients =
        clientIds
            .map((id) => clientBox.get(id))
            .where((client) => client != null)
            .map((client) => Map<String, dynamic>.from(client as Map))
            .toList();

    return clients;
  }

  // ============================================================
  // دوال الحوارات (Edit Cell, Add Client, WhatsApp, Cancel)
  // ============================================================

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
                      TextField(
                        controller: doctorController,
                        decoration: InputDecoration(labelText: 'Doctor'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
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
        setState(() {});
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

    final String message = AppConsts.getWhatsAppMessage(
      clientName,
      formattedDate,
      timeSlot,
    );

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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Yes, Cancel'),
              ),
            ],
          ),
    );

    if (confirmRemove != true) return;

    try {
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

      final Map<String, dynamic> cancelledData = Map<String, dynamic>.from(
        existing as Map,
      );
      cancelledData['status'] = 'cancelled';

      box.put(key, cancelledData);
      await _saveAppointmentToFirestore(key, cancelledData);

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext, true);
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
            onTapDown: (_) => setState(() {}),
            onTapUp: (_) => setState(() {}),
            onTap: onTap,
            child: Container(
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
