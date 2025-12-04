import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'date_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final _passwordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _sellerNameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _setupFormKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  // --- تم حذف المتغيرات غير الضرورية ---
  // bool _isFirstTime = true;  <-- غير مفيد
  // String? _savedSellerName;  <-- يمكننا قراءته مباشرة

  bool _showSetupScreen = true; // الافتراضي هو الإعداد
  String? _savedPassword;
  String? _savedSellerName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAppStatus(); // دالة ذات اسم أوضح
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _passwordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _sellerNameController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _logout();
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
  }

  // دالة ذات اسم أوضح للتحقق من حالة التطبيق
  Future<void> _checkAppStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPassword = prefs.getString('app_password');
    final savedSellerName = prefs.getString('seller_name');

    // إذا كانت هناك كلمة مرور محفوظة، فهذا يعني أن الإعداد تم بالفعل
    if (savedPassword != null) {
      setState(() {
        _showSetupScreen = false;
        _savedPassword = savedPassword;
        _savedSellerName = savedSellerName;
      });
    }
  }

  Future<void> _savePasswordAndSeller() async {
    if (!_setupFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final newPassword = _newPasswordController.text;
    final sellerName = _sellerNameController.text;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_password', newPassword);
    await prefs.setString('seller_name', sellerName);

    setState(() {
      _isLoading = false;
      _showSetupScreen = false; // الانتقال مباشرة لشاشة الدخول
      _savedPassword = newPassword;
      _savedSellerName = sellerName;
    });

    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _sellerNameController.clear();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final enteredPassword = _passwordController.text;
    if (enteredPassword == _savedPassword) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DateSelectionScreen(
              storeType: 'متجر رئيسي',
              storeName: 'اسم المتجر',
              sellerName: _savedSellerName,
            ),
          ),
        );
      }
    } else {
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
            child: _showSetupScreen ? _buildSetupScreen() : _buildLoginScreen(),
          ),
        ),
      ),
    );
  }

  // ... باقي الدوال _buildSetupScreen و _buildLoginScreen لم تتغير ...
  Widget _buildSetupScreen() {
    return Form(
      key: _setupFormKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.vpn_key, size: 80, color: Colors.teal),
          const SizedBox(height: 24),
          const Text('إعداد التطبيق',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('يرجى إعداد كلمة المرور واسم البائع',
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          TextFormField(
            controller: _sellerNameController,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: 'أدخل اسم البائع',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.teal, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty)
                return 'الرجاء إدخال اسم البائع';
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _newPasswordController,
            obscureText: true,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: 'أدخل كلمة المرور الجديدة',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.teal, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'الرجاء إدخال كلمة المرور';
              if (value.length < 4)
                return 'كلمة المرور يجب أن تكون 4 أحرف على الأقل';
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: 'أكد كلمة المرور',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.teal, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'الرجاء تأكيد كلمة المرور';
              if (value != _newPasswordController.text)
                return 'كلمتا المرور غير متطابقتين';
              return null;
            },
            onFieldSubmitted: (_) => _savePasswordAndSeller(),
          ),
          const SizedBox(height: 24),
          _isLoading
              ? const CircularProgressIndicator(color: Colors.teal)
              : ElevatedButton(
                  onPressed: _savePasswordAndSeller,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('حفظ',
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
        ],
      ),
    );
  }

  Widget _buildLoginScreen() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock, size: 80, color: Colors.teal),
          const SizedBox(height: 24),
          const Text('تسجيل الدخول',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'أدخل كلمة المرور',
              border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))),
              focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.teal, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(12))),
              errorText: _errorMessage,
            ),
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'الرجاء إدخال كلمة المرور';
              return null;
            },
            onFieldSubmitted: (_) => _login(),
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
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('دخول',
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
        ],
      ),
    );
  }
}
