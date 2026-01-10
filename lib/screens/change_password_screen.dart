import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/store_db_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String currentStoreName;
  final Function(String) onStoreNameChanged;

  const ChangePasswordScreen({
    super.key,
    required this.currentStoreName,
    required this.onStoreNameChanged,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  int _currentScreen = 0;

  // متغيرات التحقق من الهوية
  final _verifySellerNameController = TextEditingController();
  final _verifyPasswordController = TextEditingController();
  final _verifyFormKey = GlobalKey<FormState>();

  // متغيرات التعديل
  final _newSellerNameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _editFormKey = GlobalKey<FormState>();

  // متغيرات اسم المحل
  final _storeNameController = TextEditingController();
  final _storeNameFormKey = GlobalKey<FormState>();

  // FocusNodes
  final _verifySellerFocus = FocusNode();
  final _verifyPasswordFocus = FocusNode();
  final _newSellerFocus = FocusNode();
  final _newPasswordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  final _storeNameFocus = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;
  bool _identityVerified = false;
  String? _currentSellerName;

  @override
  void initState() {
    super.initState();
    _loadStoreName();
    _loadCurrentSeller();
    _loadTempSellerData();
  }

  @override
  void dispose() {
    _verifySellerNameController.dispose();
    _verifyPasswordController.dispose();
    _newSellerNameController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _storeNameController.dispose();

    _verifySellerFocus.dispose();
    _verifyPasswordFocus.dispose();
    _newSellerFocus.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _storeNameFocus.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentSeller() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentSellerName = prefs.getString('current_seller');
    });
  }

  Future<Map<String, String>> _getAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = prefs.getString('accounts');
    return accounts != null
        ? Map<String, String>.from(json.decode(accounts))
        : {};
  }

  Future<void> _verifyIdentity() async {
    if (!_verifyFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final enteredSellerName = _verifySellerNameController.text;
    final enteredPassword = _verifyPasswordController.text;
    final accounts = await _getAccounts();

    if (accounts.containsKey(enteredSellerName) &&
        accounts[enteredSellerName] == enteredPassword) {
      // التحقق الناجح
      setState(() {
        _isLoading = false;
        _identityVerified = true;
        _currentSellerName = enteredSellerName;
        _newSellerNameController.text = enteredSellerName;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'اسم البائع أو كلمة المرور غير صحيحة';
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_editFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final newSellerName = _newSellerNameController.text;
    final newPassword = _newPasswordController.text;
    final oldSellerName = _verifySellerNameController.text;

    final accounts = await _getAccounts();

    // إذا تم تغيير اسم البائع، نحتاج إلى نقل الحساب
    if (oldSellerName != newSellerName) {
      // حفظ الحساب القديم كتاريخ
      final prefs = await SharedPreferences.getInstance();
      final oldAccountsJson = prefs.getString('old_accounts');
      final Map<String, String> oldAccounts = oldAccountsJson != null
          ? Map<String, String>.from(json.decode(oldAccountsJson))
          : {};

      oldAccounts[oldSellerName] = accounts[oldSellerName]!;
      await prefs.setString('old_accounts', json.encode(oldAccounts));

      // حذف الحساب القديم
      accounts.remove(oldSellerName);
    }

    // تحديث/إضافة الحساب الجديد
    accounts[newSellerName] = newPassword;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accounts', json.encode(accounts));

    // إذا كان هذا هو البائع الحالي، تحديثه
    if (_currentSellerName == oldSellerName) {
      await prefs.setString('current_seller', newSellerName);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ التغييرات بنجاح'),
        backgroundColor: Colors.green,
      ),
    );

    // إعادة التعيين
    setState(() {
      _isLoading = false;
      _identityVerified = false;
      _verifySellerNameController.clear();
      _verifyPasswordController.clear();
      _newSellerNameController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    });
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
      _currentScreen = 0;
    });
  }

  void _resetToSelection() {
    setState(() {
      _currentScreen = 0;
      _identityVerified = false;
      _verifySellerNameController.clear();
      _verifyPasswordController.clear();
      _newSellerNameController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).size.width > 600;

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
        child: _buildCurrentScreen(isLandscape),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentScreen) {
      case 0:
        return 'الإعدادات';
      case 1:
        return 'تغيير بيانات البائع';
      case 2:
        return 'تغيير اسم المحل';
      default:
        return 'الإعدادات';
    }
  }

  Widget _buildCurrentScreen(bool isLandscape) {
    switch (_currentScreen) {
      case 0:
        return _buildSelectionScreen();
      case 1:
        return _buildSellerDataScreen(isLandscape);
      case 2:
        return _buildStoreNameChangeScreen(isLandscape);
      default:
        return _buildSelectionScreen();
    }
  }

  Widget _buildSelectionScreen() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSelectionOption(
                icon: Icons.person,
                label: 'بيانات البائع',
                description: 'تغيير الاسم وكلمة المرور',
                onTap: () => setState(() => _currentScreen = 1),
              ),
              _buildSelectionOption(
                icon: Icons.store,
                label: 'اسم المحل',
                description: 'تغيير اسم المحل',
                onTap: () => setState(() => _currentScreen = 2),
              ),
            ],
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
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
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 35, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerDataScreen(bool isLandscape) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal[400]!, Colors.teal[700]!],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: SingleChildScrollView(
        // هذه الخصائص تحل المشكلة
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isLandscape ? 800 : 500,
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _identityVerified ? Icons.person : Icons.verified_user,
                  size: isLandscape ? 48 : 38,
                  color: Colors.white,
                ),
                const SizedBox(height: 5),
                Text(
                  _identityVerified
                      ? 'تعديل بيانات البائع'
                      : 'التحقق من الهوية',
                  style: TextStyle(
                    fontSize: isLandscape ? 17 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),

                if (!_identityVerified)
                  _buildVerificationForm(isLandscape)
                else
                  _buildEditForm(isLandscape),

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

                const SizedBox(height: 5),

                // أزرار التحكم
                if (isLandscape)
                  _buildLandscapeButtons()
                else
                  _buildPortraitButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationForm(bool isLandscape) {
    return Form(
      key: _verifyFormKey,
      child: isLandscape
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildInputField(
                    _verifySellerNameController,
                    'اسم البائع الحالي',
                    false,
                    focusNode: _verifySellerFocus,
                    onSubmitted: () => FocusScope.of(context)
                        .requestFocus(_verifyPasswordFocus),
                    icon: Icons.person,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildInputField(
                    _verifyPasswordController,
                    'كلمة المرور الحالية',
                    true,
                    focusNode: _verifyPasswordFocus,
                    onSubmitted: _verifyIdentity,
                    icon: Icons.lock,
                  ),
                ),
              ],
            )
          : Column(
              children: [
                _buildInputField(
                  _verifySellerNameController,
                  'اسم البائع الحالي',
                  false,
                  focusNode: _verifySellerFocus,
                  onSubmitted: () =>
                      FocusScope.of(context).requestFocus(_verifyPasswordFocus),
                  icon: Icons.person,
                ),
                const SizedBox(height: 5),
                _buildInputField(
                  _verifyPasswordController,
                  'كلمة المرور الحالية',
                  true,
                  focusNode: _verifyPasswordFocus,
                  onSubmitted: _verifyIdentity,
                  icon: Icons.lock,
                ),
              ],
            ),
    );
  }

  Widget _buildEditForm(bool isLandscape) {
    return Form(
      key: _editFormKey,
      child: Column(
        children: [
          if (isLandscape)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildInputField(
                    _newSellerNameController,
                    'اسم البائع الجديد',
                    false,
                    focusNode: _newSellerFocus,
                    onSubmitted: () =>
                        FocusScope.of(context).requestFocus(_newPasswordFocus),
                    icon: Icons.person_add,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: [
                      _buildInputField(
                        _newPasswordController,
                        'كلمة المرور الجديدة',
                        true,
                        focusNode: _newPasswordFocus,
                        onSubmitted: () => FocusScope.of(context)
                            .requestFocus(_confirmPasswordFocus),
                        icon: Icons.lock_outline,
                      ),
                      _buildInputField(
                        _confirmPasswordController,
                        'تأكيد كلمة المرور',
                        true,
                        focusNode: _confirmPasswordFocus,
                        onSubmitted: _saveChanges,
                        icon: Icons.lock_reset,
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                _buildInputField(
                  _newSellerNameController,
                  'اسم البائع الجديد',
                  false,
                  focusNode: _newSellerFocus,
                  onSubmitted: () =>
                      FocusScope.of(context).requestFocus(_newPasswordFocus),
                  icon: Icons.person_add,
                ),
                _buildInputField(
                  _newPasswordController,
                  'كلمة المرور الجديدة',
                  true,
                  focusNode: _newPasswordFocus,
                  onSubmitted: () => FocusScope.of(context)
                      .requestFocus(_confirmPasswordFocus),
                  icon: Icons.lock_outline,
                ),
                _buildInputField(
                  _confirmPasswordController,
                  'تأكيد كلمة المرور',
                  true,
                  focusNode: _confirmPasswordFocus,
                  onSubmitted: _saveChanges,
                  icon: Icons.lock_reset,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLandscapeButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: _identityVerified ? _saveChanges : _verifyIdentity,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.teal[700],
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            _identityVerified ? 'حفظ التغييرات' : 'التحقق',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: _identityVerified
              ? () {
                  setState(() {
                    _identityVerified = false;
                    _newSellerNameController.clear();
                    _newPasswordController.clear();
                    _confirmPasswordController.clear();
                  });
                }
              : _resetToSelection,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.white, width: 1),
            ),
          ),
          child: Text(
            _identityVerified ? 'رجوع للتحقق' : 'رجوع',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitButtons() {
    return Column(
      children: [
        _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : ElevatedButton(
                onPressed: _identityVerified ? _saveChanges : _verifyIdentity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.teal[700],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _identityVerified ? 'حفظ التغييرات' : 'التحقق',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
        const SizedBox(height: 15),
        ElevatedButton(
          onPressed: _identityVerified
              ? () {
                  setState(() {
                    _identityVerified = false;
                    _newSellerNameController.clear();
                    _newPasswordController.clear();
                    _confirmPasswordController.clear();
                  });
                }
              : _resetToSelection,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.white, width: 1),
            ),
          ),
          child: Text(
            _identityVerified ? 'رجوع للتحقق' : 'رجوع',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildStoreNameChangeScreen(bool isLandscape) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isLandscape ? 30.0 : 20.0),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isLandscape ? 600 : 500,
          ),
          child: Form(
            key: _storeNameFormKey,
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
                  icon: Icons.store_mall_directory,
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _resetToSelection,
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
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 20),
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
                SizedBox(
                    height:
                        MediaQuery.of(context).viewInsets.bottom > 0 ? 300 : 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String hint,
    bool obscure, {
    required Function()? onSubmitted,
    required FocusNode? focusNode,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        textInputAction:
            onSubmitted != null ? TextInputAction.done : TextInputAction.next,
        onFieldSubmitted: (_) {
          if (onSubmitted != null) onSubmitted();
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
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          prefixIcon: Icon(icon, color: Colors.white70),
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

  Future<void> _loadTempSellerData() async {
    final prefs = await SharedPreferences.getInstance();

    // التحقق من انتهاء الصلاحية
    final expiryTime = prefs.getInt('temp_seller_expiry');
    if (expiryTime != null &&
        expiryTime < DateTime.now().millisecondsSinceEpoch) {
      // حذف البيانات المنتهية
      await prefs.remove('temp_seller_name');
      await prefs.remove('temp_seller_password');
      await prefs.remove('temp_seller_expiry');
      return;
    }

    final tempSellerName = prefs.getString('temp_seller_name');
    final tempPassword = prefs.getString('temp_seller_password');

    if (tempSellerName != null && tempPassword != null) {
      // تعبئة الحقول تلقائياً بالبيانات المؤقتة
      setState(() {
        _verifySellerNameController.text = tempSellerName;
        _verifyPasswordController.text = tempPassword;
      });

      // تنظيف البيانات المؤقتة بعد استخدامها
      await prefs.remove('temp_seller_name');
      await prefs.remove('temp_seller_password');
      await prefs.remove('temp_seller_expiry');
    }
  }
}
