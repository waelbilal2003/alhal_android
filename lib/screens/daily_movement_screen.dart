import 'package:flutter/material.dart';
import '../services/store_db_service.dart';
import 'seller_management_screen.dart';
import 'daily_movement/yield_screen.dart' as DailyMovementYield;
import 'daily_movement/purchases_screen.dart';
import 'daily_movement/sales_screen.dart';
import 'daily_movement/receipt_screen.dart';
import 'daily_movement/box_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyMovementScreen extends StatefulWidget {
  final String selectedDate;
  final String storeType;
  final String sellerName;

  const DailyMovementScreen({
    super.key,
    required this.selectedDate,
    required this.storeType,
    required this.sellerName,
  });

  @override
  State<DailyMovementScreen> createState() => _DailyMovementScreenState();
}

class _DailyMovementScreenState extends State<DailyMovementScreen> {
  String _storeName = '';

  @override
  void initState() {
    super.initState();
    _loadStoreName();
  }

  Future<void> _loadStoreName() async {
    final storeDbService = StoreDbService();
    final savedStoreName = await storeDbService.getStoreName();
    setState(() {
      _storeName = savedStoreName ?? widget.storeType;
    });
  }

  // دالة للتعامل مع زر الرجوع في AppBar
  void _handleBackButton() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('الحركة اليومية - ${widget.selectedDate}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBackButton,
          ),
        ),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 2, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3)
                  ],
                ),
                child: Text(
                  'البائع: ${widget.sellerName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 5.0),
                  child: GridView.count(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 12.0,
                    childAspectRatio: 2.25,
                    children: [
                      _buildMenuButton(context,
                          icon: Icons.inventory,
                          label: 'الاستلام',
                          color: Colors.blue[700]!, onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ReceiptScreen(
                                sellerName: widget.sellerName,
                                selectedDate: widget.selectedDate,
                                storeName: _storeName),
                          ),
                        );
                      }),
                      _buildMenuButton(context,
                          icon: Icons.point_of_sale,
                          label: 'المبيعات',
                          color: Colors.orange[700]!, onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => SalesScreen(
                                sellerName: widget.sellerName,
                                selectedDate: widget.selectedDate,
                                storeName: _storeName),
                          ),
                        );
                      }),
                      _buildMenuButton(context,
                          icon: Icons.shopping_cart,
                          label: 'المشتريات',
                          color: Colors.red[700]!, onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PurchasesScreen(
                                sellerName: widget.sellerName,
                                selectedDate: widget.selectedDate,
                                storeName: _storeName),
                          ),
                        );
                      }),
                      _buildMenuButton(context,
                          icon: Icons.account_balance,
                          label: 'الصندوق',
                          color: Colors.blueGrey[600]!, onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => BoxScreen(
                                sellerName: widget.sellerName,
                                selectedDate: widget.selectedDate,
                                storeName: _storeName),
                          ),
                        );
                      }),
                      _buildMenuButton(context,
                          icon: Icons.grain,
                          label: 'الغلة',
                          color: Colors.purple[700]!, onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                DailyMovementYield.YieldScreen(
                              sellerName: widget.sellerName,
                              password: '******',
                              selectedDate: widget.selectedDate,
                            ),
                          ),
                        );
                      }),
                      _buildMenuButton(context,
                          icon: Icons.settings,
                          label: 'الخدمات',
                          color: Colors.grey[600]!, onTap: () async {
                        final isAdmin = await _isAdminSeller(widget.sellerName);
                        if (isAdmin) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => SellerManagementScreen(
                                currentStoreName: _storeName,
                                onLogout: () {
                                  Navigator.of(context)
                                      .popUntil((route) => route.isFirst);
                                },
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('عفواً، هذه الخدمة متاحة فقط للإدارة'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      VoidCallback? onTap}) {
    // تحديد إذا كان زر الخدمات
    final isServicesButton = label == 'الخدمات';

    return FutureBuilder<bool>(
        future: isServicesButton
            ? _isAdminSeller(widget.sellerName)
            : Future.value(true),
        builder: (context, snapshot) {
          final isAdmin = snapshot.data ?? false;
          final isEnabled = !isServicesButton || isAdmin;

          return InkWell(
            onTap: isEnabled
                ? onTap ??
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم الضغط على $label'),
                          backgroundColor: color,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: isEnabled ? color : Colors.grey[400],
                borderRadius: BorderRadius.circular(12),
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                            color: color.withOpacity(0.4),
                            spreadRadius: 1,
                            blurRadius: 3)
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      size: 32,
                      color: isEnabled ? Colors.white : Colors.grey[200]),
                  const SizedBox(height: 5),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isEnabled ? Colors.white : Colors.grey[200],
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // إضافة علامة الادمن إذا كان زر الخدمات والمسؤول هو الادمن
                  if (isServicesButton && isAdmin)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.yellow,
                      ),
                    ),
                ],
              ),
            ),
          );
        });
  }

  // إضافة دالة للتحقق من الادمن
  Future<bool> _isAdminSeller(String sellerName) async {
    final prefs = await SharedPreferences.getInstance();
    final adminSeller = prefs.getString('admin_seller');
    return adminSeller == sellerName;
  }
}
