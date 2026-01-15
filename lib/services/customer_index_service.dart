import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class CustomerIndexService {
  static final CustomerIndexService _instance =
      CustomerIndexService._internal();
  factory CustomerIndexService() => _instance;
  CustomerIndexService._internal();

  static const String _fileName = 'customer_index.json';
  List<String> _customers = [];
  List<String> _customersByInsertionOrder =
      []; // <-- قائمة جديدة لحفظ ترتيب الإضافة
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _loadCustomers();
      _isInitialized = true;
    }
  }

  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_fileName';
  }

  Future<void> _loadCustomers() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final Map<String, dynamic> jsonData = jsonDecode(jsonString);

        // تحميل البيانات الجديدة مع الترتيب
        if (jsonData.containsKey('customers') &&
            jsonData.containsKey('insertionOrder')) {
          final List<dynamic> jsonList = jsonData['customers'];
          final List<dynamic> orderList = jsonData['insertionOrder'];

          _customers = jsonList.map((item) => item.toString()).toList();
          _customersByInsertionOrder =
              orderList.map((item) => item.toString()).toList();

          // ترتيب قائمة الاقتراحات أبجدياً
          _customers.sort((a, b) => a.compareTo(b));

          // التأكد من تطابق القائمتين في المحتوى
          if (_customers.length != _customersByInsertionOrder.length) {
            _customersByInsertionOrder = List.from(_customers);
          }
        } else {
          // دعم الملفات القديمة
          final List<dynamic> jsonList = jsonDecode(jsonString);
          _customers = jsonList.map((item) => item.toString()).toList();
          _customersByInsertionOrder = List.from(_customers);
          _customers.sort((a, b) => a.compareTo(b));
        }

        if (kDebugMode) {
          debugPrint('✅ تم تحميل ${_customers.length} زبون من الفهرس');
          debugPrint('ترتيب الإضافة: ${_customersByInsertionOrder.join(', ')}');
        }
      } else {
        _customers = [];
        _customersByInsertionOrder = [];
        if (kDebugMode) {
          debugPrint('✅ فهرس الزبائن جديد - لا توجد زبائن مخزنة');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في تحميل فهرس الزبائن: $e');
      }
      _customers = [];
      _customersByInsertionOrder = [];
    }
  }

  Future<void> saveCustomer(String customer) async {
    await _ensureInitialized();

    if (customer.trim().isEmpty) return;

    final normalizedCustomer = _normalizeCustomer(customer);

    // التحقق من عدم وجود الزبون مسبقاً
    if (!_customers
        .any((c) => c.toLowerCase() == normalizedCustomer.toLowerCase())) {
      // إضافة للقائمتين
      _customers.add(normalizedCustomer);
      _customersByInsertionOrder.add(normalizedCustomer);

      // ترتيب قائمة الاقتراحات أبجدياً فقط
      _customers.sort((a, b) => a.compareTo(b));

      await _saveToFile();

      if (kDebugMode) {
        debugPrint('✅ تم إضافة زبون جديد: $normalizedCustomer');
        debugPrint(
            'رقم الزبون حسب ترتيب الإضافة: ${_customersByInsertionOrder.indexOf(normalizedCustomer) + 1}');
      }
    }
  }

  String _normalizeCustomer(String customer) {
    String normalized = customer.trim();
    if (normalized.isNotEmpty) {
      normalized = normalized[0].toUpperCase() + normalized.substring(1);
    }
    return normalized;
  }

  Future<List<String>> getSuggestions(String query) async {
    await _ensureInitialized();

    if (query.isEmpty) return [];

    final normalizedQuery = query.toLowerCase().trim();

    return _customers.where((customer) {
      return customer.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  Future<List<String>> getSuggestionsByFirstLetter(String letter) async {
    await _ensureInitialized();

    if (letter.isEmpty) return [];

    final normalizedLetter = letter.toLowerCase().trim();

    return _customers.where((customer) {
      return customer.toLowerCase().startsWith(normalizedLetter);
    }).toList();
  }

  // دالة جديدة: الحصول على اقتراحات حسب الرقم (ترتيب الإضافة)
  Future<List<String>> getSuggestionsByNumber(String numberQuery) async {
    await _ensureInitialized();

    if (numberQuery.isEmpty) return [];

    try {
      final int queryNumber = int.parse(numberQuery);

      if (queryNumber <= 0 || queryNumber > _customersByInsertionOrder.length) {
        return [];
      }

      // عرض عنصر واحد فقط حسب الرقم (ترتيب الإضافة)
      return [_customersByInsertionOrder[queryNumber - 1]];
    } catch (e) {
      // إذا لم يكن النص رقماً، نعيد قائمة فارغة
      return [];
    }
  }

  // دالة متعددة الاستخدامات: تبحث حسب النص أو الرقم
  Future<List<String>> getEnhancedSuggestions(String query) async {
    await _ensureInitialized();

    if (query.isEmpty) return [];

    final normalizedQuery = query.trim();

    // محاولة البحث كرقم أولاً
    if (RegExp(r'^\d+$').hasMatch(normalizedQuery)) {
      final numberResults = await getSuggestionsByNumber(normalizedQuery);
      if (numberResults.isNotEmpty) {
        return numberResults;
      }
    }

    // إذا لم تكن نتيجة البحث كرقم، نبحث كنص
    return await getSuggestions(normalizedQuery);
  }

  Future<List<String>> getAllCustomers() async {
    await _ensureInitialized();
    return List.from(_customers);
  }

  // دالة جديدة للحصول على الزبائن حسب ترتيب الإضافة
  Future<List<String>> getAllCustomersByInsertionOrder() async {
    await _ensureInitialized();
    return List.from(_customersByInsertionOrder);
  }

  // دالة جديدة للحصول على رقم الزبون حسب ترتيب الإضافة
  Future<int?> getCustomerPosition(String customer) async {
    await _ensureInitialized();

    final normalizedCustomer = _normalizeCustomer(customer);
    final index = _customersByInsertionOrder
        .indexWhere((c) => c.toLowerCase() == normalizedCustomer.toLowerCase());

    return index >= 0 ? index + 1 : null;
  }

  Future<void> removeCustomer(String customer) async {
    await _ensureInitialized();

    final normalizedCustomer = _normalizeCustomer(customer);

    // إزالة من القائمتين
    _customers.removeWhere(
        (c) => c.toLowerCase() == normalizedCustomer.toLowerCase());
    _customersByInsertionOrder.removeWhere(
        (c) => c.toLowerCase() == normalizedCustomer.toLowerCase());

    await _saveToFile();

    if (kDebugMode) {
      debugPrint('✅ تم حذف الزبون: $customer');
    }
  }

  Future<void> clearAll() async {
    _customers.clear();
    _customersByInsertionOrder.clear();
    await _saveToFile();

    if (kDebugMode) {
      debugPrint('✅ تم مسح جميع الزبائن من الفهرس');
    }
  }

  Future<void> _saveToFile() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);

      // حفظ البيانات مع الترتيب
      final Map<String, dynamic> jsonData = {
        'customers': _customers,
        'insertionOrder': _customersByInsertionOrder,
      };

      final jsonString = jsonEncode(jsonData);
      await file.writeAsString(jsonString);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في حفظ فهرس الزبائن: $e');
      }
    }
  }

  Future<int> getCount() async {
    await _ensureInitialized();
    return _customers.length;
  }

  Future<bool> exists(String customer) async {
    await _ensureInitialized();
    return _customers.any((c) => c.toLowerCase() == customer.toLowerCase());
  }
}
