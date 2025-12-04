import 'package:flutter/material.dart';
// لم نعد نحتاج لاستيراد InvoiceEntryScreen

class DailyMovementScreen extends StatelessWidget {
  final String selectedDate;
  final String storeType;
  final String? sellerName; // إضافة اسم البائع

  const DailyMovementScreen({
    super.key,
    required this.selectedDate,
    required this.storeType,
    this.sellerName, // جعلها اختيارية
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'حركة اليومية - $selectedDate',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.green[50]!,
                Colors.grey[100]!,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // عرض معلومات المتجر والتاريخ والبائع
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'نوع المتجر: $storeType',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            'التاريخ: $selectedDate',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      if (sellerName != null) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'البائع: $sellerName',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // القائمة الرئيسية
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15.0,
                    mainAxisSpacing: 15.0,
                    childAspectRatio: 1.2,
                    children: [
                      _buildMenuButton(
                        context,
                        icon: Icons.inventory,
                        label: 'يومية الاستلام',
                        color: Colors.blue[700]!,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('تم الضغط على يومية الاستلام')),
                          );
                        },
                      ),
                      _buildMenuButton(
                        context,
                        icon: Icons.point_of_sale,
                        label: 'يومية المبيعات',
                        color: Colors.orange[700]!,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('تم الضغط على يومية المبيعات')),
                          );
                        },
                      ),
                      _buildMenuButton(
                        context,
                        icon: Icons.shopping_cart,
                        label: 'يومية المشتريات',
                        color: Colors.red[700]!,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('تم الضغط على يومية المشتريات')),
                          );
                        },
                      ),
                      _buildMenuButton(
                        context,
                        icon: Icons.account_balance,
                        label: 'يومية الصندوق',
                        color: Colors.blueGrey[600]!,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('تم الضغط على يومية الصندوق')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // دالة مساعدة لبناء أزرار القائمة
  Widget _buildMenuButton(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
