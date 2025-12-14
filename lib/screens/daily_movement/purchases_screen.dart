import 'package:flutter/material.dart';

class PurchasesScreen extends StatefulWidget {
  final String sellerName;
  final String selectedDate;

  const PurchasesScreen({
    Key? key,
    required this.sellerName,
    required this.selectedDate,
  }) : super(key: key);

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  // بيانات الحقول
  String dayInfo = '';
  String date = '';
  String serialNumber = '';
  String employeeName = '';
  String dayName = ''; // لتخزين اسم اليوم

  // FocusNodes للتحكم في التركيز بين الحقول
  List<FocusNode> focusNodes = List.generate(11, (index) => FocusNode());
  List<TextEditingController> controllers =
      List.generate(11, (index) => TextEditingController());

  @override
  void dispose() {
    // تنظيف FocusNodes عند التدمير
    for (var node in focusNodes) {
      node.dispose();
    }
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // بيانات الجدول
  List<Map<String, String>> tableData = [
    {
      'sequence': '',
      'count': '',
      'period': '',
      'second': '',
      'net': '',
      'price': '',
      'total': '',
      'secondaryOrDebt': '',
      'empty': '',
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('المشتريات',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // استخدام SingleChildScrollView للسماح بالتمرير إذا كانت الشاشة صغيرة
            return SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(12.0),
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // صف المعلومات العلوي (المعلومات المطولة)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'يومية مشتريات رقم /${serialNumber}/ ليوم $dayName تاريخ ${widget.selectedDate} البائع : ${widget.sellerName}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // المحتوى الرئيسي (الحقول والجدول)
                    Container(
                      height: constraints.maxHeight *
                          0.5, // استخدام نسبة من الارتفاع المتاح
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                              ),
                              child: _buildCompactTable(
                                  constraints.maxHeight * 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // الأزرار
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment
                                .spaceBetween, // ← تغيير إلى spaceBetween
                            children: [
                              _buildResponsiveButton(
                                  'إنشاء', Colors.blue[700]!),
                              _buildResponsiveButton(
                                  'إضافة', Colors.green[700]!),
                              _buildResponsiveButton(
                                  'تعديل', Colors.orange[700]!),
                              _buildResponsiveButton(
                                  'حذف', Colors.purple[700]!),
                              _buildResponsiveButton(
                                  'طباعة', Colors.blueGrey[600]!),
                              _buildResponsiveButton('خروج', Colors.red[700]!),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResponsiveButton(String text, Color color) {
    return Flexible(
      // ← استخدم Flexible بدلاً من Expanded
      fit: FlexFit.tight, // ← هذا يجعل الزر يتوسع ليملأ المساحة
      child: Container(
        constraints: BoxConstraints(
          minWidth: 50, // ← حد أدنى للعرض
          maxWidth: 100, // ← حد أقصى للعرض (اختياري)
        ),
        margin: const EdgeInsets.symmetric(horizontal: 1),
        height: 32,
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم الضغط على $text'),
                backgroundColor: color,
                duration: const Duration(seconds: 1),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            elevation: 1,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTable(double maxHeight) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.97,
          height: maxHeight,
          child: Table(
            defaultColumnWidth: const FlexColumnWidth(),
            border: TableBorder.all(color: Colors.grey, width: 0.5),
            children: [
              // صف العناوين
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                ),
                children: [
                  _buildTableHeaderCell('مسلسل'),
                  _buildTableHeaderCell('المادة'),
                  _buildTableHeaderCell('العائدية'),
                  _buildTableHeaderCell('العدد'),
                  _buildTableHeaderCell('العبوة'),
                  _buildTableHeaderCell('القائم'),
                  _buildTableHeaderCell('الصافي'),
                  _buildTableHeaderCell('السعر'),
                  _buildTableHeaderCell('الإجمالي'),
                  _buildTableHeaderCell('نقدي او دين'),
                  _buildTableHeaderCell('الفوارغ'),
                ],
              ),
              // صف البيانات الفارغ - يجب أن يكون 11 خلية
              TableRow(
                children: [
                  _buildTableCell(''),
                  _buildTableCell(''),
                  _buildTableCell(''),
                  _buildTableCell(''),
                  _buildTableCell(''),
                  _buildTableCell(''),
                  _buildTableCell(''),
                  _buildTableCell(''),
                  _buildTableCell(''),
                  _buildTableCell(''), // الخلية العاشرة
                  _buildTableCell(''), // الخلية الحادية عشرة
                ],
              ),
              // صف المجموع - يجب أن يكون 11 خلية
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                ),
                children: [
                  _buildTableHeaderCell('المجموع'),
                  _buildTableCell(''),
                  _buildTableCell(''),
                  _buildTableCell(''),
                  _buildTableCell(''),
                  _buildTableCell(''),
                  _buildTableCell(''),
                  _buildTableCell(''),
                  _buildTableCell(''),
                  _buildTableCell(''), // الخلية العاشرة
                  _buildTableCell(''), // الخلية الحادية عشرة
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.all(2),
      constraints: const BoxConstraints(minHeight: 30),
      child: Center(
        // ← أضف Center هنا
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Container(
      padding: const EdgeInsets.all(1),
      constraints: const BoxConstraints(minHeight: 25),
      child: TextField(
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          border: InputBorder.none,
          hintText: '.',
          hintStyle: TextStyle(fontSize: 13),
        ),
        style: const TextStyle(fontSize: 13),
        maxLines: 1,
        onChanged: (value) {
          // يمكنك حفظ القيمة في مكان مناسب
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // استخراج اسم اليوم من التاريخ المحدد
    _extractDayName(widget.selectedDate);
    // تعيين التاريخ المحدد
    date = widget.selectedDate;
    // تعيين الرقم الافتراضي
    serialNumber = '1';
  }

  void _extractDayName(String dateString) {
    // يمكنك استخدام مكتبة مثل intl للتحويل الصحيح
    // هنا مثال بسيط
    final days = [
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت'
    ];
    // يمكنك استبدال هذا بتحويل حقيقي من التاريخ
    // مؤقتاً سنستخدم تاريخ اليوم الحقيقي
    final now = DateTime.now();
    dayName = days[now.weekday % 7]; // للحصول على اليوم بالعربية
  }
}
