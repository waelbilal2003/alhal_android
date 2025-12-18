import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'date_selection_screen.dart';
import '../services/store_db_service.dart'; // استيراد خدمة قاعدة البيانات

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
  String _storeName = 'سوق الهال'; // القيمة الافتراضية

  final _formKey = GlobalKey<FormState>();
  final _setupFormKey = GlobalKey<FormState>();
  final _storeNameFormKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  LoginFlowState _currentFlowState = LoginFlowState.setup;

  // FocusNodes لإدارة انتقال التركيز بين الحقول
  late FocusNode _sellerNameFocus;
  late FocusNode _newPasswordFocus;
  late FocusNode _confirmPasswordFocus;
  late FocusNode _loginSellerNameFocus;
  late FocusNode _loginPasswordFocus;
  late FocusNode _storeNameFocus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // تهيئة FocusNodes
    _sellerNameFocus = FocusNode();
    _newPasswordFocus = FocusNode();
    _confirmPasswordFocus = FocusNode();
    _loginSellerNameFocus = FocusNode();
    _loginPasswordFocus = FocusNode();
    _storeNameFocus = FocusNode();

    if (widget.initialState == LoginFlowState.setup) {
      _currentFlowState = LoginFlowState.setup;
    } else {
      _initializeAndCheckAppStatus(); // دالة جديدة لضمان التهيئة أولاً
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
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _loginSellerNameFocus.dispose();
    _loginPasswordFocus.dispose();
    _storeNameFocus.dispose();

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

  Future<void> _initializeAndCheckAppStatus() async {
    final storeDbService = StoreDbService();
    await storeDbService
        .initializeDatabase(); // ضمان تهيئة قاعدة البيانات أولاً

    final prefs = await SharedPreferences.getInstance();
    final accountsJson = prefs.getString('accounts');
    final savedStoreName = await storeDbService.getStoreName();

    if (accountsJson != null) {
      if (savedStoreName != null) {
        setState(() {
          _currentFlowState = LoginFlowState.login;
          _storeName = savedStoreName;
        });
      } else {
        setState(() {
          _currentFlowState = LoginFlowState.storeName;
        });
      }
    } else {
      setState(() {
        _currentFlowState = LoginFlowState.setup;
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

    // التحقق مما إذا كان اسم المحل محفوظاً مسبقاً
    final storeDbService = StoreDbService();
    final savedStoreName = await storeDbService.getStoreName();

    setState(() {
      _isLoading = false;
      // إذا كان اسم المحل محفوظاً بالفعل، انتقل مباشرة إلى تسجيل الدخول
      if (savedStoreName != null) {
        _storeName = savedStoreName;
        _currentFlowState = LoginFlowState.login;
      } else {
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
                  child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: _buildInputField(
                  _sellerNameController,
                  'اسم البائع',
                  false,
                  focusNode: _sellerNameFocus,
                  nextFocusNode: _newPasswordFocus,
                  isLastInRow: false,
                  flowState: LoginFlowState.setup,
                ),
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: _buildInputField(
                  _newPasswordController,
                  'كلمة المرور الجديدة',
                  true,
                  focusNode: _newPasswordFocus,
                  nextFocusNode: _confirmPasswordFocus,
                  isLastInRow: false,
                  flowState: LoginFlowState.setup,
                ),
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: _buildInputField(
                  _confirmPasswordController,
                  'تأكيد كلمة المرور',
                  true,
                  focusNode: _confirmPasswordFocus,
                  nextFocusNode: null,
                  isLastInRow: true,
                  flowState: LoginFlowState.setup,
                ),
              )),
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
                    focusNode: _loginSellerNameFocus,
                    nextFocusNode: _loginPasswordFocus,
                    isLastInRow: false,
                    flowState: LoginFlowState.login,
                    errorText: _errorMessage,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: _buildInputField(
                    _passwordController,
                    'أدخل كلمة المرور',
                    true,
                    focusNode: _loginPasswordFocus,
                    nextFocusNode: null,
                    isLastInRow: true,
                    flowState: LoginFlowState.login,
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

  // --- دالة بناء حقل الإدخال المعدلة لإدارة FocusNodes ---
  Widget _buildInputField(
    TextEditingController controller,
    String hint,
    bool obscure, {
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    bool isLastInRow = false,
    LoginFlowState? flowState,
    String? errorText,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textAlign: TextAlign.center,
      focusNode: focusNode,
      textDirection: TextDirection.rtl,
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
      onFieldSubmitted: (_) {
        if (isLastInRow) {
          // إذا كان هذا الحقل الأخير في الصف، نفذ الإجراء المناسب
          if (flowState == LoginFlowState.setup) {
            _savePasswordAndSeller();
          } else if (flowState == LoginFlowState.login) {
            _login();
          } else if (flowState == LoginFlowState.storeName) {
            _saveStoreName();
          }
        } else if (nextFocusNode != null) {
          // إذا كان هناك حقل تالٍ، انقل التركيز إليه
          FocusScope.of(context).requestFocus(nextFocusNode);
        }
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
              focusNode: _storeNameFocus,
              nextFocusNode: null,
              isLastInRow: true,
              flowState: LoginFlowState.storeName,
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
    setState(() => _isLoading = true);

    final newStoreName = _storeNameController.text;
    final storeDbService = StoreDbService();

    await storeDbService.saveStoreName(newStoreName);

    setState(() {
      _isLoading = false;
      _storeName = newStoreName;
      _currentFlowState = LoginFlowState.login;
    });

    _storeNameController.clear();
  }
}
