# Localization & Internationalization Documentation

This document describes the current localization status, string handling patterns, multilingual support (Arabic/English), and recommended l10n roadmap for **PhysioOne**.

---

## 🌐 Current Internationalization Status

- **Supported Languages**: Arabic (`ar`) and English (`en`) mixed in UI widgets.
- **Localization Package Status**: Standard Flutter `flutter_localizations` or `arb` files are **not yet configured** in `pubspec.yaml`.
- **Implementation Pattern**: Inline bilingual strings and helper functions (e.g. `AppConsts.getWhatsAppMessage(...)` in `lib/core/app_consts/app_consts.dart:46`).

---

## 💬 WhatsApp Bilingual Reminder Template

The app generates a formatted bilingual WhatsApp appointment reminder message (`lib/core/app_consts/app_consts.dart:46-75`):

```text
Hello {clientName},

Physio One CLINIC
https://maps.app.goo.gl/UPxFe3tbG6McKAVZA 
عياده Physio One تذكركم بمعادكم يوم {appointmentDate}
الساعة {timeSlot}

برجاء العلم بأن مدة الانتظار من 0 إلى 15 دقيقه
*برجاء العلم ان التاخير عن ميعاد الجلسه يحسب من مده الجلسه* للاعتذار برجاء الاتصال قبل ميعاد الجلسه ب 4 ساعات على الاقل حتى لا يتم احتسابها من الجلسات

في حالة عدم التأكيد قبل الميعاد ب 4 ساعات برجاء الاتصال وتحديد موعد آخر

رقم الفرع

Physio One clinic reminds you about your session on {appointmentDate} at {timeSlot}

Please note that the waiting time ranges from 0 to 15 minutes
Please be informed that any delay will be calculated from the session duration.
For excuse, please call at least 4 hours before that session or it will be canceled from your package.
If you do not confirm 4 hours before your session, please call to reschedule your appointment.

Clinic number 
+20 102 124 6044
See you & Have a nice day
```

---

## 🚀 Recommended Localization Roadmap

To enable clean RTL/LTR switching and standard translation workflows:

1. **Add `flutter_localizations` dependency**:
   ```yaml
   dependencies:
     flutter_localizations:
       sdk: flutter
     intl: ^0.20.2
   ```
2. **Enable synthetic code generation in `pubspec.yaml`**:
   ```yaml
   flutter:
     generate: true
   ```
3. **Create ARB files**:
   - `lib/l10n/app_en.arb`
   - `lib/l10n/app_ar.arb`
