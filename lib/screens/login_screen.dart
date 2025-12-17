import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'date_selection_screen.dart';
import '../services/store_db_service.dart'; // استيراد خدمة shared_preferences المعدلة

enum LoginFlowState { setup, storeName, login }

class LoginScreen extends StatefulWidget {
  final LoginFlowState initialState;

  const LoginScreen({super.key, this.initialState = LoginFlowState.login});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final _storeNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _sellerNameController = TextEditingController();
  String _storeName = 'سوق الهال';

  // إضافة FocusNodes
  final _sellerNameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _newPasswordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  final _storeNameFieldFocus = FocusNode();

  final _formKey = GlobalKey<FormState>();
  final _setupFormKey = GlobalKey<FormState>();
  final _storeNameFormKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  LoginFlowState _currentFlowState = LoginFlowState.setup;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // الانتقال المباشر للإعداد إذا كانت الحالة setup
    if (widget.initialState == LoginFlowState.setup) {
      _currentFlowState = LoginFlowState.setup;
    } else {
      // التحقق من الحالة
      _checkInitialState();
    }
  }

// دالة جديدة للتحقق من الحالة الأولية
  Future<void> _checkInitialState() async {
    final storeDbService = StoreDbService();
    await storeDbService.initializeDatabase();

    final savedStoreName = await storeDbService.getStoreName();
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = prefs.getString('accounts');

    // إذا كان اسم المحل موجوداً، انتقل مباشرة لتسجيل الدخول
    if (savedStoreName != null && savedStoreName.isNotEmpty) {
      setState(() {
        _currentFlowState = LoginFlowState.login;
        _storeName = savedStoreName;
      });
    } else if (accountsJson != null) {
      // حسابات موجودة ولكن اسم المحل غير موجود
      setState(() {
        _currentFlowState = LoginFlowState.storeName;
      });
    } else {
      // لا توجد حسابات
      setState(() {
        _currentFlowState = LoginFlowState.setup;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _passwordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _sellerNameController.dispose();
    _storeNameController.dispose();

    // التخلص من FocusNodes
    _sellerNameFocus.dispose();
    _passwordFocus.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _storeNameFieldFocus.dispose();
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
              storeName: _storeName, // استخدام اسم المحل المحفوظ
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

    // التحقق من وجود اسم المحل قبل الانتقال
    final storeDbService = StoreDbService();
    final savedStoreName = await storeDbService.getStoreName();

    setState(() {
      _isLoading = false;

      if (savedStoreName != null && savedStoreName.isNotEmpty) {
        // اسم المحل موجود بالفعل، انتقل مباشرة لتسجيل الدخول
        _currentFlowState = LoginFlowState.login;
        _storeName = savedStoreName;
      } else {
        // اسم المحل غير موجود، انتقل إلى شاشة تحديد اسم المحل
        _currentFlowState = LoginFlowState.storeName;
      }
    });

    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _sellerNameController.clear();
  }

  @override
  Widget build(BuildContext context) {
    Widget currentScreen;
    switch (_currentFlowState) {
      case LoginFlowState.setup:
        currentScreen = _buildSetupScreen();
        break;
      case LoginFlowState.storeName:
        // التحقق مرة أخرى قبل عرض شاشة اسم المحل
        _verifyStoreNameNeeded();
        currentScreen = _buildStoreNameScreen();
        break;
      case LoginFlowState.login:
        currentScreen = _buildLoginScreen();
        break;
    }

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
            child: currentScreen,
          ),
        ),
      ),
    );
  }

// دالة للتحقق من الحاجة لعرض شاشة اسم المحل
  Future<void> _verifyStoreNameNeeded() async {
    final storeDbService = StoreDbService();
    final savedStoreName = await storeDbService.getStoreName();

    if (savedStoreName != null && savedStoreName.isNotEmpty) {
      // اسم المحل موجود، انتقل مباشرة لتسجيل الدخول
      if (mounted) {
        setState(() {
          _currentFlowState = LoginFlowState.login;
          _storeName = savedStoreName;
        });
      }
    }
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
                  _sellerNameController,
                  'اسم البائع',
                  false,
                  focusNode: _sellerNameFocus,
                  nextFocus: _newPasswordFocus,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildInputField(
                  _newPasswordController,
                  'كلمة المرور الجديدة',
                  true,
                  focusNode: _newPasswordFocus,
                  nextFocus: _confirmPasswordFocus,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildInputField(
                  _confirmPasswordController,
                  'تأكيد كلمة المرور',
                  true,
                  focusNode: _confirmPasswordFocus,
                  onSubmitted: _savePasswordAndSeller,
                ),
              ),
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
                    _sellerNameController,
                    'أدخل اسم البائع',
                    false,
                    focusNode: _sellerNameFocus,
                    nextFocus: _passwordFocus,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: _buildInputField(
                    _passwordController,
                    'أدخل كلمة المرور',
                    true,
                    focusNode: _passwordFocus,
                    onSubmitted: _login,
                    errorText: _errorMessage,
                  ),
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
      {String? errorText,
      FocusNode? focusNode,
      FocusNode? nextFocus,
      Function()? onSubmitted}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      focusNode: focusNode,
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      textInputAction: nextFocus != null || onSubmitted != null
          ? TextInputAction.next
          : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          // الانتقال للحقل التالي من اليمين لليسار
          FocusScope.of(context).requestFocus(nextFocus);
        } else if (onSubmitted != null) {
          onSubmitted();
        }
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
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
    );
  }

  // --- واجهة اسم المحل الجديدة ---
  Widget _buildStoreNameScreen() {
    return Form(
      key: _storeNameFormKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.store, size: 60, color: Colors.white),
          const SizedBox(height: 20),
          const Text('تحديد اسم المحل',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50.0),
            child: _buildInputField(
              _storeNameController,
              'أدخل اسم المحل',
              false,
              focusNode: _storeNameFieldFocus,
              onSubmitted: _saveStoreName,
            ),
          ),
          const SizedBox(height: 30),
          _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : ElevatedButton(
                  onPressed: _saveStoreName,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.teal[700],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 60, vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('حفظ ومتابعة',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
        ],
      ),
    );
  }

  Future<void> _saveStoreName() async {
    if (!_storeNameFormKey.currentState!.validate()) return;

    final newStoreName = _storeNameController.text.trim();

    // التحقق من أن اسم المحل ليس فارغاً
    if (newStoreName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال اسم المحل'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final storeDbService = StoreDbService();

    // التحقق أولاً من عدم وجود اسم محدد بالفعل
    final existingStoreName = await storeDbService.getStoreName();
    if (existingStoreName != null && existingStoreName.isNotEmpty) {
      // اسم المحل موجود بالفعل، انتقل مباشرة لتسجيل الدخول
      setState(() {
        _isLoading = false;
        _storeName = existingStoreName;
        _currentFlowState = LoginFlowState.login;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('اسم المحل "$existingStoreName" مضبوط بالفعل'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    // حفظ اسم المحل الجديد
    await storeDbService.saveStoreName(newStoreName);

    setState(() {
      _isLoading = false;
      _storeName = newStoreName;
      _currentFlowState = LoginFlowState.login;
    });

    _storeNameController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حفظ اسم المحل: $newStoreName'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
