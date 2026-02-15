import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/login_screen.dart'; // تأكد من صحة المسار

// دالة بسيطة لتعتيم المفتاح السري قليلاً
// في التطبيقات الحقيقية، تستخدم تقنيات أكثر تعقيداً
String getSecretKey() {
  const part1 = 'your_super_s';
  const part2 = 'ecret_key_123';
  const part3 = '!@#';
  return '$part1$part2$part3';
}

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _ngrokUrlController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String _errorMessage = '';

  // دالة لجلب معرّف الجهاز الفريد
  Future<String?> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      // androidId هو خيار جيد لأنه فريد لكل جهاز + تثبيت تطبيق
      return androidInfo.id;
    }
    // يمكنك إضافة دعم iOS هنا إذا احتجت
    // if (Platform.isIOS) {
    //   final iosInfo = await deviceInfo.iosInfo;
    //   return iosInfo.identifierForVendor;
    // }
    return null;
  }

  Future<void> _activateDevice() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final deviceId = await _getDeviceId();
    if (deviceId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'لم يتمكن من الحصول على معرّف الجهاز.';
      });
      return;
    }

    // تأكد من أن الرابط يحتوي على http/https
    String url = _ngrokUrlController.text.trim();
    if (!url.startsWith('http')) {
      url = 'https://' + url;
    }

    // تأكد من أن الرابط ينتهي بـ /
    if (!url.endsWith('/')) {
      url += '/';
    }

    final fullUrl = Uri.parse('${url}api/register_device.php');

    try {
      final response = await http
          .post(
            fullUrl,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              'customer_name': _customerNameController.text.trim(),
              'device_id': deviceId,
              'app_key': getSecretKey(), // إرسال المفتاح السري
            }),
          )
          .timeout(const Duration(seconds: 20)); // مهلة زمنية للطلب

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (responseData['status'] == 'success') {
          // حفظ حالة التفعيل محلياً
          final prefs = await SharedPreferences.getInstance();
          // نستخدم قيمة مشفرة بسيطة بدلاً من 'true' مباشرة
          await prefs.setString(
              'activation_status', base64.encode(utf8.encode('activated_ok')));

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
        }
      } else {
        setState(() {
          _errorMessage = responseData['message'] ?? 'حدث خطأ غير معروف.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'فشل الاتصال بالخادم. تأكد من الرابط واتصال الإنترنت.\n$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'تفعيل التطبيق',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _ngrokUrlController,
                    decoration: const InputDecoration(
                      labelText: 'ادخل رابط التفعيل (ngrok)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'حقل الرابط مطلوب';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _customerNameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم الزبون',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'حقل اسم الزبون مطلوب';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton(
                      onPressed: _activateDevice,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: const Text('تفعيل'),
                    ),
                  const SizedBox(height: 20),
                  if (_errorMessage.isNotEmpty)
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
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
