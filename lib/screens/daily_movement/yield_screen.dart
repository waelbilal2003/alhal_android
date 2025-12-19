import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class YieldScreen extends StatefulWidget {
  final String sellerName;
  final String password;

  const YieldScreen(
      {super.key, required this.sellerName, required this.password});

  @override
  State<YieldScreen> createState() => _YieldScreenState();
}

class _YieldScreenState extends State<YieldScreen> {
  final TextEditingController _cashSalesController = TextEditingController();
  final TextEditingController _receiptsController = TextEditingController();
  final TextEditingController _cashPurchasesController =
      TextEditingController();
  final TextEditingController _paymentsController = TextEditingController();
  final TextEditingController _collectedController = TextEditingController();

  // متغيرات التحكم بشاشة تسجيل الدخول
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String _errorMessage = '';
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _sellerNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _loginSellerNameFocus = FocusNode();
  final FocusNode _loginPasswordFocus = FocusNode();

  double _yield = 0;
  String _status = '';

  void _calculateYield() {
    final double cashSales = double.tryParse(_cashSalesController.text) ?? 0;
    final double receipts = double.tryParse(_receiptsController.text) ?? 0;
    final double cashPurchases =
        double.tryParse(_cashPurchasesController.text) ?? 0;
    final double payments = double.tryParse(_paymentsController.text) ?? 0;
    final double collected = double.tryParse(_collectedController.text) ?? 0;

    final double s = cashSales + receipts;
    final double a = cashPurchases + payments;
    _yield = double.parse((s - a).toStringAsFixed(2));

    if (collected == _yield) {
      _status = '';
    } else {
      final difference = (_yield - collected).abs().toStringAsFixed(2);
      _status = collected > _yield
          ? 'زيادة الغلة $difference'
          : 'نقص الغلة $difference';
    }
  }

  @override
  void initState() {
    super.initState();
    // تحقق إذا كان المستخدم مسجل دخول مسبقاً
    _checkIfLoggedIn();

    _cashSalesController.addListener(() => setState(_calculateYield));
    _receiptsController.addListener(() => setState(_calculateYield));
    _cashPurchasesController.addListener(() => setState(_calculateYield));
    _paymentsController.addListener(() => setState(_calculateYield));
    _collectedController.addListener(() => setState(_calculateYield));
  }

  Future<void> _checkIfLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('isLoggedIn') ?? false;
    final savedSellerName = prefs.getString('currentSellerName') ?? '';

    if (loggedIn && savedSellerName.isNotEmpty) {
      setState(() {
        _isLoggedIn = true;
      });
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final prefs = await SharedPreferences.getInstance();
        final accounts = prefs.getString('accounts');
        final Map<String, String> accountsMap = accounts != null
            ? Map<String, String>.from(json.decode(accounts))
            : {};

        final sellerName = _sellerNameController.text.trim();
        final password = _passwordController.text.trim();

        // التحقق من بيانات الدخول
        if (accountsMap.containsKey(sellerName) &&
            accountsMap[sellerName] == password) {
          // حفظ حالة تسجيل الدخول
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('currentSellerName', sellerName);

          setState(() {
            _isLoggedIn = true;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'اسم البائع أو كلمة المرور غير صحيحة';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'حدث خطأ أثناء تسجيل الدخول';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('currentSellerName');

    setState(() {
      _isLoggedIn = false;
      _sellerNameController.clear();
      _passwordController.clear();
      _errorMessage = '';
    });
  }

  Widget _buildLoginScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.teal[700]!,
            Colors.teal[500]!,
            Colors.teal[300]!,
          ],
        ),
      ),
      child: Form(
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
                    child: _buildLoginInputField(
                      _sellerNameController,
                      'أدخل اسم البائع',
                      false,
                      focusNode: _loginSellerNameFocus,
                      nextFocusNode: _loginPasswordFocus,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: _buildLoginInputField(
                      _passwordController,
                      'أدخل كلمة المرور',
                      true,
                      focusNode: _loginPasswordFocus,
                      nextFocusNode: null,
                      isPassword: true,
                    ),
                  ),
                ),
              ],
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
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
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginInputField(
    TextEditingController controller,
    String hintText,
    bool isLastInRow, {
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      textDirection: TextDirection.rtl, // إضافة هذا السطر
      textAlign: TextAlign.right, // إضافة هذا السطر
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        errorStyle: const TextStyle(color: Colors.yellow),
        hintTextDirection: TextDirection.rtl, // إضافة هذا السطر
      ),
      textInputAction:
          isLastInRow ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: (_) {
        if (isLastInRow) {
          _login();
        } else if (nextFocusNode != null) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        }
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'هذا الحقل مطلوب';
        }
        return null;
      },
    );
  }

  Widget _buildYieldScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('شاشة الغلة',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.teal[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // عنوان الغلة
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal[200]!),
                      ),
                      child: Text(
                        'غلة البائع: ${_sellerNameController.text}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // الصف الأول: مبيعات نقدية - مقبوضات
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildInputField(
                            'مبيعات نقدية',
                            _cashSalesController,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInputField(
                            'مقبوضات',
                            _receiptsController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // الصف الثاني: مشتريات نقدية - مدفوعات
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildInputField(
                            'مشتريات نقدية',
                            _cashPurchasesController,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInputField(
                            'مدفوعات',
                            _paymentsController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // الصف الثالث: الغلة - المقبوض منه
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // حقل الناتج (الغلة) - تصميم مشابه لحقل الإدخال
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'الغلة',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _yield.toStringAsFixed(2),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInputField(
                            'المقبوض منه',
                            _collectedController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // الصف الرابع: زيادة أو نقص الغلة
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color: _status.contains('زيادة')
                            ? Colors.green[50]
                            : _status.contains('نقص')
                                ? Colors.red[50]
                                : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _status.contains('زيادة')
                              ? Colors.green[200]!
                              : _status.contains('نقص')
                                  ? Colors.red[200]!
                                  : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        _status.isNotEmpty ? _status : 'لا يوجد فرق',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _status.contains('زيادة')
                              ? Colors.green[800]
                              : _status.contains('نقص')
                                  ? Colors.red[800]
                                  : Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // مسافة إضافية في الأسفل
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 1,
            offset: const Offset(0, 0.54),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.bold,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.teal[400]!, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 1,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cashSalesController.dispose();
    _receiptsController.dispose();
    _cashPurchasesController.dispose();
    _paymentsController.dispose();
    _collectedController.dispose();
    _sellerNameController.dispose();
    _passwordController.dispose();
    _loginSellerNameFocus.dispose();
    _loginPasswordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _calculateYield();

    // بناء واجهة المستخدم بناءً على حالة تسجيل الدخول
    if (!_isLoggedIn) {
      // عرض شاشة تسجيل الدخول كاملة
      return Scaffold(
        body: _buildLoginScreen(),
      );
    } else {
      // عرض شاشة الغلة
      return _buildYieldScreen();
    }
  }
}
