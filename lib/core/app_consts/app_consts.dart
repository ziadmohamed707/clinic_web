class AppConsts {
  static const String appName = 'Physio Prime';
  static const String appVersion = '1.0.0';
  static const String apiBaseUrl = 'https://api.example.com';
  static const String supportEmail = 'support@example.com';

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
    '09:50 AM',
    '10:40 AM',
    '11:30 AM',
    '12:20 PM',
    '01:10 PM',
    '02:00 PM',
    '02:50 PM',
    '03:40 PM',
    '04:30 PM',
    '05:20 PM',
    '06:10 PM',
    '07:00 PM',
    '07:50 PM',
    '08:40 PM',
    '09:30 PM',
    '10:20 PM',
    '11:10 PM',
    '12:00 AM',
  ];

  static String getWhatsAppMessage(
    String clientName,
    String appointmentDate,
    String timeSlot,
  ) {
    return '''Hello $clientName,

PHYSIO PRIME CLINIC
Cairo Stadium Club - Squash Stadium Complex https://maps.app.goo.gl/WGZ44exa2dX7tiiz9 
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
  }
}