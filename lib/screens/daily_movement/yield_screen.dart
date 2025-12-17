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
    WidgetsBinding.instance.addPostFrameCallback((_) => _showLoginDialog());
    _cashSalesController.addListener(() => setState(_calculateYield));
    _receiptsController.addListener(() => setState(_calculateYield));
    _cashPurchasesController.addListener(() => setState(_calculateYield));
    _paymentsController.addListener(() => setState(_calculateYield));
    _collectedController.addListener(() => setState(_calculateYield));
  }

  void _showLoginDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = prefs.getString('accounts');
    final Map<String, String> accountsMap =
        accounts != null ? Map<String, String>.from(json.decode(accounts)) : {};

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final TextEditingController sellerNameController =
            TextEditingController();
        final TextEditingController passwordController =
            TextEditingController();
        final FocusNode sellerNameFocus = FocusNode();
        final FocusNode passwordFocus = FocusNode();

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              scrollable: true,
              contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              title: const Text(
                'تسجيل الدخول',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    TextField(
                      controller: sellerNameController,
                      focusNode: sellerNameFocus,
                      decoration: const InputDecoration(
                        labelText: 'اسم البائع',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () {
                        sellerNameFocus.unfocus();
                        FocusScope.of(context).requestFocus(passwordFocus);
                      },
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: passwordController,
                      focusNode: passwordFocus,
                      decoration: const InputDecoration(
                        labelText: 'كلمة السر',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _validateLogin(
                          sellerNameController.text,
                          passwordController.text,
                          accountsMap),
                    ),
                  ],
                ),
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _validateLogin(sellerNameController.text,
                        passwordController.text, accountsMap),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'تسجيل الدخول',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      // التأكد من إعادة توجيه التركيز بعد إغلاق الديالوج
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  void _validateLogin(
      String sellerName, String password, Map<String, String> accountsMap) {
    if (accountsMap.containsKey(sellerName) &&
        accountsMap[sellerName] == password) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اسم البائع أو كلمة السر غير صحيحة')),
      );
    }
  }

  @override
  void dispose() {
    _cashSalesController.dispose();
    _receiptsController.dispose();
    _cashPurchasesController.dispose();
    _paymentsController.dispose();
    _collectedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _calculateYield();

    // جعل الشاشة تعمل فقط في الوضع الأفقي
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // يمكنك إضافة منطق لإجبار الوضع الأفقي هنا إذا لزم الأمر
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('شاشة الغلة',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.teal[600],
        foregroundColor: Colors.white,
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
                        'غلة البائع: ${widget.sellerName}',
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

                    // مسافة إضافية في الأسفل للتأكد من ظهور كل المحتوى
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
}
