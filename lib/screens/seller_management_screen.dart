import 'package:flutter/material.dart';
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
  Map<int, String> _suppliersWithNumbers = {};
  Map<int, String> _materialsWithNumbers = {};
  Map<int, String> _packagingsWithNumbers = {};

  // متغيرات للتحكم في التعديل
  TextEditingController _addItemController = TextEditingController();
  FocusNode _addItemFocusNode = FocusNode();
  Map<String, TextEditingController> _itemControllers = {};
  Map<String, FocusNode> _itemFocusNodes = {};
  bool _isAddingNewItem = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _loadStoreName();
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
    _itemControllers.clear();
    _itemFocusNodes.clear();
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
    // تحميل جميع الفهارس مع الأرقام الحقيقية في نفس الوقت
    try {
      _customersWithNumbers =
          await _customerIndexService.getAllCustomersWithNumbers();
      _suppliersWithNumbers =
          await _supplierIndexService.getAllSuppliersWithNumbers();
      _materialsWithNumbers =
          await _materialIndexService.getAllMaterialsWithNumbers();
      _packagingsWithNumbers =
          await _packagingIndexService.getAllPackagingsWithNumbers();

      // تهيئة المتحكمات للعناصر الموجودة
      _initializeItemControllers();

      setState(() {});
    } catch (e) {
      print('خطأ في تحميل الفهارس: $e');
    }
  }

  void _initializeItemControllers() {
    _disposeItemControllers();

    Map<int, String> currentMap = _getCurrentMap();

    currentMap.forEach((key, value) {
      _itemControllers[value] = TextEditingController(text: value);
      _itemFocusNodes[value] = FocusNode();

      // إضافة listener لحفظ التعديل عند الخروج من الحقل
      _itemFocusNodes[value]!.addListener(() {
        if (!_itemFocusNodes[value]!.hasFocus) {
          _saveItemEdit(value);
        }
      });
    });
  }

  Map<int, String> _getCurrentMap() {
    if (_showCustomerList)
      return _customersWithNumbers;
    else if (_showSupplierList)
      return _suppliersWithNumbers;
    else if (_showMaterialList)
      return _materialsWithNumbers;
    else if (_showPackagingList) return _packagingsWithNumbers;
    return {};
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
                // اسم المحل
                Text(
                  _currentStoreName,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),

                // أزرار الإدارة الرئيسية
                _buildMainManagementButtons(),
                const SizedBox(height: 20),

                // أزرار الفهارس
                _buildIndexButtons(),
                const SizedBox(height: 40),

                // عرض الفهرس المحدد
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
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndexButton(
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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

    if (sellerNames.isEmpty) {
      return _buildEmptyListMessage('لا يوجد بائعين مسجلين');
    }

    return _buildGenericList(
      title: 'فهرس البائعين المسجلين',
      items: sellerNames,
      showDelete: true,
      onDelete: (index, item) => _confirmDeleteSeller(item),
      getPassword: (item) => _accounts[item] ?? '',
    );
  }

  Widget _buildCustomerList() {
    if (_customersWithNumbers.isEmpty && !_isAddingNewItem) {
      return _buildEmptyListMessage('لا يوجد زبائن مسجلين');
    }

    return _buildEditableListWithNumbers(
      title: 'فهرس الزبائن المسجلين',
      service: _customerIndexService,
      itemsMap: _customersWithNumbers,
    );
  }

  Widget _buildSupplierList() {
    if (_suppliersWithNumbers.isEmpty && !_isAddingNewItem) {
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
    // تحويل الخريطة إلى قائمة مرتبة حسب الأرقام
    List<MapEntry<int, String>> sortedEntries = itemsMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // العنوان وزر الإضافة
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
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: Icon(
                  _isAddingNewItem ? Icons.close : Icons.add,
                  color: Colors.white,
                  size: 28,
                ),
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

          // حقل إضافة جديد
          if (_isAddingNewItem) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
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
                        border: InputBorder.none,
                        hintTextDirection: TextDirection.rtl,
                      ),
                      onSubmitted: (value) {
                        _addNewItem(service, value);
                      },
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

          // جدول العناوين
          Row(
            textDirection: TextDirection.rtl,
            children: [
              const SizedBox(width: 60), // مساحة لزر الحذف
              Expanded(
                child: Text(
                  'الرقم الحقيقي',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'الاسم',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          Divider(color: Colors.white70, thickness: 1),

          // البيانات القابلة للتعديل
          if (sortedEntries.isNotEmpty || _isAddingNewItem) ...[
            ...sortedEntries.map((entry) {
              final key = entry.key;
              final item = entry.value;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    // زر الحذف
                    SizedBox(
                      width: 60,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          if (service is CustomerIndexService) {
                            _confirmDeleteCustomer(item);
                          } else if (service is SupplierIndexService) {
                            _confirmDeleteSupplier(item);
                          } else if (service is MaterialIndexService) {
                            _confirmDeleteMaterial(item);
                          } else if (service is PackagingIndexService) {
                            _confirmDeletePackaging(item);
                          }
                        },
                      ),
                    ),

                    // الرقم الحقيقي
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          key.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    // حقل الاسم القابل للتعديل
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: TextField(
                          controller: _itemControllers[item] ??
                              TextEditingController(text: item),
                          focusNode: _itemFocusNodes[item] ?? FocusNode(),
                          textDirection: TextDirection.rtl,
                          style: TextStyle(fontSize: 16, color: Colors.white),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onSubmitted: (value) {
                            _saveItemEdit(item);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'انقر على زر (+) لإضافة عنصر جديد',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addNewItem(dynamic service, String value) async {
    if (value.trim().isEmpty) return;

    try {
      if (service is CustomerIndexService) {
        await service.saveCustomer(value);
      } else if (service is SupplierIndexService) {
        await service.saveSupplier(value);
      } else if (service is MaterialIndexService) {
        await service.saveMaterial(value);
      } else if (service is PackagingIndexService) {
        await service.savePackaging(value);
      }

      // تحميل جميع الفهارس مع الأرقام
      await _loadAllIndexesWithNumbers();

      _addItemController.clear();
      setState(() {
        _isAddingNewItem = false;
      });

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

  Future<void> _saveItemEdit(String originalValue) async {
    final controller = _itemControllers[originalValue];
    if (controller == null) return;

    final newValue = controller.text.trim();
    if (newValue.isEmpty || newValue == originalValue) {
      controller.text = originalValue;
      return;
    }
  }

  Widget _buildEmptyListMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.white, size: 40),
            onPressed: () {
              setState(() {
                _isAddingNewItem = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _addItemFocusNode.requestFocus();
                });
              });
            },
          ),
          const Text(
            'انقر لإضافة عنصر جديد',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),

          // جدول العناوين
          Row(
            textDirection: TextDirection.rtl,
            children: [
              const SizedBox(width: 60), // مساحة لزر الحذف
              Expanded(
                child: Text(
                  'رقم',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'الاسم',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (getPassword != null)
                Expanded(
                  flex: 2,
                  child: Text(
                    'كلمة السر',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
          Divider(color: Colors.white70, thickness: 1),

          // البيانات
          ...items.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final item = entry.value;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  // زر الحذف
                  if (showDelete)
                    SizedBox(
                      width: 60,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => onDelete(index, item),
                      ),
                    ),

                  // الرقم
                  Expanded(
                    child: Text(
                      index.toString(),
                      style: TextStyle(fontSize: 16, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // الاسم
                  Expanded(
                    flex: 2,
                    child: Text(
                      item,
                      style: TextStyle(fontSize: 16, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // كلمة السر (للبائعين فقط)
                  if (getPassword != null)
                    Expanded(
                      flex: 2,
                      child: Text(
                        getPassword(item),
                        style: TextStyle(fontSize: 16, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
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
    // تحميل جميع الفهارس مرة واحدة فقط
    await _loadAllIndexesWithNumbers();
    setState(() {
      _showSellerList = false;
      _showCustomerList = true;
      _showSupplierList = false;
      _showMaterialList = false;
      _showPackagingList = false;
      _isAddingNewItem = false;
    });
  }

  void _handleSupplierIndex() async {
    // تحميل جميع الفهارس مرة واحدة فقط
    await _loadAllIndexesWithNumbers();
    setState(() {
      _showSellerList = false;
      _showCustomerList = false;
      _showSupplierList = true;
      _showMaterialList = false;
      _showPackagingList = false;
      _isAddingNewItem = false;
    });
  }

  void _handleMaterialIndex() async {
    // تحميل جميع الفهارس مرة واحدة فقط
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
    // تحميل جميع الفهارس مرة واحدة فقط
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
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text(
            'سيؤدي هذا إلى حذف البائع "$sellerName" بشكل نهائي. هل أنت متأكد؟',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('تأكيد'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

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

      final currentSeller = prefs.getString('current_seller');
      if (currentSeller == sellerName) {
        widget.onLogout();
      }

      setState(() {
        _accounts = Map<String, String>.from(accounts);
      });
    }
  }

  Future<void> _confirmDeleteCustomer(String customer) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text(
            'سيؤدي هذا إلى حذف الزبون "$customer" بشكل نهائي. هل أنت متأكد؟',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('تأكيد'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _customerIndexService.removeCustomer(customer);
      await _loadAllIndexesWithNumbers();
    }
  }

  Future<void> _confirmDeleteSupplier(String supplier) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text(
            'سيؤدي هذا إلى حذف المورد "$supplier" بشكل نهائي. هل أنت متأكد؟',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('تأكيد'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _supplierIndexService.removeSupplier(supplier);
      await _loadAllIndexesWithNumbers();
    }
  }

  Future<void> _confirmDeleteMaterial(String material) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text(
            'سيؤدي هذا إلى حذف المادة "$material" بشكل نهائي. هل أنت متأكد؟',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('تأكيد'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _materialIndexService.removeMaterial(material);
      await _loadAllIndexesWithNumbers();
    }
  }

  Future<void> _confirmDeletePackaging(String packaging) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text(
            'سيؤدي هذا إلى حذف العبوة "$packaging" بشكل نهائي. هل أنت متأكد؟',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('تأكيد'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _packagingIndexService.removePackaging(packaging);
      await _loadAllIndexesWithNumbers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildManagementScreen();
  }
}
