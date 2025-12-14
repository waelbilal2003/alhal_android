import 'dart:convert';
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

  bool _showSetupScreen = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAppStatus();
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

  Future<void> _checkAppStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPassword = prefs.getString('app_password');

    if (savedPassword != null) {
      setState(() {
        _showSetupScreen = false;
      });
    }
  }

  Future<void> _saveAccount(String sellerName, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = prefs.getString('accounts');
    final Map<String, String> accountsMap =
        accounts != null ? Map<String, String>.from(json.decode(accounts)) : {};

    accountsMap[sellerName] = password;
    await prefs.setString('accounts', json.encode(accountsMap));
  }

  Future<Map<String, String>> _getAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = prefs.getString('accounts');
    return accounts != null
        ? Map<String, String>.from(json.decode(accounts))
        : {};
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final enteredSellerName = _sellerNameController.text;
    final enteredPassword = _passwordController.text;

    final accounts = await _getAccounts();

    if (accounts.containsKey(enteredSellerName) &&
        accounts[enteredSellerName] == enteredPassword) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('current_seller', enteredSellerName);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DateSelectionScreen(
              storeType: 'متجر رئيسي',
              storeName: 'سوق الهال',
              sellerName: enteredSellerName,
            ),
          ),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'اسم البائع أو كلمة المرور غير صحيحة.';
      });
    }
  }

  Future<void> _savePasswordAndSeller() async {
    if (!_setupFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final newPassword = _newPasswordController.text;
    final sellerName = _sellerNameController.text;

    await _saveAccount(sellerName, newPassword);

    setState(() {
      _isLoading = false;
      _showSetupScreen = false;
    });

    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _sellerNameController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal[400]!, Colors.teal[700]!],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: _showSetupScreen ? _buildSetupScreen() : _buildLoginScreen(),
          ),
        ),
      ),
    );
  }

  // --- واجهة الإعداد ---
  Widget _buildSetupScreen() {
    return Form(
      key: _setupFormKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.vpn_key, size: 60, color: Colors.white),
          const SizedBox(height: 20),
          const Text('إعداد التطبيق',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 30),
          // استخدام Row لوضع الحقول بجانب بعضها
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                  child: _buildInputField(
                      _sellerNameController, 'اسم البائع', false)),
              const SizedBox(width: 20),
              Expanded(
                  child: _buildInputField(
                      _newPasswordController, 'كلمة المرور الجديدة', true)),
              const SizedBox(width: 20),
              Expanded(
                  child: _buildInputField(
                      _confirmPasswordController, 'تأكيد كلمة المرور', true)),
            ],
          ),
          const SizedBox(height: 30),
          _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : ElevatedButton(
                  onPressed: _savePasswordAndSeller,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.teal[700],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 60, vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('حفظ',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
        ],
      ),
    );
  }

  // --- تعديل واجهة تسجيل الدخول ---
  Widget _buildLoginScreen() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock, size: 60, color: Colors.white),
          const SizedBox(height: 20),
          const Text('تسجيل الدخول',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 40),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: _buildInputField(
                      _sellerNameController, 'أدخل اسم البائع', false),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: _buildInputField(
                      _passwordController, 'أدخل كلمة المرور', true,
                      errorText: _errorMessage),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.teal[700],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 60, vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('دخول',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
        ],
      ),
    );
  }

  // --- دالة بناء حقل الإدخال لإعادة الاستخدام ---
  Widget _buildInputField(
      TextEditingController controller, String hint, bool obscure,
      {String? errorText}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white, width: 2)),
        errorText: errorText,
        errorStyle: const TextStyle(color: Colors.yellowAccent),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'الرجاء إدخال $hint';
        if (hint.contains('كلمة المرور') && value.length < 4)
          return 'كلمة المرور قصيرة جداً';
        if (hint.contains('تأكيد') && value != _newPasswordController.text)
          return 'كلمتا المرور غير متطابقتين';
        return null;
      },
      onFieldSubmitted: (_) =>
          _showSetupScreen ? _savePasswordAndSeller() : _login(),
    );
  }
}
