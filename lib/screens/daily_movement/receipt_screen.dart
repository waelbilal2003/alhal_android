import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/receipt_model.dart';
import '../../services/receipt_storage_service.dart';
import '../../widgets/table_builder.dart' as TableBuilder;
import '../../widgets/table_components.dart' as TableComponents;
import '../../widgets/common_dialogs.dart' as CommonDialogs;

class ReceiptScreen extends StatefulWidget {
  final String sellerName;
  final String selectedDate;
  final String storeName;

  const ReceiptScreen({
    Key? key,
    required this.sellerName,
    required this.selectedDate,
    required this.storeName,
  }) : super(key: key);

  @override
  _ReceiptScreenState createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  // خدمة التخزين
  final ReceiptStorageService _storageService = ReceiptStorageService();

  // بيانات الحقول
  String serialNumber = '';
  String dayName = '';

  // قائمة لتخزين صفوف الجدول
  List<List<TextEditingController>> rowControllers = [];
  List<List<FocusNode>> rowFocusNodes = [];

  // متحكمات صف المجموع
  late TextEditingController totalCountController;
  late TextEditingController totalStandingController;
  late TextEditingController totalPaymentController;
  late TextEditingController totalLoadController;

  // متحكمات للتمرير
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  // حالة الحفظ
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  String? _recordCreator; // منشئ السجل الحالي

  @override
  void initState() {
    super.initState();
    dayName = _extractDayName(widget.selectedDate);

    totalCountController = TextEditingController();
    totalStandingController = TextEditingController();
    totalPaymentController = TextEditingController();
    totalLoadController = TextEditingController();

    _resetTotalValues();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createNewRecordAutomatically();
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
    totalStandingController.dispose();
    totalPaymentController.dispose();
    totalLoadController.dispose();

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

  Future<void> _createNewRecordAutomatically() async {
    final nextNumber =
        await _storageService.getNextRecordNumber(widget.selectedDate);
    if (mounted) {
      _createNewRecord(nextNumber);
    }
  }

  void _resetTotalValues() {
    totalCountController.text = '0';
    totalStandingController.text = '0.00';
    totalPaymentController.text = '0.00';
    totalLoadController.text = '0.00';
  }

  void _addNewRow() {
    setState(() {
      // 8 حقول: (مسلسل، المادة، العائدية، العدد، العبوة، القائم، الدفعة، الحمولة)
      List<TextEditingController> newControllers =
          List.generate(8, (index) => TextEditingController());

      List<FocusNode> newFocusNodes = List.generate(8, (index) => FocusNode());

      newControllers[0].text = (rowControllers.length + 1).toString();

      // إضافة مستمعات للتغيرات للحقول النصية
      newControllers[1].addListener(() => _hasUnsavedChanges = true); // المادة
      newControllers[2]
          .addListener(() => _hasUnsavedChanges = true); // العائدية
      newControllers[4]
          .addListener(() => _hasUnsavedChanges = true); // العبوة (نصي)

      // المستمعات للحقول الرقمية فقط
      newControllers[3].addListener(() {
        // العدد
        _hasUnsavedChanges = true;
        _calculateAllTotals();
      });
      newControllers[5].addListener(() {
        // القائم
        _hasUnsavedChanges = true;
        _calculateAllTotals();
      });
      newControllers[6].addListener(() {
        // الدفعة
        _hasUnsavedChanges = true;
        _calculateAllTotals();
      });
      newControllers[7].addListener(() {
        // الحمولة
        _hasUnsavedChanges = true;
        _calculateAllTotals();
      });

      rowControllers.add(newControllers);
      rowFocusNodes.add(newFocusNodes);
    });
  }

  void _calculateAllTotals() {
    setState(() {
      double totalCount = 0;
      double totalStanding = 0;
      double totalPayment = 0;
      double totalLoad = 0;

      for (var controllers in rowControllers) {
        try {
          totalCount += double.tryParse(controllers[3].text) ?? 0; // العدد
          totalStanding += double.tryParse(controllers[5].text) ?? 0; // القائم
          totalPayment += double.tryParse(controllers[6].text) ?? 0; // الدفعة
          totalLoad += double.tryParse(controllers[7].text) ?? 0; // الحمولة
        } catch (e) {
          // تجاهل الأخطاء في التحويل
        }
      }

      totalCountController.text = totalCount.toStringAsFixed(0);
      totalStandingController.text = totalStanding.toStringAsFixed(2);
      totalPaymentController.text = totalPayment.toStringAsFixed(2);
      totalLoadController.text = totalLoad.toStringAsFixed(2);
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
            TableComponents.buildTableHeaderCell('الدفعة'),
            TableComponents.buildTableHeaderCell('الحمولة'),
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
            _buildTableCell(rowControllers[i][3], rowFocusNodes[i][3], i, 3),
            _buildTableCell(rowControllers[i][4], rowFocusNodes[i][4], i, 4),
            _buildTableCell(rowControllers[i][5], rowFocusNodes[i][5], i, 5),
            _buildTableCell(rowControllers[i][6], rowFocusNodes[i][6], i, 6),
            _buildTableCell(rowControllers[i][7], rowFocusNodes[i][7], i, 7),
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
            TableComponents.buildTotalCell(totalStandingController),
            TableComponents.buildTotalCell(totalPaymentController),
            TableComponents.buildTotalCell(totalLoadController),
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
      int rowIndex, int colIndex) {
    bool isSerialField = colIndex == 0;
    // تعديل: حقل العبوة (المؤشر 4) ليس رقمية، فقط الحقول 3،5،6،7 رقمية
    bool isNumericField =
        colIndex == 3 || colIndex == 5 || colIndex == 6 || colIndex == 7;

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
      inputFormatters: isNumericField
          ? [
              TableComponents.PositiveDecimalInputFormatter(),
              FilteringTextInputFormatter.deny(RegExp(r'\.\d{3,}')),
            ]
          : null,
    );
  }

  void _handleFieldSubmitted(String value, int rowIndex, int colIndex) {
    if (colIndex == 7) {
      // إذا وصلنا لآخر حقل (الحمولة)، نضيف سطر جديد
      _addNewRow();
      if (rowControllers.isNotEmpty) {
        final newRowIndex = rowControllers.length - 1;
        FocusScope.of(context).requestFocus(rowFocusNodes[newRowIndex][1]);
      }
    } else if (colIndex < 7) {
      FocusScope.of(context)
          .requestFocus(rowFocusNodes[rowIndex][colIndex + 1]);
    }
  }

  void _handleFieldChanged(String value, int rowIndex, int colIndex) {
    setState(() {
      _hasUnsavedChanges = true;

      if (colIndex == 0) {
        // تحديث الأرقام التسلسلية
        for (int i = 0; i < rowControllers.length; i++) {
          rowControllers[i][0].text = (i + 1).toString();
        }
      }

      // الحقول الرقمية فقط التي تؤثر في الحسابات
      if (colIndex == 3 || colIndex == 5 || colIndex == 6 || colIndex == 7) {
        _calculateAllTotals();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'يومية استلام رقم /$serialNumber/ ليوم $dayName تاريخ ${widget.selectedDate} لمحل ${widget.storeName} البائع ${widget.sellerName}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue[700],
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
                : 'حفظ السجل',
            onPressed: _isSaving
                ? null
                : () {
                    _saveCurrentRecord();
                    setState(() => _hasUnsavedChanges = false);
                  },
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'فتح سجل',
            onPressed: () async {
              await _saveCurrentRecord(silent: true);
              await _showRecordSelectionDialog();
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

    // نظام الصلاحيات
    if (_recordCreator != null && _recordCreator != widget.sellerName) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('هذا السجل ليس سجلك، لا يمكنك التعديل عليه'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // التحقق من أن السجل غير فارغ
    bool isEmptyRecord = true;
    for (var controllers in rowControllers) {
      if (controllers[1].text.isNotEmpty || // المادة
          controllers[3].text.isNotEmpty) {
        // العدد
        isEmptyRecord = false;
        break;
      }
    }

    if (isEmptyRecord) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن حفظ سجل فارغ'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

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

    setState(() => _isSaving = true);
    final receiptsList = <Receipt>[];
    for (int i = 0; i < rowControllers.length; i++) {
      final controllers = rowControllers[i];
      receiptsList.add(Receipt(
        serialNumber: controllers[0].text,
        material: controllers[1].text,
        affiliation: controllers[2].text,
        count: controllers[3].text,
        packaging: controllers[4].text,
        standing: controllers[5].text,
        payment: controllers[6].text,
        load: controllers[7].text,
        sellerName: widget.sellerName, // إضافة اسم البائع لكل سجل
      ));
    }

    final document = ReceiptDocument(
      recordNumber: serialNumber,
      date: widget.selectedDate,
      sellerName: widget.sellerName,
      storeName: widget.storeName,
      dayName: dayName,
      receipts: receiptsList,
      totals: {
        'totalCount': totalCountController.text,
        'totalStanding': totalStandingController.text,
        'totalPayment': totalPaymentController.text,
        'totalLoad': totalLoadController.text,
      },
    );

    final success = await _storageService.saveReceiptDocument(document);

    if (success) {
      setState(() => _hasUnsavedChanges = false);
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
                            const Icon(Icons.description, color: Colors.blue),
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
                                final confirm = await CommonDialogs
                                    .showDeleteConfirmationDialog(
                                  context: context,
                                  recordNumber: recordNum,
                                );

                                if (confirm == true) {
                                  await _storageService.deleteReceiptDocument(
                                    widget.selectedDate,
                                    recordNum,
                                  );
                                  Navigator.pop(context);
                                  await _showRecordSelectionDialog();
                                }
                              },
                            ),
                          ],
                        ),
                        onTap: () async {
                          Navigator.of(context).pop();
                          await _loadRecord(recordNum);
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
      CommonDialogs.showFilePathDialog(
        context: context,
        filePath: filePath,
      );
    }
  }

  void _createNewRecord(String recordNumber) {
    setState(() {
      serialNumber = recordNumber;
      _recordCreator = widget.sellerName;
      rowControllers.clear();
      rowFocusNodes.clear();
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

  Future<void> _loadRecord(String recordNumber) async {
    final document = await _storageService.loadReceiptDocument(
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
      _recordCreator = document.sellerName;

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

      for (var receipt in document.receipts) {
        List<TextEditingController> newControllers = [
          TextEditingController(text: receipt.serialNumber),
          TextEditingController(text: receipt.material),
          TextEditingController(text: receipt.affiliation),
          TextEditingController(text: receipt.count),
          TextEditingController(text: receipt.packaging),
          TextEditingController(text: receipt.standing),
          TextEditingController(text: receipt.payment),
          TextEditingController(text: receipt.load),
        ];

        List<FocusNode> newFocusNodes =
            List.generate(8, (index) => FocusNode());

        newControllers[1].addListener(() => _hasUnsavedChanges = true);
        newControllers[2].addListener(() => _hasUnsavedChanges = true);
        newControllers[4].addListener(() => _hasUnsavedChanges = true);

        // المستمعات للحقول الرقمية فقط
        newControllers[3].addListener(() {
          _hasUnsavedChanges = true;
          _calculateAllTotals();
        });
        newControllers[5].addListener(() {
          _hasUnsavedChanges = true;
          _calculateAllTotals();
        });
        newControllers[6].addListener(() {
          _hasUnsavedChanges = true;
          _calculateAllTotals();
        });
        newControllers[7].addListener(() {
          _hasUnsavedChanges = true;
          _calculateAllTotals();
        });

        rowControllers.add(newControllers);
        rowFocusNodes.add(newFocusNodes);
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
