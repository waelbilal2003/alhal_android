import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// أضف هذا الكود في بداية ملف purchases_screen.dart (قبل تعريف الـ class)
class PositiveDecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // التحقق من أن النص يحتوي فقط على أرقام ونقطة عشرية
    final regex = RegExp(r'^[0-9]*\.?[0-9]*$');
    if (!regex.hasMatch(newValue.text)) {
      return oldValue;
    }

    // التحقق من وجود نقطة عشرية واحدة فقط
    final decimalCount = '.'.allMatches(newValue.text).length;
    if (decimalCount > 1) {
      return oldValue;
    }

    // منع الأرقام السالبة
    if (newValue.text.contains('-')) {
      return oldValue;
    }

    return newValue;
  }
}

// كلاس لتثبيت رأس الجدول
class _StickyTableHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyTableHeaderDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => 32.0; // ارتفاع رأس الجدول

  @override
  double get minExtent => 32.0;

  @override
  bool shouldRebuild(_StickyTableHeaderDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}

class PurchasesScreen extends StatefulWidget {
  final String sellerName;
  final String selectedDate;
  final String storeName;

  const PurchasesScreen({
    Key? key,
    required this.sellerName,
    required this.selectedDate,
    required this.storeName,
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

  // قوائم الخيارات
  final List<String> cashOrDebtOptions = ['نقدي', 'دين'];
  final List<String> emptiesOptions = ['مع فوارغ', 'بدون فوارغ'];

  // متحكمات للتمرير
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
 

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

    _resetTotalValues();

    // إضافة الصف الأول عند التهيئة
    _addNewRow();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (rowFocusNodes.isNotEmpty && rowFocusNodes[0].length > 1) {
        FocusScope.of(context).requestFocus(rowFocusNodes[0][1]);
      }
    });
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

    // تنظيف متحكمات التمرير
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();

    super.dispose();
  }

  // إعادة تعيين قيم المجموع
  void _resetTotalValues() {
    totalCountController.text = '0';
    totalBaseController.text = '0.00';
    totalNetController.text = '0.00';
    totalGrandController.text = '0.00';
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

      // إضافة المستمعين لحقول الحساب (العدد، العبوة، القائم، الصافي، السعر)
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
      // ===== تم التعديل: إضافة مستمع لحقل "الصافي" =====
      newControllers[6].addListener(() {
        _calculateRowValues(rowControllers.length);
        _calculateAllTotals();
      });
      // =================================================
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
        // تأكد من أن القيم غير سالبة
        double count =
            (double.tryParse(controllers[3].text) ?? 0).abs(); // العدد
        double net =
            (double.tryParse(controllers[6].text) ?? 0).abs(); // الصافي
        double price =
            (double.tryParse(controllers[7].text) ?? 0).abs(); // السعر

        // تطبيق القاعدة الجديدة:
        // إذا كان الصافي > 0، استخدم الصافي، وإلا استخدم العدد
        double baseValue = net > 0 ? net : count;

        // حساب الإجمالي: القيمة المحددة × السعر
        double total = baseValue * price;
        controllers[8].text = total.toStringAsFixed(2); // الإجمالي
      } catch (e) {
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
        } catch (e) {
          // تجاهل الأخطاء
        }
      }

      // تحديث قيم المتحكمات
      totalCountController.text = totalCount.toStringAsFixed(0);
      totalBaseController.text = totalBase.toStringAsFixed(2);
      totalNetController.text = totalNet.toStringAsFixed(2);
      totalGrandController.text = totalGrand.toStringAsFixed(2);
    });
  }

  // دالة لبناء صفوف الجدول
  void _buildTableRows() {
    setState(() {
      // سيتم إعادة بناء الواجهة تلقائياً
    });
  }

  // بناء رأس الجدول المنفصل
  Widget _buildTableHeader() {
    return Table(
      defaultColumnWidth: const FlexColumnWidth(),
      border: TableBorder.all(color: Colors.grey, width: 0.5),
      children: [
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
      ],
    );
  }

  // بناء محتوى الجدول (بدون الرأس)
  Widget _buildTableContent() {
    List<TableRow> contentRows = [];

    // إضافة صفوف البيانات فقط (بدون عنوان)
    for (int i = 0; i < rowControllers.length; i++) {
      contentRows.add(
        TableRow(
          children: [
            _buildTableCell(
                rowControllers[i][0], rowFocusNodes[i][0], false, i, 0),
            _buildTableCell(
                rowControllers[i][1], rowFocusNodes[i][1], false, i, 1),
            _buildTableCell(
                rowControllers[i][2], rowFocusNodes[i][2], false, i, 2),
            _buildTableCell(
                rowControllers[i][3], rowFocusNodes[i][3], true, i, 3),
            _buildTableCell(
                rowControllers[i][4], rowFocusNodes[i][4], false, i, 4),
            _buildTableCell(
                rowControllers[i][5], rowFocusNodes[i][5], true, i, 5),
            _buildTableCell(
                rowControllers[i][6], rowFocusNodes[i][6], true, i, 6),
            _buildTableCell(
                rowControllers[i][7], rowFocusNodes[i][7], true, i, 7),
            _buildTotalValueCell(rowControllers[i][8]),
            _buildCashOrDebtCell(i, 9),
            _buildEmptiesCell(i, 10),
          ],
        ),
      );
    }

    // إضافة صف المجموع إذا كان هناك أكثر من صف
    if (rowControllers.length >= 2) {
      contentRows.add(
        TableRow(
          decoration: BoxDecoration(color: Colors.yellow[50]),
          children: [
            _buildTableCell(
                TextEditingController()..text = '', FocusNode(), false, -1, -1),
            _buildTableCell(
                TextEditingController()..text = '', FocusNode(), false, -1, -1),
            _buildTableCell(
                TextEditingController()..text = '', FocusNode(), false, -1, -1),
            _buildTotalCell(totalCountController),
            _buildTableCell(
                TextEditingController()..text = '', FocusNode(), false, -1, -1),
            _buildTotalCell(totalBaseController),
            _buildTotalCell(totalNetController),
            _buildTableCell(
                TextEditingController()..text = '', FocusNode(), false, -1, -1),
            _buildTotalCell(totalGrandController),
            _buildTableCell(
                TextEditingController()..text = '', FocusNode(), false, -1, -1),
            _buildTableCell(
                TextEditingController()..text = '', FocusNode(), false, -1, -1),
          ],
        ),
      );
    }

    return Table(
      defaultColumnWidth: const FlexColumnWidth(),
      border: TableBorder.all(color: Colors.grey, width: 0.5),
      children: contentRows,
    );
  }

  Widget _buildTableCell(TextEditingController controller, FocusNode focusNode,
      bool isNumeric, int rowIndex, int colIndex) {
    bool isSerialField = colIndex == 0;

    // تحديد الحقول الرقمية: 3=العدد، 5=القائم، 6=الصافي، 7=السعر
    bool isNumericField =
        colIndex == 3 || colIndex == 5 || colIndex == 6 || colIndex == 7;

    return Container(
      padding: const EdgeInsets.all(1),
      constraints: const BoxConstraints(minHeight: 25),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: !isSerialField,
        readOnly: isSerialField,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          border: InputBorder.none,
          hintText: '.',
          hintStyle: TextStyle(fontSize: 13),
        ),
        style: TextStyle(
          fontSize: 13,
          color: isSerialField ? Colors.grey[700] : Colors.black,
        ),
        maxLines: 1,
        keyboardType: isNumericField
            ? TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        textInputAction: TextInputAction.next,

        // ===== التعديل الجديد: فلترة الإدخال =====
        inputFormatters: isNumericField
            ? [
                PositiveDecimalInputFormatter(),
                // تقييد عدد المنازل العشرية إذا لزم الأمر
                FilteringTextInputFormatter.deny(
                    RegExp(r'\.\d{3,}')), // لا تسمح بأكثر من منزلتين عشريتين
              ]
            : null,

        onTap: () {
          _scrollToField(rowIndex, colIndex);
        },
        onSubmitted: (value) {
          if (colIndex == 0) {
            FocusScope.of(context).requestFocus(rowFocusNodes[rowIndex][1]);
          } else if (colIndex == 7) {
            _showCashOrDebtDialog(rowIndex);
          } else if (colIndex == 10) {
            _addNewRow();
            if (rowControllers.length > 0) {
              final newRowIndex = rowControllers.length - 1;
              FocusScope.of(context)
                  .requestFocus(rowFocusNodes[newRowIndex][1]);
            }
          } else if (colIndex < 10) {
            FocusScope.of(context)
                .requestFocus(rowFocusNodes[rowIndex][colIndex + 1]);
          }
        },
        onChanged: (value) {
          if (colIndex == 0) {
            // تحديث المسلسل تلقائياً
            for (int i = 0; i < rowControllers.length; i++) {
              rowControllers[i][0].text = (i + 1).toString();
            }
          }

          // ===== التعديل الجديد: فلترة الإدخال الفوري =====
          if (isNumericField) {
            // حذف أي حرف غير رقم أو نقطة
            if (value.isNotEmpty) {
              String filteredValue = '';
              bool hasDecimalPoint = false;

              for (int i = 0; i < value.length; i++) {
                final char = value[i];

                // التحقق من أن الحرف رقم
                if (char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57) {
                  filteredValue += char;
                }
                // التحقق من أن الحرف نقطة عشرية ولم تكن موجودة من قبل
                else if (char == '.' && !hasDecimalPoint) {
                  filteredValue += char;
                  hasDecimalPoint = true;
                }
              }

              // تحديث قيمة المتحكم إذا تغيرت
              if (filteredValue != value) {
                controller.value = controller.value.copyWith(
                  text: filteredValue,
                  selection:
                      TextSelection.collapsed(offset: filteredValue.length),
                );
              }
            }

            // التحقق من عدم وجود علامة سالب
            if (value.contains('-')) {
              final cleanValue = value.replaceAll('-', '');
              controller.text = cleanValue;
            }
          }

          if (colIndex == 3 ||
              colIndex == 4 ||
              colIndex == 5 ||
              colIndex == 6 ||
              colIndex == 7) {
            _calculateRowValues(rowIndex);
            _calculateAllTotals();
          }
        },
      ),
    );
  }

  // ===== وظيفة جديدة: خلية الإجمالي غير القابلة للتعديل =====
  Widget _buildTotalValueCell(TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.all(1),
      constraints: const BoxConstraints(minHeight: 25),
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          border: InputBorder.none,
          hintText: '0.00',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
        maxLines: 1,
        keyboardType: TextInputType.number,
        enabled: false, // غير قابل للتعديل
        readOnly: true, // للقراءة فقط
      ),
    );
  }

  // دالة للتمرير إلى الحقل المحدد
  void _scrollToField(int rowIndex, int colIndex) {
    const double headerHeight =
        32.0; // نفس الارتفاع المحدد في _StickyTableHeaderDelegate
    const double rowHeight = 25.0;
    final double verticalPosition = (rowIndex * rowHeight);
    const double columnWidth = 60.0;
    final double horizontalPosition = colIndex * columnWidth;

    // التمرير العمودي
    final double verticalScrollOffset = verticalPosition;
    _verticalScrollController.animateTo(
      verticalScrollOffset + headerHeight, // إضافة ارتفاع الرأس
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    // التمرير الأفقي
    _horizontalScrollController.animateTo(
      horizontalPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
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
          _scrollToField(rowIndex, colIndex);
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
          _scrollToField(rowIndex, colIndex);
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
        title: Text(
          'يومية مشتريات رقم /${serialNumber}/ ليوم $dayName تاريخ ${widget.selectedDate} لمحل ${widget.storeName} البائع ${widget.sellerName}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: _buildTableWithStickyHeader(),
    );
  }

  // بناء الواجهة مع رأس جدول مثبت
  Widget _buildTableWithStickyHeader() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: CustomScrollView(
        controller: _verticalScrollController,
        slivers: [
          // الجزء العلوي المثبت (رأس الجدول)
          SliverPersistentHeader(
            pinned: true, // تثبيت الرأس
            floating: false,
            delegate: _StickyTableHeaderDelegate(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.grey),
                ),
                child: _buildTableHeader(),
              ),
            ),
          ),

          // محتوى الجدول (البيانات)
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: _horizontalScrollController,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width,
                  ),
                  child: _buildTableContent(),
                ),
              ),
            ),
          ),
        ],
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
                      _buildTableRows();
                      // ===== التعديل: التبويب إلى حقل "الفوارغ" =====
                      if (rowIndex >= 0) {
                        _showEmptiesDialog(
                            rowIndex); // افتح اختيار الفوارغ مباشرة
                      }
                    },
                  ),
                  onTap: () {
                    setState(() {
                      cashOrDebtValues[rowIndex] = option;
                    });
                    Navigator.of(context).pop();
                    _buildTableRows();
                    // ===== التعديل: التبويب إلى حقل "الفوارغ" =====
                    if (rowIndex >= 0) {
                      _showEmptiesDialog(
                          rowIndex); // افتح اختيار الفوارغ مباشرة
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
                      _addRowAfterEmptiesSelection(rowIndex);
                    },
                  ),
                  onTap: () {
                    setState(() {
                      emptiesValues[rowIndex] = option;
                    });
                    Navigator.of(context).pop();
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
    _addNewRow();
    if (rowControllers.length > 0) {
      final newRowIndex = rowControllers.length - 1;
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          FocusScope.of(context).requestFocus(rowFocusNodes[newRowIndex][0]);
          _scrollToField(newRowIndex, 0);
        }
      });
    }
  }
}
