import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AppointmentEditor {
  final Box appointmentBox;
  final Box clientBox;
  final Function(String key, Map appointmentData) saveToFirestore;
  final VoidCallback? onAppointmentChanged;

  AppointmentEditor({
    required this.appointmentBox,
    required this.clientBox,
    required this.saveToFirestore,
    this.onAppointmentChanged,
  });

  /// Main method to edit a cell appointment
  Future<void> editCell({
    required BuildContext context,
    required String timeSlot,
    required String columnDoctorName,
    required DateTime selectedDate,
  }) async {
    final appointmentDialog = _AppointmentDialog(
      appointmentBox: appointmentBox,
      clientBox: clientBox,
      saveToFirestore: saveToFirestore,
      timeSlot: timeSlot,
      columnDoctorName: columnDoctorName,
      selectedDate: selectedDate,
    );

    final bool? appointmentSaved = await appointmentDialog.show(context);

    if (appointmentSaved == true && onAppointmentChanged != null) {
      onAppointmentChanged!();
    }
  }
}

class _AppointmentDialog {
  final Box appointmentBox;
  final Box clientBox;
  final Function(String key, Map appointmentData) saveToFirestore;
  final String timeSlot;
  final String columnDoctorName;
  final DateTime selectedDate;

  late final String _key;
  late final Map _existingAppointment;
  late final List<Map> _allClients;

  _AppointmentDialog({
    required this.appointmentBox,
    required this.clientBox,
    required this.saveToFirestore,
    required this.timeSlot,
    required this.columnDoctorName,
    required this.selectedDate,
  }) {
    _initializeData();
  }

  void _initializeData() {
    final String formattedDateForKey = DateFormat('yyyy-MM-dd').format(selectedDate);
    _key = '$formattedDateForKey-$timeSlot-$columnDoctorName';

    _existingAppointment = appointmentBox.get(
      _key,
      defaultValue: {
        'patient': '',
        'doctor': columnDoctorName,
        'phone': '',
        'clientId': null,
        'status': null,
      },
    );

    _allClients = clientBox.keys
        .where((key) => key != 'lastId')
        .map((key) => clientBox.get(key) as Map)
        .toList();
  }

  Future<bool?> show(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _AppointmentDialogWidget(
        existingAppointment: _existingAppointment,
        allClients: _allClients,
        timeSlot: timeSlot,
        columnDoctorName: columnDoctorName,
        selectedDate: selectedDate,
        appointmentKey: _key,
        onSave: _saveAppointment,
        onCancel: _cancelAppointment,
        onSendWhatsApp: _sendWhatsAppMessage,
      ),
    );
  }

  Future<void> _saveAppointment(BuildContext context, Map? selectedClient, String doctor) async {
    if (selectedClient == null) {
      _showSnackBar(context, 'Please select a client to save.', Colors.orange);
      return;
    }

    try {
      final appointmentData = {
        'patient': selectedClient['name'],
        'phone': selectedClient['phone'],
        'doctor': doctor,
        'clientId': selectedClient['id'],
        'status': 'booked',
      };

      appointmentBox.put(_key, appointmentData);
      await saveToFirestore(_key, appointmentData);
      
      if (context.mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackBar(context, 'Error saving appointment: $e', Colors.red);
    }
  }

  Future<void> _cancelAppointment(BuildContext context) async {
    final bool? confirmRemove = await _showCancelConfirmationDialog(context);

    if (confirmRemove == true) {
      try {
        final cancelledAppointment = {
          'patient': _existingAppointment['patient'] ?? '',
          'phone': _existingAppointment['phone'] ?? '',
          'clientId': _existingAppointment['clientId'],
          'doctor': columnDoctorName,
          'status': 'cancelled',
        };

        appointmentBox.put(_key, cancelledAppointment);
        await saveToFirestore(_key, cancelledAppointment);

        if (context.mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        _showSnackBar(context, 'Error canceling appointment: $e', Colors.red);
      }
    }
  }

  Future<bool?> _showCancelConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (confirmDialogContext) => AlertDialog(
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
  }

  Future<void> _sendWhatsAppMessage(BuildContext context, Map selectedClient) async {
    try {
      final String appointmentDate = DateFormat('dd-MM-yyyy').format(selectedDate);
      final String message = _buildWhatsAppMessage(selectedClient['name'], appointmentDate);

      String phone = selectedClient['phone'].toString();
      if (!phone.startsWith('+')) {
        phone = '+2$phone'; // Egypt country code
      }

      final Uri whatsappUri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');

      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      _showSnackBar(context, 'Error opening WhatsApp: $e', Colors.red);
    }
  }

  String _buildWhatsAppMessage(String clientName, String appointmentDate) {
    return '''Hello $clientName,

PHYSIO PRIME CLINIC
"Cairo Stadium Club"
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

See you & Have a nice day''';
  }

  void _showSnackBar(BuildContext context, String message, Color backgroundColor) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
        ),
      );
    }
  }
}

class _AppointmentDialogWidget extends StatefulWidget {
  final Map existingAppointment;
  final List<Map> allClients;
  final String timeSlot;
  final String columnDoctorName;
  final DateTime selectedDate;
  final String appointmentKey;
  final Future<void> Function(BuildContext, Map?, String) onSave;
  final Future<void> Function(BuildContext) onCancel;
  final Future<void> Function(BuildContext, Map) onSendWhatsApp;

  const _AppointmentDialogWidget({
    required this.existingAppointment,
    required this.allClients,
    required this.timeSlot,
    required this.columnDoctorName,
    required this.selectedDate,
    required this.appointmentKey,
    required this.onSave,
    required this.onCancel,
    required this.onSendWhatsApp,
  });

  @override
  State<_AppointmentDialogWidget> createState() => _AppointmentDialogWidgetState();
}

class _AppointmentDialogWidgetState extends State<_AppointmentDialogWidget> {
  late final TextEditingController _doctorController;
  late final TextEditingController _searchController;
  late List<Map> _filteredClients;
  Map? _selectedClient;

  @override
  void initState() {
    super.initState();
    _doctorController = TextEditingController(text: widget.existingAppointment['doctor']);
    _searchController = TextEditingController();
    _filteredClients = List.from(widget.allClients);
    
    _initializeSelectedClient();
  }

  void _initializeSelectedClient() {
    if (widget.existingAppointment['patient'] != null &&
        (widget.existingAppointment['patient'] as String).isNotEmpty) {
      _selectedClient = {
        'name': widget.existingAppointment['patient'],
        'phone': widget.existingAppointment['phone'] ?? '',
        'id': widget.existingAppointment['clientId'],
      };
    }
  }

  @override
  void dispose() {
    _doctorController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterClients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredClients = List.from(widget.allClients);
      } else {
        _filteredClients = widget.allClients.where((client) {
          final name = client['name']?.toString().toLowerCase() ?? '';
          final id = client['id']?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase()) ||
              id.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Edit Appointment on ${DateFormat('MMM d').format(widget.selectedDate)} at ${widget.timeSlot}',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      content: PopScope(
        canPop: true,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSearchField(),
              const SizedBox(height: 10),
              _buildClientList(),
              const SizedBox(height: 15),
              _buildDoctorField(),
            ],
          ),
        ),
      ),
      actions: _buildActions(context),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Search Client by Name or ID',
        suffixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      autofocus: true,
      onChanged: _filterClients,
    );
  }

  Widget _buildClientList() {
    return Container(
      height: 200,
      width: double.maxFinite,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: _filteredClients.isEmpty
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
              itemCount: _filteredClients.length,
              itemBuilder: (context, index) {
                final client = _filteredClients[index];
                final isSelected = _selectedClient != null &&
                    _selectedClient!['id'] == client['id'];

                return ListTile(
                  title: Text(
                    '${client['name']}',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text('ID: ${client['id']}'),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                  onTap: () {
                    setState(() {
                      _selectedClient = client;
                    });
                  },
                  tileColor: isSelected
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : null,
                );
              },
            ),
    );
  }

  Widget _buildDoctorField() {
    return TextField(
      controller: _doctorController,
      decoration: InputDecoration(
        labelText: 'Assigned Doctor',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    return [
      // Cancel Button
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        style: TextButton.styleFrom(
          foregroundColor: Colors.grey[700],
        ),
        child: const Text('Cancel'),
      ),

      // Cancel Appointment Button (if booked)
      if (widget.existingAppointment['status'] == 'booked')
        TextButton.icon(
          icon: const Icon(Icons.event_busy, color: Colors.orange),
          label: const Text(
            'Cancel Appt.',
            style: TextStyle(color: Colors.orange),
          ),
          onPressed: () => widget.onCancel(context),
        ),

      // Save Button
      ElevatedButton(
        onPressed: () => widget.onSave(context, _selectedClient, _doctorController.text),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        child: const Text('Save'),
      ),

      // WhatsApp Button (if client selected)
      if (_selectedClient != null)
        TextButton.icon(
          icon: const Icon(Icons.chat, color: Colors.green),
          label: const Text(
            'WhatsApp',
            style: TextStyle(color: Colors.green),
          ),
          onPressed: () => widget.onSendWhatsApp(context, _selectedClient!),
        ),
    ];
  }
}