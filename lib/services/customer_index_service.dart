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
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _customers = jsonList.map((item) => item.toString()).toList();

        // ترتيب الزبائن أبجدياً
        _customers.sort((a, b) => a.compareTo(b));

        if (kDebugMode) {
          debugPrint('✅ تم تحميل ${_customers.length} زبون من الفهرس');
        }
      } else {
        _customers = [];
        // لا توجد قيم افتراضية - تبدأ فارغة تماماً
        if (kDebugMode) {
          debugPrint('✅ فهرس الزبائن جديد - لا توجد زبائن مخزنة');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في تحميل فهرس الزبائن: $e');
      }
      _customers = [];
    }
  }

  Future<void> saveCustomer(String customer) async {
    await _ensureInitialized();

    if (customer.trim().isEmpty) return;

    final normalizedCustomer = _normalizeCustomer(customer);

    // التحقق من عدم وجود الزبون مسبقاً
    if (!_customers
        .any((c) => c.toLowerCase() == normalizedCustomer.toLowerCase())) {
      _customers.add(normalizedCustomer);
      _customers.sort((a, b) => a.compareTo(b));

      await _saveToFile();

      if (kDebugMode) {
        debugPrint('✅ تم إضافة زبون جديد: $normalizedCustomer');
      }
    }
  }

  String _normalizeCustomer(String customer) {
    // إزالة المسافات الزائدة وتحويل أول حرف لحرف كبير
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

  Future<List<String>> getAllCustomers() async {
    await _ensureInitialized();
    return List.from(_customers);
  }

  Future<void> removeCustomer(String customer) async {
    await _ensureInitialized();

    _customers.removeWhere((c) => c.toLowerCase() == customer.toLowerCase());
    await _saveToFile();

    if (kDebugMode) {
      debugPrint('✅ تم حذف الزبون: $customer');
    }
  }

  Future<void> clearAll() async {
    _customers.clear();
    await _saveToFile();

    if (kDebugMode) {
      debugPrint('✅ تم مسح جميع الزبائن من الفهرس');
    }
  }

  Future<void> _saveToFile() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);

      final jsonString = jsonEncode(_customers);
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
