import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/store_db_service.dart'; // استيراد خدمة قاعدة البيانات

// يجب استيراد الشاشات الأخرى المطلوبة
// ChangePasswordScreen و LoginScreen (لإعادة توجيه الإضافة)
import 'change_password_screen.dart'; // نفترض وجود هذا الملف
import 'login_screen.dart'; // للوصول إلى _buildSetupScreen

class SellerManagementScreen extends StatefulWidget {
  final String currentStoreName;
  final Function() onLogout;

  const SellerManagementScreen({
    super.key,
    required this.currentStoreName,
    required this.onLogout,
  });

  @override
  State<SellerManagementScreen> createState() => _SellerManagementScreenState();
}

class _SellerManagementScreenState extends State<SellerManagementScreen> {
  final _sellerNameController = TextEditingController();
  String _currentStoreName = ''; // لتخزين اسم المحل الموحد
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  Map<String, String> _accounts = {};

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _loadStoreName();
  }

  Future<void> _loadStoreName() async {
    final storeDbService = StoreDbService();
    final savedStoreName = await storeDbService.getStoreName();
    setState(() {
      _currentStoreName = savedStoreName ?? widget.currentStoreName;
    });
  }

  Future<void> _loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = prefs.getString('accounts');
    setState(() {
      _accounts = accountsJson != null
          ? Map<String, String>.from(json.decode(accountsJson))
          : {};
    });
  }

  Future<void> _saveAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accounts', json.encode(_accounts));
  }

  Future<void> _deleteSeller(String sellerName) async {
    if (_accounts.containsKey(sellerName)) {
      setState(() {
        _accounts.remove(sellerName);
      });
      await _saveAccounts();
      // إذا كان البائع المحذوف هو البائع الحالي، يجب تسجيل الخروج
      final prefs = await SharedPreferences.getInstance();
      final currentSeller = prefs.getString('current_seller');
      if (currentSeller == sellerName) {
        widget.onLogout();
      }
    }
  }

  // دالة لبناء حقل الإدخال مع دعم زر ENTER
  Widget _buildInputField(
    TextEditingController controller,
    String hint,
    bool obscure, {
    String? errorText,
    Function()? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textAlign: TextAlign.center,
      textInputAction: TextInputAction.next, // استخدام Next للتنقل بين الحقول
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
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
        errorText: errorText,
        errorStyle: const TextStyle(color: Colors.yellowAccent),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'الرجاء إدخال $hint';
        return null;
      },
      onFieldSubmitted: (_) {
        if (onSubmitted != null) {
          onSubmitted();
        } else {
          FocusScope.of(context).nextFocus();
        }
      },
    );
  }

  // دالة بناء شاشة إدارة البائعين
  Widget _buildManagementScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal[400]!, Colors.teal[700]!],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // اسم المحل
                Text(
                  _currentStoreName,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),

                // حقول اسم البائع وكلمة السر
                Form(
                  key: _formKey,
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: _buildInputField(
                            _sellerNameController,
                            'اسم البائع',
                            false,
                            onSubmitted: () =>
                                FocusScope.of(context).nextFocus(),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: _buildInputField(
                            _passwordController,
                            'كلمة السر',
                            true,
                            errorText: _errorMessage,
                            onSubmitted: _handleEditSeller,
                          ), // عند الضغط على ENTER في آخر حقل، يتم محاولة التعديل
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // أزرار الإدارة (إضافة، تعديل، حذف، خروج)
                _buildManagementButtons(),
                const SizedBox(height: 40),

                // قائمة البائعين للحذف
                _buildDeleteSellerList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // بناء الأزرار السفلية المشابهة لـ purchases_screen.dart
  Widget _buildManagementButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      textDirection: TextDirection.rtl,
      children: [
        _buildActionButton('إضافة', Icons.person_add, _handleAddSeller),
        _buildActionButton('تعديل', Icons.edit, _handleEditSeller),
        _buildActionButton('حذف', Icons.delete, _handleDeleteMode),
        _buildActionButton('خروج', Icons.exit_to_app, () {
          Navigator.of(context).pop();
        }),
      ],
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.teal[700]),
          label: Text(text, style: TextStyle(color: Colors.teal[700])),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  // معالجة زر الإضافة: الانتقال إلى شاشة الإعداد لإضافة مستخدم جديد
  void _handleAddSeller() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const LoginScreen(initialState: LoginFlowState.setup),
      ),
    );
  }

  // معالجة زر التعديل: الانتقال إلى شاشة ChangePasswordScreen مع خيار تعديل اسم المحل
  void _handleEditSeller() {
    if (!_formKey.currentState!.validate()) return;

    final sellerName = _sellerNameController.text;
    final password = _passwordController.text;

    if (_accounts.containsKey(sellerName) &&
        _accounts[sellerName] == password) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChangePasswordScreen(
            sellerName: sellerName,
            // تمرير اسم المحل الحالي لتمكين تعديله
            currentStoreName: _currentStoreName,
            onStoreNameChanged: (newName) {
              // تحديث اسم المحل في الشاشة الحالية بعد التعديل
              setState(() {
                _currentStoreName = newName;
              });
            },
          ),
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'اسم البائع أو كلمة المرور غير صحيحة للتعديل.';
      });
    }
  }

  // معالجة زر الحذف: عرض قائمة البائعين
  bool _showDeleteList = false;
  void _handleDeleteMode() {
    setState(() {
      _showDeleteList = !_showDeleteList;
    });
  }

  Widget _buildDeleteSellerList() {
    if (!_showDeleteList) return const SizedBox.shrink();

    final sellerNames = _accounts.keys.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'قائمة البائعين المسجلين:',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          ...sellerNames.map((seller) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: Text(
                      seller,
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _confirmDelete(seller),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('حذف'),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _confirmDelete(String sellerName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text(
            'سيؤدي هذا إلى حذف البائع "$sellerName" بشكل نهائي. هل أنت متأكد؟',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('تأكيد'),
              onPressed: () {
                _deleteSeller(sellerName);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildManagementScreen();
  }
}
