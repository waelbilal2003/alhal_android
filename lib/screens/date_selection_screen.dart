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

  // دالة لتحديث التاريخ بأمان مع التحقق من صحة الأيام في الشهر
  void _updateDate({int? year, int? month, int? day}) {
    final currentYear = year ?? _selectedDate.year;
    final currentMonth = month ?? _selectedDate.month;
    var currentDay = day ?? _selectedDate.day;

    // التحقق من أن اليوم المحدد لا يتجاوز عدد أيام الشهر الجديد
    final daysInMonth = DateUtils.getDaysInMonth(currentYear, currentMonth);
    if (currentDay > daysInMonth) {
      currentDay = daysInMonth;
    }

    setState(() {
      _selectedDate = DateTime(currentYear, currentMonth, currentDay);
    });
  }

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
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            // ========= القسم الأيمن: المعلومات وزر الدخول =========
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المتجر: ${widget.storeName}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (widget.sellerName != null)
                      Text(
                        'البائع: ${widget.sellerName}',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[700],
                        ),
                      ),
                    const Spacer(), // يدفع الزر إلى الأسفل
                    Center(
                      child: ElevatedButton.icon(
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
                              horizontal: 60, vertical: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 24),
                        label: const Text(
                          'دخــول',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ========= فاصل مرئي بين القسمين =========
            const VerticalDivider(width: 1, thickness: 1),
            // ========= القسم الأيسر: التحكم بالتاريخ =========
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.teal[50],
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // عرض التاريخ المحدد
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.teal.shade200),
                        ),
                      ),
                      child: Text(
                        '${_selectedDate.day} / ${_selectedDate.month} / ${_selectedDate.year}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 25),
                    // أدوات التحكم بالتاريخ
                    _buildCompactPicker(
                      'اليوم',
                      _selectedDate.day,
                      () => _updateDate(day: _selectedDate.day + 1),
                      () => _updateDate(day: _selectedDate.day - 1),
                    ),
                    const SizedBox(height: 15),
                    _buildCompactPicker(
                      'الشهر',
                      _selectedDate.month,
                      () => _updateDate(month: _selectedDate.month + 1),
                      () => _updateDate(month: _selectedDate.month - 1),
                      isMonth: true,
                    ),
                    const SizedBox(height: 15),
                    _buildCompactPicker(
                      'السنة',
                      _selectedDate.year,
                      () => _updateDate(year: _selectedDate.year + 1),
                      () => _updateDate(year: _selectedDate.year - 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // دالة بناء منتقي التاريخ بتصميم عمودي ومدمج
  Widget _buildCompactPicker(
    String label,
    int currentValue,
    VoidCallback onIncrement,
    VoidCallback onDecrement, {
    bool isMonth = false,
  }) {
    const months = [
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

    String displayValue =
        isMonth ? months[currentValue - 1] : currentValue.toString();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        const SizedBox(width: 15),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: onDecrement,
                color: Colors.red[600],
                iconSize: 22,
              ),
              SizedBox(
                width: isMonth ? 90 : 65, // مساحة أوسع لاسم الشهر
                child: Text(
                  displayValue,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: onIncrement,
                color: Colors.green[600],
                iconSize: 22,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
