import 'package:flutter/material.dart';
import 'main_menu_screen.dart'; // 1. استيراد الشاشة الرئيسية

class DateSelectionScreen extends StatefulWidget {
  final String storeType;
  final String storeName;

  const DateSelectionScreen({
    super.key,
    required this.storeType,
    required this.storeName,
  });

  @override
  State<DateSelectionScreen> createState() => _DateSelectionScreenState();
}

class _DateSelectionScreenState extends State<DateSelectionScreen> {
  DateTime? _selectedDate;

  // استبدل دالة _selectDate الحالية بهذه
  Future<void> _selectDate(BuildContext context) async {
    // إزالة التخصيصات التي قد تسبب المشاكل
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      // تم حذف builder و locale للتبسيط
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _proceedToNextScreen() {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار التاريخ أولاً'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // 2. تعديل الدالة للانتقال إلى الشاشة الرئيسية
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainMenuScreen(
          selectedDate:
              '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
          storeType: widget.storeType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'اختيار التاريخ - ${widget.storeName}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal[600],
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.calendar_today,
                size: 100,
                color: Colors.teal[400],
              ),
              const SizedBox(height: 30),
              Text(
                'الرجاء تحديد تاريخ العمل',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  _selectedDate == null
                      ? 'لم يتم تحديد تاريخ'
                      : 'التاريخ المختار: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: _selectedDate == null
                        ? Colors.grey[600]
                        : Colors.teal[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => _selectDate(context),
                icon: const Icon(Icons.date_range, size: 28),
                label: const Text(
                  'فتح التقويم واختيار التاريخ',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _proceedToNextScreen,
                icon: const Icon(Icons.login, size: 28),
                label: const Text(
                  'دخول',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
