import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // شاشة تسجيل الدخول

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      // الشاشة التي ستظهر عند بدء التطبيق
      home: const LoginScreen(),
    );
  }
}
