import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../widgets/daily_movement_widget.dart';

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
          ? 'زيادة  الغلة  $difference'
          : 'نقص  الغلة  $difference';
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

        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تسجيل الدخول'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: sellerNameController,
                    decoration: const InputDecoration(labelText: 'اسم البائع'),
                    textInputAction: TextInputAction.next,
                  ),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'كلمة السر'),
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
              TextButton(
                onPressed: () => _validateLogin(sellerNameController.text,
                    passwordController.text, accountsMap),
                child: const Text('تسجيل الدخول'),
              ),
            ],
          ),
        );
      },
    );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('شاشة الغلة',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.teal[600],
        foregroundColor: Colors.white,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'غلة البائع: ${widget.sellerName} ${_yield.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: DailyMovementWidget.buildInputField(
                          'مبيعات نقدية', _cashSalesController),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DailyMovementWidget.buildInputField(
                          'مقبوضات', _receiptsController),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DailyMovementWidget.buildInputField(
                          'مشتريات نقدية', _cashPurchasesController),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DailyMovementWidget.buildInputField(
                          'مدفوعات', _paymentsController),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DailyMovementWidget.buildInputField(
                          'المقبوض منه', _collectedController),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _status,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _status == 'زيادة غلة'
                              ? Colors.green
                              : Colors.red,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DailyMovementWidget.buildResultRow(
                        'الغلة:',
                        _yield.toStringAsFixed(2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
