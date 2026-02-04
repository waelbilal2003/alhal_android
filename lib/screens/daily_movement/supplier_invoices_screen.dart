import 'package:flutter/material.dart';
import '../../services/invoices_service.dart';

class SupplierInvoicesScreen extends StatefulWidget {
  final String selectedDate;
  final String storeName;
  final String supplierName;

  const SupplierInvoicesScreen({
    Key? key,
    required this.selectedDate,
    required this.storeName,
    required this.supplierName,
  }) : super(key: key);

  @override
  _SupplierInvoicesScreenState createState() => _SupplierInvoicesScreenState();
}

class _SupplierInvoicesScreenState extends State<SupplierInvoicesScreen> {
  final InvoicesService _invoicesService = InvoicesService();
  late Future<SupplierReportData> _reportDataFuture;

  @override
  void initState() {
    super.initState();
    _reportDataFuture = _invoicesService.getSupplierReport(
        widget.selectedDate, widget.supplierName);
  }

  // دوال مساعدة لبناء الخلايا
  Widget _buildHeaderCell(String text, int flex, {Color color = Colors.white}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, int flex,
      {Color color = Colors.black87,
      FontWeight fontWeight = FontWeight.normal}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontWeight: fontWeight,
          fontSize: 12,
        ),
      ),
    );
  }

  // بناء قسم العنوان
  Widget _buildSectionTitle(String title, Color bgColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(top: 16, bottom: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تقرير المورد ${widget.supplierName}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20.0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'بتاريخ ${widget.selectedDate}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: FutureBuilder<SupplierReportData>(
          future: _reportDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return const Center(child: Text('لا توجد بيانات'));
            }

            final data = snapshot.data!;
            final bool hasSales = data.sales.isNotEmpty;
            final bool hasReceipts = data.receipts.isNotEmpty;
            final bool hasSummary = data.summary.isNotEmpty;

            if (!hasSales && !hasReceipts && !hasSummary) {
              return const Center(
                child: Text(
                  'لا توجد حركات لهذا المورد في اليوم المحدد',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  // --- جدول المبيعات (نفس فواتير الزبائن) ---
                  if (hasSales) ...[
                    _buildSectionTitle(
                        'جدول المبيعات (حسب العائدية)', Colors.indigo),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.indigo.shade200),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        children: [
                          // رأس الجدول
                          Container(
                            color: Colors.indigo.shade400,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                _buildHeaderCell('ت', 1),
                                _buildHeaderCell('المادة', 4),
                                _buildHeaderCell('العدد', 2),
                                _buildHeaderCell('العبوة', 3),
                                _buildHeaderCell('القائم', 2),
                                _buildHeaderCell('الصافي', 2),
                                _buildHeaderCell('السعر', 2),
                                _buildHeaderCell('الإجمالي', 3),
                                _buildHeaderCell('الزبون',
                                    3), // أضفنا الزبون هنا لتمييز البيع
                              ],
                            ),
                          ),
                          // البيانات
                          ...data.sales.map((item) => Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border(
                                      bottom: BorderSide(
                                          color: Colors.grey.shade300)),
                                ),
                                child: Row(
                                  children: [
                                    _buildDataCell(item.serialNumber, 1),
                                    _buildDataCell(item.material, 4),
                                    _buildDataCell(item.count, 2),
                                    _buildDataCell(item.packaging, 3),
                                    _buildDataCell(item.standing, 2),
                                    _buildDataCell(item.net, 2),
                                    _buildDataCell(item.price, 2),
                                    _buildDataCell(item.total, 3,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo),
                                    _buildDataCell(item.customerName ?? '-', 3),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],

                  // --- جدول الاستلام (بدون العائدية) ---
                  if (hasReceipts) ...[
                    _buildSectionTitle('جدول الاستلام', Colors.green[700]!),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green.shade200),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        children: [
                          // رأس الجدول
                          Container(
                            color: Colors.green.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                _buildHeaderCell('ت', 1),
                                _buildHeaderCell('المادة', 4),
                                _buildHeaderCell('العدد', 2),
                                _buildHeaderCell('العبوة', 3),
                                _buildHeaderCell('القائم', 2),
                                _buildHeaderCell('الدفعة', 2),
                                _buildHeaderCell('الحمولة', 2),
                                // تم إخفاء العائدية
                              ],
                            ),
                          ),
                          // البيانات
                          ...data.receipts.map((item) => Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border(
                                      bottom: BorderSide(
                                          color: Colors.grey.shade300)),
                                ),
                                child: Row(
                                  children: [
                                    _buildDataCell(item.serialNumber, 1),
                                    _buildDataCell(item.material, 4),
                                    _buildDataCell(item.count, 2),
                                    _buildDataCell(item.packaging, 3),
                                    _buildDataCell(item.standing, 2),
                                    _buildDataCell(item.payment, 2),
                                    _buildDataCell(item.load, 2),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],

                  // --- جدول المقارنة (الاستلام vs المبيعات) ---
                  if (hasSummary) ...[
                    _buildSectionTitle(
                        'مقارنة الحركة (استلام - مبيعات)', Colors.orange[800]!),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange.shade200),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        children: [
                          // رأس الجدول
                          Container(
                            color: Colors.orange.shade300,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                _buildHeaderCell('المادة', 4,
                                    color: Colors.black87),
                                _buildHeaderCell('وارد (استلام)', 2,
                                    color: Colors.black87),
                                _buildHeaderCell('صادر (مبيعات)', 2,
                                    color: Colors.black87),
                                _buildHeaderCell('البايت', 2,
                                    color: Colors.black87),
                              ],
                            ),
                          ),
                          // البيانات
                          ...data.summary.map((item) => Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border(
                                      bottom: BorderSide(
                                          color: Colors.grey.shade300)),
                                ),
                                child: Row(
                                  children: [
                                    _buildDataCell(item.material, 4),
                                    _buildDataCell(
                                        item.receiptCount.toStringAsFixed(0),
                                        2),
                                    _buildDataCell(
                                        item.salesCount.toStringAsFixed(0), 2),
                                    _buildDataCell(
                                      item.balance.toStringAsFixed(0),
                                      2,
                                      fontWeight: FontWeight.bold,
                                      color: item.balance >= 0
                                          ? Colors.green[800]!
                                          : Colors.red[800]!,
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
