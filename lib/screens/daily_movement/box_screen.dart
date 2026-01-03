import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/box_model.dart';
import '../../services/box_storage_service.dart';
import '../../widgets/table_builder.dart' as TableBuilder;
import '../../widgets/table_components.dart' as TableComponents;
import '../../widgets/common_dialogs.dart' as CommonDialogs;

class BoxScreen extends StatefulWidget {
  final String sellerName;
  final String selectedDate;
  final String storeName;

  const BoxScreen({
    Key? key,
    required this.sellerName,
    required this.selectedDate,
    required this.storeName,
  }) : super(key: key);

  @override
  _BoxScreenState createState() => _BoxScreenState();
}

class _BoxScreenState extends State<BoxScreen> {
  // خدمة التخزين
  final BoxStorageService _storageService = BoxStorageService();

  // بيانات الحقول
  String serialNumber = '';
  String dayName = '';

  // قائمة لتخزين صفوف الجدول
  List<List<TextEditingController>> rowControllers = [];
  List<List<FocusNode>> rowFocusNodes = [];
  List<String> accountTypeValues = [];

  // قوائم الخيارات
  final List<String> accountTypeOptions = ['زبون', 'مورد', 'مصروف'];

  // متحكمات للتمرير
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  // حالة الحفظ
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  String? _recordCreator;

  @override
  void initState() {
    super.initState();
    dayName = _extractDayName(widget.selectedDate);

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

  void _createNewRecord(String recordNumber) {
    setState(() {
      serialNumber = recordNumber;
      _recordCreator = widget.sellerName;
      rowControllers.clear();
      rowFocusNodes.clear();
      accountTypeValues.clear();
      _hasUnsavedChanges = false;
      _addNewRow(); // إضافة الصف الأول
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (rowFocusNodes.isNotEmpty && rowFocusNodes[0].length > 1) {
        FocusScope.of(context).requestFocus(rowFocusNodes[0][1]);
      }
    });
  }

  void _addNewRow() {
    setState(() {
      List<TextEditingController> newControllers =
          List.generate(5, (index) => TextEditingController());

      List<FocusNode> newFocusNodes = List.generate(5, (index) => FocusNode());

      newControllers[0].text = (rowControllers.length + 1).toString();

      // إضافة مستمعين للحقول
      newControllers[1].addListener(() {
        _hasUnsavedChanges = true;
        // إذا كان هناك قيمة في المقبوض، جعل المدفوع غير قابل للكتابة
        if (newControllers[1].text.isNotEmpty && mounted) {
          setState(() {
            newControllers[2].text = '';
          });
        }
      });

      newControllers[2].addListener(() {
        _hasUnsavedChanges = true;
        // إذا كان هناك قيمة في المدفوع، جعل المقبوض غير قابل للكتابة
        if (newControllers[2].text.isNotEmpty && mounted) {
          setState(() {
            newControllers[1].text = '';
          });
        }
      });

      newControllers[3].addListener(() => _hasUnsavedChanges = true);
      newControllers[4].addListener(() => _hasUnsavedChanges = true);

      rowControllers.add(newControllers);
      rowFocusNodes.add(newFocusNodes);
      accountTypeValues.add('');
    });
  }

  void _scrollToField(int rowIndex, int colIndex) {
    const double headerHeight = 32.0;
    const double rowHeight = 25.0;
    final double verticalPosition = (rowIndex * rowHeight);
    const double columnWidth = 80.0;
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
      columnWidths: {
        0: FlexColumnWidth(0.09), // مسلسل
        1: FlexColumnWidth(0.18), // مقبوض
        2: FlexColumnWidth(0.18), // مدفوع
        3: FlexColumnWidth(0.37), // الحساب
        4: FlexColumnWidth(0.18), // ملاحظات
      },
      border: TableBorder.all(color: Colors.grey, width: 0.5),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[200]),
          children: [
            TableComponents.buildTableHeaderCell('مسلسل'),
            TableComponents.buildTableHeaderCell('مقبوض'),
            TableComponents.buildTableHeaderCell('مدفوع'),
            TableComponents.buildTableHeaderCell('الحساب'),
            TableComponents.buildTableHeaderCell('ملاحظات'),
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
            _buildReceivedCell(rowControllers[i][1], rowFocusNodes[i][1], i, 1),
            _buildPaidCell(rowControllers[i][2], rowFocusNodes[i][2], i, 2),
            _buildAccountCell(i, 3), // هذا هو الحقل المعدل
            _buildNotesCell(rowControllers[i][4], rowFocusNodes[i][4], i, 4),
          ],
        ),
      );
    }

    return Table(
      columnWidths: {
        0: FlexColumnWidth(0.09),
        1: FlexColumnWidth(0.18),
        2: FlexColumnWidth(0.18),
        3: FlexColumnWidth(0.37),
        4: FlexColumnWidth(0.18),
      },
      border: TableBorder.all(color: Colors.grey, width: 0.5),
      children: contentRows,
    );
  }

  Widget _buildTableCell(TextEditingController controller, FocusNode focusNode,
      int rowIndex, int colIndex) {
    bool isSerialField = colIndex == 0;

    return TableBuilder.buildTableCell(
      controller: controller,
      focusNode: focusNode,
      isSerialField: isSerialField,
      isNumericField: false,
      rowIndex: rowIndex,
      colIndex: colIndex,
      scrollToField: _scrollToField,
      onFieldSubmitted: (value, rIndex, cIndex) =>
          _handleFieldSubmitted(value, rIndex, cIndex),
      onFieldChanged: (value, rIndex, cIndex) =>
          _handleFieldChanged(value, rIndex, cIndex),
      inputFormatters: null,
    );
  }

  Widget _buildReceivedCell(TextEditingController controller,
      FocusNode focusNode, int rowIndex, int colIndex) {
    return Container(
      padding: const EdgeInsets.all(1),
      constraints: const BoxConstraints(minHeight: 25),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        enabled: rowControllers[rowIndex][2]
            .text
            .isEmpty, // غير قابل للكتابة إذا كان المدفوع به قيمة
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          border: InputBorder.none,
          hintText: '0.00',
        ),
        inputFormatters: [
          TableComponents.PositiveDecimalInputFormatter(),
          FilteringTextInputFormatter.deny(RegExp(r'\.\d{3,}')),
        ],
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            // إذا كتب في المقبوض، انتقل مباشرة إلى الحساب
            _showAccountTypeDialog(rowIndex);
          } else {
            // إذا كان فارغاً، انتقل إلى المدفوع
            FocusScope.of(context).requestFocus(rowFocusNodes[rowIndex][2]);
          }
        },
        onChanged: (value) {
          _hasUnsavedChanges = true;
          // منع الكتابة في المدفوع إذا كان المقبوض به قيمة
          if (value.isNotEmpty && mounted) {
            setState(() {
              rowControllers[rowIndex][2].text = '';
            });
          }
        },
      ),
    );
  }

  Widget _buildPaidCell(TextEditingController controller, FocusNode focusNode,
      int rowIndex, int colIndex) {
    return Container(
      padding: const EdgeInsets.all(1),
      constraints: const BoxConstraints(minHeight: 25),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        enabled: rowControllers[rowIndex][1]
            .text
            .isEmpty, // غير قابل للكتابة إذا كان المقبوض به قيمة
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          border: InputBorder.none,
          hintText: '0.00',
        ),
        inputFormatters: [
          TableComponents.PositiveDecimalInputFormatter(),
          FilteringTextInputFormatter.deny(RegExp(r'\.\d{3,}')),
        ],
        onSubmitted: (value) {
          _showAccountTypeDialog(rowIndex);
        },
        onChanged: (value) {
          _hasUnsavedChanges = true;
          // منع الكتابة في المقبوض إذا كان المدفوع به قيمة
          if (value.isNotEmpty && mounted) {
            setState(() {
              rowControllers[rowIndex][1].text = '';
            });
          }
        },
      ),
    );
  }

  // هذه هي الدالة المعدلة لتكون مشابهة لـ purchases_screen ولكن مع إضافة إمكانية الكتابة
  Widget _buildAccountCell(int rowIndex, int colIndex) {
    final String accountType = accountTypeValues[rowIndex];
    final TextEditingController accountNameController =
        rowControllers[rowIndex][3];
    final FocusNode accountNameFocusNode = rowFocusNodes[rowIndex][3];

    // إذا كان نوع الحساب محدداً، نعرض حقل كتابة
    if (accountType.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(1),
        constraints: const BoxConstraints(minHeight: 25),
        child: Row(
          children: [
            // زر الاختيار (مشابه لـ purchases_screen)
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: () {
                  _showAccountTypeDialog(rowIndex);
                  _scrollToField(rowIndex, colIndex);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _getAccountTypeColor(accountType),
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Center(
                    child: Text(
                      accountType,
                      style: TextStyle(
                        fontSize: 10,
                        color: _getAccountTypeColor(accountType),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // حقل كتابة اسم الحساب (لجميع الخيارات)
            Expanded(
              flex: 5,
              child: TextField(
                controller: accountNameController,
                focusNode: accountNameFocusNode,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 0.5),
                  ),
                  hintText: _getAccountHintText(accountType),
                  hintStyle: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
                onSubmitted: (value) {
                  // عند الانتهاء من الكتابة، انتقل إلى الملاحظات
                  FocusScope.of(context)
                      .requestFocus(rowFocusNodes[rowIndex][4]);
                },
                onChanged: (value) {
                  _hasUnsavedChanges = true;
                },
                onTap: () {
                  _scrollToField(rowIndex, colIndex);
                },
              ),
            ),
          ],
        ),
      );
    }

    // إذا لم يتم تحديد نوع الحساب بعد، نعرض خلية اختيار فقط
    return Container(
      padding: const EdgeInsets.all(1),
      constraints: const BoxConstraints(minHeight: 25),
      child: InkWell(
        onTap: () {
          _showAccountTypeDialog(rowIndex);
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
                  'اختر',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.normal,
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

  // دالة للحصول على لون نوع الحساب
  Color _getAccountTypeColor(String accountType) {
    switch (accountType) {
      case 'زبون':
        return Colors.green;
      case 'مورد':
        return Colors.blue;
      case 'مصروف':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // دالة للحصول على نص التلميح بناءً على نوع الحساب
  String _getAccountHintText(String accountType) {
    switch (accountType) {
      case 'زبون':
        return 'اسم الزبون';
      case 'مورد':
        return 'اسم المورد';
      case 'مصروف':
        return 'نوع المصروف';
      default:
        return '...';
    }
  }

  // تعديل دالة معالجة الإرسال
  void _handleFieldSubmitted(String value, int rowIndex, int colIndex) {
    if (colIndex == 0) {
      FocusScope.of(context).requestFocus(rowFocusNodes[rowIndex][1]);
    } else if (colIndex == 1) {
      if (value.isNotEmpty) {
        _showAccountTypeDialog(rowIndex);
      } else {
        FocusScope.of(context).requestFocus(rowFocusNodes[rowIndex][2]);
      }
    } else if (colIndex == 2) {
      _showAccountTypeDialog(rowIndex);
    } else if (colIndex == 3) {
      // إذا كان حقل اسم الحساب، انتقل إلى الملاحظات
      FocusScope.of(context).requestFocus(rowFocusNodes[rowIndex][4]);
    } else if (colIndex == 4) {
      _addNewRow();
      if (rowControllers.isNotEmpty) {
        final newRowIndex = rowControllers.length - 1;
        FocusScope.of(context).requestFocus(rowFocusNodes[newRowIndex][1]);
      }
    }
  }

  Widget _buildNotesCell(TextEditingController controller, FocusNode focusNode,
      int rowIndex, int colIndex) {
    return Container(
      padding: const EdgeInsets.all(1),
      constraints: const BoxConstraints(minHeight: 25),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          border: InputBorder.none,
          hintText: '...',
        ),
        onSubmitted: (value) {
          _addNewRow();
          if (rowControllers.isNotEmpty) {
            final newRowIndex = rowControllers.length - 1;
            FocusScope.of(context).requestFocus(rowFocusNodes[newRowIndex][1]);
          }
        },
        onChanged: (value) {
          _hasUnsavedChanges = true;
        },
      ),
    );
  }

  // تعديل دالة إظهار دايلوج نوع الحساب
  void _showAccountTypeDialog(int rowIndex) {
    CommonDialogs.showAccountTypeDialog(
      context: context,
      currentValue: accountTypeValues[rowIndex],
      options: accountTypeOptions,
      onSelected: (value) {
        setState(() {
          accountTypeValues[rowIndex] = value;
          _hasUnsavedChanges = true;

          // إذا تم اختيار نوع الحساب، ركز على حقل اسم الحساب للكتابة
          if (value.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 150), () {
              if (mounted) {
                FocusScope.of(context).requestFocus(rowFocusNodes[rowIndex][3]);
                _scrollToField(rowIndex, 3);
              }
            });
          }
        });
      },
      onCancel: () {
        // إذا تم الإلغاء، نرجع التركيز إلى حقل المقبوض/المدفوع
        if (rowControllers[rowIndex][1].text.isNotEmpty) {
          FocusScope.of(context).requestFocus(rowFocusNodes[rowIndex][1]);
        } else if (rowControllers[rowIndex][2].text.isNotEmpty) {
          FocusScope.of(context).requestFocus(rowFocusNodes[rowIndex][2]);
        }
      },
    );
  }

  // تعديل دالة handleFieldChanged لإضافة دعم لاسم الحساب
  void _handleFieldChanged(String value, int rowIndex, int colIndex) {
    setState(() {
      _hasUnsavedChanges = true;

      if (colIndex == 0) {
        for (int i = 0; i < rowControllers.length; i++) {
          rowControllers[i][0].text = (i + 1).toString();
        }
      }

      // التحقق من عدم السماح بالكتابة في كلا الحقلين (المقبوض والمدفوع)
      if (colIndex == 1 && value.isNotEmpty) {
        rowControllers[rowIndex][2].text = '';
      } else if (colIndex == 2 && value.isNotEmpty) {
        rowControllers[rowIndex][1].text = '';
      }

      // إذا كان التغيير في حقل اسم الحساب (colIndex == 3)
      if (colIndex == 3) {
        _hasUnsavedChanges = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'يومية الصندوق رقم /$serialNumber/ ليوم $dayName تاريخ ${widget.selectedDate} لمحل ${widget.storeName} البائع ${widget.sellerName}',
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
      if (controllers[1].text.isNotEmpty ||
          controllers[2].text.isNotEmpty ||
          (controllers[3].text.isNotEmpty &&
              accountTypeValues[rowControllers.indexOf(controllers)]
                  .isNotEmpty)) {
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
    final transactionsList = <BoxTransaction>[];
    for (int i = 0; i < rowControllers.length; i++) {
      final controllers = rowControllers[i];
      transactionsList.add(BoxTransaction(
        serialNumber: controllers[0].text,
        received: controllers[1].text,
        paid: controllers[2].text,
        accountType: accountTypeValues[i],
        accountName: controllers[3].text,
        notes: controllers[4].text,
      ));
    }

    // حساب المجاميع
    double totalReceived = 0;
    double totalPaid = 0;
    for (var transaction in transactionsList) {
      totalReceived += double.tryParse(transaction.received) ?? 0;
      totalPaid += double.tryParse(transaction.paid) ?? 0;
    }

    final document = BoxDocument(
      recordNumber: serialNumber,
      date: widget.selectedDate,
      sellerName: widget.sellerName,
      storeName: widget.storeName,
      dayName: dayName,
      transactions: transactionsList,
      totals: {
        'totalReceived': totalReceived.toStringAsFixed(2),
        'totalPaid': totalPaid.toStringAsFixed(2),
      },
    );

    final success = await _storageService.saveBoxDocument(document);

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
                                  await _storageService.deleteBoxDocument(
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

  Future<void> _loadRecord(String recordNumber) async {
    final document = await _storageService.loadBoxDocument(
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
      accountTypeValues.clear();

      for (var transaction in document.transactions) {
        List<TextEditingController> newControllers = [
          TextEditingController(text: transaction.serialNumber),
          TextEditingController(text: transaction.received),
          TextEditingController(text: transaction.paid),
          TextEditingController(text: transaction.accountName),
          TextEditingController(text: transaction.notes),
        ];

        List<FocusNode> newFocusNodes =
            List.generate(5, (index) => FocusNode());

        newControllers[1].addListener(() {
          _hasUnsavedChanges = true;
          if (newControllers[1].text.isNotEmpty) {
            newControllers[2].text = '';
          }
        });

        newControllers[2].addListener(() {
          _hasUnsavedChanges = true;
          if (newControllers[2].text.isNotEmpty) {
            newControllers[1].text = '';
          }
        });

        newControllers[3].addListener(() => _hasUnsavedChanges = true);
        newControllers[4].addListener(() => _hasUnsavedChanges = true);

        rowControllers.add(newControllers);
        rowFocusNodes.add(newFocusNodes);
        accountTypeValues.add(transaction.accountType);
      }

      // إذا لم يكن هناك صفوف، أضف صفاً واحداً
      if (rowControllers.isEmpty) {
        _addNewRow();
      }

      _hasUnsavedChanges = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحميل السجل رقم $recordNumber'),
          backgroundColor: Colors.green,
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
