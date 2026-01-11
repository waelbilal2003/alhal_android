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
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _materials = jsonList.map((item) => item.toString()).toList();

        // ترتيب المواد أبجدياً
        _materials.sort((a, b) => a.compareTo(b));

        if (kDebugMode) {
          debugPrint('✅ تم تحميل ${_materials.length} مادة من الفهرس');
        }
      } else {
        _materials = [];
        // لا توجد قيم افتراضية - تبدأ فارغة تماماً
        if (kDebugMode) {
          debugPrint('✅ فهرس المواد جديد - لا توجد مواد مخزنة');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في تحميل فهرس المواد: $e');
      }
      _materials = [];
    }
  }

  Future<void> saveMaterial(String material) async {
    await _ensureInitialized();

    if (material.trim().isEmpty) return;

    final normalizedMaterial = _normalizeMaterial(material);

    // التحقق من عدم وجود المادة مسبقاً
    if (!_materials
        .any((m) => m.toLowerCase() == normalizedMaterial.toLowerCase())) {
      _materials.add(normalizedMaterial);
      _materials.sort((a, b) => a.compareTo(b));

      await _saveToFile();

      if (kDebugMode) {
        debugPrint('✅ تم إضافة مادة جديدة: $normalizedMaterial');
      }
    }
  }

  String _normalizeMaterial(String material) {
    // إزالة المسافات الزائدة وتحويل أول حرف لحرف كبير
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

  Future<List<String>> getAllMaterials() async {
    await _ensureInitialized();
    return List.from(_materials);
  }

  Future<void> removeMaterial(String material) async {
    await _ensureInitialized();

    _materials.removeWhere((m) => m.toLowerCase() == material.toLowerCase());
    await _saveToFile();

    if (kDebugMode) {
      debugPrint('✅ تم حذف المادة: $material');
    }
  }

  Future<void> clearAll() async {
    _materials.clear();
    await _saveToFile();

    if (kDebugMode) {
      debugPrint('✅ تم مسح جميع المواد من الفهرس');
    }
  }

  Future<void> _saveToFile() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);

      final jsonString = jsonEncode(_materials);
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
