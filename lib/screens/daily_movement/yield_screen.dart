// yield_screen.dart (محدث)
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../services/purchase_storage_service.dart';
import '../../services/box_storage_service.dart';
import '../../services/receipt_storage_service.dart';
import '../../services/sales_storage_service.dart'; // إضافة لشاشة المبيعات

class YieldScreen extends StatefulWidget {
  final String sellerName;
  final String password;
  final String? selectedDate;

  const YieldScreen({
    super.key,
    required this.sellerName,
    required this.password,
    this.selectedDate,
  });

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
  String? _errorMessage;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _sellerNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late FocusNode _loginSellerNameFocus;
  late FocusNode _loginPasswordFocus;

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
    // تهيئة FocusNodes
    _loginSellerNameFocus = FocusNode();
    _loginPasswordFocus = FocusNode();

    // تحقق إذا كان المستخدم مسجل دخول مسبقاً
    _checkIfLoggedIn();

    _cashSalesController.addListener(() => setState(_calculateYield));
    _receiptsController.addListener(() => setState(_calculateYield));
    _cashPurchasesController.addListener(() => setState(_calculateYield));
    _paymentsController.addListener(() => setState(_calculateYield));
    _collectedController.addListener(() => setState(_calculateYield));

    // إضافة Listener لحفظ القيمة عند التغيير
    _collectedController.addListener(() async {
      // استخدام debounce لتجنب الحفظ المستمر مع كل ضغطة زر
      await Future.delayed(const Duration(milliseconds: 500));
      if (_isLoggedIn && _collectedController.text.isNotEmpty) {
        await _saveCollectedAmount();
      }
    });

    // تحميل البيانات تلقائياً إذا توفر التاريخ
    if (widget.selectedDate != null) {
      _loadCashPurchases();
      _loadCashSales(); // تحميل المبيعات النقدية
      _loadBoxData(); // تحميل بيانات الصندوق
      _loadReceiptData(); // تحميل بيانات الاستلام
      // تحميل قيمة المقبوض منه المحفوظة
      _loadCollectedAmount(); // إضافة هذا السطر هنا أيضًا
    }
  }

  Future<void> _loadCashPurchases() async {
    if (widget.selectedDate == null) return;

    final purchaseStorage = PurchaseStorageService();
    final currentSellerName = _sellerNameController.text;

    if (currentSellerName.isEmpty) return;

    try {
      // الحصول على إجمالي المشتريات النقدية للبائع الحالي
      final totalCashPurchases =
          await purchaseStorage.getCashPurchasesForSeller(
        widget.selectedDate!,
        currentSellerName,
      );

      setState(() {
        _cashPurchasesController.text = totalCashPurchases.toStringAsFixed(2);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل المشتريات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadCashSales() async {
    if (widget.selectedDate == null) return;

    final salesStorage = SalesStorageService();
    final records =
        await salesStorage.getAvailableRecords(widget.selectedDate!);
    double totalCashSales = 0;

    // الحصول على اسم البائع الحالي من تسجيل الدخول
    final currentSellerName = _sellerNameController.text;

    for (var recordNum in records) {
      final doc =
          await salesStorage.loadSalesDocument(widget.selectedDate!, recordNum);
      if (doc != null) {
        for (var sale in doc.sales) {
          // إظهار فقط سجلات البائع الحالي
          if (sale.sellerName == currentSellerName &&
              sale.cashOrDebt == 'نقدي') {
            totalCashSales += double.tryParse(sale.total) ?? 0;
          }
        }
      }
    }

    setState(() {
      _cashSalesController.text = totalCashSales.toStringAsFixed(2);
    });
  }

  Future<void> _loadBoxData() async {
    if (widget.selectedDate == null) return;

    final boxStorage = BoxStorageService();
    final records = await boxStorage.getAvailableRecords(widget.selectedDate!);

    double totalReceived = 0;
    double totalPaid = 0;

    // الحصول على اسم البائع الحالي
    final currentSellerName = _sellerNameController.text;

    for (var recordNum in records) {
      final doc =
          await boxStorage.loadBoxDocument(widget.selectedDate!, recordNum);
      if (doc != null) {
        for (var transaction in doc.transactions) {
          // إظهار فقط سجلات البائع الحالي
          if (transaction.sellerName == currentSellerName) {
            totalReceived += double.tryParse(transaction.received) ?? 0;
            totalPaid += double.tryParse(transaction.paid) ?? 0;
          }
        }
      }
    }

    setState(() {
      _receiptsController.text = totalReceived.toStringAsFixed(2);
      _paymentsController.text = totalPaid.toStringAsFixed(2);
    });
  }

  Future<void> _loadReceiptData() async {
    if (widget.selectedDate == null) return;

    final receiptStorage = ReceiptStorageService();
    final currentSellerName = _sellerNameController.text;

    // طريقة أفضل: اجمع فقط سجلات البائع الحالي
    double totalPaymentFromReceipt = 0;
    double totalLoadFromReceipt = 0;

    final records =
        await receiptStorage.getAvailableRecords(widget.selectedDate!);

    for (var recordNum in records) {
      final doc = await receiptStorage.loadReceiptDocument(
          widget.selectedDate!, recordNum);

      if (doc != null && doc.sellerName == currentSellerName) {
        totalPaymentFromReceipt +=
            double.tryParse(doc.totals['totalPayment'] ?? '0') ?? 0;
        totalLoadFromReceipt +=
            double.tryParse(doc.totals['totalLoad'] ?? '0') ?? 0;
      }
    }

    final double currentPaymentsFromBox =
        double.tryParse(_paymentsController.text) ?? 0;
    final double totalPayments =
        currentPaymentsFromBox + totalPaymentFromReceipt + totalLoadFromReceipt;

    setState(() {
      _paymentsController.text = totalPayments.toStringAsFixed(2);
    });
  }

  Future<void> _checkIfLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('isLoggedIn') ?? false;
    final savedSellerName = prefs.getString('currentSellerName') ?? '';

    if (loggedIn && savedSellerName.isNotEmpty) {
      setState(() {
        _isLoggedIn = true;
        _sellerNameController.text = savedSellerName;
      });

      // إذا تم تسجيل الدخول، تحميل البيانات
      if (widget.selectedDate != null) {
        _loadCashPurchases();
        _loadCashSales();
        _loadBoxData();
        _loadReceiptData();
      }
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
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

          // بعد تسجيل الدخول، تحميل البيانات
          if (widget.selectedDate != null) {
            _loadCashPurchases();
            _loadCashSales();
            _loadBoxData();
            _loadReceiptData();
            _loadCollectedAmount(); // <-- إضافة هذا السطر
          }
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
      _errorMessage = null;
      _cashSalesController.text = '0.00';
      _cashPurchasesController.text = '0.00';
      _receiptsController.text = '0.00';
      _paymentsController.text = '0.00';
      _collectedController.text = '';
      _yield = 0;
      _status = '';
    });
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
          const Text(
            'تسجيل الدخول',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
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
                      horizontal: 60,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'دخول',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String hint,
    bool obscure, {
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    bool isLastInRow = false,
    String? errorText,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textAlign: TextAlign.center,
      focusNode: focusNode,
      textDirection: TextDirection.rtl,
      style: const TextStyle(color: Colors.white),
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
        if (value == null || value.isEmpty) return 'هذا الحقل مطلوب';
        return null;
      },
      onFieldSubmitted: (_) {
        if (isLastInRow) {
          _login();
        } else if (nextFocusNode != null) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        }
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
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (widget.selectedDate != null) {
                _loadCashPurchases();
                _loadCashSales();
                _loadBoxData();
                _loadReceiptData();
              }
            },
            tooltip: 'تحديث البيانات',
          ),
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
                          child: _buildReadOnlyField(
                            'مبيعات نقدية',
                            _cashSalesController,
                            icon: Icons.shopping_cart,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildReadOnlyField(
                            'مقبوضات',
                            _receiptsController,
                            icon: Icons.account_balance_wallet,
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
                          child: _buildReadOnlyField(
                            'مشتريات نقدية',
                            _cashPurchasesController,
                            icon: Icons.shopping_bag,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildReadOnlyField(
                            'مدفوعات',
                            _paymentsController,
                            icon: Icons.payment,
                            infoText: 'مدفوعات الصندوق + دفعة وحمولة الاستلام',
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
                          child: _buildYieldResultField(
                            'الغلة',
                            TextEditingController(
                                text: _yield.toStringAsFixed(2)),
                            icon: Icons.calculate,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildYieldInputField(
                            'المقبوض منه',
                            _collectedController,
                            icon: Icons.money,
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
                      child: Column(
                        children: [
                          Text(
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
                          if (_status.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                _status.contains('زيادة')
                                    ? 'المقبوض أكبر من الغلة الحقيقية'
                                    : 'المقبوض أقل من الغلة الحقيقية',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                    /*
                   // معلومات عن الحقول
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoItem(
                            'مبيعات نقدية',
                            'إجمالي المبيعات النقدية من شاشة المبيعات (لا تشمل المبيعات بالدين)',
                          ),
                          _buildInfoItem(
                            'مشتريات نقدية',
                            'إجمالي المشتريات النقدية من شاشة المشتريات',
                          ),
                          _buildInfoItem(
                            'مقبوضات',
                            'إجمالي المقبوضات من شاشة الصندوق',
                          ),
                          _buildInfoItem(
                            'مدفوعات',
                            'إجمالي المدفوعات من شاشة الصندوق + إجمالي الدفعة والحمولة من شاشة الاستلام',
                          ),
                        ],
                      ),
                    ),
*/
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

/*
  Widget _buildInfoItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.start,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
*/
  Widget _buildReadOnlyField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    String? infoText,
  }) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (infoText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0, right: 8.0),
              child: Text(
                infoText,
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          TextField(
            controller: controller,
            readOnly: true,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.teal[700],
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
              prefixIcon: icon != null
                  ? Icon(
                      icon,
                      size: 18,
                      color: Colors.teal[600],
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey[100],
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
        ],
      ),
    );
  }

  Widget _buildYieldResultField(
    String label,
    TextEditingController controller, {
    IconData? icon,
  }) {
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
        readOnly: true,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.teal[900],
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.bold,
          ),
          prefixIcon: icon != null
              ? Icon(
                  icon,
                  size: 18,
                  color: Colors.teal[700],
                )
              : null,
          filled: true,
          fillColor: Colors.teal[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.teal[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.teal[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.teal[500]!, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildYieldInputField(
    String label,
    TextEditingController controller, {
    IconData? icon,
  }) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0, right: 8.0),
            child: Text(
              'سيتم حفظ القيمة تلقائياً عند التعديل',
              style: TextStyle(
                fontSize: 9,
                color: Colors.teal[600],
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
              prefixIcon: icon != null
                  ? Icon(
                      icon,
                      size: 18,
                      color: Colors.teal[600],
                    )
                  : null,
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
            onChanged: (value) {
              setState(() {
                _calculateYield();
              });
            },
            onTapOutside: (_) {
              // حفظ القيمة عند النقر خارج الحقل
              if (_isLoggedIn) {
                _saveCollectedAmount();
              }
            },
            onEditingComplete: () {
              // حفظ القيمة عند الضغط على Enter
              if (_isLoggedIn) {
                _saveCollectedAmount();
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // حفظ قيمة المقبوض منه عند تدمير الشاشة
    if (_isLoggedIn && _collectedController.text.isNotEmpty) {
      _saveCollectedAmount();
    }

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
              child: _buildLoginScreen(),
            ),
          ),
        ),
      );
    } else {
      return _buildYieldScreen();
    }
  }

  Future<void> _saveCollectedAmount() async {
    if (!_isLoggedIn) return;

    final prefs = await SharedPreferences.getInstance();
    final collectedValue = _collectedController.text.trim();
    final currentSellerName = _sellerNameController.text.trim();
    final dateKey = widget.selectedDate ?? 'default';

    if (currentSellerName.isNotEmpty) {
      // إنشاء مفتاح فريد يجمع بين البائع والتاريخ
      final uniqueKey = 'collected_${currentSellerName}_$dateKey';

      if (collectedValue.isEmpty) {
        // إذا كانت القيمة فارغة، احفظ "0.00"
        await prefs.setString(uniqueKey, '0.00');
      } else {
        // تأكد من تنسيق الرقم بشكل صحيح
        final doubleValue = double.tryParse(collectedValue);
        final formattedValue = doubleValue?.toStringAsFixed(2) ?? '0.00';
        await prefs.setString(uniqueKey, formattedValue);
      }

      // تحديث واجهة المستخدم
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'تم حفظ قيمة المقبوض منه: ${collectedValue.isNotEmpty ? collectedValue : "0.00"}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _loadCollectedAmount() async {
    // انتظار تسجيل الدخول أولاً
    if (!_isLoggedIn) return;

    final prefs = await SharedPreferences.getInstance();
    final currentSellerName = _sellerNameController.text.trim();
    final dateKey = widget.selectedDate ?? 'default';

    if (currentSellerName.isNotEmpty) {
      final uniqueKey = 'collected_${currentSellerName}_$dateKey';
      final savedValue = prefs.getString(uniqueKey);

      if (savedValue != null && savedValue.isNotEmpty && mounted) {
        setState(() {
          _collectedController.text = savedValue;
          // إعادة حساب الغلة بعد تحميل القيمة
          _calculateYield();
        });
      }
    }
  }
}
