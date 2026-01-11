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
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _suppliers = jsonList.map((item) => item.toString()).toList();

        // ترتيب الموردين أبجدياً
        _suppliers.sort((a, b) => a.compareTo(b));

        if (kDebugMode) {
          debugPrint('✅ تم تحميل ${_suppliers.length} مورد من الفهرس');
        }
      } else {
        _suppliers = [];
        // لا توجد قيم افتراضية - تبدأ فارغة تماماً
        if (kDebugMode) {
          debugPrint('✅ فهرس الموردين جديد - لا توجد موردين مخزنين');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في تحميل فهرس الموردين: $e');
      }
      _suppliers = [];
    }
  }

  Future<void> saveSupplier(String supplier) async {
    await _ensureInitialized();

    if (supplier.trim().isEmpty) return;

    final normalizedSupplier = _normalizeSupplier(supplier);

    // التحقق من عدم وجود المورد مسبقاً
    if (!_suppliers
        .any((s) => s.toLowerCase() == normalizedSupplier.toLowerCase())) {
      _suppliers.add(normalizedSupplier);
      _suppliers.sort((a, b) => a.compareTo(b));

      await _saveToFile();

      if (kDebugMode) {
        debugPrint('✅ تم إضافة مورد جديد: $normalizedSupplier');
      }
    }
  }

  String _normalizeSupplier(String supplier) {
    // إزالة المسافات الزائدة وتحويل أول حرف لحرف كبير
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

  Future<List<String>> getAllSuppliers() async {
    await _ensureInitialized();
    return List.from(_suppliers);
  }

  Future<void> removeSupplier(String supplier) async {
    await _ensureInitialized();

    _suppliers.removeWhere((s) => s.toLowerCase() == supplier.toLowerCase());
    await _saveToFile();

    if (kDebugMode) {
      debugPrint('✅ تم حذف المورد: $supplier');
    }
  }

  Future<void> clearAll() async {
    _suppliers.clear();
    await _saveToFile();

    if (kDebugMode) {
      debugPrint('✅ تم مسح جميع الموردين من الفهرس');
    }
  }

  Future<void> _saveToFile() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);

      final jsonString = jsonEncode(_suppliers);
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
