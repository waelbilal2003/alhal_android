import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 1. استيراد الملفات الضرورية
import 'core/security/license_validator.dart'; // ملف مسؤول الأمان
import 'screens/login_screen.dart'; // شاشتك الأصلية

void main() async {
  // الكود الأصلي الخاص بك كما هو
  WidgetsFlutterBinding.ensureInitialized();

  // 2. إضافة منطق التحقق من الترخيص هنا قبل تشغيل التطبيق
  // 🔐 التحقق من الترخيص قبل بدء التطبيق
  final validationResult = await LicenseValidator.validateLicense();

  // الكود الأصلي الخاص بك كما هو
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // 3. تمرير نتيجة التحقق إلى التطبيق الرئيسي
  runApp(MyApp(validationResult: validationResult));
}

class MyApp extends StatelessWidget {
  // 4. استقبال نتيجة التحقق في MyApp
  final LicenseValidationResult validationResult;

  const MyApp({super.key, required this.validationResult});

  @override
  Widget build(BuildContext context) {
    // الكود الأصلي الخاص بك (MaterialApp) كما هو بدون أي تغيير في الثيم أو العنوان
    return MaterialApp(
      title: 'Al Hal Market',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      // 5. هنا يتم تطبيق الخوارزمية المطلوبة
      // إذا كان الترخيص صالحاً، اذهب إلى شاشتك LoginScreen
      // إذا كان غير صالح، اذهب إلى شاشة الخطأ
      home: validationResult.isValid
          ? const LoginScreen() // <-- شاشتك الأصلية في حالة النجاح
          : LicenseErrorScreen(validationResult: validationResult), // <-- شاشة الخطأ في حالة الفشل
    );
  }
}

// 6. نسخ شاشة الخطأ كما هي من ملف مسؤول الأمان
// هذا الكود ضروري لعرض رسائل الخطأ بشكل صحيح عند فشل التحقق
class LicenseErrorScreen extends StatelessWidget {
  final LicenseValidationResult validationResult;

  const LicenseErrorScreen({super.key, required this.validationResult});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 24),
                Text(
                  'خطأ في الترخيص',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _getErrorMessage(),
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'هذا التطبيق مرخص لجهاز محدد ولا يمكن نسخه أو مشاركته.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'للحصول على نسخة مرخصة، يرجى التواصل مع المطور عن طريق الواتساب 0935702074',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getErrorMessage() {
    switch (validationResult.errorCode) {
      case LicenseErrorCode.deviceMismatch:
        return '⚠️ هذا التطبيق مرخص لجهاز آخر\n\nلا يمكن تشغيل هذه النسخة على هذا الجهاز';
      case LicenseErrorCode.invalidLicense:
        return '❌ معرف الترخيص غير صالح\n\nيرجى التواصل مع المطور';
      case LicenseErrorCode.deviceError:
        return '🔧 خطأ في التحقق من الجهاز\n\nتأكد من أذونات التطبيق';
      default:
        return '❓ حدث خطأ غير متوقع\n\n${validationResult.errorMessage ?? "خطأ غير معروف"}';
    }
  }
}