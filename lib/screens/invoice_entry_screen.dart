import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InvoiceEntryScreen extends StatefulWidget {
  const InvoiceEntryScreen({super.key});

  @override
  State<InvoiceEntryScreen> createState() => _InvoiceEntryScreenState();
}

class _InvoiceEntryScreenState extends State<InvoiceEntryScreen> {
  // controllers للحقول النصية
  final _customerNameController = TextEditingController();
  final _itemCountController = TextEditingController();
  final _itemPriceController = TextEditingController();
  final _paidAmountController = TextEditingController();

  // متغيرات الحالة
  double _totalAmount = 0.0;
  double _netAmount = 0.0;

  // دالة لحساب المجموع والصافي تلقائياً
  void _calculateTotals() {
    final itemCount = double.tryParse(_itemCountController.text) ?? 0.0;
    final itemPrice = double.tryParse(_itemPriceController.text) ?? 0.0;
    final paidAmount = double.tryParse(_paidAmountController.text) ?? 0.0;

    setState(() {
      _totalAmount = itemCount * itemPrice;
      _netAmount = _totalAmount - paidAmount;
    });
  }

  // دالة لحفظ الفاتورة (واجهة فارغة حالياً)
  void _saveInvoice() {
    // هنا يمكنك إضافة منطق الحفظ
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ الفاتورة بنجاح!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // دالة لطباعة الفاتورة (واجهة فارغة حالياً)
  void _printInvoice() {
    // هنا يمكنك إضافة منطق الطباعة
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري إعداد الطباعة...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // إضافة مستمعين لحقول العدد والسعر والمدفوع لتحديث الحسابات عند التغيير
    _itemCountController.addListener(_calculateTotals);
    _itemPriceController.addListener(_calculateTotals);
    _paidAmountController.addListener(_calculateTotals);
  }

  @override
  void dispose() {
    // تنظيف الـ controllers عند إتلاف الويدجت
    _customerNameController.dispose();
    _itemCountController.dispose();
    _itemPriceController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  // دالة مساعدة لبناء حقول الإدخال
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black87),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // التحقق مما إذا كانت الشاشة واسعة (كمبيوتر) أو ضيقة (هاتف)
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // لون خلفية فاتح
      appBar: AppBar(
        title: const Text(
          'فاتورة جديدة',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32), // لون أخضر داكن
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 4,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            // تحديد عرض أقصى للواجهة على الشاشات الواسعة
            constraints:
                BoxConstraints(maxWidth: isWideScreen ? 800 : double.infinity),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- قسم معلومات العميل ---
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9), // لون أخضر فاتح جداً
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'معلومات العميل',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'اسم العميل',
                              controller: _customerNameController,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- قسم تفاصيل الفاتورة ---
                      const Text(
                        'تفاصيل الفاتورة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'عدد المواد',
                        controller: _itemCountController,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                      ),
                      _buildTextField(
                        label: 'سعر المادة الواحدة',
                        controller: _itemPriceController,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                      ),
                      _buildTextField(
                        label: 'المدفوع',
                        controller: _paidAmountController,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 24),

                      // --- قسم الحسابات ---
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9), // نفس لون قسم العميل
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Column(
                          children: [
                            _buildTotalRow('الإجمالي:',
                                '${_totalAmount.toStringAsFixed(2)} ل.س'),
                            const Divider(color: Colors.grey),
                            _buildTotalRow('الصافي:',
                                '${_netAmount.toStringAsFixed(2)} ل.س'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // --- قسم الأزرار ---
                      isWideScreen
                          ? Row(
                              children: [
                                Expanded(
                                    child: _buildActionButton(
                                        'حفظ', _saveInvoice, Colors.green)),
                                const SizedBox(width: 16),
                                Expanded(
                                    child: _buildActionButton(
                                        'طباعة', _printInvoice, Colors.blue)),
                              ],
                            )
                          : Column(
                              children: [
                                _buildActionButton(
                                    'حفظ', _saveInvoice, Colors.green),
                                const SizedBox(height: 16),
                                _buildActionButton(
                                    'طباعة', _printInvoice, Colors.blue),
                              ],
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // دالة لبناء صفوف الحسابات (الإجمالي والصافي)
  Widget _buildTotalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          Text(
            value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // دالة لبناء الأزرار الرئيسية
  Widget _buildActionButton(String text, VoidCallback onPressed, Color color) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
