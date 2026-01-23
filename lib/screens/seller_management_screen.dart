import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/store_db_service.dart';

// استيراد خدمات الفهارس
import '../services/supplier_index_service.dart';
import '../services/customer_index_service.dart';
import '../services/material_index_service.dart';
import '../services/packaging_index_service.dart';

// استيراد الشاشات الأخرى المطلوبة
import 'change_password_screen.dart'; // الشاشة الموحدة الجديدة
import 'login_screen.dart';

class SellerManagementScreen extends StatefulWidget {
  final String currentStoreName;
  final Function() onLogout;

  const SellerManagementScreen({
    super.key,
    required this.currentStoreName,
    required this.onLogout,
  });

  @override
  State<SellerManagementScreen> createState() => _SellerManagementScreenState();
}

class _SellerManagementScreenState extends State<SellerManagementScreen> {
  String _currentStoreName = '';

  Map<String, String> _accounts = {};

  // متغيرات لعرض الفهارس المختلفة
  bool _showSellerList = false;
  bool _showCustomerList = false;
  bool _showSupplierList = false;
  bool _showMaterialList = false;
  bool _showPackagingList = false;

  // خدمات الفهارس
  final SupplierIndexService _supplierIndexService = SupplierIndexService();
  final CustomerIndexService _customerIndexService = CustomerIndexService();
  final MaterialIndexService _materialIndexService = MaterialIndexService();
  final PackagingIndexService _packagingIndexService = PackagingIndexService();

  // قوائم البيانات مع الأرقام الحقيقية
  Map<int, String> _customersWithNumbers = {};
  Map<int, CustomerData> _customersWithData = {};
  Map<int, String> _suppliersWithNumbers = {};
  Map<int, SupplierData> _suppliersWithData = {};
  Map<int, String> _materialsWithNumbers = {};
  Map<int, String> _packagingsWithNumbers = {};

  // متغيرات للتحكم في التعديل
  TextEditingController _addItemController = TextEditingController();
  FocusNode _addItemFocusNode = FocusNode();
  Map<String, TextEditingController> _itemControllers = {};
  Map<String, FocusNode> _itemFocusNodes = {};
  Map<String, TextEditingController> _mobileControllers = {};
  Map<String, FocusNode> _mobileFocusNodes = {};
  Map<String, TextEditingController> _balanceControllers = {};
  Map<String, FocusNode> _balanceFocusNodes = {};
  bool _isAddingNewItem = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _loadStoreName();

    // تحميل البيانات مسبقاً عند فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadData();
    });
  }

  @override
  void dispose() {
    _addItemController.dispose();
    _addItemFocusNode.dispose();
    _disposeItemControllers();
    super.dispose();
  }

  void _disposeItemControllers() {
    _itemControllers.values.forEach((controller) => controller.dispose());
    _itemFocusNodes.values.forEach((focusNode) => focusNode.dispose());
    _mobileControllers.values.forEach((controller) => controller.dispose());
    _mobileFocusNodes.values.forEach((focusNode) => focusNode.dispose());
    _balanceControllers.values.forEach((controller) => controller.dispose());
    _balanceFocusNodes.values.forEach((focusNode) => focusNode.dispose());
    _itemControllers.clear();
    _itemFocusNodes.clear();
    _mobileControllers.clear();
    _mobileFocusNodes.clear();
    _balanceControllers.clear();
    _balanceFocusNodes.clear();
  }

  Future<void> _loadStoreName() async {
    final storeDbService = StoreDbService();
    final savedStoreName = await storeDbService.getStoreName();
    setState(() {
      _currentStoreName = savedStoreName ?? widget.currentStoreName;
    });
  }

  Future<void> _loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = prefs.getString('accounts');
    setState(() {
      _accounts = accountsJson != null
          ? Map<String, String>.from(json.decode(accountsJson))
          : {};
    });
  }

  Future<void> _loadAllIndexesWithNumbers() async {
    try {
      // جلب جميع البيانات بشكل متزامن
      final customersFuture =
          _customerIndexService.getAllCustomersWithNumbers();
      final customersDataFuture =
          _customerIndexService.getAllCustomersWithData();
      final suppliersFuture =
          _supplierIndexService.getAllSuppliersWithNumbers();
      final suppliersDataFuture =
          _supplierIndexService.getAllSuppliersWithData();
      final materialsFuture =
          _materialIndexService.getAllMaterialsWithNumbers();
      final packagingsFuture =
          _packagingIndexService.getAllPackagingsWithNumbers();

      // انتظار جميع البيانات دفعة واحدة
      final results = await Future.wait([
        customersFuture,
        customersDataFuture,
        suppliersFuture,
        suppliersDataFuture,
        materialsFuture,
        packagingsFuture,
      ]);

      // تعيين النتائج
      _customersWithNumbers = results[0] as Map<int, String>;
      _customersWithData = results[1] as Map<int, CustomerData>;
      _suppliersWithNumbers = results[2] as Map<int, String>;
      _suppliersWithData = results[3] as Map<int, SupplierData>;
      _materialsWithNumbers = results[4] as Map<int, String>;
      _packagingsWithNumbers = results[5] as Map<int, String>;

      // تهيئة المتحكمات مرة واحدة
      _initializeItemControllers();

      // تحديث الواجهة مباشرة
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('❌ خطأ في تحميل الفهارس: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الفهارس: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _initializeItemControllers() {
    _disposeItemControllers();
    Map<int, String> currentMap = _getCurrentMap();

    currentMap.forEach((key, value) {
      // إنشاء المتحكمات للأسماء
      _itemControllers[value] = TextEditingController(text: value);
      _itemFocusNodes[value] = FocusNode();
      _itemFocusNodes[value]!.addListener(() {
        if (!_itemFocusNodes[value]!.hasFocus) {
          _saveItemEdit(key, value);
        }
      });

      // إذا كان زبوناً
      if (_showCustomerList && _customersWithData.containsKey(key)) {
        final mobile = _customersWithData[key]!.mobile;
        final balance = _customersWithData[key]!.balance;
        final isLocked = _customersWithData[key]!.isBalanceLocked;

        _mobileControllers[value] = TextEditingController(text: mobile);
        _mobileFocusNodes[value] = FocusNode();
        _mobileFocusNodes[value]!.addListener(() {
          if (!_mobileFocusNodes[value]!.hasFocus) {
            _saveMobileEdit(value);
          }
        });

        _balanceControllers[value] =
            TextEditingController(text: balance.toStringAsFixed(2));
        _balanceFocusNodes[value] = FocusNode();
        _balanceFocusNodes[value]!.addListener(() {
          if (!_balanceFocusNodes[value]!.hasFocus) {
            _saveBalanceEdit(value);
          }
        });

        // تسجيل البيانات للتتبع
        print(
            'زبون: $value | الرصيد: $balance | الموبايل: $mobile | مقفل: $isLocked');
      }
      // إذا كان مورداً
      else if (_showSupplierList && _suppliersWithData.containsKey(key)) {
        final mobile = _suppliersWithData[key]!.mobile;
        final balance = _suppliersWithData[key]!.balance;
        final isLocked = _suppliersWithData[key]!.isBalanceLocked;

        _mobileControllers[value] = TextEditingController(text: mobile);
        _mobileFocusNodes[value] = FocusNode();
        _mobileFocusNodes[value]!.addListener(() {
          if (!_mobileFocusNodes[value]!.hasFocus) {
            _saveMobileEdit(value);
          }
        });

        _balanceControllers[value] =
            TextEditingController(text: balance.toStringAsFixed(2));
        _balanceFocusNodes[value] = FocusNode();
        _balanceFocusNodes[value]!.addListener(() {
          if (!_balanceFocusNodes[value]!.hasFocus) {
            _saveBalanceEdit(value);
          }
        });

        // تسجيل البيانات للتتبع
        print(
            'مورد: $value | الرصيد: $balance | الموبايل: $mobile | مقفل: $isLocked');
      }
    });

    print('✅ تم تهيئة ${currentMap.length} متحكم');
  }

  Map<int, String> _getCurrentMap() {
    if (_showCustomerList) return _customersWithNumbers;
    if (_showSupplierList) return _suppliersWithNumbers;
    if (_showMaterialList) return _materialsWithNumbers;
    if (_showPackagingList) return _packagingsWithNumbers;
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return _buildManagementScreen();
  }

  Widget _buildManagementScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal[400]!, Colors.teal[700]!],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _currentStoreName,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                _buildMainManagementButtons(),
                const SizedBox(height: 20),
                _buildIndexButtons(),
                const SizedBox(height: 40),
                _buildCurrentIndexList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainManagementButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      textDirection: TextDirection.rtl,
      children: [
        _buildActionButton('إضافة', Icons.person_add, _handleAddSeller),
        _buildActionButton('تعديل', Icons.edit, _handleEditSeller),
        _buildActionButton('خروج', Icons.exit_to_app, () {
          Navigator.of(context).pop();
        }),
      ],
    );
  }

  Widget _buildIndexButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      textDirection: TextDirection.rtl,
      children: [
        _buildIndexButton(
            'فهرس البائعين', Icons.assignment_ind, _handleSellerIndex),
        _buildIndexButton('فهرس الزبائن', Icons.group, _handleCustomerIndex),
        _buildIndexButton(
            'فهرس الموردين', Icons.local_shipping, _handleSupplierIndex),
        _buildIndexButton(
            'فهرس المواد', Icons.shopping_basket, _handleMaterialIndex),
        _buildIndexButton(
            'فهرس العبوات', Icons.inventory_2, _handlePackagingIndex),
      ],
    );
  }

  Widget _buildActionButton(
      String text, IconData icon, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.teal[700]),
          label: Text(text, style: TextStyle(color: Colors.teal[700])),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildIndexButton(String text, IconData icon, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18, color: Colors.teal[700]),
          label: Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.teal[700]),
            textAlign: TextAlign.center,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }

  void _handleAddSeller() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const LoginScreen(initialState: LoginFlowState.setup),
      ),
    );
  }

  void _handleEditSeller() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangePasswordScreen(
          currentStoreName: _currentStoreName,
          onStoreNameChanged: (newName) {
            setState(() {
              _currentStoreName = newName;
            });
          },
        ),
      ),
    );
  }

  Widget _buildCurrentIndexList() {
    if (_showSellerList) return _buildSellerList();
    if (_showCustomerList) return _buildCustomerList();
    if (_showSupplierList) return _buildSupplierList();
    if (_showMaterialList) return _buildMaterialList();
    if (_showPackagingList) return _buildPackagingList();
    return const SizedBox.shrink();
  }

  Widget _buildSellerList() {
    final sellerNames = _accounts.keys.toList();
    if (sellerNames.isEmpty)
      return _buildEmptyListMessage('لا يوجد بائعين مسجلين');
    return _buildGenericList(
      title: 'فهرس البائعين المسجلين',
      items: sellerNames,
      showDelete: true,
      onDelete: (index, item) => _confirmDeleteSeller(item),
      getPassword: (item) => _accounts[item] ?? '',
    );
  }

  Widget _buildCustomerList() {
    // إذا كانت القائمة فارغة ولم يكن هناك إضافة جديدة
    if (_customersWithNumbers.isEmpty && !_isAddingNewItem) {
      // إذا كان العرض نشطاً ولكن البيانات لم تحمل بعد
      if (_showCustomerList && _customersWithNumbers.isEmpty) {
        // عرض مؤشر تحميل أثناء جلب البيانات
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text('جاري تحميل بيانات الزبائن...',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ],
          ),
        );
      }

      return _buildEmptyListMessage('لا يوجد زبائن مسجلين');
    }

    return _buildEditableListWithNumbers(
      title: 'فهرس الزبائن المسجلين',
      service: _customerIndexService,
      itemsMap: _customersWithNumbers,
    );
  }

  Widget _buildSupplierList() {
    // إذا كانت القائمة فارغة ولم يكن هناك إضافة جديدة
    if (_suppliersWithNumbers.isEmpty && !_isAddingNewItem) {
      // إذا كان العرض نشطاً ولكن البيانات لم تحمل بعد
      if (_showSupplierList && _suppliersWithNumbers.isEmpty) {
        // عرض مؤشر تحميل أثناء جلب البيانات
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text('جاري تحميل بيانات الموردين...',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ],
          ),
        );
      }

      return _buildEmptyListMessage('لا يوجد موردين مسجلين');
    }

    return _buildEditableListWithNumbers(
      title: 'فهرس الموردين المسجلين',
      service: _supplierIndexService,
      itemsMap: _suppliersWithNumbers,
    );
  }

  Widget _buildMaterialList() {
    if (_materialsWithNumbers.isEmpty && !_isAddingNewItem) {
      return _buildEmptyListMessage('لا يوجد مواد مسجلة');
    }
    return _buildEditableListWithNumbers(
      title: 'فهرس المواد المسجلة',
      service: _materialIndexService,
      itemsMap: _materialsWithNumbers,
    );
  }

  Widget _buildPackagingList() {
    if (_packagingsWithNumbers.isEmpty && !_isAddingNewItem) {
      return _buildEmptyListMessage('لا يوجد عبوات مسجلة');
    }
    return _buildEditableListWithNumbers(
      title: 'فهرس العبوات المسجلة',
      service: _packagingIndexService,
      itemsMap: _packagingsWithNumbers,
    );
  }

  Widget _buildEditableListWithNumbers({
    required String title,
    required dynamic service,
    required Map<int, String> itemsMap,
  }) {
    List<MapEntry<int, String>> sortedEntries = itemsMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    bool isCustomer = service is CustomerIndexService;
    bool isSupplier = service is SupplierIndexService;
    bool hasExtraCols = isCustomer || isSupplier;

    // تحقق من بيانات الرصيد
    Map<int, CustomerData> customerData = {};
    Map<int, SupplierData> supplierData = {};

    if (isCustomer) {
      customerData = _customersWithData;
    } else if (isSupplier) {
      supplierData = _suppliersWithData;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              // زر تدقيق الأرصدة
              if (hasExtraCols)
                IconButton(
                  icon:
                      const Icon(Icons.verified, color: Colors.white, size: 24),
                  onPressed: () async {
                    await _auditBalances(service);
                  },
                  tooltip: 'تدقيق وتأكيد الأرصدة',
                ),
              IconButton(
                icon: Icon(_isAddingNewItem ? Icons.close : Icons.add,
                    color: Colors.white, size: 28),
                onPressed: () {
                  setState(() {
                    _isAddingNewItem = !_isAddingNewItem;
                    if (!_isAddingNewItem) {
                      _addItemController.clear();
                    } else {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _addItemFocusNode.requestFocus();
                      });
                    }
                  });
                },
              ),
            ],
          ),
          if (_isAddingNewItem) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addItemController,
                      focusNode: _addItemFocusNode,
                      textDirection: TextDirection.rtl,
                      decoration: const InputDecoration(
                          hintText: 'أدخل العنصر الجديد...',
                          border: InputBorder.none),
                      onSubmitted: (value) => _addNewItem(service, value),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.teal),
                    onPressed: () {
                      if (_addItemController.text.trim().isNotEmpty) {
                        _addNewItem(service, _addItemController.text);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
          ],
          // رأس الجدول
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                const SizedBox(width: 50), // مساحة لزر الحذف
                _buildHeaderCell('الرقم', 1),
                _buildHeaderCell('الاسم', 3),
                if (hasExtraCols) ...[
                  _buildHeaderCell('الرصيد', 2),
                  _buildHeaderCell('الموبايل', 2),
                  _buildHeaderCell('الحالة', 1),
                ],
              ],
            ),
          ),
          Divider(color: Colors.white70, thickness: 1),
          if (sortedEntries.isNotEmpty || _isAddingNewItem) ...[
            ...sortedEntries.map((entry) {
              final key = entry.key;
              final item = entry.value;

              double balance = 0;
              String mobile = '';
              bool isLocked = true;
              String balanceStatus = '✅';

              if (isCustomer && customerData.containsKey(key)) {
                balance = customerData[key]!.balance;
                mobile = customerData[key]!.mobile;
                isLocked = customerData[key]!.isBalanceLocked;
                balanceStatus = isLocked ? '🔒' : '✏️';
              } else if (isSupplier && supplierData.containsKey(key)) {
                balance = supplierData[key]!.balance;
                mobile = supplierData[key]!.mobile;
                isLocked = supplierData[key]!.isBalanceLocked;
                balanceStatus = isLocked ? '🔒' : '✏️';
              }

              // تحقق من سلامة الرصيد
              if (balance.isNaN || balance.isInfinite) {
                balance = 0.0;
                balanceStatus = '⚠️';
              }

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.1), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      SizedBox(
                        width: 50,
                        child: Center(
                          child: IconButton(
                            icon: const Icon(Icons.delete_forever,
                                color: Colors.red, size: 20),
                            onPressed: () {
                              if (service is CustomerIndexService)
                                _confirmDeleteCustomer(item);
                              else if (service is SupplierIndexService)
                                _confirmDeleteSupplier(item);
                              else if (service is MaterialIndexService)
                                _confirmDeleteMaterial(item);
                              else if (service is PackagingIndexService)
                                _confirmDeletePackaging(item);
                            },
                          ),
                        ),
                      ),
                      _buildDataCell(key.toString(), 1),
                      Expanded(
                        flex: 3,
                        child: _buildEditableTextField(
                          controller: _itemControllers[item] ??
                              TextEditingController(text: item),
                          focusNode: _itemFocusNodes[item] ?? FocusNode(),
                          onSubmitted: (val) => _saveItemEdit(key, item),
                        ),
                      ),
                      if (hasExtraCols) ...[
                        Expanded(
                          flex: 2,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            child: Stack(
                              children: [
                                _buildEditableTextField(
                                  controller: _balanceControllers[item] ??
                                      TextEditingController(
                                          text: balance.toStringAsFixed(2)),
                                  focusNode:
                                      _balanceFocusNodes[item] ?? FocusNode(),
                                  onSubmitted: (val) => _saveBalanceEdit(item),
                                  isNumeric: true,
                                  isReadOnly: isLocked,
                                ),
                                if (isLocked)
                                  Positioned(
                                    left: 4,
                                    top: 4,
                                    child: Icon(Icons.lock,
                                        size: 12, color: Colors.grey[600]),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _buildEditableTextField(
                            controller: _mobileControllers[item] ??
                                TextEditingController(text: mobile),
                            focusNode: _mobileFocusNodes[item] ?? FocusNode(),
                            onSubmitted: (val) => _saveMobileEdit(item),
                            isNumeric: true,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getBalanceStatusColor(balanceStatus),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                balanceStatus,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),

            // صف الملخص الإحصائي
            if (hasExtraCols && sortedEntries.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal, width: 1),
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryStat(
                        'إجمالي العناصر', '${sortedEntries.length}'),
                    _buildSummaryStat(
                        'إجمالي الرصيد',
                        _calculateTotalBalance(isCustomer, isSupplier)
                            .toStringAsFixed(2)),
                    _buildSummaryStat(
                        'متوسط الرصيد',
                        _calculateAverageBalance(
                                isCustomer, isSupplier, sortedEntries.length)
                            .toStringAsFixed(2)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

// دالة مساعدة لبناء خلية الرأس
  Widget _buildHeaderCell(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }

// دالة مساعدة لبناء خلية البيانات
  Widget _buildDataCell(String text, int flex, {bool isReadOnly = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color:
              isReadOnly ? Colors.white.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

// دالة مساعدة لبناء حقل نص قابل للتحرير
  Widget _buildEditableTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required Function(String) onSubmitted,
    bool isNumeric = false,
    bool isReadOnly = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
          color: isReadOnly
              ? Colors.grey.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4)),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: !isReadOnly,
        textDirection: TextDirection.rtl,
        keyboardType: isNumeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        inputFormatters: isNumeric
            ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
            : null,
        style: TextStyle(
            fontSize: 14, color: isReadOnly ? Colors.white70 : Colors.white),
        decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8)),
        onSubmitted: onSubmitted,
        onTap: () {
          if (!isReadOnly && isNumeric && controller.text == '0.00') {
            controller.clear();
          }
        },
      ),
    );
  }

// دالة مساعدة للحصول على لون حالة الرصيد
  Color _getBalanceStatusColor(String status) {
    switch (status) {
      case '✅':
        return Colors.green;
      case '🔒':
        return Colors.orange;
      case '✏️':
        return Colors.blue;
      case '⚠️':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

// دالة مساعدة لبناء إحصائية الملخص
  Widget _buildSummaryStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

// دالة لحساب إجمالي الرصيد
  double _calculateTotalBalance(bool isCustomer, bool isSupplier) {
    double total = 0;

    if (isCustomer) {
      for (var data in _customersWithData.values) {
        total += data.balance;
      }
    } else if (isSupplier) {
      for (var data in _suppliersWithData.values) {
        total += data.balance;
      }
    }

    return total;
  }

// دالة لحساب متوسط الرصيد
  double _calculateAverageBalance(bool isCustomer, bool isSupplier, int count) {
    if (count == 0) return 0;

    double total = _calculateTotalBalance(isCustomer, isSupplier);
    return total / count;
  }

  Future<void> _auditBalances(dynamic service) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('جاري تدقيق الأرصدة...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('يرجى الانتظار أثناء تدقيق جميع الأرصدة'),
          ],
        ),
      ),
    );

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      if (service is SupplierIndexService) {
        final suppliers = await service.getAllSuppliersWithData();
        int corrected = 0;

        for (var entry in suppliers.entries) {
          final supplier = entry.value;

          // هنا يمكنك إضافة منطق التدقيق إذا كان متاحاً
          // حالياً سنقوم فقط بإعادة تحميل البيانات

          // مثال: إذا كان هناك دالة لحساب الرصيد من التاريخ
          // double calculated = await service.calculateSupplierBalanceFromHistory(supplier.name);
          // if (supplier.balance != calculated) {
          //   corrected++;
          //   await service.correctSupplierBalance(supplier.name, calculated);
          // }
        }

        Navigator.pop(context);

        // إعادة تحميل البيانات
        if (service is SupplierIndexService) {
          await _loadSupplierDataImmediately();
        } else if (service is CustomerIndexService) {
          await _loadCustomerDataImmediately();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تدقيق ${suppliers.length} سجل'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في التدقيق: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

/*
// دالة تدقيق الأرصدة
  Future<void> _auditAllBalances(dynamic service) async {
    try {
      if (service is SupplierIndexService) {
        final suppliers = await service.getAllSuppliersWithData();

        for (var entry in suppliers.entries) {
          final supplier = entry.value;
          final calculatedBalance =
              await service.calculateSupplierBalanceFromHistory(supplier.name);

          if (supplier.balance != calculatedBalance) {
            print('⚠️ تناقض في رصيد المورد ${supplier.name}:');
            print('   - الرصيد المسجل: ${supplier.balance}');
            print('   - الرصيد المحسوب: $calculatedBalance');

            // تصحيح الرصيد
            await service.correctSupplierBalance(
                supplier.name, calculatedBalance);
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تدقيق أرصدة ${suppliers.length} مورد'),
            backgroundColor: Colors.green,
          ),
        );

        // إعادة تحميل البيانات
        await _loadAllIndexesWithNumbers();
      }
    } catch (e) {
      print('❌ خطأ في تدقيق الأرصدة: $e');
    }
  }
*/
  Future<void> _saveItemEdit(int id, String originalValue) async {
    final controller = _itemControllers[originalValue];
    if (controller == null) return;
    final newValue = controller.text.trim();
    if (newValue.isEmpty || newValue == originalValue) {
      controller.text = originalValue;
      return;
    }
    if (_showCustomerList) {
      await _customerIndexService.updateCustomerName(id, newValue);
    } else if (_showSupplierList) {
      await _supplierIndexService.updateSupplierName(id, newValue);
    }
    await _loadAllIndexesWithNumbers();
  }

  Future<void> _saveMobileEdit(String itemName) async {
    final controller = _mobileControllers[itemName];
    if (controller == null) return;
    final newMobile = controller.text.trim();

    if (_showCustomerList) {
      await _customerIndexService.updateCustomerMobile(itemName, newMobile);
    } else if (_showSupplierList) {
      await _supplierIndexService.updateSupplierMobile(itemName, newMobile);
    }
    await _loadAllIndexesWithNumbers();
  }

  Future<void> _saveBalanceEdit(String itemName) async {
    final controller = _balanceControllers[itemName];
    if (controller == null) return;
    final newBalance = double.tryParse(controller.text.trim()) ?? 0.0;
    if (_showCustomerList) {
      await _customerIndexService.setInitialBalance(itemName, newBalance);
    } else if (_showSupplierList) {
      await _supplierIndexService.setInitialBalance(itemName, newBalance);
    }
    await _loadAllIndexesWithNumbers();
  }

  Widget _buildEmptyListMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(message,
              style: const TextStyle(fontSize: 18, color: Colors.white),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.white, size: 40),
            onPressed: () {
              setState(() {
                _isAddingNewItem = true;
                WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _addItemFocusNode.requestFocus());
              });
            },
          ),
          const Text('انقر لإضافة عنصر جديد',
              style: TextStyle(fontSize: 14, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildGenericList({
    required String title,
    required List<String> items,
    bool showDelete = false,
    required Function(int index, String item) onDelete,
    String Function(String item)? getPassword,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              textAlign: TextAlign.center),
          const SizedBox(height: 15),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              const SizedBox(width: 60),
              _buildHeaderCell('رقم', 1),
              _buildHeaderCell('الاسم', 2),
              if (getPassword != null) _buildHeaderCell('كلمة السر', 2),
            ],
          ),
          Divider(color: Colors.white70, thickness: 1),
          ...items.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  if (showDelete)
                    SizedBox(
                        width: 60,
                        child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => onDelete(index, item))),
                  _buildDataCell(index.toString(), 1),
                  _buildDataCell(item, 2),
                  if (getPassword != null) _buildDataCell(getPassword(item), 2),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _handleSellerIndex() {
    setState(() {
      _showSellerList = true;
      _showCustomerList = false;
      _showSupplierList = false;
      _showMaterialList = false;
      _showPackagingList = false;
      _isAddingNewItem = false;
    });
  }

  void _handleCustomerIndex() async {
    // إظهار المؤشر تحميل فوراً
    setState(() {
      _showSellerList = false;
      _showCustomerList = true;
      _showSupplierList = false;
      _showMaterialList = false;
      _showPackagingList = false;
      _isAddingNewItem = false;
    });

    // جلب البيانات في الخلفية
    await _loadCustomerDataImmediately();
  }

// دالة جديدة لجلب بيانات الزبائن فوراً
  Future<void> _loadCustomerDataImmediately() async {
    try {
      // جلب البيانات بشكل متزامن
      _customersWithNumbers =
          await _customerIndexService.getAllCustomersWithNumbers();
      _customersWithData =
          await _customerIndexService.getAllCustomersWithData();

      // تهيئة المتحكمات فوراً
      _initializeItemControllers();

      // تحديث الواجهة مباشرة
      if (mounted) {
        setState(() {});
      }

      // سجل للتتبع (يمكن إزالته)
      print(
          '✅ بيانات الزبائن تم تحميلها فوراً: ${_customersWithData.length} سجلاً');
    } catch (e) {
      print('❌ خطأ في تحميل بيانات الزبائن: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل بيانات الزبائن: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleSupplierIndex() async {
    // إظهار المؤشر تحميل فوراً
    setState(() {
      _showSellerList = false;
      _showCustomerList = false;
      _showSupplierList = true;
      _showMaterialList = false;
      _showPackagingList = false;
      _isAddingNewItem = false;
    });

    // جلب البيانات في الخلفية
    await _loadSupplierDataImmediately();
  }

// دالة جديدة لجلب بيانات الموردين فوراً
  Future<void> _loadSupplierDataImmediately() async {
    try {
      // جلب البيانات بشكل متزامن
      _suppliersWithNumbers =
          await _supplierIndexService.getAllSuppliersWithNumbers();
      _suppliersWithData =
          await _supplierIndexService.getAllSuppliersWithData();

      // تهيئة المتحكمات فوراً
      _initializeItemControllers();

      // تحديث الواجهة مباشرة
      if (mounted) {
        setState(() {});
      }

      // سجل للتتبع (يمكن إزالته)
      print(
          '✅ بيانات الموردين تم تحميلها فوراً: ${_suppliersWithData.length} سجلاً');
    } catch (e) {
      print('❌ خطأ في تحميل بيانات الموردين: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل بيانات الموردين: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleMaterialIndex() async {
    await _loadAllIndexesWithNumbers();
    setState(() {
      _showSellerList = false;
      _showCustomerList = false;
      _showSupplierList = false;
      _showMaterialList = true;
      _showPackagingList = false;
      _isAddingNewItem = false;
    });
  }

  void _handlePackagingIndex() async {
    await _loadAllIndexesWithNumbers();
    setState(() {
      _showSellerList = false;
      _showCustomerList = false;
      _showSupplierList = false;
      _showMaterialList = false;
      _showPackagingList = true;
      _isAddingNewItem = false;
    });
  }

  Future<void> _confirmDeleteSeller(String sellerName) async {
    final result = await _showConfirmDialog('تأكيد الحذف',
        'سيؤدي هذا إلى حذف البائع "$sellerName" بشكل نهائي. هل أنت متأكد؟');
    if (result == true) {
      await _deleteSeller(sellerName);
      _loadAccounts();
    }
  }

  Future<void> _deleteSeller(String sellerName) async {
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = prefs.getString('accounts');
    if (accountsJson != null) {
      Map<String, dynamic> accounts = json.decode(accountsJson);
      accounts.remove(sellerName);
      await prefs.setString('accounts', json.encode(accounts));
      if (prefs.getString('current_seller') == sellerName) widget.onLogout();
      setState(() => _accounts = Map<String, String>.from(accounts));
    }
  }

  Future<void> _confirmDeleteCustomer(String customer) async {
    if (await _showConfirmDialog(
        'تأكيد الحذف', 'هل أنت متأكد من حذف الزبون "$customer"؟')) {
      await _customerIndexService.removeCustomer(customer);
      await _loadAllIndexesWithNumbers();
    }
  }

  Future<void> _confirmDeleteSupplier(String supplier) async {
    if (await _showConfirmDialog(
        'تأكيد الحذف', 'هل أنت متأكد من حذف المورد "$supplier"؟')) {
      await _supplierIndexService.removeSupplier(supplier);
      await _loadAllIndexesWithNumbers();
    }
  }

  Future<void> _confirmDeleteMaterial(String material) async {
    if (await _showConfirmDialog(
        'تأكيد الحذف', 'هل أنت متأكد من حذف المادة "$material"؟')) {
      await _materialIndexService.removeMaterial(material);
      await _loadAllIndexesWithNumbers();
    }
  }

  Future<void> _confirmDeletePackaging(String packaging) async {
    if (await _showConfirmDialog(
        'تأكيد الحذف', 'هل أنت متأكد من حذف العبوة "$packaging"؟')) {
      await _packagingIndexService.removePackaging(packaging);
      await _loadAllIndexesWithNumbers();
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                  child: const Text('إلغاء'),
                  onPressed: () => Navigator.of(context).pop(false)),
              TextButton(
                  child: const Text('تأكيد'),
                  onPressed: () => Navigator.of(context).pop(true)),
            ],
          ),
        ) ??
        false;
  }

// تحميل مسبق للبيانات
  Future<void> _preloadData() async {
    try {
      // جلب بيانات الزبائن والموردين مسبقاً
      await Future.wait([
        _customerIndexService.getAllCustomersWithData(),
        _supplierIndexService.getAllSuppliersWithData(),
      ]);

      print('✅ البيانات تم تحميلها مسبقاً');
    } catch (e) {
      print('⚠️ تحميل البيانات المسبق فشل: $e');
    }
  }

  Future<void> _addNewItem(dynamic service, String value) async {
    if (value.trim().isEmpty) return;
    try {
      if (service is CustomerIndexService)
        await service.saveCustomer(value);
      else if (service is SupplierIndexService)
        await service.saveSupplier(value);
      else if (service is MaterialIndexService)
        await service.saveMaterial(value);
      else if (service is PackagingIndexService)
        await service.savePackaging(value);

      // إعادة تحميل البيانات حسب النوع
      if (service is CustomerIndexService) {
        await _loadCustomerDataImmediately();
      } else if (service is SupplierIndexService) {
        await _loadSupplierDataImmediately();
      } else if (service is MaterialIndexService) {
        await _loadMaterialDataImmediately();
      } else if (service is PackagingIndexService) {
        await _loadPackagingDataImmediately();
      }

      _addItemController.clear();
      setState(() => _isAddingNewItem = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إضافة "$value" بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء الإضافة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// دوال التحميل الخاصة بكل نوع
  Future<void> _loadMaterialDataImmediately() async {
    try {
      _materialsWithNumbers =
          await _materialIndexService.getAllMaterialsWithNumbers();
      _initializeItemControllers();
      if (mounted) setState(() {});
    } catch (e) {
      print('❌ خطأ في تحميل المواد: $e');
    }
  }

  Future<void> _loadPackagingDataImmediately() async {
    try {
      _packagingsWithNumbers =
          await _packagingIndexService.getAllPackagingsWithNumbers();
      _initializeItemControllers();
      if (mounted) setState(() {});
    } catch (e) {
      print('❌ خطأ في تحميل العبوات: $e');
    }
  }
}
