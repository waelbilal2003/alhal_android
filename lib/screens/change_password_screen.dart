import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String? sellerName;

  const ChangePasswordScreen({super.key, this.sellerName});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  // متغيرات التحكم في الواجهة المعروضة
  int _currentScreen =
      0; // 0: الاختيار، 1: تغيير كلمة المرور، 2: تغيير اسم البائع

  // متغيرات تغيير كلمة المرور
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFormKey = GlobalKey<FormState>();

  // متغيرات تغيير اسم البائع
  final _sellerNameController = TextEditingController();
  final _sellerFormKey = GlobalKey<FormState>();

  // متغيرات مشتركة
  bool _isLoading = false;
  String? _errorMessage;
  String? _savedPassword;
  // تم حذف _savedSellerName لأنه غير مستخدم

  @override
  void initState() {
    super.initState();
    _getSavedData();

    // تهيئة اسم البائع الحالي إذا كان متوفراً
    if (widget.sellerName != null) {
      _sellerNameController.text = widget.sellerName!;
    }
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _sellerNameController.dispose();
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
        builder: (context) => LoginScreen(),
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
        builder: (context) => LoginScreen(),
      ),
    );
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
        child: Center(
          child: _buildCurrentScreen(),
        ),
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
                side: const BorderSide(color: Colors.white, width: 1),
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
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
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
    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: Form(
        key: _passwordFormKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_reset, size: 80, color: Colors.white),
            const SizedBox(height: 15),
            _buildInputField(
              _oldPasswordController,
              'كلمة المرور القديمة',
              true,
            ),
            const SizedBox(height: 15),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: _buildInputField(
                    _newPasswordController,
                    'كلمة المرور الجديدة',
                    true,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildInputField(
                    _confirmPasswordController,
                    'تأكيد كلمة المرور',
                    true,
                  ),
                ),
              ],
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.yellowAccent,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 20),
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
                      side: const BorderSide(color: Colors.white, width: 1),
                    ),
                  ),
                  child: const Text(
                    'رجوع',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          ],
        ),
      ),
    );
  }

  // واجهة تغيير اسم البائع
  Widget _buildSellerNameChangeScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _sellerFormKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 50, color: Colors.white),
            const SizedBox(height: 15),
            const Text(
              'تغيير اسم البائع',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 25),
            _buildInputField(
              _sellerNameController,
              'اسم البائع الجديد',
              false,
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
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
                      side: const BorderSide(color: Colors.white, width: 1),
                    ),
                  ),
                  child: const Text(
                    'رجوع',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
      TextEditingController controller, String hint, bool obscure) {
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
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
    );
  }
}
