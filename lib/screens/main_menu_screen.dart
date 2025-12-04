import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'basics_menu_screen.dart'; // <-- تم تصحيح الاستيراد

class MainMenuScreen extends StatelessWidget {
  final String selectedDate;
  final String storeType; // <-- تم إضافة المتغير

  const MainMenuScreen({
    super.key,
    required this.selectedDate,
    required this.storeType, // <-- تم إضافته هنا
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'القائمة الرئيسية',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal[600],
        foregroundColor: Colors.white,
        elevation: 4,
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
                Colors.teal[50]!,
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
                  icon: Icons.settings_applications,
                  label: 'أساسيات البرنامج',
                  color: Colors.blue[600]!,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // تم إزالة const هنا
                        builder: (context) => BasicsMenuScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuButton(
                  context,
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'حركة الحسابات',
                  color: Colors.orange[600]!,
                  onTap: () {},
                ),
                _buildMenuButton(
                  context,
                  icon: Icons.miscellaneous_services,
                  label: 'الخدمات',
                  color: Colors.purple[600]!,
                  onTap: () {},
                ),
                _buildMenuButton(
                  context,
                  icon: Icons.store,
                  label: 'تغيير المحل',
                  color: Colors.cyan[700]!,
                  onTap: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                ),
                _buildMenuButton(
                  context,
                  icon: Icons.exit_to_app,
                  label: 'خروج',
                  color: Colors.red[600]!,
                  onTap: () {
                    SystemNavigator.pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
