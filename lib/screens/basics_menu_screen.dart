import 'package:flutter/material.dart';
import 'daily_movement_screen.dart'; // استيراد شاشة حركة اليومية

class BasicsMenuScreen extends StatelessWidget {
  const BasicsMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'أساسيات البرنامج',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue[600],
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
                Colors.blue[50]!,
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
                  icon: Icons.today,
                  label: 'حركة اليومية',
                  color: Colors.green[600]!,
                  onTap: () {
                    // الانتقال إلى شاشة حركة اليومية
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DailyMovementScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuButton(
                  context,
                  icon: Icons.people,
                  label: 'حركة الزبائن',
                  color: Colors.indigo[600]!,
                  onTap: () {}, // لا وظيفة حالياً
                ),
                _buildMenuButton(
                  context,
                  icon: Icons.local_shipping,
                  label: 'حركة الموردين',
                  color: Colors.brown[600]!,
                  onTap: () {}, // لا وظيفة حالياً
                ),
                _buildMenuButton(
                  context,
                  icon: Icons.grain,
                  label: 'حركة الغلة',
                  color: Colors.lime[700]!,
                  onTap: () {}, // لا وظيفة حالياً
                ),
                _buildMenuButton(
                  context,
                  icon: Icons.handshake,
                  label: 'حركة الشركاء',
                  color: Colors.teal[600]!,
                  onTap: () {}, // لا وظيفة حالياً
                ),
                _buildMenuButton(
                  context,
                  icon: Icons.money,
                  label: 'حركة الأجور',
                  color: Colors.amber[700]!,
                  onTap: () {}, // لا وظيفة حالياً
                ),
                _buildMenuButton(
                  context,
                  icon: Icons.account_balance,
                  label: 'حركة الأموال الجاهزة',
                  color: Colors.blueGrey[600]!,
                  onTap: () {}, // لا وظيفة حالياً
                ),
                _buildMenuButton(
                  context,
                  icon: Icons.inventory_2,
                  label: 'حركة المواد',
                  color: Colors.deepOrange[600]!,
                  onTap: () {}, // لا وظيفة حالياً
                ),
                _buildMenuButton(
                  context,
                  icon: Icons.recycling,
                  label: 'حركة الفوارغ',
                  color: Colors.grey[600]!,
                  onTap: () {}, // لا وظيفة حالياً
                ),
                _buildMenuButton(
                  context,
                  icon: Icons.currency_exchange,
                  label: 'حركة العملات',
                  color: Colors.lightGreen[700]!,
                  onTap: () {}, // لا وظيفة حالياً
                ),
                _buildMenuButton(
                  context,
                  icon: Icons.receipt_long,
                  label: 'حركة الفواتير',
                  color: Colors.red[600]!,
                  onTap: () {}, // لا وظيفة حالياً
                ),
                _buildMenuButton(
                  context,
                  icon: Icons.drive_eta,
                  label: 'حركة السائقين',
                  color: Colors.purple[700]!,
                  onTap: () {}, // لا وظيفة حالياً
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // دالة مساعدة لبناء أزرار القائمة (يمكن إعادة استخدامها)
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
