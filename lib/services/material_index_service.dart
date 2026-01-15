import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class MaterialIndexService {
  static final MaterialIndexService _instance =
      MaterialIndexService._internal();
  factory MaterialIndexService() => _instance;
  MaterialIndexService._internal();

  static const String _fileName = 'material_index.json';
  List<String> _materials = [];
  List<String> _materialsByInsertionOrder =
      []; // <-- قائمة جديدة لحفظ ترتيب الإضافة
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _loadMaterials();
      _isInitialized = true;
    }
  }

  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_fileName';
  }

  Future<void> _loadMaterials() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final Map<String, dynamic> jsonData = jsonDecode(jsonString);

        // تحميل البيانات الجديدة مع الترتيب
        if (jsonData.containsKey('materials') &&
            jsonData.containsKey('insertionOrder')) {
          final List<dynamic> jsonList = jsonData['materials'];
          final List<dynamic> orderList = jsonData['insertionOrder'];

          _materials = jsonList.map((item) => item.toString()).toList();
          _materialsByInsertionOrder =
              orderList.map((item) => item.toString()).toList();

          // ترتيب قائمة الاقتراحات أبجدياً
          _materials.sort((a, b) => a.compareTo(b));

          // التأكد من تطابق القائمتين في المحتوى
          if (_materials.length != _materialsByInsertionOrder.length) {
            _materialsByInsertionOrder = List.from(_materials);
          }
        } else {
          // دعم الملفات القديمة
          final List<dynamic> jsonList = jsonDecode(jsonString);
          _materials = jsonList.map((item) => item.toString()).toList();
          _materialsByInsertionOrder = List.from(_materials);
          _materials.sort((a, b) => a.compareTo(b));
        }

        if (kDebugMode) {
          debugPrint('✅ تم تحميل ${_materials.length} مادة من الفهرس');
          debugPrint('ترتيب الإضافة: ${_materialsByInsertionOrder.join(', ')}');
        }
      } else {
        _materials = [];
        _materialsByInsertionOrder = [];
        if (kDebugMode) {
          debugPrint('✅ فهرس المواد جديد - لا توجد مواد مخزنة');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في تحميل فهرس المواد: $e');
      }
      _materials = [];
      _materialsByInsertionOrder = [];
    }
  }

  Future<void> saveMaterial(String material) async {
    await _ensureInitialized();

    if (material.trim().isEmpty) return;

    final normalizedMaterial = _normalizeMaterial(material);

    // التحقق من عدم وجود المادة مسبقاً
    if (!_materials
        .any((m) => m.toLowerCase() == normalizedMaterial.toLowerCase())) {
      // إضافة للقائمتين
      _materials.add(normalizedMaterial);
      _materialsByInsertionOrder.add(normalizedMaterial);

      // ترتيب قائمة الاقتراحات أبجدياً فقط
      _materials.sort((a, b) => a.compareTo(b));

      await _saveToFile();

      if (kDebugMode) {
        debugPrint('✅ تم إضافة مادة جديدة: $normalizedMaterial');
        debugPrint(
            'رقم المادة حسب ترتيب الإضافة: ${_materialsByInsertionOrder.indexOf(normalizedMaterial) + 1}');
      }
    }
  }

  String _normalizeMaterial(String material) {
    String normalized = material.trim();
    if (normalized.isNotEmpty) {
      normalized = normalized[0].toUpperCase() + normalized.substring(1);
    }
    return normalized;
  }

  Future<List<String>> getSuggestions(String query) async {
    await _ensureInitialized();

    if (query.isEmpty) return [];

    final normalizedQuery = query.toLowerCase().trim();

    return _materials.where((material) {
      return material.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  Future<List<String>> getSuggestionsByFirstLetter(String letter) async {
    await _ensureInitialized();

    if (letter.isEmpty) return [];

    final normalizedLetter = letter.toLowerCase().trim();

    return _materials.where((material) {
      return material.toLowerCase().startsWith(normalizedLetter);
    }).toList();
  }

  // دالة جديدة: الحصول على اقتراحات حسب الرقم (ترتيب الإضافة)
  Future<List<String>> getSuggestionsByNumber(String numberQuery) async {
    await _ensureInitialized();

    if (numberQuery.isEmpty) return [];

    try {
      final int queryNumber = int.parse(numberQuery);

      if (queryNumber <= 0 || queryNumber > _materialsByInsertionOrder.length) {
        return [];
      }

      // عرض عنصر واحد فقط حسب الرقم (ترتيب الإضافة)
      return [_materialsByInsertionOrder[queryNumber - 1]];
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

  Future<List<String>> getAllMaterials() async {
    await _ensureInitialized();
    return List.from(_materials);
  }

  // دالة جديدة للحصول على المواد حسب ترتيب الإضافة
  Future<List<String>> getAllMaterialsByInsertionOrder() async {
    await _ensureInitialized();
    return List.from(_materialsByInsertionOrder);
  }

  // دالة جديدة للحصول على رقم المادة حسب ترتيب الإضافة
  Future<int?> getMaterialPosition(String material) async {
    await _ensureInitialized();

    final normalizedMaterial = _normalizeMaterial(material);
    final index = _materialsByInsertionOrder
        .indexWhere((m) => m.toLowerCase() == normalizedMaterial.toLowerCase());

    return index >= 0 ? index + 1 : null;
  }

  Future<void> removeMaterial(String material) async {
    await _ensureInitialized();

    final normalizedMaterial = _normalizeMaterial(material);

    // إزالة من القائمتين
    _materials.removeWhere(
        (m) => m.toLowerCase() == normalizedMaterial.toLowerCase());
    _materialsByInsertionOrder.removeWhere(
        (m) => m.toLowerCase() == normalizedMaterial.toLowerCase());

    await _saveToFile();

    if (kDebugMode) {
      debugPrint('✅ تم حذف المادة: $material');
    }
  }

  Future<void> clearAll() async {
    _materials.clear();
    _materialsByInsertionOrder.clear();
    await _saveToFile();

    if (kDebugMode) {
      debugPrint('✅ تم مسح جميع المواد من الفهرس');
    }
  }

  Future<void> _saveToFile() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);

      // حفظ البيانات مع الترتيب
      final Map<String, dynamic> jsonData = {
        'materials': _materials,
        'insertionOrder': _materialsByInsertionOrder,
      };

      final jsonString = jsonEncode(jsonData);
      await file.writeAsString(jsonString);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في حفظ فهرس المواد: $e');
      }
    }
  }

  Future<int> getCount() async {
    await _ensureInitialized();
    return _materials.length;
  }

  Future<bool> exists(String material) async {
    await _ensureInitialized();
    return _materials.any((m) => m.toLowerCase() == material.toLowerCase());
  }
}
