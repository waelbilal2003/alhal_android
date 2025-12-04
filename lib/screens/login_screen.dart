import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'location_selection_screen.dart'; // الانتقال إلى هنا بعد تسجيل الدخول

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  // كلمة المرور الافتراضية
  static const String _defaultPassword = 'w';

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final enteredPassword = _passwordController.text;

    // التحقق من كلمة المرور
    if (enteredPassword == _defaultPassword) {
      // كلمة المرور صحيحة، احفظ الحالة وانتقل
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);

      // الانتقال إلى شاشة اختيار المحل
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (context) => const LocationSelectionScreen()),
        );
      }
    } else {
      // كلمة المرور خاطئة
      setState(() {
        _isLoading = false;
        _errorMessage = 'كلمة المرور غير صحيحة. حاول مرة أخرى.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock,
                    size: 80,
                    color: Colors.teal,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'تسجيل الدخول',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'أدخل كلمة المرور',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.teal, width: 2),
                      ),
                      errorText: _errorMessage,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال كلمة المرور';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.teal)
                      : ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'دخول',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
