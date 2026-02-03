import 'package:flutter/material.dart';
import '../../services/customer_index_service.dart';
import 'invoices_screen.dart';

class CustomerSelectionScreen extends StatefulWidget {
  final String selectedDate;
  final String storeName;

  const CustomerSelectionScreen({
    Key? key,
    required this.selectedDate,
    required this.storeName,
  }) : super(key: key);

  @override
  _CustomerSelectionScreenState createState() =>
      _CustomerSelectionScreenState();
}

class _CustomerSelectionScreenState extends State<CustomerSelectionScreen> {
  late Future<List<String>> _customersFuture;
  final CustomerIndexService _customerIndexService = CustomerIndexService();

  @override
  void initState() {
    super.initState();
    _customersFuture = _customerIndexService.getAllCustomers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر زبوناً لعرض الفاتورة'),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
      ),
      
      body: Directionality(
        textDirection: TextDirection.rtl, // تحديد الاتجاه من اليمين لليسار
        child: FutureBuilder<List<String>>(
          future: _customersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text('خطأ في تحميل الزبائن: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('لا يوجد زبائن مسجلين في الفهرس',
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
              );
            }

            final customers = snapshot.data!;
            return ListView.builder(
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customerName = customers[index];
                return ListTile(
                  title:
                      Text(customerName, style: const TextStyle(fontSize: 18)),
                  // ستبقى leading كما هي، ولكنها ستظهر على اليمين تلقائياً
                  leading: const Icon(Icons.person, color: Colors.indigo),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => InvoicesScreen(
                          selectedDate: widget.selectedDate,
                          storeName: widget.storeName,
                          customerName: customerName,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
  
    );
  }
}