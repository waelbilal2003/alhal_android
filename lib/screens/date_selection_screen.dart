import 'package:flutter/material.dart';
import 'daily_movement_screen.dart';

class DateSelectionScreen extends StatefulWidget {
  final String storeType;
  final String storeName;
  final String? sellerName;

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
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'اختيار التاريخ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal[600],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      // تم تغليف المحتوى بـ SingleChildScrollView لمنع تجاوز المساحة
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          // تحديد ارتفاع الشاشة المتاح للمنع من تجاوز المساحة
          height: MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top - // ارتفاع شريط الحالة
              AppBar().preferredSize.height - // ارتفاع الـ AppBar
              32, // هامش إضافي
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              // جزء عرض المعلومات والتاريخ
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المتجر: ${widget.storeName}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.sellerName != null)
                      Text(
                        'البائع: ${widget.sellerName}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.teal[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal[300]!),
                      ),
                      child: Text(
                        '${_selectedDate.day} / ${_selectedDate.month} / ${_selectedDate.year}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 30),
              // جزء التحكم بالتاريخ
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCompactPicker('اليوم', _selectedDate.day, 31,
                        (newDay) {
                      setState(() {
                        _selectedDate = DateTime(
                            _selectedDate.year, _selectedDate.month, newDay);
                      });
                    }),
                    const SizedBox(height: 25),
                    _buildCompactPicker('الشهر', _selectedDate.month, 12,
                        (newMonth) {
                      setState(() {
                        _selectedDate = DateTime(
                            _selectedDate.year, newMonth, _selectedDate.day);
                      });
                    }),
                    const SizedBox(height: 25),
                    _buildCompactPicker('السنة', _selectedDate.year - 2020, 50,
                        (newYearIndex) {
                      setState(() {
                        _selectedDate = DateTime(2020 + newYearIndex,
                            _selectedDate.month, _selectedDate.day);
                      });
                    }),
                    const SizedBox(height: 30),
                    // إعادة زر الدخول بحجمه الأكبر
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DailyMovementScreen(
                              selectedDate:
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              storeType: widget.storeType,
                              sellerName: widget.sellerName,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'دخول',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة بناء منتقي التاريخ المدمج
  Widget _buildCompactPicker(
      String label, int currentValue, int maxValue, Function(int) onChanged) {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 70,
              child: Text(
                label == 'الشهر'
                    ? months[currentValue - 1]
                    : (label == 'السنة'
                        ? (2020 + currentValue).toString()
                        : currentValue.toString()),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              children: [
                SizedBox(
                  width: 30,
                  height: 30,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.keyboard_arrow_up, size: 24),
                    onPressed: currentValue > (label == 'السنة' ? 0 : 1)
                        ? () => onChanged(currentValue - 1)
                        : null,
                  ),
                ),
                SizedBox(
                  width: 30,
                  height: 30,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 24),
                    onPressed: currentValue <
                            (label == 'السنة' ? maxValue - 1 : maxValue)
                        ? () => onChanged(currentValue + 1)
                        : null,
                  ),
                ),
              ],
            )
          ],
        ),
      ],
    );
  }
}
