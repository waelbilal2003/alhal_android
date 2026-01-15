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

  // قوائم البيانات
  List<String> _customers = [];
  List<String> _suppliers = [];
  List<String> _materials = [];
  List<String> _packagings = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _loadStoreName();
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

  Future<void> _loadAllIndexes() async {
    _customers = await _customerIndexService.getAllCustomers();
    _suppliers = await _supplierIndexService.getAllSuppliers();
    _materials = await _materialIndexService.getAllMaterials();
    _packagings = await _packagingIndexService.getAllPackagings();

    setState(() {});
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
    // الانتقال مباشرة إلى شاشة التعديل بدون تحقق
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangePasswordScreen(
          currentStoreName: _currentStoreName,
          onStoreNameChanged: (newName) {
            // تحديث اسم المحل في الشاشة الحالية بعد التعديل
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
    if (_customers.isEmpty) {
      return _buildEmptyListMessage('لا يوجد زبائن مسجلين');
    }

    return _buildGenericList(
      title: 'فهرس الزبائن المسجلين',
      items: _customers,
      showDelete: true,
      onDelete: (index, item) => _confirmDeleteCustomer(item),
    );
  }

  Widget _buildSupplierList() {
    if (_suppliers.isEmpty) {
      return _buildEmptyListMessage('لا يوجد موردين مسجلين');
    }

    return _buildGenericList(
      title: 'فهرس الموردين المسجلين',
      items: _suppliers,
      showDelete: true,
      onDelete: (index, item) => _confirmDeleteSupplier(item),
    );
  }

  Widget _buildMaterialList() {
    if (_materials.isEmpty) {
      return _buildEmptyListMessage('لا يوجد مواد مسجلة');
    }

    return _buildGenericList(
      title: 'فهرس المواد المسجلة',
      items: _materials,
      showDelete: true,
      onDelete: (index, item) => _confirmDeleteMaterial(item),
    );
  }

  Widget _buildPackagingList() {
    if (_packagings.isEmpty) {
      return _buildEmptyListMessage('لا يوجد عبوات مسجلة');
    }

    return _buildGenericList(
      title: 'فهرس العبوات المسجلة',
      items: _packagings,
      showDelete: true,
      onDelete: (index, item) => _confirmDeletePackaging(item),
    );
  }

  Widget _buildEmptyListMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 18,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
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
    });
  }

  void _handleCustomerIndex() async {
    await _loadAllIndexes();
    setState(() {
      _showSellerList = false;
      _showCustomerList = true;
      _showSupplierList = false;
      _showMaterialList = false;
      _showPackagingList = false;
    });
  }

  void _handleSupplierIndex() async {
    await _loadAllIndexes();
    setState(() {
      _showSellerList = false;
      _showCustomerList = false;
      _showSupplierList = true;
      _showMaterialList = false;
      _showPackagingList = false;
    });
  }

  void _handleMaterialIndex() async {
    await _loadAllIndexes();
    setState(() {
      _showSellerList = false;
      _showCustomerList = false;
      _showSupplierList = false;
      _showMaterialList = true;
      _showPackagingList = false;
    });
  }

  void _handlePackagingIndex() async {
    await _loadAllIndexes();
    setState(() {
      _showSellerList = false;
      _showCustomerList = false;
      _showSupplierList = false;
      _showMaterialList = false;
      _showPackagingList = true;
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

      // إذا كان البائع المحذوف هو البائع الحالي، يجب تسجيل الخروج
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
      _customers.remove(customer);
      setState(() {});
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
      _suppliers.remove(supplier);
      setState(() {});
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
      _materials.remove(material);
      setState(() {});
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
      _packagings.remove(packaging);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildManagementScreen();
  }
}
