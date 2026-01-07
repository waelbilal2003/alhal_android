import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/purchase_model.dart';
import '../../services/purchase_storage_service.dart';
import '../../widgets/table_builder.dart' as TableBuilder;
import '../../widgets/table_components.dart' as TableComponents;
import '../../widgets/common_dialogs.dart' as CommonDialogs;

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
  _PurchasesScreenState createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  // خدمة التخزين
  final PurchaseStorageService _storageService = PurchaseStorageService();

  // بيانات الحقول
  String dayName = '';

  // قائمة لتخزين صفوف الجدول
  List<List<TextEditingController>> rowControllers = [];
  List<List<FocusNode>> rowFocusNodes = [];
  List<String> cashOrDebtValues = [];
  List<String> emptiesValues = [];

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
      _loadOrCreateJournal();
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

  // تحميل اليومية إذا كانت موجودة، أو إنشاء جديدة
  Future<void> _loadOrCreateJournal() async {
    final document =
        await _storageService.loadPurchaseDocument(widget.selectedDate);

    if (document != null && document.purchases.isNotEmpty) {
      // تحميل اليومية الموجودة
      _loadJournal(document);
    } else {
      // إنشاء يومية جديدة
      _createNewJournal();
    }
  }

  void _resetTotalValues() {
    totalCountController.text = '0';
    totalBaseController.text = '0.00';
    totalNetController.text = '0.00';
    totalGrandController.text = '0.00';
  }

  void _createNewJournal() {
    setState(() {
      rowControllers.clear();
      rowFocusNodes.clear();
      cashOrDebtValues.clear();
      emptiesValues.clear();
      _resetTotalValues();
      _hasUnsavedChanges = false;
      _addNewRow();
    });
  }

  void _loadJournal(PurchaseDocument document) {
    setState(() {
      // تنظيف المتحكمات القديمة
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

      // إعادة تهيئة القوائم
      rowControllers.clear();
      rowFocusNodes.clear();
      cashOrDebtValues.clear();
      emptiesValues.clear();

      // تحميل السجلات من الوثيقة
      for (var purchase in document.purchases) {
        List<TextEditingController> newControllers = [
          TextEditingController(text: purchase.serialNumber),
          TextEditingController(text: purchase.material),
          TextEditingController(text: purchase.affiliation),
          TextEditingController(text: purchase.count),
          TextEditingController(text: purchase.packaging),
          TextEditingController(text: purchase.standing),
          TextEditingController(text: purchase.net),
          TextEditingController(text: purchase.price),
          TextEditingController(text: purchase.total),
          TextEditingController(),
          TextEditingController(),
        ];

        List<FocusNode> newFocusNodes =
            List.generate(11, (index) => FocusNode());

        // التحقق إذا كان السجل مملوكاً للبائع الحالي
        final bool isOwnedByCurrentSeller =
            purchase.sellerName == widget.sellerName;

        // إضافة مستمعات للتغيير فقط إذا كان السجل مملوكاً للبائع الحالي
        if (isOwnedByCurrentSeller) {
          for (int i = 1; i <= 7; i++) {
            newControllers[i].addListener(() {
              _hasUnsavedChanges = true;
              if (i >= 3 && i <= 7) {
                final rowIndex = rowControllers.length - 1;
                _calculateRowValues(rowIndex);
                _calculateAllTotals();
              }
            });
          }

          // إضافة التحقق من قاعدة القائم والصافي
          newControllers[5].addListener(() {
            _validateStandingAndNet(rowControllers.length - 1);
          });

          newControllers[6].addListener(() {
            _validateStandingAndNet(rowControllers.length - 1);
          });
        } else {
          // إذا كان السجل مملوكاً لبائع آخر، جعل الحقول للقراءة فقط
          for (int i = 0; i < newControllers.length; i++) {
            newControllers[i].text = _getControllerText(i, purchase);
          }
        }

        rowControllers.add(newControllers);
        rowFocusNodes.add(newFocusNodes);
        cashOrDebtValues.add(purchase.cashOrDebt);
        emptiesValues.add(purchase.empties);
      }

      // تحميل المجاميع
      if (document.totals.isNotEmpty) {
        totalCountController.text = document.totals['totalCount'] ?? '0';
        totalBaseController.text = document.totals['totalBase'] ?? '0.00';
        totalNetController.text = document.totals['totalNet'] ?? '0.00';
        totalGrandController.text = document.totals['totalGrand'] ?? '0.00';
      }

      _hasUnsavedChanges = false;
    });
  }

  String _getControllerText(int index, Purchase purchase) {
    switch (index) {
      case 0:
        return purchase.serialNumber;
      case 1:
        return purchase.material;
      case 2:
        return purchase.affiliation;
      case 3:
        return purchase.count;
      case 4:
        return purchase.packaging;
      case 5:
        return purchase.standing;
      case 6:
        return purchase.net;
      case 7:
        return purchase.price;
      case 8:
        return purchase.total;
      default:
        return '';
    }
  }

  void _addNewRow() {
    setState(() {
      final newSerialNumber = (rowControllers.length + 1).toString();

      List<TextEditingController> newControllers =
          List.generate(11, (index) => TextEditingController());

      List<FocusNode> newFocusNodes = List.generate(11, (index) => FocusNode());

      newControllers[0].text = newSerialNumber;

      // إضافة مستمعات للتغيير
      newControllers[1].addListener(() => _hasUnsavedChanges = true);
      newControllers[2].addListener(() => _hasUnsavedChanges = true);

      newControllers[3].addListener(() {
        _hasUnsavedChanges = true;
        _calculateRowValues(rowControllers.length);
        _calculateAllTotals();
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

      // إضافة التحقق من قاعدة القائم والصافي
      newControllers[5].addListener(() {
        _validateStandingAndNet(rowControllers.length);
      });

      newControllers[6].addListener(() {
        _validateStandingAndNet(rowControllers.length);
      });

      rowControllers.add(newControllers);
      rowFocusNodes.add(newFocusNodes);
      cashOrDebtValues.add('');
      emptiesValues.add('');
    });
  }

  void _validateStandingAndNet(int rowIndex) {
    if (rowIndex >= rowControllers.length) return;

    final controllers = rowControllers[rowIndex];
    double standing = double.tryParse(controllers[5].text) ?? 0;
    double net = double.tryParse(controllers[6].text) ?? 0;

    if (standing < net) {
      // إذا كان الصافي أكبر من القائم، نجعل الصافي يساوي القائم
      controllers[6].text = standing.toStringAsFixed(2);
      _showInlineWarning(rowIndex, 'الصافي لا يمكن أن يكون أكبر من القائم');
    } else if (standing == 0 && net > 0) {
      // إذا كان القائم صفر، يجب أن يكون الصافي صفر
      controllers[6].text = '0.00';
      _showInlineWarning(
          rowIndex, 'إذا كان القائم صفر، يجب أن يكون الصافي صفر');
    }
  }

  void _calculateRowValues(int rowIndex) {
    if (rowIndex >= rowControllers.length) return;

    final controllers = rowControllers[rowIndex];

    setState(() {
      try {
        double count = (double.tryParse(controllers[3].text) ?? 0).abs();
        double net = (double.tryParse(controllers[6].text) ?? 0).abs();
        double price = (double.tryParse(controllers[7].text) ?? 0).abs();

        double baseValue = net > 0 ? net : count;
        double total = baseValue * price;
        controllers[8].text = total.toStringAsFixed(2);
      } catch (e) {
        controllers[8].text = '';
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
          totalCount += double.tryParse(controllers[3].text) ?? 0;
          totalBase += double.tryParse(controllers[5].text) ?? 0;
          totalNet += double.tryParse(controllers[6].text) ?? 0;
          totalGrand += double.tryParse(controllers[8].text) ?? 0;
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
      border: TableBorder.all(color: Colors.grey, width: 0.5),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[200]),
          children: [
            TableComponents.buildTableHeaderCell('مسلسل'),
            TableComponents.buildTableHeaderCell('المادة'),
            TableComponents.buildTableHeaderCell('العائدية'),
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
      // التحقق إذا كان السجل مملوكاً للبائع الحالي
      final bool isOwnedByCurrentSeller = _isRowOwnedByCurrentSeller(i);

      contentRows.add(
        TableRow(
          children: [
            _buildTableCell(rowControllers[i][0], rowFocusNodes[i][0], i, 0,
                isOwnedByCurrentSeller),
            _buildTableCell(rowControllers[i][1], rowFocusNodes[i][1], i, 1,
                isOwnedByCurrentSeller),
            _buildTableCell(rowControllers[i][2], rowFocusNodes[i][2], i, 2,
                isOwnedByCurrentSeller),
            _buildTableCell(rowControllers[i][3], rowFocusNodes[i][3], i, 3,
                isOwnedByCurrentSeller),
            _buildTableCell(rowControllers[i][4], rowFocusNodes[i][4], i, 4,
                isOwnedByCurrentSeller),
            _buildTableCell(rowControllers[i][5], rowFocusNodes[i][5], i, 5,
                isOwnedByCurrentSeller),
            _buildTableCell(rowControllers[i][6], rowFocusNodes[i][6], i, 6,
                isOwnedByCurrentSeller),
            _buildTableCell(rowControllers[i][7], rowFocusNodes[i][7], i, 7,
                isOwnedByCurrentSeller),
            TableComponents.buildTotalValueCell(rowControllers[i][8]),
            _buildCashOrDebtCell(i, 9, isOwnedByCurrentSeller),
            _buildEmptiesCell(i, 10, isOwnedByCurrentSeller),
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
      border: TableBorder.all(color: Colors.grey, width: 0.5),
      children: contentRows,
    );
  }

  Widget _buildTableCell(TextEditingController controller, FocusNode focusNode,
      int rowIndex, int colIndex, bool isOwnedByCurrentSeller) {
    bool isSerialField = colIndex == 0;
    bool isNumericField =
        colIndex == 3 || colIndex == 5 || colIndex == 6 || colIndex == 7;

    Widget cell = TableBuilder.buildTableCell(
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
      inputFormatters: isNumericField
          ? [
              TableComponents.PositiveDecimalInputFormatter(),
              FilteringTextInputFormatter.deny(RegExp(r'\.\d{3,}')),
            ]
          : null,
    );

    // إذا لم يكن السجل مملوكاً للبائع الحالي، جعل الخلية للقراءة فقط
    if (!isOwnedByCurrentSeller) {
      return IgnorePointer(
        child: Opacity(
          opacity: 0.7,
          child: cell,
        ),
      );
    }

    return cell;
  }

  void _handleFieldSubmitted(String value, int rowIndex, int colIndex) {
    // التحقق إذا كان السجل مملوكاً للبائع الحالي
    if (!_isRowOwnedByCurrentSeller(rowIndex)) {
      return; // لا تفعل شيئاً إذا لم يكن السجل مملوكاً للبائع الحالي
    }

    if (colIndex == 0) {
      FocusScope.of(context).requestFocus(rowFocusNodes[rowIndex][1]);
    } else if (colIndex == 7) {
      _showCashOrDebtDialog(rowIndex);
    } else if (colIndex == 10) {
      _addNewRow();
      if (rowControllers.isNotEmpty) {
        final newRowIndex = rowControllers.length - 1;
        FocusScope.of(context).requestFocus(rowFocusNodes[newRowIndex][1]);
      }
    } else if (colIndex < 10) {
      FocusScope.of(context)
          .requestFocus(rowFocusNodes[rowIndex][colIndex + 1]);
    }
  }

  void _handleFieldChanged(String value, int rowIndex, int colIndex) {
    // التحقق إذا كان السجل مملوكاً للبائع الحالي
    if (!_isRowOwnedByCurrentSeller(rowIndex)) {
      return; // لا تفعل شيئاً إذا لم يكن السجل مملوكاً للبائع الحالي
    }

    setState(() {
      _hasUnsavedChanges = true;

      if (colIndex == 0) {
        // عند تغيير الرقم المسلسل، ترقيم كل السجلات
        for (int i = 0; i < rowControllers.length; i++) {
          rowControllers[i][0].text = (i + 1).toString();
        }
      }
    });
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

  Widget _buildCashOrDebtCell(
      int rowIndex, int colIndex, bool isOwnedByCurrentSeller) {
    Widget cell = TableBuilder.buildCashOrDebtCell(
      rowIndex: rowIndex,
      colIndex: colIndex,
      cashOrDebtValue: cashOrDebtValues[rowIndex],
      customerName: '',
      customerController: TextEditingController(),
      focusNode: rowFocusNodes[rowIndex][colIndex],
      hasUnsavedChanges: _hasUnsavedChanges,
      setHasUnsavedChanges: (value) =>
          setState(() => _hasUnsavedChanges = value),
      onTap: () => _showCashOrDebtDialog(rowIndex),
      scrollToField: _scrollToField,
      onCustomerNameChanged: (value) {},
      onCustomerSubmitted: (value, rIndex, cIndex) {},
      isSalesScreen: false,
    );

    // إذا لم يكن السجل مملوكاً للبائع الحالي، جعل الخلية للقراءة فقط
    if (!isOwnedByCurrentSeller) {
      return IgnorePointer(
        child: Opacity(
          opacity: 0.7,
          child: cell,
        ),
      );
    }

    return cell;
  }

  Widget _buildEmptiesCell(
      int rowIndex, int colIndex, bool isOwnedByCurrentSeller) {
    Widget cell = TableComponents.buildEmptiesCell(
      value: emptiesValues[rowIndex],
      onTap: () => _showEmptiesDialog(rowIndex),
      rowIndex: rowIndex,
      colIndex: colIndex,
      scrollToField: _scrollToField,
    );

    // إذا لم يكن السجل مملوكاً للبائع الحالي، جعل الخلية للقراءة فقط
    if (!isOwnedByCurrentSeller) {
      return IgnorePointer(
        child: Opacity(
          opacity: 0.7,
          child: cell,
        ),
      );
    }

    return cell;
  }

  void _showCashOrDebtDialog(int rowIndex) {
    // التحقق إذا كان السجل مملوكاً للبائع الحالي
    if (!_isRowOwnedByCurrentSeller(rowIndex)) {
      return;
    }

    CommonDialogs.showCashOrDebtDialog(
      context: context,
      currentValue: cashOrDebtValues[rowIndex],
      options: cashOrDebtOptions,
      onSelected: (value) {
        setState(() {
          cashOrDebtValues[rowIndex] = value;
          _hasUnsavedChanges = true;

          // فتح نافذة الفوارغ مباشرة
          if (value == 'نقدي' || value == 'دين') {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                _showEmptiesDialog(rowIndex);
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
    // التحقق إذا كان السجل مملوكاً للبائع الحالي
    if (!_isRowOwnedByCurrentSeller(rowIndex)) {
      return;
    }

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

  // التحقق إذا كان السجل مملوكاً للبائع الحالي
  bool _isRowOwnedByCurrentSeller(int rowIndex) {
    // في التطبيق الحقيقي، يجب تخزين اسم البائع مع كل سجل
    // حالياً، نفترض أن جميع السجلات الجديدة مملوكة للبائع الحالي

    // إذا كان السجل فارغاً، فهو مملوك للبائع الحالي
    final controllers = rowControllers[rowIndex];
    if (controllers[1].text.isEmpty && controllers[3].text.isEmpty) {
      return true;
    }

    // للتبسيط، نعتبر أن البائع الحالي يملك السجل
    // في الإصدار النهائي، تحتاج إلى تخزين اسم البائع مع كل سجل
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'يومية مشتريات تاريخ ${widget.selectedDate} لمحل ${widget.storeName} البائع ${widget.sellerName}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.red[700],
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
                : 'حفظ اليومية',
            onPressed: _isSaving
                ? null
                : () {
                    _saveCurrentRecord();
                  },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'فتح يومية أخرى',
            onPressed: () async {
              await _saveCurrentRecord(silent: true);
              await _showDateSelectionDialog();
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

    // التحقق من وجود سجلات للحفظ
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

    // إنشاء قائمة بالمشتريات للبائع الحالي فقط
    final currentSellerPurchases = <Purchase>[];
    for (int i = 0; i < rowControllers.length; i++) {
      final controllers = rowControllers[i];

      // التحقق إذا كان السجل فارغاً
      if (controllers[1].text.isNotEmpty || controllers[3].text.isNotEmpty) {
        currentSellerPurchases.add(Purchase(
          serialNumber: controllers[0].text,
          material: controllers[1].text,
          affiliation: controllers[2].text,
          count: controllers[3].text,
          packaging: controllers[4].text,
          standing: controllers[5].text,
          net: controllers[6].text,
          price: controllers[7].text,
          total: controllers[8].text,
          cashOrDebt: cashOrDebtValues[i],
          empties: emptiesValues[i],
          sellerName: widget.sellerName,
        ));
      }
    }

    if (currentSellerPurchases.isEmpty) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا توجد سجلات مضافة للحفظ'),
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
      double standing = double.tryParse(controllers[5].text) ?? 0;
      double net = double.tryParse(controllers[6].text) ?? 0;

      if (standing < net) {
        hasInvalidNetValue = true;
        controllers[6].text = standing.toStringAsFixed(2);
        _calculateRowValues(i);
      } else if (standing == 0 && net > 0) {
        hasInvalidNetValue = true;
        controllers[6].text = '0.00';
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

    final document = PurchaseDocument(
      recordNumber: '1', // رقم افتراضي (لم يعد مهماً)
      date: widget.selectedDate,
      sellerName: widget.sellerName,
      storeName: widget.storeName,
      dayName: dayName,
      purchases: currentSellerPurchases,
      totals: {
        'totalCount': totalCountController.text,
        'totalBase': totalBaseController.text,
        'totalNet': totalNetController.text,
        'totalGrand': totalGrandController.text,
      },
    );

    final success = await _storageService.savePurchaseDocument(document);

    if (success) {
      setState(() {
        _hasUnsavedChanges = false;
      });
    }

    setState(() => _isSaving = false);

    if (!silent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'تم الحفظ بنجاح' : 'فشل الحفظ'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _showDateSelectionDialog() async {
    final availableDates = await _storageService.getAvailableDates();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'اليوميات المحفوظة',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (availableDates.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'لا توجد يوميات محفوظة',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (availableDates.isNotEmpty)
                  ...availableDates.map((date) {
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today,
                            color: Colors.blue),
                        title: Text(
                          'يومية تاريخ $date',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            // يمكن إضافة وظيفة حذف اليومية لاحقاً
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('سيتم إضافة وظيفة الحذف لاحقاً'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          },
                        ),
                        onTap: () async {
                          Navigator.of(context).pop();
                          // في التطبيق الحقيقي، تحتاج إلى إعادة تحميل الشاشة بالتاريخ الجديد
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'لتحميل يومية تاريخ مختلف، يرجى العودة للشاشة الرئيسية واختيار التاريخ: $date'),
                                backgroundColor: Colors.blue,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  }).toList(),
                const Divider(),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _createNewJournal();
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('بدء يومية جديدة'),
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

  void _showInlineWarning(int rowIndex, String message) {
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
