import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/sales_model.dart';
import '../../services/sales_storage_service.dart';

// كلاس للفلترة الرقمية مع منع الفاصلة العشرية
class TwoDigitInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // التحقق من أن النص يحتوي فقط على أرقام
    final regex = RegExp(r'^[0-9]*$');
    if (!regex.hasMatch(newValue.text)) {
      return oldValue;
    }

    // منع الأرقام السالبة
    if (newValue.text.contains('-')) {
      return oldValue;
    }

    // منع أكثر من خانتين (رقمين)
    if (newValue.text.length > 2) {
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

class SalesScreen extends StatefulWidget {
  final String sellerName;
  final String selectedDate;
  final String storeName;

  const SalesScreen({
    Key? key,
    required this.sellerName,
    required this.selectedDate,
    required this.storeName,
  }) : super(key: key);

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  // خدمة التخزين
  final SalesStorageService _storageService = SalesStorageService();

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
  List<String> customerNames = []; // تخزين أسماء الزبائن (عندما يكون دين)

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

  // حالة الحفظ
  bool _isSaving = false;

  // متغير لتتبع التغييرات غير المحفوظة
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    // استخراج اسم اليوم من التاريخ المحدد
    _extractDayName(widget.selectedDate);
    // تعيين التاريخ المحدد
    date = widget.selectedDate;

    // تهيئة المتحكمات الخاصة بصف المجموع
    totalCountController = TextEditingController();
    totalBaseController = TextEditingController();
    totalNetController = TextEditingController();
    totalGrandController = TextEditingController();

    _resetTotalValues();

    // ===== التعديل الأول: فتح سجل جديد تلقائياً بدون نافذة اختيار =====
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createNewRecordAutomatically();
    });
  }

  @override
  void dispose() {
    // ===== التعديل الثاني: الحفظ التلقائي بدون استعلام =====
    _saveCurrentRecord(silent: true);

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

  // ===== التعديل الأول: دالة لإنشاء سجل جديد تلقائياً =====
  Future<void> _createNewRecordAutomatically() async {
    final nextNumber =
        await _storageService.getNextRecordNumber(widget.selectedDate);
    if (mounted) {
      _createNewRecord(nextNumber);
    }
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
      // إنشاء متحكمين للصف الجديد (12 حقل - تم إضافة حقل "س")
      List<TextEditingController> newControllers =
          List.generate(12, (index) => TextEditingController());

      // إنشاء FocusNodes للصف الجديد
      List<FocusNode> newFocusNodes = List.generate(12, (index) => FocusNode());

      // تعيين المسلسل تلقائياً
      newControllers[0].text = (rowControllers.length + 1).toString();

      // إضافة المستمعين لحقول الحساب مع تعيين علامة التغيير
      newControllers[1].addListener(() {
        _hasUnsavedChanges = true;
      });

      newControllers[2].addListener(() {
        _hasUnsavedChanges = true;
      });

      newControllers[3].addListener(() {
        _hasUnsavedChanges = true;
      });

      newControllers[4].addListener(() {
        _hasUnsavedChanges = true;
        _calculateRowValues(rowControllers.length);
        _calculateAllTotals();
      });

      newControllers[5].addListener(() {
        _hasUnsavedChanges = true;
        _calculateRowValues(rowControllers.length);
        _calculateAllTotals();
      });

      newControllers[6].addListener(() {
        _hasUnsavedChanges = true;
        _calculateRowValues(rowControllers.length);
        _calculateAllTotals();
      });

      newControllers[7].addListener(() {
        _hasUnsavedChanges = true;
        _calculateRowValues(rowControllers.length);
        _calculateAllTotals();
      });

      newControllers[8].addListener(() {
        _hasUnsavedChanges = true;
        _calculateRowValues(rowControllers.length);
        _calculateAllTotals();
      });

      rowControllers.add(newControllers);
      rowFocusNodes.add(newFocusNodes);
      cashOrDebtValues.add(''); // قيمة افتراضية
      emptiesValues.add(''); // قيمة افتراضية
      customerNames.add(''); // قيمة افتراضية لاسم الزبون

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
            (double.tryParse(controllers[4].text) ?? 0).abs(); // العدد
        double net =
            (double.tryParse(controllers[7].text) ?? 0).abs(); // الصافي
        double price =
            (double.tryParse(controllers[8].text) ?? 0).abs(); // السعر

        // تطبيق القاعدة: إذا كان الصافي > 0، استخدم الصافي، وإلا استخدم العدد
        double baseValue = net > 0 ? net : count;

        // حساب الإجمالي: القيمة المحددة × السعر
        double total = baseValue * price;
        controllers[9].text = total.toStringAsFixed(2); // الإجمالي
      } catch (e) {
        controllers[9].text = '';
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
          double count = double.tryParse(controllers[4].text) ?? 0;
          totalCount += count;

          // مجموع القائم
          double base = double.tryParse(controllers[6].text) ?? 0;
          totalBase += base;

          // مجموع الصافي
          double net = double.tryParse(controllers[7].text) ?? 0;
          totalNet += net;

          // مجموع الإجمالي
          double total = double.tryParse(controllers[9].text) ?? 0;
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
  // بناء رأس الجدول المنفصل
  Widget _buildTableHeader() {
    return Table(
      defaultColumnWidth: const FlexColumnWidth(), // هذا للعامود المتكيف
      columnWidths: {
        3: const FixedColumnWidth(30.0), // حقل "س" عرض ثابت صغير
        10: const FlexColumnWidth(1.5), // حقل "نقدي او دين" مرن أكثر
      },
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
            _buildTableHeaderCell('س'), // العمود الجديد - سيصبح عرضه 30
            _buildTableHeaderCell('العدد'),
            _buildTableHeaderCell('العبوة'),
            _buildTableHeaderCell('القائم'),
            _buildTableHeaderCell('الصافي'),
            _buildTableHeaderCell('السعر'),
            _buildTableHeaderCell('الإجمالي'),
            _buildTableHeaderCell('نقدي او دين'), // سيأخذ عرض أكبر نسبياً
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
                rowControllers[i][3], rowFocusNodes[i][3], false, i, 3,
                isSField: true), // حقل "س" الخاص
            _buildTableCell(
                rowControllers[i][4], rowFocusNodes[i][4], true, i, 4),
            _buildTableCell(
                rowControllers[i][5], rowFocusNodes[i][5], false, i, 5),
            _buildTableCell(
                rowControllers[i][6], rowFocusNodes[i][6], true, i, 6),
            _buildTableCell(
                rowControllers[i][7], rowFocusNodes[i][7], true, i, 7),
            _buildTableCell(
                rowControllers[i][8], rowFocusNodes[i][8], true, i, 8),
            _buildTotalValueCell(rowControllers[i][9]),
            _buildCashOrDebtCell(i, 10),
            _buildEmptiesCell(i, 11),
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
      columnWidths: {
        3: const FixedColumnWidth(30.0), // حقل "س" عرض ثابت
        10: const FlexColumnWidth(1.5), // حقل "نقدي او دين" مرن أكثر
      },
      border: TableBorder.all(color: Colors.grey, width: 0.5),
      children: contentRows,
    );
  }

  Widget _buildTableCell(TextEditingController controller, FocusNode focusNode,
      bool isNumeric, int rowIndex, int colIndex,
      {bool isSField = false}) {
    bool isSerialField = colIndex == 0;

    // تحديد الحقول الرقمية: 4=العدد، 6=القائم، 7=الصافي، 8=السعر
    bool isNumericField =
        colIndex == 4 || colIndex == 6 || colIndex == 7 || colIndex == 8;

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
          fontSize: isSField ? 11 : 13, // خط أصغر لحقل "س"
          color: isSerialField ? Colors.grey[700] : Colors.black,
        ),
        maxLines: 1,
        keyboardType: isSField
            ? TextInputType.number
            : (isNumericField
                ? TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text),
        textInputAction: TextInputAction.next,
        textAlign:
            isSField ? TextAlign.center : TextAlign.right, // توسيط حقل "س"
        textDirection:
            isSField ? null : TextDirection.rtl, // حقل "س" لا يحتاج RTL

        // ===== فلترة خاصة لحقل "س" =====
        inputFormatters: isSField
            ? [
                TwoDigitInputFormatter(), // فقط رقمين، لا فاصلة عشرية
                FilteringTextInputFormatter.digitsOnly,
              ]
            : (isNumericField
                ? [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                    FilteringTextInputFormatter.deny(RegExp(
                        r'\.\d{3,}')), // لا تسمح بأكثر من منزلتين عشريتين
                  ]
                : null),

        onTap: () {
          _scrollToField(rowIndex, colIndex);
        },
        onSubmitted: (value) {
          if (colIndex == 0) {
            FocusScope.of(context).requestFocus(rowFocusNodes[rowIndex][1]);
          } else if (colIndex == 8) {
            // السعر -> نقدي او دين
            _showCashOrDebtDialog(rowIndex);
          } else if (colIndex == 10) {
            // نقدي او دين -> الفوارغ
            if (cashOrDebtValues[rowIndex] == 'نقدي') {
              _showEmptiesDialog(rowIndex);
            } else if (cashOrDebtValues[rowIndex] == 'دين' &&
                customerNames[rowIndex].isNotEmpty) {
              _showEmptiesDialog(rowIndex);
            } else if (cashOrDebtValues[rowIndex].isEmpty) {
              _showCashOrDebtDialog(rowIndex);
            }
          } else if (colIndex == 11) {
            _addNewRow();
            if (rowControllers.length > 0) {
              final newRowIndex = rowControllers.length - 1;
              FocusScope.of(context)
                  .requestFocus(rowFocusNodes[newRowIndex][1]);
            }
          } else if (colIndex < 11) {
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

          // ===== فلترة خاصة لحقل "س" =====
          if (isSField) {
            // حذف أي حرف غير رقم
            if (value.isNotEmpty) {
              String filteredValue = '';
              for (int i = 0; i < value.length; i++) {
                final char = value[i];
                if (char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57) {
                  filteredValue += char;
                }
              }

              // تقييد بعدد خانتين فقط
              if (filteredValue.length > 2) {
                filteredValue = filteredValue.substring(0, 2);
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
          }

          if (colIndex == 4 ||
              colIndex == 5 ||
              colIndex == 6 ||
              colIndex == 7 ||
              colIndex == 8) {
            _calculateRowValues(rowIndex);
            _calculateAllTotals();
          }
        },
      ),
    );
  }

  // ===== وظيفة: خلية الإجمالي غير القابلة للتعديل =====
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

  Widget _buildCashOrDebtCell(int rowIndex, int colIndex) {
    // إذا كانت القيمة "دين"، اعرض TextField للكتابة
    if (cashOrDebtValues[rowIndex] == 'دين') {
      return Container(
        padding: const EdgeInsets.all(1),
        constraints: const BoxConstraints(minHeight: 25),
        child: TextField(
          controller: rowControllers[rowIndex][10],
          focusNode: rowFocusNodes[rowIndex][colIndex],
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 0.5),
            ),
            hintText: 'اسم الزبون',
            hintStyle: TextStyle(fontSize: 9, color: Colors.grey),
          ),
          style: TextStyle(
            fontSize: 11, // خط أصغر
            color: Colors.red[700],
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2, // <-- تغيير من 1 إلى 2 للسماح بالتفاف النص
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          textInputAction: TextInputAction.next,
          onTap: () {
            _scrollToField(rowIndex, colIndex);
          },
          onChanged: (value) {
            setState(() {
              customerNames[rowIndex] = value;
              _hasUnsavedChanges = true;
            });
          },
          onSubmitted: (value) {
            _showEmptiesDialog(rowIndex);
          },
        ),
      );
    }

    // إذا كانت القيمة "نقدي"، اعرض خلية مكتوب فيها "نقدي"
    if (cashOrDebtValues[rowIndex] == 'نقدي') {
      return Container(
        padding: const EdgeInsets.all(1),
        constraints: const BoxConstraints(minHeight: 25),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.green,
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Center(
            child: Text(
              'نقدي',
              style: TextStyle(
                fontSize: 9, // خط أصغر
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // إذا كانت القيمة فارغة (لم يتم الاختيار بعد)، اعرض "اختر"
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
            borderRadius: BorderRadius.circular(2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'اختر',
                  style: TextStyle(
                    fontSize: 9, // خط أصغر
                    color: Colors.grey,
                    fontWeight: FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                size: 12, // أيقونة أصغر
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
          'يومية مبيعات رقم /${serialNumber}/ ليوم $dayName تاريخ ${widget.selectedDate} لمحل ${widget.storeName} البائع ${widget.sellerName}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        actions: [
          // زر المشاركة
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'مشاركة الملف',
            onPressed: _shareFile,
          ),
          // زر الحفظ مع إشارة التغييرات غير المحفوظة
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Stack(
                    children: [
                      const Icon(Icons.save),
                      if (_hasUnsavedChanges)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: const SizedBox(
                              width: 8,
                              height: 8,
                            ),
                          ),
                        ),
                    ],
                  ),
            tooltip: _hasUnsavedChanges
                ? 'هناك تغييرات غير محفوظة - انقر للحفظ'
                : 'حفظ سجل المبيعات',
            onPressed: _isSaving
                ? null
                : () {
                    _saveCurrentRecord();
                    _hasUnsavedChanges =
                        false; // إعادة تعيين بعد النقر على الحفظ
                  },
          ),
          // زر فتح سجل آخر
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'فتح سجل',
            onPressed: () async {
              // ===== التعديل الثالث: الحفظ التلقائي قبل فتح نافذة السجلات =====
              await _saveCurrentRecord(silent: true);
              _showRecordSelectionDialog();
            },
          ),
        ],
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
                        _hasUnsavedChanges = true;

                        if (value == 'نقدي') {
                          // إذا كان نقدي، امسح اسم الزبون
                          customerNames[rowIndex] = '';
                        }
                      });
                      Navigator.of(context).pop();

                      if (value == 'نقدي') {
                        // نقدي: انتقل مباشرة إلى اختيار الفوارغ
                        _showEmptiesDialog(rowIndex);
                      } else {
                        // دين: حوّل الحقل إلى TextField وابدأ الكتابة مباشرة
                        _buildTableRows(); // إعادة بناء للتحويل إلى TextField
                        Future.delayed(const Duration(milliseconds: 50), () {
                          if (mounted && rowIndex < rowFocusNodes.length) {
                            FocusScope.of(context)
                                .requestFocus(rowFocusNodes[rowIndex][10]);
                          }
                        });
                      }
                    },
                  ),
                  onTap: () {
                    setState(() {
                      cashOrDebtValues[rowIndex] = option;
                      _hasUnsavedChanges = true;

                      if (option == 'نقدي') {
                        // إذا كان نقدي، امسح اسم الزبون
                        customerNames[rowIndex] = '';
                      }
                    });
                    Navigator.of(context).pop();

                    if (option == 'نقدي') {
                      // نقدي: انتقل مباشرة إلى اختيار الفوارغ
                      _showEmptiesDialog(rowIndex);
                    } else {
                      // دين: حوّل الحقل إلى TextField وابدأ الكتابة مباشرة
                      _buildTableRows(); // إعادة بناء للتحويل إلى TextField
                      Future.delayed(const Duration(milliseconds: 50), () {
                        if (mounted && rowIndex < rowFocusNodes.length) {
                          FocusScope.of(context)
                              .requestFocus(rowFocusNodes[rowIndex][10]);
                        }
                      });
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
                        _hasUnsavedChanges = true; // تحديث علامة التغيير
                      });
                      Navigator.of(context).pop();
                      _addRowAfterEmptiesSelection(rowIndex);
                    },
                  ),
                  onTap: () {
                    setState(() {
                      emptiesValues[rowIndex] = option;
                      _hasUnsavedChanges = true; // تحديث علامة التغيير
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

  // عرض نافذة اختيار السجلات
  Future<void> _showRecordSelectionDialog() async {
    final availableRecords =
        await _storageService.getAvailableRecords(widget.selectedDate);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'اختر رقم السجل',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (availableRecords.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'لا توجد سجلات محفوظة لهذا التاريخ',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (availableRecords.isNotEmpty)
                  ...availableRecords.map((recordNum) {
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading:
                            const Icon(Icons.description, color: Colors.green),
                        title: Text(
                          'سجل رقم $recordNum',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('تأكيد الحذف'),
                                    content: Text(
                                        'هل تريد حذف السجل رقم $recordNum؟'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('إلغاء'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('حذف',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await _storageService.deleteSalesDocument(
                                    widget.selectedDate,
                                    recordNum,
                                  );
                                  Navigator.pop(context);
                                  _showRecordSelectionDialog();
                                }
                              },
                            ),
                          ],
                        ),
                        onTap: () async {
                          // ===== التعديل الثالث: الحفظ التلقائي قبل فتح السجل الجديد =====
                          Navigator.of(context).pop();
                          _loadRecord(recordNum);
                        },
                      ),
                    );
                  }).toList(),
                const Divider(),
                ElevatedButton.icon(
                  onPressed: () async {
                    final nextNumber = await _storageService
                        .getNextRecordNumber(widget.selectedDate);
                    if (mounted) {
                      Navigator.of(context).pop();
                      _createNewRecord(nextNumber);
                    }
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('سجل جديد'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // إنشاء سجل جديد
  void _createNewRecord(String recordNumber) {
    setState(() {
      serialNumber = recordNumber;
      // مسح جميع البيانات
      rowControllers.clear();
      rowFocusNodes.clear();
      cashOrDebtValues.clear();
      emptiesValues.clear();
      customerNames.clear();
      _resetTotalValues();
      _hasUnsavedChanges = false; // إعادة تعيين علامة التغيير
      // إضافة صف جديد
      _addNewRow();
    });

    // تركيز على الحقل الأول
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (rowFocusNodes.isNotEmpty && rowFocusNodes[0].length > 1) {
        FocusScope.of(context).requestFocus(rowFocusNodes[0][1]);
      }
    });
  }

  // تحميل سجل موجود
  Future<void> _loadRecord(String recordNumber) async {
    final document = await _storageService.loadSalesDocument(
      widget.selectedDate,
      recordNumber,
    );

    if (document == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل تحميل السجل'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      serialNumber = recordNumber;

      // مسح البيانات القديمة
      for (var row in rowControllers) {
        for (var controller in row) {
          controller.dispose();
        }
      }
      for (var row in rowFocusNodes) {
        for (var node in row) {
          node.dispose();
        }
      }

      rowControllers.clear();
      rowFocusNodes.clear();
      cashOrDebtValues.clear();
      emptiesValues.clear();
      customerNames.clear();

      // تحميل البيانات الجديدة
      for (var sale in document.sales) {
        List<TextEditingController> newControllers = [
          TextEditingController(text: sale.serialNumber),
          TextEditingController(text: sale.material),
          TextEditingController(text: sale.affiliation),
          TextEditingController(text: sale.sValue), // حقل "س"
          TextEditingController(text: sale.count),
          TextEditingController(text: sale.packaging),
          TextEditingController(text: sale.standing),
          TextEditingController(text: sale.net),
          TextEditingController(text: sale.price),
          TextEditingController(text: sale.total),
          TextEditingController(),
          TextEditingController(),
        ];

        List<FocusNode> newFocusNodes =
            List.generate(12, (index) => FocusNode());

        // إضافة المستمعين مع تعيين علامة التغيير
        newControllers[1].addListener(() {
          _hasUnsavedChanges = true;
        });

        newControllers[2].addListener(() {
          _hasUnsavedChanges = true;
        });

        newControllers[3].addListener(() {
          _hasUnsavedChanges = true;
        });

        newControllers[4].addListener(() {
          _hasUnsavedChanges = true;
          _calculateRowValues(rowControllers.length - 1);
          _calculateAllTotals();
        });

        newControllers[5].addListener(() {
          _hasUnsavedChanges = true;
          _calculateRowValues(rowControllers.length - 1);
          _calculateAllTotals();
        });

        newControllers[6].addListener(() {
          _hasUnsavedChanges = true;
          _calculateRowValues(rowControllers.length - 1);
          _calculateAllTotals();
        });

        newControllers[7].addListener(() {
          _hasUnsavedChanges = true;
          _calculateRowValues(rowControllers.length - 1);
          _calculateAllTotals();
        });

        newControllers[8].addListener(() {
          _hasUnsavedChanges = true;
          _calculateRowValues(rowControllers.length - 1);
          _calculateAllTotals();
        });

        rowControllers.add(newControllers);
        rowFocusNodes.add(newFocusNodes);
        cashOrDebtValues.add(sale.cashOrDebt);
        emptiesValues.add(sale.empties);
        customerNames.add(sale.customerName ?? '');
      }

      // تحديث المجاميع
      _calculateAllTotals();
      _buildTableRows();
      _hasUnsavedChanges = false; // إعادة تعيين علامة التغيير بعد التحميل
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحميل سجل المبيعات رقم $recordNumber'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // حفظ السجل الحالي
  Future<void> _saveCurrentRecord({bool silent = false}) async {
    if (_isSaving) return;

    // التحقق من وجود بيانات للحفظ
    if (rowControllers.isEmpty) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا توجد بيانات للحفظ'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // إنشاء قائمة المبيعات
    final sales = <Sale>[];
    for (int i = 0; i < rowControllers.length; i++) {
      final controllers = rowControllers[i];
      sales.add(Sale(
        serialNumber: controllers[0].text,
        material: controllers[1].text,
        affiliation: controllers[2].text,
        sValue: controllers[3].text, // حقل "س"
        count: controllers[4].text,
        packaging: controllers[5].text,
        standing: controllers[6].text,
        net: controllers[7].text,
        price: controllers[8].text,
        total: controllers[9].text,
        cashOrDebt: cashOrDebtValues[i],
        empties: emptiesValues[i],
        customerName: cashOrDebtValues[i] == 'دين' ? customerNames[i] : null,
      ));
    }

    // التحقق من وجود بيانات صحيحة
    bool hasValidData = false;
    for (var sale in sales) {
      if (sale.material.isNotEmpty ||
          sale.count.isNotEmpty ||
          sale.price.isNotEmpty) {
        hasValidData = true;
        break;
      }
    }

    if (!hasValidData && !silent) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا توجد بيانات للحفظ'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // إنشاء المستند
    final document = SalesDocument(
      recordNumber: serialNumber,
      date: widget.selectedDate,
      sellerName: widget.sellerName,
      storeName: widget.storeName,
      dayName: dayName,
      sales: sales,
      totals: {
        'totalCount': totalCountController.text,
        'totalBase': totalBaseController.text,
        'totalNet': totalNetController.text,
        'totalGrand': totalGrandController.text,
      },
    );

    // حفظ المستند
    final success = await _storageService.saveSalesDocument(document);

    if (success) {
      _hasUnsavedChanges = false; // إعادة تعيين العلم بعد الحفظ الناجح
    }

    setState(() {
      _isSaving = false;
    });

    if (!silent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'تم حفظ سجل المبيعات بنجاح' : 'فشل الحفظ'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  // مشاركة الملف
  Future<void> _shareFile() async {
    final filePath = await _storageService.getFilePath(
      widget.selectedDate,
      serialNumber,
    );

    if (filePath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء حفظ السجل أولاً'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('مسار ملف المبيعات'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('يمكنك نسخ المسار أدناه:'),
              const SizedBox(height: 8),
              SelectableText(
                filePath,
                style: const TextStyle(fontSize: 12, color: Colors.blue),
              ),
              const SizedBox(height: 16),
              const Text(
                'يمكنك نقل الملف إلى الحاسوب عبر USB أو البلوتوث',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('موافق'),
            ),
          ],
        ),
      );
    }
  }
}
