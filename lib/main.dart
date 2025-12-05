import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- 1. أضف الاستيراد
import 'screens/login_screen.dart'; // تأكد من أن المسار صحيح

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. قفل اتجاه التطبيق بأكمله هنا قبل تشغيل التطبيق
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      home: const LoginScreen(),
    );
  }
}
