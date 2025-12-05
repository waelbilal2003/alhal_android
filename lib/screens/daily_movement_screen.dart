import 'package:flutter/material.dart';

class DailyMovementScreen extends StatelessWidget {
  final String selectedDate;
  final String storeType;
  final String? sellerName;

  const DailyMovementScreen({
    super.key,
    required this.selectedDate,
    required this.storeType,
    this.sellerName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('حركة اليومية - $selectedDate',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // شريط المعلومات العلوي المدمج
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 2)
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                textDirection: TextDirection.rtl,
                children: [
                  Text('المتجر: $storeType',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  Text('التاريخ: $selectedDate',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  if (sellerName != null)
                    Text('البائع: $sellerName',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            // شبكة الأزرار
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: GridView.count(
                  crossAxisCount: 4, // 4 أعمدة لاستغلال العرض
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 10.0,
                  childAspectRatio: 1.0, // مربع تقريباً
                  children: [
                    _buildMenuButton(context,
                        icon: Icons.inventory,
                        label: 'الاستلام',
                        color: Colors.blue[700]!),
                    _buildMenuButton(context,
                        icon: Icons.point_of_sale,
                        label: 'المبيعات',
                        color: Colors.orange[700]!),
                    _buildMenuButton(context,
                        icon: Icons.shopping_cart,
                        label: 'المشتريات',
                        color: Colors.red[700]!),
                    _buildMenuButton(context,
                        icon: Icons.account_balance,
                        label: 'الصندوق',
                        color: Colors.blueGrey[600]!),
                    _buildMenuButton(context,
                        icon: Icons.grain,
                        label: 'الغلة',
                        color: Colors.purple[700]!),
                    _buildMenuButton(context,
                        icon: Icons.settings,
                        label: 'الإعدادات',
                        color: Colors.grey[600]!),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // دالة بناء الزر المدمج
  Widget _buildMenuButton(BuildContext context,
      {required IconData icon, required String label, required Color color}) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم الضغط على $label'),
            backgroundColor: color,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.4), spreadRadius: 1, blurRadius: 3)
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: Colors.white),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
