import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/store_db_service.dart';

// استيراد الشاشات الأخرى المطلوبة
import 'change_password_screen.dart'; // الشاشة الموحدة الجديدة
import 'login_screen.dart';

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
  String _currentStoreName = '';
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  Map<String, String> _accounts = {};
  bool _showDeleteList = false;

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
      textInputAction: TextInputAction.next,
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
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // أزرار الإدارة
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

  Widget _buildManagementButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      textDirection: TextDirection.rtl,
      children: [
        _buildActionButton('إضافة', Icons.person_add, _handleAddSeller),
        _buildActionButton('تعديل', Icons.edit, _handleEditSeller),
        _buildActionButton('فهرس البائعين', Icons.list, _handleSellerIndex),
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

  void _handleAddSeller() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const LoginScreen(initialState: LoginFlowState.setup),
      ),
    );
  }

  void _handleEditSeller() {
    if (!_formKey.currentState!.validate()) return;

    final sellerName = _sellerNameController.text;
    final password = _passwordController.text;

    // التحقق من صحة بيانات البائع
    if (_accounts.containsKey(sellerName) &&
        _accounts[sellerName] == password) {
      // حفظ بيانات البائع الحالي في SharedPreferences مؤقتاً للتحقق في الشاشة التالية
      _saveCurrentSellerForVerification(sellerName, password).then((_) {
        // الانتقال إلى شاشة التعديل الموحدة
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChangePasswordScreen(
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
      });
    } else {
      setState(() {
        _errorMessage = 'اسم البائع أو كلمة المرور غير صحيحة للتعديل.';
      });
    }
  }

  Future<void> _saveCurrentSellerForVerification(
      String sellerName, String password) async {
    final prefs = await SharedPreferences.getInstance();

    // حفظ بيانات البائع المؤقتة للتحقق في ChangePasswordScreen
    await prefs.setString('temp_seller_name', sellerName);
    await prefs.setString('temp_seller_password', password);

    // تعيين مهلة للحذف التلقائي بعد 5 دقائق
    final expiryTime =
        DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch;
    await prefs.setInt('temp_seller_expiry', expiryTime);
  }

  void _handleDeleteMode() {
    setState(() {
      _showDeleteList = !_showDeleteList;
    });
  }

  Widget _buildDeleteSellerList() {
    if (!_showDeleteList) return const SizedBox.shrink();

    final sellerNames = _accounts.keys.toList();

    if (sellerNames.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'لا يوجد بائعين مسجلين',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

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
            'فهرس البائعين المسجلين:',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),

          // جدول العناوين
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: Text(
                  'رقم البائع',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  'اسم البائع',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  'كلمة السر',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          Divider(color: Colors.white70, thickness: 1),

          // بيانات البائعين
          ...sellerNames.asMap().entries.map((entry) {
            final index = entry.key + 1; // بدء الترقيم من 1
            final seller = entry.value;
            final password = _accounts[seller]!;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: Text(
                      index.toString(),
                      style: TextStyle(fontSize: 16, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      seller,
                      style: TextStyle(fontSize: 16, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      password,
                      style: TextStyle(fontSize: 16, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
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
                setState(() {});
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

  void _handleSellerIndex() {
    setState(() {
      _showDeleteList = !_showDeleteList;
    });
  }
}
