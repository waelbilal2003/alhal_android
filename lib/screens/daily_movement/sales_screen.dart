import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../models/sales_model.dart';
import '../../services/sales_storage_service.dart';
import '../../widgets/table_builder.dart' as TableBuilder;
import '../../widgets/table_components.dart' as TableComponents;
import '../../widgets/common_dialogs.dart' as CommonDialogs;

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
  _SalesScreenState createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  // خدمة التخزين
  final SalesStorageService _storageService = SalesStorageService();

  // بيانات الحقول
  String serialNumber = '';
  String dayName = '';

  // قائمة لتخزين صفوف الجدول
  List<List<TextEditingController>> rowControllers = [];
  List<List<FocusNode>> rowFocusNodes = [];
  List<String> cashOrDebtValues = [];
  List<String> emptiesValues = [];
  List<String> customerNames = [];

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
  bool _hasUnsavedChanges = false;
  bool _isLoadingJournal = false;

  @override
  void initState() {
    super.initState();
    dayName = _extractDayName(widget.selectedDate);

    totalCountController = TextEditingController();
    totalBaseController = TextEditingController();
    totalNetController = TextEditingController();
    totalGrandController = TextEditingController();

    _resetTotalValues();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrCreateDailyJournal();
    });
  }

  @override
  void dispose() {
    _saveCurrentRecord(silent: true);

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

    totalCountController.dispose();
    totalBaseController.dispose();
    totalNetController.dispose();
    totalGrandController.dispose();

    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();

    super.dispose();
  }

  String _extractDayName(String dateString) {
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
    return days[now.weekday % 7];
  }

  // تحميل أو إنشاء اليومية عند الدخول
  Future<void> _loadOrCreateDailyJournal() async {
    setState(() => _isLoadingJournal = true);

    try {
      // محاولة تحميل اليومية الموجودة
      final document =
          await _storageService.loadSalesDocument(widget.selectedDate);

      if (document != null && mounted) {
        // اليومية موجودة - نحملها
        _loadExistingJournal(document);
      } else {
        // اليومية غير موجودة - ننشئ واحدة جديدة
        final journalNumber =
            await _storageService.getDailyJournalNumber(widget.selectedDate);
        if (mounted) {
          _createNewJournal(journalNumber);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في تحميل يومية المبيعات: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingJournal = false);
      }
    }
  }

  void _resetTotalValues() {
    totalCountController.text = '0';
    totalBaseController.text = '0.00';
    totalNetController.text = '0.00';
    totalGrandController.text = '0.00';
  }

  void _addNewRow() {
    setState(() {
      List<TextEditingController> newControllers =
          List.generate(12, (index) => TextEditingController());

      List<FocusNode> newFocusNodes = List.generate(12, (index) => FocusNode());

      newControllers[0].text = (rowControllers.length + 1).toString();

      newControllers[1].addListener(() => _hasUnsavedChanges = true);
      newControllers[2].addListener(() => _hasUnsavedChanges = true);
      newControllers[3].addListener(() => _hasUnsavedChanges = true);

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
      cashOrDebtValues.add('');
      emptiesValues.add('');
      customerNames.add('');
    });
  }

  void _calculateRowValues(int rowIndex) {
    if (rowIndex >= rowControllers.length) return;

    final controllers = rowControllers[rowIndex];

    setState(() {
      try {
        double count = (double.tryParse(controllers[4].text) ?? 0).abs();
        double net = (double.tryParse(controllers[7].text) ?? 0).abs();
        double price = (double.tryParse(controllers[8].text) ?? 0).abs();

        double baseValue = net > 0 ? net : count;
        double total = baseValue * price;
        controllers[9].text = total.toStringAsFixed(2);
      } catch (e) {
        controllers[9].text = '';
      }
    });
  }

  void _calculateAllTotals() {
    setState(() {
      double totalCount = 0;
      double totalBase = 0;
      double totalNet = 0;
      double totalGrand = 0;

      for (var controllers in rowControllers) {
        try {
          totalCount += double.tryParse(controllers[4].text) ?? 0;
          totalBase += double.tryParse(controllers[6].text) ?? 0;
          totalNet += double.tryParse(controllers[7].text) ?? 0;
          totalGrand += double.tryParse(controllers[9].text) ?? 0;
        } catch (e) {}
      }

      totalCountController.text = totalCount.toStringAsFixed(0);
      totalBaseController.text = totalBase.toStringAsFixed(2);
      totalNetController.text = totalNet.toStringAsFixed(2);
      totalGrandController.text = totalGrand.toStringAsFixed(2);
    });
  }

  void _scrollToField(int rowIndex, int colIndex) {
    const double headerHeight = 32.0;
    const double rowHeight = 25.0;
    final double verticalPosition = (rowIndex * rowHeight);
    const double columnWidth = 60.0;
    final double horizontalPosition = colIndex * columnWidth;

    _verticalScrollController.animateTo(
      verticalPosition + headerHeight,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    _horizontalScrollController.animateTo(
      horizontalPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildTableHeader() {
    return Table(
      defaultColumnWidth: const FlexColumnWidth(),
      columnWidths: {
        3: const FixedColumnWidth(30.0),
        10: const FlexColumnWidth(1.5),
      },
      border: TableBorder.all(color: Colors.grey, width: 0.5),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[200]),
          children: [
            TableComponents.buildTableHeaderCell('مسلسل'),
            TableComponents.buildTableHeaderCell('المادة'),
            TableComponents.buildTableHeaderCell('العائدية'),
            TableComponents.buildTableHeaderCell('س'),
            TableComponents.buildTableHeaderCell('العدد'),
            TableComponents.buildTableHeaderCell('العبوة'),
            TableComponents.buildTableHeaderCell('القائم'),
            TableComponents.buildTableHeaderCell('الصافي'),
            TableComponents.buildTableHeaderCell('السعر'),
            TableComponents.buildTableHeaderCell('الإجمالي'),
            TableComponents.buildTableHeaderCell('نقدي او دين'),
            TableComponents.buildTableHeaderCell('الفوارغ'),
          ],
        ),
      ],
    );
  }

  Widget _buildTableContent() {
    List<TableRow> contentRows = [];

    for (int i = 0; i < rowControllers.length; i++) {
      contentRows.add(
        TableRow(
          children: [
            _buildTableCell(rowControllers[i][0], rowFocusNodes[i][0], i, 0),
            _buildTableCell(rowControllers[i][1], rowFocusNodes[i][1], i, 1),
            _buildTableCell(rowControllers[i][2], rowFocusNodes[i][2], i, 2),
            _buildTableCell(rowControllers[i][3], rowFocusNodes[i][3], i, 3,
                isSField: true),
            _buildTableCell(rowControllers[i][4], rowFocusNodes[i][4], i, 4),
            _buildTableCell(rowControllers[i][5], rowFocusNodes[i][5], i, 5),
            _buildTableCell(rowControllers[i][6], rowFocusNodes[i][6], i, 6),
            _buildTableCell(rowControllers[i][7], rowFocusNodes[i][7], i, 7),
            _buildTableCell(rowControllers[i][8], rowFocusNodes[i][8], i, 8),
            TableComponents.buildTotalValueCell(rowControllers[i][9]),
            _buildCashOrDebtCell(i, 10),
            _buildEmptiesCell(i, 11),
          ],
        ),
      );
    }

    if (rowControllers.length >= 2) {
      contentRows.add(
        TableRow(
          decoration: BoxDecoration(color: Colors.yellow[50]),
          children: [
            _buildEmptyCell(),
            _buildEmptyCell(),
            _buildEmptyCell(),
            _buildEmptyCell(),
            TableComponents.buildTotalCell(totalCountController),
            _buildEmptyCell(),
            TableComponents.buildTotalCell(totalBaseController),
            TableComponents.buildTotalCell(totalNetController),
            _buildEmptyCell(),
            TableComponents.buildTotalCell(totalGrandController),
            _buildEmptyCell(),
            _buildEmptyCell(),
          ],
        ),
      );
    }

    return Table(
      defaultColumnWidth: const FlexColumnWidth(),
      columnWidths: {
        3: const FixedColumnWidth(30.0),
        10: const FlexColumnWidth(1.5),
      },
      border: TableBorder.all(color: Colors.grey, width: 0.5),
      children: contentRows,
    );
  }

  Widget _buildTableCell(TextEditingController controller, FocusNode focusNode,
      int rowIndex, int colIndex,
      {bool isSField = false}) {
    bool isSerialField = colIndex == 0;
    bool isNumericField =
        colIndex == 4 || colIndex == 6 || colIndex == 7 || colIndex == 8;

    return TableBuilder.buildTableCell(
      controller: controller,
      focusNode: focusNode,
      isSerialField: isSerialField,
      isNumericField: isNumericField,
      rowIndex: rowIndex,
      colIndex: colIndex,
      scrollToField: _scrollToField,
      onFieldSubmitted: (value, rIndex, cIndex) =>
          _handleFieldSubmitted(value, rIndex, cIndex),
      onFieldChanged: (value, rIndex, cIndex) =>
          _handleFieldChanged(value, rIndex, cIndex),
      isSField: isSField,
      inputFormatters: isSField
          ? [
              TableComponents.TwoDigitInputFormatter(),
              FilteringTextInputFormatter.digitsOnly,
            ]
          : (isNumericField
              ? [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                  FilteringTextInputFormatter.deny(RegExp(r'\.\d{3,}')),
                ]
              : null),
      fontSize: isSField ? 11 : 13,
      textAlign: isSField ? TextAlign.center : TextAlign.right,
      textDirection: isSField ? TextDirection.ltr : TextDirection.rtl,
    );
  }

  void _handleFieldSubmitted(String value, int rowIndex, int colIndex) {
    if (colIndex == 0) {
      FocusScope.of(context).requestFocus(rowFocusNodes[rowIndex][1]);
    } else if (colIndex == 8) {
      _showCashOrDebtDialog(rowIndex);
    } else if (colIndex == 10) {
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
      if (rowControllers.isNotEmpty) {
        final newRowIndex = rowControllers.length - 1;
        FocusScope.of(context).requestFocus(rowFocusNodes[newRowIndex][1]);
      }
    } else if (colIndex < 11) {
      FocusScope.of(context)
          .requestFocus(rowFocusNodes[rowIndex][colIndex + 1]);
    }
  }

  void _handleFieldChanged(String value, int rowIndex, int colIndex) {
    setState(() {
      _hasUnsavedChanges = true;

      if (colIndex == 0) {
        for (int i = 0; i < rowControllers.length; i++) {
          rowControllers[i][0].text = (i + 1).toString();
        }
      }

      // التحقق من قاعدة القائم والصافي عند تغيير أي منهما
      if (colIndex == 6 || colIndex == 7) {
        final controllers = rowControllers[rowIndex];
        double standing = double.tryParse(controllers[6].text) ?? 0;
        double net = double.tryParse(controllers[7].text) ?? 0;

        if (standing == 0 && net > 0) {
          // إذا كان القائم صفر، يجب أن يكون الصافي صفر
          controllers[7].text = '0.00';
          _showInlineWarning(
              rowIndex, 'إذا كان القائم صفر، يجب أن يكون الصافي صفر');
        } else if (standing < net) {
          // إذا كان الصافي أكبر من القائم، نجعل الصافي يساوي القائم
          controllers[7].text = standing.toStringAsFixed(2);
          _showInlineWarning(rowIndex, 'الصافي لا يمكن أن يكون أكبر من القائم');
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
    });
  }

// إضافة دالة لعرض تحذير في منتصف الشاشة
  void _showInlineWarning(int rowIndex, String message) {
    // إظهار رسالة مؤقتة في منتصف الشاشة
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildEmptyCell() {
    return Container(
      padding: const EdgeInsets.all(1),
      constraints: const BoxConstraints(minHeight: 25),
      child: TextField(
        controller: TextEditingController()..text = '',
        focusNode: FocusNode(),
        enabled: false,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildCashOrDebtCell(int rowIndex, int colIndex) {
    return TableBuilder.buildCashOrDebtCell(
      rowIndex: rowIndex,
      colIndex: colIndex,
      cashOrDebtValue: cashOrDebtValues[rowIndex],
      customerName: customerNames[rowIndex],
      customerController: rowControllers[rowIndex][10],
      focusNode: rowFocusNodes[rowIndex][colIndex],
      hasUnsavedChanges: _hasUnsavedChanges,
      setHasUnsavedChanges: (value) =>
          setState(() => _hasUnsavedChanges = value),
      onTap: () => _showCashOrDebtDialog(rowIndex),
      scrollToField: _scrollToField,
      onCustomerNameChanged: (value) {
        setState(() {
          customerNames[rowIndex] = value;
          _hasUnsavedChanges = true;
        });
      },
      onCustomerSubmitted: (value, rIndex, cIndex) {
        _showEmptiesDialog(rowIndex);
      },
      isSalesScreen: true,
    );
  }

  Widget _buildEmptiesCell(int rowIndex, int colIndex) {
    return TableComponents.buildEmptiesCell(
      value: emptiesValues[rowIndex],
      onTap: () => _showEmptiesDialog(rowIndex),
      rowIndex: rowIndex,
      colIndex: colIndex,
      scrollToField: _scrollToField,
    );
  }

  void _showCashOrDebtDialog(int rowIndex) {
    CommonDialogs.showCashOrDebtDialog(
      context: context,
      currentValue: cashOrDebtValues[rowIndex], // القيمة الحالية فقط
      options: cashOrDebtOptions,
      onSelected: (value) {
        setState(() {
          cashOrDebtValues[rowIndex] = value;
          _hasUnsavedChanges = true;

          if (value == 'نقدي') {
            customerNames[rowIndex] = '';

            // تأخير بسيط لضمان إغلاق النافذة الحالية أولاً
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                _showEmptiesDialog(rowIndex);
              }
            });
          } else {
            // إذا كان "دين"، ننتقل إلى حقل اسم الزبون بعد تأخير بسيط
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted && rowIndex < rowFocusNodes.length) {
                FocusScope.of(context)
                    .requestFocus(rowFocusNodes[rowIndex][10]);
              }
            });
          }
        });
      },
      onCancel: () {
        // لا نقوم بأي شيء عند الإلغاء
      },
    );
  }

  void _showEmptiesDialog(int rowIndex) {
    CommonDialogs.showEmptiesDialog(
      context: context,
      currentValue: emptiesValues[rowIndex],
      options: emptiesOptions,
      onSelected: (value) {
        setState(() {
          emptiesValues[rowIndex] = value;
          _hasUnsavedChanges = true;
        });
        _addRowAfterEmptiesSelection(rowIndex);
      },
      onCancel: () {},
    );
  }

  void _addRowAfterEmptiesSelection(int rowIndex) {
    _addNewRow();
    if (rowControllers.isNotEmpty) {
      final newRowIndex = rowControllers.length - 1;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          FocusScope.of(context).requestFocus(rowFocusNodes[newRowIndex][0]);
          _scrollToField(newRowIndex, 0);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'يومية مبيعات رقم /$serialNumber/ ليوم $dayName تاريخ ${widget.selectedDate} لمحل ${widget.storeName} البائع ${widget.sellerName}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'مشاركة الملف',
            onPressed: () => _shareFile(),
          ),
          IconButton(
            icon: _isSaving
                ? SizedBox(
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
                : 'حفظ يومية المبيعات',
            onPressed: _isSaving
                ? null
                : () {
                    _saveCurrentRecord();
                    setState(() => _hasUnsavedChanges = false);
                  },
          ),
        ],
      ),
      body: _buildTableWithStickyHeader(),
    );
  }

  Widget _buildTableWithStickyHeader() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: CustomScrollView(
        controller: _verticalScrollController,
        slivers: [
          SliverPersistentHeader(
            pinned: true,
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

  Future<void> _saveCurrentRecord({bool silent = false}) async {
    if (_isSaving) return;

    // التحقق من أن اليومية غير فارغة
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

    // التحقق من قاعدة القائم والصافي
    bool hasInvalidNetValue = false;
    for (int i = 0; i < rowControllers.length; i++) {
      final controllers = rowControllers[i];
      double standing = double.tryParse(controllers[6].text) ?? 0;
      double net = double.tryParse(controllers[7].text) ?? 0;

      if (standing < net) {
        hasInvalidNetValue = true;
        // تصحيح القيمة تلقائياً
        controllers[7].text = standing.toStringAsFixed(2);
        _calculateRowValues(i);
      } else if (standing == 0 && net > 0) {
        hasInvalidNetValue = true;
        controllers[7].text = '0.00';
        _calculateRowValues(i);
      }
    }

    // إذا كانت هناك قيم غير صحيحة، نطلب تأكيد
    if (hasInvalidNetValue && !silent && mounted) {
      bool confirmed = await _showNetValueWarning();
      if (!confirmed) {
        setState(() => _isSaving = false);
        return;
      }
    }

    // إعادة حساب المجاميع بعد التصحيح
    _calculateAllTotals();

    setState(() => _isSaving = true);

    final salesList = <Sale>[];
    for (int i = 0; i < rowControllers.length; i++) {
      final controllers = rowControllers[i];
      salesList.add(Sale(
        serialNumber: controllers[0].text,
        material: controllers[1].text,
        affiliation: controllers[2].text,
        sValue: controllers[3].text,
        count: controllers[4].text,
        packaging: controllers[5].text,
        standing: controllers[6].text,
        net: controllers[7].text,
        price: controllers[8].text,
        total: controllers[9].text,
        cashOrDebt: cashOrDebtValues[i],
        empties: emptiesValues[i],
        customerName: cashOrDebtValues[i] == 'دين' ? customerNames[i] : null,
        sellerName: widget.sellerName, // إضافة اسم البائع لكل سجل
      ));
    }

    final document = SalesDocument(
      recordNumber: serialNumber,
      date: widget.selectedDate,
      sellerName: widget.sellerName,
      storeName: widget.storeName,
      dayName: dayName,
      sales: salesList, // ✅ الآن معرف
      totals: {
        'totalCount': totalCountController.text,
        'totalBase': totalBaseController.text,
        'totalNet': totalNetController.text,
        'totalGrand': totalGrandController.text,
      },
    );
    final success = await _storageService.saveSalesDocument(document);

    if (success) {
      setState(() => _hasUnsavedChanges = false);
    }

    setState(() => _isSaving = false);

    if (!silent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'تم حفظ يومية المبيعات بنجاح' : 'فشل الحفظ'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

// إضافة دالة لعرض تحذير القيم غير الصحيحة
  Future<bool> _showNetValueWarning() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('تنبيه'),
            content: const Text(
              'تم تصحيح بعض القيم في حقل الصافي لأنها كانت أكبر من القائم.\n\nتذكر: يجب أن يكون القائم دائماً أكبر من أو يساوي الصافي.',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('موافق'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _shareFile() async {
    final filePath = await _storageService.getFilePath(widget.selectedDate);

    if (filePath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء حفظ اليومية أولاً'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (mounted) {
      CommonDialogs.showFilePathDialog(
        context: context,
        filePath: filePath,
      );
    }
  }

  // إنشاء يومية جديدة
  void _createNewJournal(String journalNumber) {
    setState(() {
      serialNumber = journalNumber;
      rowControllers.clear();
      rowFocusNodes.clear();
      cashOrDebtValues.clear();
      emptiesValues.clear();
      customerNames.clear();
      _resetTotalValues();
      _hasUnsavedChanges = false;
      _addNewRow();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (rowFocusNodes.isNotEmpty && rowFocusNodes[0].length > 1) {
        FocusScope.of(context).requestFocus(rowFocusNodes[0][1]);
      }
    });
  }

  // تحميل يومية موجودة
  void _loadExistingJournal(SalesDocument document) {
    setState(() {
      serialNumber = document.recordNumber;

      // تنظيف البيانات القديمة
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

      // تحميل السجلات (الصفوف) من اليومية
      for (var sale in document.sales) {
        List<TextEditingController> newControllers = [
          TextEditingController(text: sale.serialNumber),
          TextEditingController(text: sale.material),
          TextEditingController(text: sale.affiliation),
          TextEditingController(text: sale.sValue),
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

        // إضافة المستمعين
        newControllers[1].addListener(() => _hasUnsavedChanges = true);
        newControllers[2].addListener(() => _hasUnsavedChanges = true);
        newControllers[3].addListener(() => _hasUnsavedChanges = true);
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

      _calculateAllTotals();
      _hasUnsavedChanges = false;
    });
  }
}

class _StickyTableHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyTableHeaderDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => 32.0;

  @override
  double get minExtent => 32.0;

  @override
  bool shouldRebuild(_StickyTableHeaderDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
