import 'package:flutter/material.dart';
import 'package:market_ledger/screens/general_sales_screen.dart';
import 'package:market_ledger/screens/marketer_sales_screen.dart';
import 'package:market_ledger/screens/marketer_by_supplier_screen.dart';
import 'package:market_ledger/screens/commission_sales_screen.dart';
import 'package:market_ledger/screens/customer_sales_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'سوق الهال - النظام المحاسبي',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.3),
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Icon(
                    Icons.store,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'نظام إدارة مبيعات الخضراوات',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اختر نوع الفاتورة',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                  ),
                  const SizedBox(height: 40),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildMenuCard(
                          context,
                          title: 'صفحة المبيعات العامة',
                          subtitle: 'إدارة المبيعات اليومية العامة',
                          icon: Icons.receipt_long,
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const GeneralSalesScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildMenuCard(
                          context,
                          title: 'مبيعات المسواق',
                          subtitle: 'مبيعات المسوقين الثانوية',
                          icon: Icons.business_center,
                          color: Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MarketerSalesScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildMenuCard(
                          context,
                          title: 'مبيعات المسواق حسب مورد',
                          subtitle: 'مبيعات مرتبطة بمورد معين',
                          icon: Icons.local_shipping,
                          color: Colors.orange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MarketerBySupplierScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildMenuCard(
                          context,
                          title: 'مبيعات الكمسيون (عمولة)',
                          subtitle: 'فواتير المبيعات بنظام العمولة',
                          icon: Icons.attach_money,
                          color: Colors.purple,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const CommissionSalesScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildMenuCard(
                          context,
                          title: 'المبيعات حسب زبون',
                          subtitle: 'فواتير مخصصة لزبون محدد',
                          icon: Icons.person,
                          color: Colors.teal,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const CustomerSalesScreen(),
                              ),
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
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_back_ios,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
