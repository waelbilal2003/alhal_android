import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class SupplierIndexService {
  static final SupplierIndexService _instance =
      SupplierIndexService._internal();
  factory SupplierIndexService() => _instance;
  SupplierIndexService._internal();

  static const String _fileName = 'supplier_index.json';
  Map<int, String> _supplierMap = {}; // <-- خريطة تربط الرقم بالمورد
  bool _isInitialized = false;
  int _nextId = 1; // <-- رقم المورد التالي للإضافة

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _loadSuppliers();
      _isInitialized = true;
    }
  }

  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_fileName';
  }

  Future<void> _loadSuppliers() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final Map<String, dynamic> jsonData = jsonDecode(jsonString);

        if (jsonData.containsKey('suppliers') &&
            jsonData.containsKey('nextId')) {
          final Map<String, dynamic> suppliersJson = jsonData['suppliers'];

          // تحميل الخريطة من JSON
          _supplierMap.clear();
          suppliersJson.forEach((key, value) {
            _supplierMap[int.parse(key)] = value.toString();
          });

          _nextId = jsonData['nextId'] ?? 1;

          if (kDebugMode) {
            debugPrint('✅ تم تحميل ${_supplierMap.length} مورد من الفهرس');
            debugPrint(
                'الموردين: ${_supplierMap.entries.map((e) => '${e.key}:${e.value}').join(', ')}');
          }
        } else {
          // دعم الملفات القديمة
          _supplierMap.clear();
          if (jsonData is List) {
            // تنسيق قديم: قائمة فقط
            for (int i = 0; i < jsonData.length; i++) {
              _supplierMap[i + 1] = jsonData[i].toString();
            }
            _nextId = jsonData.length + 1;
          } else if (jsonData.containsKey('suppliers')) {
            // تنسيق قديم آخر
            final List<dynamic> jsonList = jsonData['suppliers'];
            for (int i = 0; i < jsonList.length; i++) {
              _supplierMap[i + 1] = jsonList[i].toString();
            }
            _nextId = jsonList.length + 1;
          }

          // حفظ بالتنسيق الجديد
          await _saveToFile();
        }
      } else {
        _supplierMap.clear();
        _nextId = 1;
        if (kDebugMode) {
          debugPrint('✅ فهرس الموردين جديد - لا توجد موردين مخزنين');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في تحميل فهرس الموردين: $e');
      }
      _supplierMap.clear();
      _nextId = 1;
    }
  }

  Future<void> saveSupplier(String supplier) async {
    await _ensureInitialized();

    if (supplier.trim().isEmpty) return;

    final normalizedSupplier = _normalizeSupplier(supplier);

    // التحقق من عدم وجود المورد مسبقاً
    if (!_supplierMap.values
        .any((s) => s.toLowerCase() == normalizedSupplier.toLowerCase())) {
      // إضافة مع رقم ثابت جديد
      _supplierMap[_nextId] = normalizedSupplier;
      _nextId++;

      await _saveToFile();

      if (kDebugMode) {
        debugPrint(
            '✅ تم إضافة مورد جديد: $normalizedSupplier (رقم: ${_nextId - 1})');
      }
    }
  }

  String _normalizeSupplier(String supplier) {
    String normalized = supplier.trim();
    if (normalized.isNotEmpty) {
      normalized = normalized[0].toUpperCase() + normalized.substring(1);
    }
    return normalized;
  }

  Future<List<String>> getSuggestions(String query) async {
    await _ensureInitialized();

    if (query.isEmpty) return [];

    final normalizedQuery = query.toLowerCase().trim();

    return _supplierMap.entries
        .where((entry) => entry.value.toLowerCase().contains(normalizedQuery))
        .map((entry) => entry.value)
        .toList();
  }

  Future<List<String>> getSuggestionsByFirstLetter(String letter) async {
    await _ensureInitialized();

    if (letter.isEmpty) return [];

    final normalizedLetter = letter.toLowerCase().trim();

    return _supplierMap.entries
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

      // البحث عن المورد بهذا الرقم
      if (_supplierMap.containsKey(queryNumber)) {
        return [_supplierMap[queryNumber]!];
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

  Future<List<String>> getAllSuppliers() async {
    await _ensureInitialized();

    // ترتيب أبجدي للعرض فقط (لا يؤثر على الأرقام)
    final suppliers = _supplierMap.values.toList();
    suppliers.sort((a, b) => a.compareTo(b));
    return suppliers;
  }

  // دالة جديدة للحصول على الموردين حسب ترتيب الإضافة (حسب الرقم)
  Future<List<String>> getAllSuppliersByInsertionOrder() async {
    await _ensureInitialized();

    // ترتيب حسب الرقم (ترتيب الإضافة)
    final sortedEntries = _supplierMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return sortedEntries.map((entry) => entry.value).toList();
  }

  // دالة جديدة للحصول على رقم المورد الثابت
  Future<int?> getSupplierPosition(String supplier) async {
    await _ensureInitialized();

    final normalizedSupplier = _normalizeSupplier(supplier);

    // البحث عن المورد وإرجاع رقمها
    for (var entry in _supplierMap.entries) {
      if (entry.value.toLowerCase() == normalizedSupplier.toLowerCase()) {
        return entry.key;
      }
    }

    return null;
  }

  Future<void> removeSupplier(String supplier) async {
    await _ensureInitialized();

    final normalizedSupplier = _normalizeSupplier(supplier);

    // البحث عن الرقم الخاص بالمورد وحذفها
    int? keyToRemove;
    for (var entry in _supplierMap.entries) {
      if (entry.value.toLowerCase() == normalizedSupplier.toLowerCase()) {
        keyToRemove = entry.key;
        break;
      }
    }

    if (keyToRemove != null) {
      _supplierMap.remove(keyToRemove);
      await _saveToFile();

      if (kDebugMode) {
        debugPrint('✅ تم حذف المورد: $supplier (رقم: $keyToRemove)');
      }
    }
  }

  Future<void> clearAll() async {
    _supplierMap.clear();
    _nextId = 1;
    await _saveToFile();

    if (kDebugMode) {
      debugPrint('✅ تم مسح جميع الموردين من الفهرس');
    }
  }

  Future<void> _saveToFile() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);

      // تحويل الخريطة إلى Map<String, dynamic> للتخزين
      final Map<String, dynamic> suppliersJson = {};
      _supplierMap.forEach((key, value) {
        suppliersJson[key.toString()] = value;
      });

      // حفظ البيانات مع الأرقام الثابتة
      final Map<String, dynamic> jsonData = {
        'suppliers': suppliersJson,
        'nextId': _nextId,
      };

      final jsonString = jsonEncode(jsonData);
      await file.writeAsString(jsonString);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في حفظ فهرس الموردين: $e');
      }
    }
  }

  Future<int> getCount() async {
    await _ensureInitialized();
    return _supplierMap.length;
  }

  Future<bool> exists(String supplier) async {
    await _ensureInitialized();
    return _supplierMap.values
        .any((s) => s.toLowerCase() == supplier.toLowerCase());
  }

  // دالة جديدة: الحصول على جميع الموردين مع أرقامها
  Future<Map<int, String>> getAllSuppliersWithNumbers() async {
    await _ensureInitialized();
    return Map.from(_supplierMap);
  }
}
