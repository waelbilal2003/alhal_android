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
  String? _savedPassword;
  String? _savedSellerName;

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
    final savedSellerName = prefs.getString('seller_name');

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
      _showSetupScreen = false;
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
              storeName: 'سوق الهال',
              sellerName: _savedSellerName,
            ),
          ),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'كلمة المرور غير صحيحة.';
      });
    }
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

  // --- واجهة تسجيل الدخول ---
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
          SizedBox(
            width: 300,
            child: _buildInputField(
                _passwordController, 'أدخل كلمة المرور', true,
                errorText: _errorMessage),
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
