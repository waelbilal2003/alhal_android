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
  List<String> _suppliers = [];
  List<String> _suppliersByInsertionOrder =
      []; // <-- قائمة جديدة لحفظ ترتيب الإضافة
  bool _isInitialized = false;

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

        // تحميل البيانات الجديدة مع الترتيب
        if (jsonData.containsKey('suppliers') &&
            jsonData.containsKey('insertionOrder')) {
          final List<dynamic> jsonList = jsonData['suppliers'];
          final List<dynamic> orderList = jsonData['insertionOrder'];

          _suppliers = jsonList.map((item) => item.toString()).toList();
          _suppliersByInsertionOrder =
              orderList.map((item) => item.toString()).toList();

          // ترتيب قائمة الاقتراحات أبجدياً
          _suppliers.sort((a, b) => a.compareTo(b));

          // التأكد من تطابق القائمتين في المحتوى
          if (_suppliers.length != _suppliersByInsertionOrder.length) {
            _suppliersByInsertionOrder = List.from(_suppliers);
          }
        } else {
          // دعم الملفات القديمة
          final List<dynamic> jsonList = jsonDecode(jsonString);
          _suppliers = jsonList.map((item) => item.toString()).toList();
          _suppliersByInsertionOrder = List.from(_suppliers);
          _suppliers.sort((a, b) => a.compareTo(b));
        }

        if (kDebugMode) {
          debugPrint('✅ تم تحميل ${_suppliers.length} مورد من الفهرس');
          debugPrint('ترتيب الإضافة: ${_suppliersByInsertionOrder.join(', ')}');
        }
      } else {
        _suppliers = [];
        _suppliersByInsertionOrder = [];
        if (kDebugMode) {
          debugPrint('✅ فهرس الموردين جديد - لا توجد موردين مخزنين');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في تحميل فهرس الموردين: $e');
      }
      _suppliers = [];
      _suppliersByInsertionOrder = [];
    }
  }

  Future<void> saveSupplier(String supplier) async {
    await _ensureInitialized();

    if (supplier.trim().isEmpty) return;

    final normalizedSupplier = _normalizeSupplier(supplier);

    // التحقق من عدم وجود المورد مسبقاً
    if (!_suppliers
        .any((s) => s.toLowerCase() == normalizedSupplier.toLowerCase())) {
      // إضافة للقائمتين
      _suppliers.add(normalizedSupplier);
      _suppliersByInsertionOrder.add(normalizedSupplier);

      // ترتيب قائمة الاقتراحات أبجدياً فقط
      _suppliers.sort((a, b) => a.compareTo(b));

      await _saveToFile();

      if (kDebugMode) {
        debugPrint('✅ تم إضافة مورد جديد: $normalizedSupplier');
        debugPrint(
            'رقم المورد حسب ترتيب الإضافة: ${_suppliersByInsertionOrder.indexOf(normalizedSupplier) + 1}');
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

    return _suppliers.where((supplier) {
      return supplier.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  Future<List<String>> getSuggestionsByFirstLetter(String letter) async {
    await _ensureInitialized();

    if (letter.isEmpty) return [];

    final normalizedLetter = letter.toLowerCase().trim();

    return _suppliers.where((supplier) {
      return supplier.toLowerCase().startsWith(normalizedLetter);
    }).toList();
  }

  // دالة جديدة: الحصول على اقتراحات حسب الرقم (ترتيب الإضافة)
  Future<List<String>> getSuggestionsByNumber(String numberQuery) async {
    await _ensureInitialized();

    if (numberQuery.isEmpty) return [];

    try {
      final int queryNumber = int.parse(numberQuery);

      if (queryNumber <= 0 || queryNumber > _suppliersByInsertionOrder.length) {
        return [];
      }

      // عرض عنصر واحد فقط حسب الرقم (ترتيب الإضافة)
      return [_suppliersByInsertionOrder[queryNumber - 1]];
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
    return List.from(_suppliers);
  }

  // دالة جديدة للحصول على الموردين حسب ترتيب الإضافة
  Future<List<String>> getAllSuppliersByInsertionOrder() async {
    await _ensureInitialized();
    return List.from(_suppliersByInsertionOrder);
  }

  // دالة جديدة للحصول على رقم المورد حسب ترتيب الإضافة
  Future<int?> getSupplierPosition(String supplier) async {
    await _ensureInitialized();

    final normalizedSupplier = _normalizeSupplier(supplier);
    final index = _suppliersByInsertionOrder
        .indexWhere((s) => s.toLowerCase() == normalizedSupplier.toLowerCase());

    return index >= 0 ? index + 1 : null;
  }

  Future<void> removeSupplier(String supplier) async {
    await _ensureInitialized();

    final normalizedSupplier = _normalizeSupplier(supplier);

    // إزالة من القائمتين
    _suppliers.removeWhere(
        (s) => s.toLowerCase() == normalizedSupplier.toLowerCase());
    _suppliersByInsertionOrder.removeWhere(
        (s) => s.toLowerCase() == normalizedSupplier.toLowerCase());

    await _saveToFile();

    if (kDebugMode) {
      debugPrint('✅ تم حذف المورد: $supplier');
    }
  }

  Future<void> clearAll() async {
    _suppliers.clear();
    _suppliersByInsertionOrder.clear();
    await _saveToFile();

    if (kDebugMode) {
      debugPrint('✅ تم مسح جميع الموردين من الفهرس');
    }
  }

  Future<void> _saveToFile() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);

      // حفظ البيانات مع الترتيب
      final Map<String, dynamic> jsonData = {
        'suppliers': _suppliers,
        'insertionOrder': _suppliersByInsertionOrder,
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
    return _suppliers.length;
  }

  Future<bool> exists(String supplier) async {
    await _ensureInitialized();
    return _suppliers.any((s) => s.toLowerCase() == supplier.toLowerCase());
  }
}
