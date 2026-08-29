// bin/seed_firestore.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:physioone/firebase_options.dart' show DefaultFirebaseOptions; // غير اسم المشروع لو مختلف

Future<void> main() async {
  // تأكد من تهيئة Flutter (مهم عشان Firebase)
  // هنستخدم WidgetsFlutterBinding
  // لكن في السكربت المستقل، هنضطر نستدعيها يدويًا
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  print('🚀 بدأ التهيئة...');

  try {
    // ---- 1. إنشاء العيادة ----
    await firestore.collection('clinics').doc('clinic_001').set({
      'clinicId': 'clinic_001',
      'name': 'عيادة الأسنان المثالية',
      'nameEn': 'Ideal Dental Clinic',
      'address': 'شارع النيل، القاهرة',
      'location': {'latitude': 30.0444, 'longitude': 31.2357},
      'phone': '+201012345678',
      'countryCode': '+20',
      'subscriptionStatus': 'active',
      'subscriptionEndsAt': '2027-12-31T23:59:59Z',
      'createdAt': FieldValue.serverTimestamp(),
      'settings': {
        'workingHoursStart': '09:00',
        'workingHoursEnd': '21:00',
        'slotDurationMinutes': 50,
        'timeSlots': [
          '09:00','09:50','10:40','11:30','12:20','13:10',
          '14:00','14:50','15:40','16:30','17:20','18:10','19:00','19:50','20:40'
        ],
        'geofenceRadiusMeters': 200,
        'defaultServiceType': 'dental',
      },
      'whatsappMessageTemplate':
          'Hello {patientName},\n\n{clinicName} reminds you of your appointment on {date} at {time}.\nAddress: {address}',
    });
    print('✅ تم إنشاء العيادة');

    // ---- 2. الخدمات (3 تخصصات) ----
    final services = [
      {
        'serviceId': 'svc_001',
        'clinicId': 'clinic_001',
        'name': 'حشو عصب (علاج جذور)',
        'nameEn': 'Root Canal',
        'category': 'dental',
        'type': 'procedure',
        'defaultDurationMinutes': 60,
        'defaultPrice': 1200,
        'isActive': true,
        'packageMappings': [
          {'packageCategory': 'Package Dental', 'sessionsCount': 3, 'price': 3000}
        ],
      },
      {
        'serviceId': 'svc_002',
        'clinicId': 'clinic_001',
        'name': 'جلسة علاج طبيعي',
        'nameEn': 'Physiotherapy',
        'category': 'physiotherapy',
        'type': 'session',
        'defaultDurationMinutes': 30,
        'defaultPrice': 400,
        'isActive': true,
        'packageMappings': [
          {'packageCategory': 'Package Physio', 'sessionsCount': 10, 'price': 3500}
        ],
      },
      {
        'serviceId': 'svc_003',
        'clinicId': 'clinic_001',
        'name': 'كشف جلدية',
        'nameEn': 'Dermatology',
        'category': 'dermatology',
        'type': 'consultation',
        'defaultDurationMinutes': 20,
        'defaultPrice': 500,
        'isActive': true,
        'packageMappings': [],
      },
    ];
    for (var svc in services) {
      await firestore.collection('services').doc(svc['serviceId'] as String?).set(svc);
    }
    print('✅ تم إنشاء الخدمات');

    // ---- 3. عداد الأرقام المتسلسلة ----
    await firestore
        .collection('clinics')
        .doc('clinic_001')
        .collection('metadata')
        .doc('counters')
        .set({
      'lastClientId': 0,
      'lastEmployeeId': 0,
      'lastAppointmentId': 0,
    });
    print('✅ تم إنشاء العداد');

    // ---- 4. مستخدم مدير ----
    await firestore.collection('users').doc('user_001').set({
      'userId': 'user_001',
      'email': 'admin@clinic001.com',
      'name': 'أحمد محمد',
      'clinicId': 'clinic_001',
      'role': 'clinic_admin',
      'phone': '+201012345679',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('✅ تم إنشاء المستخدم');

    // ---- 5. عميل تجريبي ----
    await firestore.collection('clients').add({
      'clientId': 1,
      'clinicId': 'clinic_001',
      'name': 'محمد علي',
      'age': 35,
      'phone': '+201011112222',
      'details': 'حساسية بنسلين',
      'bookedPackages': [
        {
          'name': 'حزمة علاج جذور (3 جلسات)',
          'totalSessions': 3,
          'remainingSessions': 3,
          'category': 'Package Dental',
          'serviceId': 'svc_001',
          'purchaseDate': '2026-01-15',
        }
      ],
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('✅ تم إنشاء عميل تجريبي');

    // ---- 6. موعد تجريبي ----
    await firestore.collection('appointments').add({
      'appointmentId': '2026-08-28-09:00-dr_ahmed',
      'clinicId': 'clinic_001',
      'patientName': 'محمد علي',
      'patientPhone': '+201011112222',
      'clientId': 1,
      'doctorName': 'د. أحمد',
      'doctorId': 'user_001',
      'serviceId': 'svc_001',
      'date': '2026-08-28',
      'timeSlot': '09:00',
      'status': 'booked',
      'packageUsed': 'حزمة علاج جذور (3 جلسات)',
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('✅ تم إنشاء موعد تجريبي');

    print('🎉 التهيئة انتهت بنجاح! روح شوف البيانات في Firebase Console.');
  } catch (e) {
    print('❌ حدث خطأ: $e');
  }


  // ------------------------------------------
// 7. إنشاء الأطباء (الموظفين) في العيادة
// ------------------------------------------
print('🩺 جاري إنشاء الأطباء...');

// أطباء مع بيانات دخول (Users) وبيانات وظيفية (Employees)
final doctorsData = [
  {
    'userId': 'doc_001',
    'email': 'dr.ahmed@clinic001.com',
    'name': 'د. أحمد محمد',
    'phone': '+201011112223',
    'role': 'doctor',
    'specialization': 'علاج الجذور و التركيبات',
    'availableDays': ['Monday', 'Tuesday', 'Wednesday', 'Thursday'],
    'baseSalary': 12000,
  },
  {
    'userId': 'doc_002',
    'email': 'dr.sara@clinic001.com',
    'name': 'د. سارة علي',
    'phone': '+201011112224',
    'role': 'doctor',
    'specialization': 'تقويم الأسنان و التجميل',
    'availableDays': ['Saturday', 'Sunday', 'Monday', 'Wednesday'],
    'baseSalary': 15000,
  },
  {
    'userId': 'doc_003',
    'email': 'dr.khaled@clinic001.com',
    'name': 'د. خالد حسن',
    'phone': '+201011112225',
    'role': 'doctor',
    'specialization': 'علاج طبيعي و إصابات الملاعب',
    'availableDays': ['Sunday', 'Tuesday', 'Thursday'],
    'baseSalary': 10000,
  },
];

for (var doc in doctorsData) {
  // 7.1 إنشاء حساب مستخدم للطبيب (عشان يسجل دخول)
  await firestore.collection('users').doc(doc['userId'] as String?).set({
    'userId': doc['userId'],
    'email': doc['email'],
    'name': doc['name'],
    'clinicId': 'clinic_001',
    'role': 'doctor', // دور الطبيب
    'phone': doc['phone'],
    'isActive': true,
    'createdAt': FieldValue.serverTimestamp(),
  });

  // 7.2 إنشاء بطاقة الموظف (Employee) فيها التفاصيل الطبية
  await firestore.collection('employees').doc(doc['userId'] as String?).set({
    'employeeId': doc['userId'],
    'userId': doc['userId'],
    'clinicId': 'clinic_001',
    'name': doc['name'],
    'position': 'طبيب',
    'department': doc['specialization'],
    'baseSalary': doc['baseSalary'],
    'allowances': 1000,
    'deductions': 200,
    'joinDate': '2026-01-01',
    'availableDays': doc['availableDays'], // ده اللي هيتقرأ في جدول المواعيد
    'isDoctor': true, // علم عشان نفرق بين الدكتور والموظف العادي
    'createdAt': FieldValue.serverTimestamp(),
  });
}
print('✅ تم إنشاء ٣ أطباء مع حسابات دخول خاصة بهم');

// ------------------------------------------
// 8. إنشاء قاعدة كبيرة من المرضى (العملاء)
// ------------------------------------------
print('🧑‍🤝‍🧑 جاري إنشاء قاعدة المرضى...');

final List<Map<String, dynamic>> clientsList = [
  {
    'name': 'يوسف إبراهيم',
    'age': 28,
    'phone': '+201011112226',
    'details': 'يعاني من ألم في الضرس الخلفي',
    'packages': [
      {
        'name': 'حزمة علاج جذور (3 جلسات)',
        'totalSessions': 3,
        'remainingSessions': 2,
        'category': 'Package Dental',
        'serviceId': 'svc_001',
        'purchaseDate': '2026-08-01'
      }
    ]
  },
  {
    'name': 'فاطمة محمود',
    'age': 45,
    'phone': '+201011112227',
    'details': 'ترغب في تركيب تقويم شفاف',
    'packages': [
      {
        'name': 'حزمة تقويم (6 جلسات)',
        'totalSessions': 6,
        'remainingSessions': 6,
        'category': 'Package Dental',
        'serviceId': 'svc_002',
        'purchaseDate': '2026-08-10'
      }
    ]
  },
  {
    'name': 'أحمد سامي',
    'age': 55,
    'phone': '+201011112228',
    'details': 'آلام مزمنة في الركبة بعد عملية',
    'packages': [
      {
        'name': 'حزمة علاج طبيعي (10 جلسات)',
        'totalSessions': 10,
        'remainingSessions': 8,
        'category': 'Package Physio',
        'serviceId': 'svc_003',
        'purchaseDate': '2026-07-20'
      }
    ]
  },
  {
    'name': 'نورا طارق',
    'age': 30,
    'phone': '+201011112229',
    'details': 'كشف جلدية عام وحساسية موسمية',
    'packages': []
  },
  {
    'name': 'كريم مصطفى',
    'age': 40,
    'phone': '+201011112230',
    'details': 'خلع ضرس عقل وتركيب زراعة',
    'packages': [
      {
        'name': 'حزمة جراحة الفم (جلستان)',
        'totalSessions': 2,
        'remainingSessions': 1,
        'category': 'Package Dental',
        'serviceId': 'svc_001',
        'purchaseDate': '2026-08-15'
      }
    ]
  }
];

// نجيب آخر ID مستخدم من العداد عشان نبدأ منه
final countersDoc = await firestore
    .collection('clinics')
    .doc('clinic_001')
    .collection('metadata')
    .doc('counters')
    .get();
int currentClientId = (countersDoc.data()?['lastClientId'] as int? ?? 0);

for (var clientData in clientsList) {
  currentClientId++;
  
  await firestore.collection('clients').add({
    'clientId': currentClientId,
    'clinicId': 'clinic_001',
    'name': clientData['name'],
    'age': clientData['age'],
    'phone': clientData['phone'],
    'details': clientData['details'],
    'bookedPackages': clientData['packages'],
    'createdAt': FieldValue.serverTimestamp(),
  });
}

// نحدث العداد في الميتاداتا عشان الجديد يبدأ من الرقم الصحيح
await firestore
    .collection('clinics')
    .doc('clinic_001')
    .collection('metadata')
    .doc('counters')
    .update({'lastClientId': currentClientId});

print('✅ تم إنشاء ${clientsList.length} مريض جديد (إجمالي العملاء الآن: $currentClientId)');

// ------------------------------------------
// 9. إنشاء مواعيد حقيقية مرتبطة بالأطباء والمرضى
// ------------------------------------------
print('📅 جاري إنشاء مواعيد تجريبية للأطباء...');

// هناخد أول مريضين والأطباء الثلاثة عشان نوزع عليهم مواعيد
final allClientsSnapshot = await firestore
    .collection('clients')
    .where('clinicId', isEqualTo: 'clinic_001')
    .orderBy('clientId')
    .limit(4) // ناخد أول 4 مرضى
    .get();

final clientsIds = allClientsSnapshot.docs.map((doc) => doc.data()).toList();

// المواعيد المقترحة (تاريخ اليوم + 3 أيام قادمة)
final now = DateTime.now();
final List<Map<String, dynamic>> sampleAppointments = [
  {
    'date': now,
    'time': '10:00',
    'doctorId': 'doc_001', // د. أحمد
    'status': 'booked'
  },
  {
    'date': now.add(Duration(days: 1)),
    'time': '11:30',
    'doctorId': 'doc_002', // د. سارة
    'status': 'booked'
  },
  {
    'date': now.add(Duration(days: 2)),
    'time': '14:00',
    'doctorId': 'doc_003', // د. خالد
    'status': 'booked'
  },
  {
    'date': now.add(Duration(days: 3)),
    'time': '09:00',
    'doctorId': 'doc_001',
    'status': 'booked'
  },
];

// نربط كل موعد بمريض مختلف من اللي جبناها
int clientIndex = 0;
for (var apptData in sampleAppointments) {
  if (clientIndex >= clientsIds.length) break;
  
  final patient = clientsIds[clientIndex];
  final doctor = doctorsData.firstWhere((d) => d['userId'] == apptData['doctorId']);
  
  final formattedDate = DateFormat('yyyy-MM-dd').format(apptData['date']);
  final apptKey = '$formattedDate-${apptData['time']}-${doctor['userId']}';

  await firestore.collection('appointments').doc(apptKey).set({
    'appointmentId': apptKey,
    'clinicId': 'clinic_001',
    'patientName': patient['name'],
    'patientPhone': patient['phone'],
    'clientId': patient['clientId'],
    'doctorName': doctor['name'],
    'doctorId': doctor['userId'],
    'serviceId': 'svc_001', // خدمة افتراضية
    'date': formattedDate,
    'timeSlot': apptData['time'],
    'status': apptData['status'],
    'packageUsed': (patient['bookedPackages'] as List).isNotEmpty 
        ? (patient['bookedPackages'] as List).first['name'] 
        : null,
    'createdAt': FieldValue.serverTimestamp(),
  });
  
  clientIndex++;
}
print('✅ تم إنشاء ${sampleAppointments.length} موعد مرتبط بأطباء ومرضاء حقيقيين');

print('🎉🎉 اكتمل كل شيء! الآن عندك:');
print('   - عيادة واحدة (clinic_001)');
print('   - 1 مدير عيادة');
print('   - 3 أطباء (لكل منهم حساب دخول وإجازات)');
print('   - ${clientsList.length} مريض (مع باقات متنوعة)');
print('   - مواعيد فعلية مرتبطة بين الأطباء والمرضى');
}