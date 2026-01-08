import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../services/purchase_storage_service.dart';
import '../services/sales_storage_service.dart';
import '../services/receipt_storage_service.dart';
import '../services/box_storage_service.dart';

/// شاشة استعراض اليوميات القديمة
/// تعرض جميع اليوميات المحفوظة مع إمكانية الفلترة والبحث
class JournalsHistoryScreen extends StatefulWidget {
  final String storeName;
  final String sellerName;

  const JournalsHistoryScreen({
    Key? key,
    required this.storeName,
    required this.sellerName,
  }) : super(key: key);

  @override
  _JournalsHistoryScreenState createState() => _JournalsHistoryScreenState();
}

class _JournalsHistoryScreenState extends State<JournalsHistoryScreen> {
  final _purchaseService = PurchaseStorageService();
  final _salesService = SalesStorageService();
  final _receiptService = ReceiptStorageService();
  final _boxService = BoxStorageService();

  List<JournalInfo> _journals = [];
  List<JournalInfo> _filteredJournals = [];
  bool _isLoading = true;
  String _selectedType = 'الكل'; // الكل، مشتريات، مبيعات، استلام، صندوق
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllJournals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllJournals() async {
    setState(() => _isLoading = true);

    try {
      List<JournalInfo> allJournals = [];

      // تحميل يوميات المشتريات
      final purchaseJournals = await _loadJournalsFromFolder('AlhalPurchases', 'مشتريات');
      allJournals.addAll(purchaseJournals);

      // تحميل يوميات المبيعات
      final salesJournals = await _loadJournalsFromFolder('AlhalSales', 'مبيعات');
      allJournals.addAll(salesJournals);

      // تحميل يوميات الاستلام
      final receiptJournals = await _loadJournalsFromFolder('AlhalReceipts', 'استلام');
      allJournals.addAll(receiptJournals);

      // تحميل يوميات الصندوق
      final boxJournals = await _loadJournalsFromFolder('AlhalBox', 'صندوق');
      allJournals.addAll(boxJournals);

      // ترتيب اليوميات حسب التاريخ (الأحدث أولاً)
      allJournals.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _journals = allJournals;
        _filteredJournals = allJournals;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في تحميل اليوميات: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  Future<List<JournalInfo>> _loadJournalsFromFolder(String folderName, String type) async {
    try {
      final basePath = await _getBasePath();
      final folderPath = '$basePath/$folderName';
      final folder = Directory(folderPath);

      if (!await folder.exists()) {
        return [];
      }

      final files = await folder.list().toList();
      List<JournalInfo> journals = [];

      for (var file in files) {
        if (file is File && file.path.endsWith('.json')) {
          try {
            final fileName = file.path.split('/').last;
            // استخراج التاريخ من اسم الملف
            // مثال: alhal-purchases-2025-01-07.json
            final parts = fileName.split('-');
            if (parts.length >= 5) {
              final year = parts[parts.length - 3];
              final month = parts[parts.length - 2];
              final day = parts[parts.length - 1].replaceAll('.json', '');
              final date = '$year/$month/$day';

              // قراءة معلومات اليومية
              final content = await file.readAsString();
              final Map<String, dynamic> jsonData = 
                  jsonDecode(content) as Map<String, dynamic>;

              final recordNumber = jsonData['recordNumber'] ?? '';
              final recordsCount = (jsonData['purchases'] as List?)?.length ??
                  (jsonData['sales'] as List?)?.length ??
                  (jsonData['receipts'] as List?)?.length ??
                  (jsonData['boxes'] as List?)?.length ??
                  0;

              journals.add(JournalInfo(
                type: type,
                date: date,
                recordNumber: recordNumber,
                filePath: file.path,
                recordsCount: recordsCount,
              ));
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('❌ خطأ في قراءة ملف: ${file.path}');
            }
          }
        }
      }

      return journals;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في تحميل مجلد $folderName: $e');
      }
      return [];
    }
  }

  Future<String> _getBasePath() async {
    Directory? directory;

    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();
    } else if (Platform.isWindows) {
      directory = await getApplicationDocumentsDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    return directory!.path;
  }

  void _filterJournals(String query) {
    setState(() {
      _filteredJournals = _journals.where((journal) {
        // فلترة حسب النوع
        if (_selectedType != 'الكل' && journal.type != _selectedType) {
          return false;
        }

        // فلترة حسب البحث
        if (query.isNotEmpty) {
          return journal.date.contains(query) ||
              journal.recordNumber.contains(query) ||
              journal.type.contains(query);
        }

        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'استعراض اليوميات القديمة',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // شريط البحث والفلترة
            _buildFilterSection(),
            
            // قائمة اليوميات
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredJournals.isEmpty
                      ? _buildEmptyState()
                      : _buildJournalsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // حقل البحث
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'البحث بالتاريخ أو الرقم...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: _filterJournals,
          ),
          const SizedBox(height: 12),
          
          // أزرار الفلترة
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('الكل'),
                const SizedBox(width: 8),
                _buildFilterChip('مشتريات'),
                const SizedBox(width: 8),
                _buildFilterChip('مبيعات'),
                const SizedBox(width: 8),
                _buildFilterChip('استلام'),
                const SizedBox(width: 8),
                _buildFilterChip('صندوق'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedType == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedType = label;
          _filterJournals(_searchController.text);
        });
      },
      selectedColor: Colors.indigo,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'لا توجد يوميات محفوظة',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredJournals.length,
      itemBuilder: (context, index) {
        final journal = _filteredJournals[index];
        return _buildJournalCard(journal);
      },
    );
  }

  Widget _buildJournalCard(JournalInfo journal) {
    Color typeColor;
    IconData typeIcon;

    switch (journal.type) {
      case 'مشتريات':
        typeColor = Colors.red;
        typeIcon = Icons.shopping_cart;
        break;
      case 'مبيعات':
        typeColor = Colors.green;
        typeIcon = Icons.sell;
        break;
      case 'استلام':
        typeColor = Colors.blue;
        typeIcon = Icons.receipt;
        break;
      case 'صندوق':
        typeColor = Colors.orange;
        typeIcon = Icons.account_balance_wallet;
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.description;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: typeColor.withOpacity(0.1),
          child: Icon(typeIcon, color: typeColor),
        ),
        title: Row(
          children: [
            Text(
              'يومية ${journal.type}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'رقم ${journal.recordNumber}',
                style: TextStyle(
                  color: typeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(journal.date),
                const SizedBox(width: 16),
                Icon(Icons.format_list_numbered, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${journal.recordsCount} سجل'),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () {
            // TODO: فتح اليومية للاطلاع
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('فتح يومية ${journal.type} - ${journal.date}'),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// معلومات اليومية
class JournalInfo {
  final String type; // نوع اليومية (مشتريات، مبيعات، ...)
  final String date; // التاريخ
  final String recordNumber; // رقم اليومية
  final String filePath; // مسار الملف
  final int recordsCount; // عدد السجلات

  JournalInfo({
    required this.type,
    required this.date,
    required this.recordNumber,
    required this.filePath,
    required this.recordsCount,
  });
}
