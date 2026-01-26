import 'package:flutter/material.dart';
import '../models/bait_model.dart';
import '../services/bait_service.dart';

class BaitScreen extends StatefulWidget {
  final String selectedDate;

  const BaitScreen({
    Key? key,
    required this.selectedDate,
  }) : super(key: key);

  @override
  _BaitScreenState createState() => _BaitScreenState();
}

class _BaitScreenState extends State<BaitScreen> {
  final BaitService _baitService = BaitService();
  late Future<List<BaitData>> _baitDataFuture;

  @override
  void initState() {
    super.initState();
    _baitDataFuture = _baitService.getBaitDataForDate(widget.selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('شاشة البايت ليوم ${widget.selectedDate}'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: FutureBuilder<List<BaitData>>(
          future: _baitDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'لا توجد حركة مواد لهذا اليوم',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }

            final baitList = snapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(8.0),
              child: DataTable(
                columnSpacing: 16.0,
                headingRowColor: MaterialStateColor.resolveWith(
                    (states) => Colors.teal.shade100),
                columns: const [
                  DataColumn(
                      label: Text('المادة',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('الاستلام',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      numeric: true),
                  DataColumn(
                      label: Text('المشتريات',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      numeric: true),
                  DataColumn(
                      label: Text('المبيعات',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      numeric: true),
                  DataColumn(
                      label: Text('البايت',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      numeric: true),
                ],
                rows: baitList.map((data) {
                  return DataRow(
                    cells: [
                      DataCell(Text(data.materialName)),
                      DataCell(Text(data.receiptsCount.toStringAsFixed(0))),
                      DataCell(Text(data.purchasesCount.toStringAsFixed(0))),
                      DataCell(Text(data.salesCount.toStringAsFixed(0))),
                      DataCell(
                        Text(
                          data.baitValue.toStringAsFixed(0),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: data.baitValue >= 0
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}
