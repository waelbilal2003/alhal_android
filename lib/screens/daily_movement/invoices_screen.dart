import 'package:flutter/material.dart';
import '../../models/invoice_model.dart';
import '../../services/invoices_service.dart';

class InvoicesScreen extends StatefulWidget {
  final String selectedDate;
  final String storeName;
  final String customerName;

  const InvoicesScreen({
    Key? key,
    required this.selectedDate,
    required this.storeName,
    required this.customerName,
  }) : super(key: key);

  @override
  _InvoicesScreenState createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final InvoicesService _invoicesService = InvoicesService();
  late Future<List<InvoiceItem>> _invoiceDataFuture;

  @override
  void initState() {
    super.initState();
    _invoiceDataFuture = _invoicesService.getInvoicesForCustomer(
        widget.selectedDate, widget.customerName);
  }

  Widget _buildHeaderCell(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 13, // تعديل حجم الخط ليتناسب
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'فاتورة الزبون ${widget.customerName}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20.0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'بتاريخ ${widget.selectedDate} لمحل ${widget.storeName}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: FutureBuilder<List<InvoiceItem>>(
          future: _invoiceDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'لا توجد فواتير دين لهذا الزبون في اليوم المحدد',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }

            final invoiceItems = snapshot.data!;
            double grandTotal = 0;
            for (var item in invoiceItems) {
              grandTotal += double.tryParse(item.total) ?? 0;
            }

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  // 1. رأس الجدول
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 4.0),
                    decoration: BoxDecoration(
                        color: Colors.indigo.shade400,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                        border: Border.all(color: Colors.indigo.shade200)),
                    child: Row(
                      children: [
                        _buildHeaderCell('ت', 1),
                        _buildHeaderCell('المادة', 4),
                        _buildHeaderCell('العدد', 2),
                        _buildHeaderCell('العبوة', 3),
                        // --- الإضافة هنا ---
                        _buildHeaderCell('القائم', 2),
                        // --- نهاية الإضافة ---
                        _buildHeaderCell('الصافي', 2),
                        _buildHeaderCell('السعر', 2),
                        _buildHeaderCell('الإجمالي', 3),
                        _buildHeaderCell('فوارغ', 3),
                      ],
                    ),
                  ),

                  // 2. قائمة البيانات
                  Expanded(
                    child: ListView.builder(
                      itemCount: invoiceItems.length,
                      itemBuilder: (context, index) {
                        final item = invoiceItems[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 4.0),
                          decoration: BoxDecoration(
                            color: index.isEven
                                ? Colors.white
                                : Colors.indigo.shade50,
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade300),
                              left: BorderSide(color: Colors.grey.shade300),
                              right: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildDataCell(item.serialNumber, 1),
                              _buildDataCell(item.material, 4),
                              _buildDataCell(item.count, 2),
                              _buildDataCell(item.packaging, 3),
                              // --- الإضافة هنا ---
                              _buildDataCell(item.standing, 2),
                              // --- نهاية الإضافة ---
                              _buildDataCell(item.net, 2),
                              _buildDataCell(item.price, 2),
                              _buildDataCell(
                                item.total,
                                3,
                                color: Colors.indigo.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                              _buildDataCell(item.empties, 3),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // 3. المجموع النهائي
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    margin: const EdgeInsets.only(top: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade800,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'المجموع ${grandTotal.toStringAsFixed(2)} ليرة سورية فقط لا غير .',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}