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
  String dayName = '';

  // قائمة لتخزين صفوف الجدول
  List<TableRow> tableRows = [];
  List<List<TextEditingController>> rowControllers = [];
  List<List<FocusNode>> rowFocusNodes = [];
  List<String> cashOrDebtValues = []; // تخزين قيمة "نقدي او دين" لكل صف
  List<String> emptiesValues = []; // تخزين قيمة "الفوارغ" لكل صف

  // متحكمات صف المجموع
  late TextEditingController totalCountController;
  late TextEditingController totalBaseController;
  late TextEditingController totalNetController;
  late TextEditingController totalGrandController;
  late TextEditingController totalPriceController;

  // قوائم الخيارات
  final List<String> cashOrDebtOptions = ['نقدي', 'دين'];
  final List<String> emptiesOptions = ['مع فوارغ', 'بدون فوارغ'];

  @override
  void initState() {
    super.initState();
    // استخراج اسم اليوم من التاريخ المحدد
    _extractDayName(widget.selectedDate);
    // تعيين التاريخ المحدد
    date = widget.selectedDate;
    // تعيين الرقم الافتراضي
    serialNumber = '1';

    // تهيئة المتحكمات الخاصة بصف المجموع
    totalCountController = TextEditingController();
    totalBaseController = TextEditingController();
    totalNetController = TextEditingController();
    totalGrandController = TextEditingController();
    totalPriceController = TextEditingController();

    _resetTotalValues();

    // إضافة الصف الأول عند التهيئة
    _addNewRow();
  }

  @override
  void dispose() {
    // تنظيف جميع المتحكمين
    for (var row in rowControllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }

    // تنظيف جميع FocusNodes
    for (var row in rowFocusNodes) {
      for (var node in row) {
        node.dispose();
      }
    }

    // تنظيف متحكمات المجموع
    totalCountController.dispose();
    totalBaseController.dispose();
    totalNetController.dispose();
    totalGrandController.dispose();
    totalPriceController.dispose();

    super.dispose();
  }

  // إعادة تعيين قيم المجموع
  void _resetTotalValues() {
    totalCountController.text = '0';
    totalBaseController.text = '0.00';
    totalNetController.text = '0.00';
    totalGrandController.text = '0.00';
    totalPriceController.text = '0.00';
  }

  // دالة لإضافة صف جديد
  void _addNewRow() {
    setState(() {
      // إنشاء متحكمين للصف الجديد (11 حقل)
      List<TextEditingController> newControllers =
          List.generate(11, (index) => TextEditingController());

      // إنشاء FocusNodes للصف الجديد
      List<FocusNode> newFocusNodes = List.generate(11, (index) => FocusNode());

      // تعيين المسلسل تلقائياً
      newControllers[0].text = (rowControllers.length + 1).toString();
/*
      // إضافة مستمع للحقل الأخير (الفوارغ) لإضافة صف جديد عند الضغط على Enter
      newFocusNodes[10].addListener(() {
        if (newFocusNodes[10].hasFocus) {
          _setupEnterKeyListener(newFocusNodes[10]);
        }
      });

      // إضافة مستمع لحقل السعر (المؤشر 7) لإضافة صف جديد عند الضغط على Enter
      newFocusNodes[7].addListener(() {
        if (newFocusNodes[7].hasFocus) {
          _setupEnterKeyListener(newFocusNodes[7]);
        }
      });
*/
      // إضافة المستمعين لحقول الحساب (العدد، العبوة، القائم، السعر)
      newControllers[3].addListener(() {
        _calculateRowValues(rowControllers.length);
        _calculateAllTotals();
      });
      newControllers[4].addListener(() {
        _calculateRowValues(rowControllers.length);
        _calculateAllTotals();
      });
      newControllers[5].addListener(() {
        _calculateRowValues(rowControllers.length);
        _calculateAllTotals();
      });
      newControllers[7].addListener(() {
        _calculateRowValues(rowControllers.length);
        _calculateAllTotals();
      });

      rowControllers.add(newControllers);
      rowFocusNodes.add(newFocusNodes);
      cashOrDebtValues.add(''); // قيمة افتراضية
      emptiesValues.add(''); // قيمة افتراضية

      // إعادة بناء صفوف الجدول
      _buildTableRows();
    });
  }

  // دالة لحساب قيم الصف
  void _calculateRowValues(int rowIndex) {
    if (rowIndex >= rowControllers.length) return;

    final controllers = rowControllers[rowIndex];

    setState(() {
      try {
        double count = double.tryParse(controllers[3].text) ?? 0; // العدد
        double price = double.tryParse(controllers[7].text) ?? 0; // السعر

        // حساب الإجمالي: العدد × السعر
        double total = count * price;
        controllers[8].text = total.toStringAsFixed(2); // الإجمالي
      } catch (e) {
        controllers[6].text = '';
        controllers[8].text = '';
      }
    });
  }

  // دالة لحساب جميع المجاميع
  void _calculateAllTotals() {
    setState(() {
      double totalCount = 0;
      double totalBase = 0;
      double totalNet = 0;
      double totalGrand = 0;
      double totalPrice = 0;

      for (var controllers in rowControllers) {
        try {
          // مجموع العدد
          double count = double.tryParse(controllers[3].text) ?? 0;
          totalCount += count;

          // مجموع القائم
          double base = double.tryParse(controllers[5].text) ?? 0;
          totalBase += base;

          // مجموع الصافي
          double net = double.tryParse(controllers[6].text) ?? 0;
          totalNet += net;

          // مجموع الإجمالي
          double total = double.tryParse(controllers[8].text) ?? 0;
          totalGrand += total;

          double price = double.tryParse(controllers[7].text) ?? 0;
          totalPrice += price;
        } catch (e) {
          // تجاهل الأخطاء
        }
      }

      // تحديث قيم المتحكمات
      totalCountController.text = totalCount.toStringAsFixed(0);
      totalBaseController.text = totalBase.toStringAsFixed(2);
      totalNetController.text = totalNet.toStringAsFixed(2);
      totalGrandController.text = totalGrand.toStringAsFixed(2);
      totalPriceController.text = totalPrice.toStringAsFixed(2);
    });
  }

  // دالة لبناء صفوف الجدول
  void _buildTableRows() {
    List<TableRow> newTableRows = [];

    // صف العناوين
    newTableRows.add(
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
    );

    // إضافة صفوف البيانات
    for (int i = 0; i < rowControllers.length; i++) {
      newTableRows.add(
        TableRow(
          children: [
            _buildTableCell(rowControllers[i][0], rowFocusNodes[i][0], false, i,
                0), // مسلسل
            _buildTableCell(rowControllers[i][1], rowFocusNodes[i][1], false, i,
                1), // المادة
            _buildTableCell(rowControllers[i][2], rowFocusNodes[i][2], false, i,
                2), // العائدية
            _buildTableCell(
                rowControllers[i][3], rowFocusNodes[i][3], true, i, 3), // العدد
            _buildTableCell(rowControllers[i][4], rowFocusNodes[i][4], true, i,
                4), // العبوة
            _buildTableCell(rowControllers[i][5], rowFocusNodes[i][5], true, i,
                5), // القائم
            _buildTableCell(rowControllers[i][6], rowFocusNodes[i][6], false, i,
                6), // الصافي
            _buildTableCell(
                rowControllers[i][7], rowFocusNodes[i][7], true, i, 7), // السعر
            _buildTableCell(rowControllers[i][8], rowFocusNodes[i][8], false, i,
                8), // الإجمالي
            _buildCashOrDebtCell(i, 9), // نقدي او دين (المؤشر 9)
            _buildEmptiesCell(i, 10), // الفوارغ (المؤشر 10)
          ],
        ),
      );
    }

    // إضافة صف المجموع فقط إذا كان هناك أكثر من صف
    if (rowControllers.length >= 2) {
      newTableRows.add(
        TableRow(
          decoration: BoxDecoration(
            color: Colors.yellow[50],
          ),
          children: [
            _buildTableHeaderCell('المجموع'),
            _buildTableCell(
                TextEditingController()..text = '', FocusNode(), false, -1, -1),
            _buildTableCell(
                TextEditingController()..text = '', FocusNode(), false, -1, -1),
            _buildTotalCell(totalCountController), // مجموع العدد
            _buildTableCell(
                TextEditingController()..text = '', FocusNode(), false, -1, -1),
            _buildTotalCell(totalBaseController), // مجموع القائم
            _buildTotalCell(totalNetController), // مجموع الصافي
            _buildTotalCell(totalPriceController), // مجموع السعر
            _buildTotalCell(totalGrandController), // مجموع الإجمالي
            _buildTableCell(
                TextEditingController()..text = '', FocusNode(), false, -1, -1),
            _buildTableCell(
                TextEditingController()..text = '', FocusNode(), false, -1, -1),
          ],
        ),
      );
    }

    tableRows = newTableRows;
  }

  Widget _buildTableCell(TextEditingController controller, FocusNode focusNode,
      bool isNumeric, int rowIndex, int colIndex) {
    return Container(
      padding: const EdgeInsets.all(1),
      constraints: const BoxConstraints(minHeight: 25),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          border: InputBorder.none,
          hintText: '.',
          hintStyle: TextStyle(fontSize: 13),
        ),
        style: const TextStyle(fontSize: 13),
        maxLines: 1,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        textInputAction: TextInputAction.next, // جميع الحقول تستخدم next
        onSubmitted: (value) {
          // في اتجاه RTL (من اليمين لليسار):
          // colIndex = 0 ← أقصى اليمين (المسلسل)
          // colIndex = 10 ← أقصى اليسار (الفوارغ)

          // نريد الانتقال من اليمين لليسار: 0 → 1 → 2 → ... → 10
          // ولكن عند الضغط Enter نريد الانتقال عكس ذلك: 10 ← 9 ← 8 ← ... ← 0

          if (colIndex < 10) {
            // إذا لم نكن في آخر حقل (الفوارغ)، انتقل إلى الحقل التالي (إلى اليسار)
            FocusScope.of(context)
                .requestFocus(rowFocusNodes[rowIndex][colIndex + 1]);
          } else if (colIndex == 10) {
            // إذا كنا في آخر حقل (الفوارغ)، انتقل إلى الصف التالي أو أضف صف جديد
            _addNewRow();
            if (rowControllers.length > 0) {
              final newRowIndex = rowControllers.length - 1;
              FocusScope.of(context).requestFocus(
                  rowFocusNodes[newRowIndex][0]); // المسلسل في الصف الجديد
            }
          }
        },
        onChanged: (value) {
          if (colIndex == 0) {
            // تحديث المسلسل تلقائياً
            for (int i = 0; i < rowControllers.length; i++) {
              rowControllers[i][0].text = (i + 1).toString();
            }
          }

          // إذا كان حقل حسابي (العدد، العبوة، القائم، السعر)
          if (colIndex == 3 ||
              colIndex == 4 ||
              colIndex == 5 ||
              colIndex == 7) {
            _calculateRowValues(rowIndex);
            _calculateAllTotals();
          }
        },
      ),
    );
  }

  // خلية خاصة للمجاميع
  Widget _buildTotalCell(TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.all(1),
      constraints: const BoxConstraints(minHeight: 25),
      decoration: BoxDecoration(
        color: Colors.yellow[100],
      ),
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          border: InputBorder.none,
          hintStyle: TextStyle(fontSize: 13),
        ),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.red[700],
        ),
        maxLines: 1,
        keyboardType: TextInputType.number,
        enabled: false,
        readOnly: true,
      ),
    );
  }

  // خلية خاصة لـ "نقدي او دين"
  Widget _buildCashOrDebtCell(int rowIndex, int colIndex) {
    return Container(
      padding: const EdgeInsets.all(1),
      constraints: const BoxConstraints(minHeight: 25),
      child: InkWell(
        onTap: () {
          _showCashOrDebtDialog(rowIndex);
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(3),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  cashOrDebtValues[rowIndex].isEmpty
                      ? 'اختر'
                      : cashOrDebtValues[rowIndex],
                  style: TextStyle(
                    fontSize: 11,
                    color: cashOrDebtValues[rowIndex].isEmpty
                        ? Colors.grey
                        : Colors.black,
                    fontWeight: cashOrDebtValues[rowIndex].isEmpty
                        ? FontWeight.normal
                        : FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // خلية خاصة لـ "الفوارغ"
  Widget _buildEmptiesCell(int rowIndex, int colIndex) {
    return Container(
      padding: const EdgeInsets.all(1),
      constraints: const BoxConstraints(minHeight: 25),
      child: InkWell(
        onTap: () {
          _showEmptiesDialog(rowIndex);
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(3),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  emptiesValues[rowIndex].isEmpty
                      ? 'اختر'
                      : emptiesValues[rowIndex],
                  style: TextStyle(
                    fontSize: 11,
                    color: emptiesValues[rowIndex].isEmpty
                        ? Colors.grey
                        : Colors.black,
                    fontWeight: emptiesValues[rowIndex].isEmpty
                        ? FontWeight.normal
                        : FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                    // صف المعلومات العلوي
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
                    // المحتوى الرئيسي
                    Container(
                      height: constraints.maxHeight * 0.5,
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildResponsiveButton(
                                  'إنشاء', Colors.blue[700]!),
                              _buildResponsiveButton(
                                  'إضافة', Colors.green[700]!,
                                  onPressed: _addNewRow),
                              _buildResponsiveButton(
                                  'تعديل', Colors.orange[700]!),
                              _buildResponsiveButton('حذف', Colors.purple[700]!,
                                  onPressed: _deleteLastRow),
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
            children: tableRows,
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

  Widget _buildResponsiveButton(String text, Color color,
      {VoidCallback? onPressed}) {
    return Flexible(
      fit: FlexFit.tight,
      child: Container(
        constraints: BoxConstraints(
          minWidth: 50,
          maxWidth: 100,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 1),
        height: 32,
        child: ElevatedButton(
          onPressed: onPressed ??
              () {
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

  // عرض مربع حوار لاختيار "نقدي او دين"
  void _showCashOrDebtDialog(int rowIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('اختر طريقة الدفع'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: cashOrDebtOptions.map((option) {
                return ListTile(
                  title: Text(option),
                  leading: Radio<String>(
                    value: option,
                    groupValue: cashOrDebtValues[rowIndex],
                    onChanged: (String? value) {
                      setState(() {
                        cashOrDebtValues[rowIndex] = value!;
                      });
                      Navigator.of(context).pop();
                      // بعد الاختيار، أعد بناء الجدول للتحديث الفوري
                      _buildTableRows();
                      // انتقل للحقل السابق (إلى اليمين - المؤشر 8)
                      if (rowIndex >= 0) {
                        // توجد 3 خيارات للانتقال:

                        // الخيار 1: الانتقال إلى حقل "الإجمالي" (المؤشر 8)
                        FocusScope.of(context)
                            .requestFocus(rowFocusNodes[rowIndex][8]);
                      }
                    },
                  ),
                  onTap: () {
                    setState(() {
                      cashOrDebtValues[rowIndex] = option;
                    });
                    Navigator.of(context).pop();
                    // بعد الاختيار، أعد بناء الجدول للتحديث الفوري
                    _buildTableRows();
                    // انتقل للحقل السابق (إلى اليمين - المؤشر 8)
                    if (rowIndex >= 0) {
                      FocusScope.of(context)
                          .requestFocus(rowFocusNodes[rowIndex][8]);
                    }
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('إلغاء'),
            ),
          ],
        );
      },
    );
  }

// عرض مربع حوار لاختيار "الفوارغ"
  void _showEmptiesDialog(int rowIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('اختر حالة الفوارغ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: emptiesOptions.map((option) {
                return ListTile(
                  title: Text(option),
                  leading: Radio<String>(
                    value: option,
                    groupValue: emptiesValues[rowIndex],
                    onChanged: (String? value) {
                      setState(() {
                        emptiesValues[rowIndex] = value!;
                      });
                      Navigator.of(context).pop();
                      // بعد اختيار الفوارغ، أضف صف جديد
                      _addRowAfterEmptiesSelection(rowIndex);
                    },
                  ),
                  onTap: () {
                    setState(() {
                      emptiesValues[rowIndex] = option;
                    });
                    Navigator.of(context).pop();
                    // بعد اختيار الفوارغ، أضف صف جديد
                    _addRowAfterEmptiesSelection(rowIndex);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('إلغاء'),
            ),
          ],
        );
      },
    );
  }

  // دالة لحذف آخر صف
  void _deleteLastRow() {
    if (rowControllers.length > 1) {
      setState(() {
        // تنظيف متحكمات الصف الأخير
        for (var controller in rowControllers.last) {
          controller.dispose();
        }

        // تنظيف FocusNodes للصف الأخير
        for (var node in rowFocusNodes.last) {
          node.dispose();
        }

        // إزالة الصف الأخير
        rowControllers.removeLast();
        rowFocusNodes.removeLast();
        cashOrDebtValues.removeLast();
        emptiesValues.removeLast();

        // تحديث المسلسل
        for (int i = 0; i < rowControllers.length; i++) {
          rowControllers[i][0].text = (i + 1).toString();
        }

        // إعادة بناء صفوف الجدول
        _buildTableRows();

        // تحديث جميع المجاميع
        _calculateAllTotals();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف الصف الأخير'),
            backgroundColor: Colors.purple[700],
            duration: const Duration(seconds: 1),
          ),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا يمكن حذف الصف الوحيد'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _extractDayName(String dateString) {
    final days = [
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت'
    ];
    final now = DateTime.now();
    dayName = days[now.weekday % 7];
  }

  void _addRowAfterEmptiesSelection(int rowIndex) {
    // بعد اختيار الفوارغ، إضافة صف جديد
    _addNewRow();

    // نقل التركيز إلى الصف الجديد (الحقل الأول)
    if (rowControllers.length > 0) {
      final newRowIndex = rowControllers.length - 1;
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          FocusScope.of(context).requestFocus(
              rowFocusNodes[newRowIndex][0]); // المسلسل في الصف الجديد
        }
      });
    }
  }
}
