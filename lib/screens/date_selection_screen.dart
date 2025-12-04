import 'package:flutter/material.dart';
import 'daily_movement_screen.dart';

class DateSelectionScreen extends StatefulWidget {
  final String storeType;
  final String storeName;
  final String? sellerName; // استقبال اسم البائع

  const DateSelectionScreen({
    super.key,
    required this.storeType,
    required this.storeName,
    this.sellerName,
  });

  @override
  State<DateSelectionScreen> createState() => _DateSelectionScreenState();
}

class _DateSelectionScreenState extends State<DateSelectionScreen> {
  int _selectedDay = DateTime.now().day;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final ScrollController _dayController = ScrollController();
  final ScrollController _monthController = ScrollController();
  final ScrollController _yearController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dayController.jumpTo((_selectedDay - 1) * 50.0);
      _monthController.jumpTo((_selectedMonth - 1) * 50.0);
      _yearController.jumpTo((_selectedYear - 2020) * 50.0);
    });
  }

  void _proceedToNextScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DailyMovementScreen(
          selectedDate: '$_selectedDay/$_selectedMonth/$_selectedYear',
          storeType: widget.storeType,
          sellerName: widget.sellerName, // تمرير اسم البائع
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('اختيار التاريخ - ${widget.storeName}'),
        backgroundColor: Colors.teal[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                      child: _buildPicker('اليوم', _dayController,
                          (index) => _selectedDay = index + 1, 31, false)),
                  Expanded(
                      child: _buildPicker('الشهر', _monthController,
                          (index) => _selectedMonth = index + 1, 12, true)),
                  Expanded(
                      child: _buildPicker('السنة', _yearController,
                          (index) => _selectedYear = 2020 + index, 82, false)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _proceedToNextScreen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('دخول',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPicker(String title, ScrollController controller,
      Function(int) onChanged, int itemCount, bool isMonth) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 50,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              setState(() {
                onChanged(index);
              });
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                String text;
                if (isMonth) {
                  final months = [
                    'يناير',
                    'فبراير',
                    'مارس',
                    'أبريل',
                    'مايو',
                    'يونيو',
                    'يوليو',
                    'أغسطس',
                    'سبتمبر',
                    'أكتوبر',
                    'نوفمبر',
                    'ديسمبر'
                  ];
                  text = months[index];
                } else {
                  text = '${(title == 'السنة' ? 2020 + index : index + 1)}';
                }
                return Center(
                    child: Text(text,
                        style:
                            TextStyle(fontSize: 20, color: Colors.teal[700])));
              },
              childCount: itemCount,
            ),
          ),
        ),
      ],
    );
  }
}
