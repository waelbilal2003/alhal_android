import 'package:flutter/material.dart';
import 'invoice_entry_screen.dart';

class DailyMovementScreen extends StatelessWidget {
  const DailyMovementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'حركة اليومية',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
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
                  onTap: () {}, // لا وظيفة حالياً
                ),
                _buildMenuButton(
                  context,
                  icon: Icons.point_of_sale,
                  label: 'يومية المبيعات',
                  color: Colors.orange[700]!,
                  onTap: () {
                    // الانتقال إلى شاشة إدخال الفاتورة
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InvoiceEntryScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuButton(
                  context,
                  icon: Icons.shopping_cart,
                  label: 'يومية المشتريات',
                  color: Colors.red[700]!,
                  onTap: () {}, // لا وظيفة حالياً
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
