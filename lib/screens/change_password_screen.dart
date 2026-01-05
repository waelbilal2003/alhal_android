import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import '../services/store_db_service.dart'; // استيراد خدمة قاعدة البيانات

class ChangePasswordScreen extends StatefulWidget {
  final String? sellerName;
  final String currentStoreName;
  final Function(String) onStoreNameChanged;

  const ChangePasswordScreen({
    super.key,
    this.sellerName,
    required this.currentStoreName,
    required this.onStoreNameChanged,//
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  int _currentScreen = 0;

  // متغيرات التحكم
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFormKey = GlobalKey<FormState>();

  final _sellerNameController = TextEditingController();
  final _sellerFormKey = GlobalKey<FormState>();

  final _storeNameController = TextEditingController();
  final _storeNameFormKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;
  String? _savedPassword;

  // إضافة FocusNode لكل حقل
  final _oldPasswordFocus = FocusNode();
  final _newPasswordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  final _sellerNameFocus = FocusNode();
  final _storeNameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _getSavedData();

    if (widget.sellerName != null) {
      _sellerNameController.text = widget.sellerName!;
    }
    _storeNameController.text = widget.currentStoreName;
    _loadStoreName();
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _sellerNameController.dispose();
    _storeNameController.dispose();

    // التخلص من FocusNodes
    _oldPasswordFocus.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _sellerNameFocus.dispose();
    _storeNameFocus.dispose();
    super.dispose();
  }

  Future<void> _getSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedPassword = prefs.getString('app_password');
      // تم حذف السطر التالي لإزالة التحذير
      // _savedSellerName = prefs.getString('seller_name');
    });
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;

    if (oldPassword != _savedPassword) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'كلمة المرور القديمة غير صحيحة';
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_password', newPassword);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تغيير كلمة المرور بنجاح'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  Future<void> _changeSellerName() async {
    if (!_sellerFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final newSellerName = _sellerNameController.text;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('seller_name', newSellerName);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تغيير اسم البائع بنجاح'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  Future<void> _loadStoreName() async {
    final storeDbService = StoreDbService();
    final savedStoreName = await storeDbService.getStoreName();
    if (savedStoreName != null) {
      setState(() {
        _storeNameController.text = savedStoreName;
      });
    }
  }

  Future<void> _changeStoreName() async {
    if (!_storeNameFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final newStoreName = _storeNameController.text;
    final storeDbService = StoreDbService();

    await storeDbService.saveStoreName(newStoreName);

    // تحديث اسم المحل في الشاشة السابقة
    widget.onStoreNameChanged(newStoreName);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تغيير اسم المحل بنجاح'),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {
      _isLoading = false;
      _currentScreen = 0; // العودة إلى شاشة الاختيار
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        centerTitle: true,
        backgroundColor: Colors.teal[600],
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal[400]!, Colors.teal[700]!],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: _buildCurrentScreen(),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentScreen) {
      case 0:
        return 'الإعدادات';
      case 1:
        return 'تغيير كلمة المرور';
      case 2:
        return 'تغيير اسم البائع';
      case 3:
        return 'تغيير اسم المحل';
      default:
        return 'الإعدادات';
    }
  }

  Widget _buildCurrentScreen() {
    switch (_currentScreen) {
      case 0:
        return _buildSelectionScreen();
      case 1:
        return _buildPasswordChangeScreen();
      case 2:
        return _buildSellerNameChangeScreen();
      case 3:
        return _buildStoreNameChangeScreen();
      default:
        return _buildSelectionScreen();
    }
  }

  // واجهة الاختيار
  Widget _buildSelectionScreen() {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.settings, size: 75, color: Colors.white),
          const SizedBox(height: 15),
          const Text(
            'اختر الإعداد الذي تريد تغييره',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSelectionOption(
                icon: Icons.lock,
                label: 'تغيير كلمة المرور',
                onTap: () => setState(() => _currentScreen = 1),
              ),
              _buildSelectionOption(
                icon: Icons.person,
                label: 'تغيير اسم البائع',
                onTap: () => setState(() => _currentScreen = 2),
              ),
              _buildSelectionOption(
                icon: Icons.store,
                label: 'تغيير اسم المحل',
                onTap: () => setState(() => _currentScreen = 3),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white, width: 1),
              ),
            ),
            child: const Text(
              'رجوع',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 130,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 25, color: Colors.white),
            const SizedBox(height: 15),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // واجهة تغيير كلمة المرور
  Widget _buildPasswordChangeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _passwordFormKey,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_reset, size: 80, color: Colors.white),
              const SizedBox(height: 30),
              _buildInputField(
                _oldPasswordController,
                'كلمة المرور القديمة',
                true,
                focusNode: _oldPasswordFocus,
                onSubmitted: () =>
                    FocusScope.of(context).requestFocus(_newPasswordFocus),
              ),
              const SizedBox(height: 20),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: _buildInputField(
                      _newPasswordController,
                      'كلمة المرور الجديدة',
                      true,
                      focusNode: _newPasswordFocus,
                      onSubmitted: () => FocusScope.of(context)
                          .requestFocus(_confirmPasswordFocus),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildInputField(
                      _confirmPasswordController,
                      'تأكيد كلمة المرور',
                      true,
                      focusNode: _confirmPasswordFocus,
                      onSubmitted: _changePassword,
                    ),
                  ),
                ],
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 15.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.yellowAccent,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() => _currentScreen = 0),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white, width: 1),
                      ),
                    ),
                    child: const Text(
                      'رجوع',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : ElevatedButton(
                          onPressed: _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.teal[700],
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'حفظ',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                ],
              ),
              // مساحة إضافية في الأسفل للكيبورد
              SizedBox(
                  height:
                      MediaQuery.of(context).viewInsets.bottom > 0 ? 300 : 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSellerNameChangeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _sellerFormKey,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person, size: 80, color: Colors.white),
              const SizedBox(height: 30),
              _buildInputField(
                _sellerNameController,
                'اسم البائع الجديد',
                false,
                focusNode: _sellerNameFocus,
                onSubmitted: _changeSellerName,
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 15.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.yellowAccent,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() => _currentScreen = 0),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white, width: 1),
                      ),
                    ),
                    child: const Text(
                      'رجوع',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : ElevatedButton(
                          onPressed: _changeSellerName,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.teal[700],
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'حفظ',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                ],
              ),
              // مساحة إضافية في الأسفل للكيبورد
              SizedBox(
                  height:
                      MediaQuery.of(context).viewInsets.bottom > 0 ? 300 : 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreNameChangeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _storeNameFormKey,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.store, size: 80, color: Colors.white),
              const SizedBox(height: 30),
              _buildInputField(
                _storeNameController,
                'اسم المحل الجديد',
                false,
                focusNode: _storeNameFocus,
                onSubmitted: _changeStoreName,
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 15.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.yellowAccent,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() => _currentScreen = 0),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white, width: 1),
                      ),
                    ),
                    child: const Text(
                      'رجوع',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : ElevatedButton(
                          onPressed: _changeStoreName,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.teal[700],
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'حفظ',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                ],
              ),
              // مساحة إضافية في الأسفل للكيبورد
              SizedBox(
                  height:
                      MediaQuery.of(context).viewInsets.bottom > 0 ? 300 : 0),
            ],
          ),
        ),
      ),
    );
  }

  // تحديث دالة بناء حقل الإدخال:
  Widget _buildInputField(
    TextEditingController controller,
    String hint,
    bool obscure, {
    String? errorText,
    Function()? onSubmitted,
    FocusNode? focusNode,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        textInputAction:
            onSubmitted != null ? TextInputAction.done : TextInputAction.next,
        onFieldSubmitted: (_) {
          if (onSubmitted != null) {
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
            borderSide: BorderSide(width: 0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          errorText: errorText,
          errorStyle: const TextStyle(color: Colors.yellowAccent),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'الرجاء إدخال $hint';
          }
          if (hint.contains('كلمة المرور') && value.length < 4) {
            return 'كلمة المرور قصيرة جداً';
          }
          if (hint.contains('تأكيد') && value != _newPasswordController.text) {
            return 'كلمتا المرور غير متطابقتين';
          }
          return null;
        },
      ),
    );
  }
}
