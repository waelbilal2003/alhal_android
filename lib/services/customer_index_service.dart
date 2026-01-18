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
  Map<int, String> _customerMap = {}; // <-- خريطة تربط الرقم بالزبون
  bool _isInitialized = false;
  int _nextId = 1; // <-- رقم الزبون التالي للإضافة

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

        if (jsonData.containsKey('customers') &&
            jsonData.containsKey('nextId')) {
          final Map<String, dynamic> customersJson = jsonData['customers'];

          // تحميل الخريطة من JSON
          _customerMap.clear();
          customersJson.forEach((key, value) {
            _customerMap[int.parse(key)] = value.toString();
          });

          _nextId = jsonData['nextId'] ?? 1;

          if (kDebugMode) {
            debugPrint('✅ تم تحميل ${_customerMap.length} زبون من الفهرس');
            debugPrint(
                'الزبائن: ${_customerMap.entries.map((e) => '${e.key}:${e.value}').join(', ')}');
          }
        } else {
          // دعم الملفات القديمة
          _customerMap.clear();
          if (jsonData is List) {
            // تنسيق قديم: قائمة فقط
            for (int i = 0; i < jsonData.length; i++) {
              _customerMap[i + 1] = jsonData[i].toString();
            }
            _nextId = jsonData.length + 1;
          } else if (jsonData.containsKey('customers')) {
            // تنسيق قديم آخر
            final List<dynamic> jsonList = jsonData['customers'];
            for (int i = 0; i < jsonList.length; i++) {
              _customerMap[i + 1] = jsonList[i].toString();
            }
            _nextId = jsonList.length + 1;
          }

          // حفظ بالتنسيق الجديد
          await _saveToFile();
        }
      } else {
        _customerMap.clear();
        _nextId = 1;
        if (kDebugMode) {
          debugPrint('✅ فهرس الزبائن جديد - لا توجد زبائن مخزنة');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في تحميل فهرس الزبائن: $e');
      }
      _customerMap.clear();
      _nextId = 1;
    }
  }

  Future<void> saveCustomer(String customer) async {
    await _ensureInitialized();

    if (customer.trim().isEmpty) return;

    final normalizedCustomer = _normalizeCustomer(customer);

    // التحقق من عدم وجود الزبون مسبقاً
    if (!_customerMap.values
        .any((c) => c.toLowerCase() == normalizedCustomer.toLowerCase())) {
      // إضافة مع رقم ثابت جديد
      _customerMap[_nextId] = normalizedCustomer;
      _nextId++;

      await _saveToFile();

      if (kDebugMode) {
        debugPrint(
            '✅ تم إضافة زبون جديد: $normalizedCustomer (رقم: ${_nextId - 1})');
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

    return _customerMap.entries
        .where((entry) => entry.value.toLowerCase().contains(normalizedQuery))
        .map((entry) => entry.value)
        .toList();
  }

  Future<List<String>> getSuggestionsByFirstLetter(String letter) async {
    await _ensureInitialized();

    if (letter.isEmpty) return [];

    final normalizedLetter = letter.toLowerCase().trim();

    return _customerMap.entries
        .where(
            (entry) => entry.value.toLowerCase().startsWith(normalizedLetter))
        .map((entry) => entry.value)
        .toList();
  }

  // دالة جديدة: الحصول على اقتراحات حسب الرقم (رقم الفهرس الثابت)
  Future<List<String>> getSuggestionsByNumber(String numberQuery) async {
    await _ensureInitialized();

    if (numberQuery.isEmpty) return [];

    try {
      final int queryNumber = int.parse(numberQuery);

      // البحث عن الزبون بهذا الرقم
      if (_customerMap.containsKey(queryNumber)) {
        return [_customerMap[queryNumber]!];
      } else {
        return [];
      }
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

    // ترتيب أبجدي للعرض فقط (لا يؤثر على الأرقام)
    final customers = _customerMap.values.toList();
    customers.sort((a, b) => a.compareTo(b));
    return customers;
  }

  // دالة جديدة للحصول على الزبائن حسب ترتيب الإضافة (حسب الرقم)
  Future<List<String>> getAllCustomersByInsertionOrder() async {
    await _ensureInitialized();

    // ترتيب حسب الرقم (ترتيب الإضافة)
    final sortedEntries = _customerMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return sortedEntries.map((entry) => entry.value).toList();
  }

  // دالة جديدة للحصول على رقم الزبون الثابت
  Future<int?> getCustomerPosition(String customer) async {
    await _ensureInitialized();

    final normalizedCustomer = _normalizeCustomer(customer);

    // البحث عن الزبون وإرجاع رقمها
    for (var entry in _customerMap.entries) {
      if (entry.value.toLowerCase() == normalizedCustomer.toLowerCase()) {
        return entry.key;
      }
    }

    return null;
  }

  Future<void> removeCustomer(String customer) async {
    await _ensureInitialized();

    final normalizedCustomer = _normalizeCustomer(customer);

    // البحث عن الرقم الخاص بالزبون وحذفها
    int? keyToRemove;
    for (var entry in _customerMap.entries) {
      if (entry.value.toLowerCase() == normalizedCustomer.toLowerCase()) {
        keyToRemove = entry.key;
        break;
      }
    }

    if (keyToRemove != null) {
      _customerMap.remove(keyToRemove);
      await _saveToFile();

      if (kDebugMode) {
        debugPrint('✅ تم حذف الزبون: $customer (رقم: $keyToRemove)');
      }
    }
  }

  Future<void> clearAll() async {
    _customerMap.clear();
    _nextId = 1;
    await _saveToFile();

    if (kDebugMode) {
      debugPrint('✅ تم مسح جميع الزبائن من الفهرس');
    }
  }

  Future<void> _saveToFile() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);

      // تحويل الخريطة إلى Map<String, dynamic> للتخزين
      final Map<String, dynamic> customersJson = {};
      _customerMap.forEach((key, value) {
        customersJson[key.toString()] = value;
      });

      // حفظ البيانات مع الأرقام الثابتة
      final Map<String, dynamic> jsonData = {
        'customers': customersJson,
        'nextId': _nextId,
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
    return _customerMap.length;
  }

  Future<bool> exists(String customer) async {
    await _ensureInitialized();
    return _customerMap.values
        .any((c) => c.toLowerCase() == customer.toLowerCase());
  }

  // دالة جديدة: الحصول على جميع الزبائن مع أرقامها
  Future<Map<int, String>> getAllCustomersWithNumbers() async {
    await _ensureInitialized();
    return Map.from(_customerMap);
  }
}
