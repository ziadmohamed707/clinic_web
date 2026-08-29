class AppConsts {
  static const String appName = 'Physio One';
  static const String appVersion = '1.0.0';
  static const String apiBaseUrl = 'https://api.example.com';
  static const String supportEmail = 'support@example.com';

  // Clinic Location for HR System


  static const double clinicLatitude = 30.041237;
  static const double clinicLongitude = 31.243411;
  static const double clinicCheckInRadiusMeters = 200.0; // 200 meters radius

  static const List<String> kServiceTypes = [
    'Examination',
    'Consultation',
    'Recovery (Full Body)',
    'Recovery (Upper)',
    'Recovery (Lower)',
    'Cupping',
    'Follow-up Session',
  ];

  static const List<String> timeSlots = [
    '09:00 AM',
    '09:45 AM',
    '10:30 AM',
    '11:15 AM',
    '12:00 PM',
    '12:45 PM',
    '01:30 PM',
    '02:15 PM',
    '03:00 PM',
    '03:45 PM',
    '04:30 PM',
    '05:15 PM',
    '06:00 PM',
    '06:45 PM',
    '07:30 PM',
    '08:15 PM',
    '09:00 PM',
    '09:45 PM',
    '10:30 PM',
    '11:15 PM',
    '12:00 AM',
  ];

  static String getWhatsAppMessage(
    String clientName,
    String appointmentDate,
    String timeSlot,
  ) {
    return '''Hello $clientName,

Physio One CLINIC
https://maps.app.goo.gl/UPxFe3tbG6McKAVZA 
عياده Physio One تذكركم بمعادكم يوم $appointmentDate
الساعة $timeSlot

برجاء العلم بأن مدة الانتظار من 0 إلى 15 دقيقه
‎*برجاء العلم ان التاخير عن ميعاد الجلسه يحسب من مده الجلسه* للاعتذار برجاء الاتصال قبل ميعاد الجلسه ب 4 ساعات على الاقل حتى لا يتم احتسابها من الجلسات

في حالة عدم التأكيد قبل الميعاد ب 4 ساعات برجاء الاتصال وتحديد موعد آخر

رقم الفرع

Physio One clinic reminds you about your session on $appointmentDate at $timeSlot

Please note that the waiting time ranges from 0 to 15 minutes
Please be informed that any delay will be calculated from the session duration.
For excuse, please call at least 4 hours before that session or it will be canceled from your package.
If you do not confirm 4 hours before your session, please call to reschedule your appointment.

Clinic number 
+20 102 124 6044
See you & Have a nice day''';
  }
}
