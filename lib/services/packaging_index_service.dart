import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class PackagingIndexService {
  static final PackagingIndexService _instance =
      PackagingIndexService._internal();
  factory PackagingIndexService() => _instance;
  PackagingIndexService._internal();

  static const String _fileName = 'packaging_index.json';
  List<String> _packagings = [];
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _loadPackagings();
      _isInitialized = true;
    }
  }

  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_fileName';
  }

  Future<void> _loadPackagings() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _packagings = jsonList.map((item) => item.toString()).toList();

        // ترتيب العبوات أبجدياً
        _packagings.sort((a, b) => a.compareTo(b));

        if (kDebugMode) {
          debugPrint('✅ تم تحميل ${_packagings.length} عبوة من الفهرس');
        }
      } else {
        _packagings = [];
        // لا توجد قيم افتراضية - تبدأ فارغة تماماً
        if (kDebugMode) {
          debugPrint('✅ فهرس العبوات جديد - لا توجد عبوات مخزنة');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في تحميل فهرس العبوات: $e');
      }
      _packagings = [];
    }
  }

  Future<void> savePackaging(String packaging) async {
    await _ensureInitialized();

    if (packaging.trim().isEmpty) return;

    final normalizedPackaging = _normalizePackaging(packaging);

    // التحقق من عدم وجود العبوة مسبقاً
    if (!_packagings
        .any((p) => p.toLowerCase() == normalizedPackaging.toLowerCase())) {
      _packagings.add(normalizedPackaging);
      _packagings.sort((a, b) => a.compareTo(b));

      await _saveToFile();

      if (kDebugMode) {
        debugPrint('✅ تم إضافة عبوة جديدة: $normalizedPackaging');
      }
    }
  }

  String _normalizePackaging(String packaging) {
    // إزالة المسافات الزائدة وتحويل أول حرف لحرف كبير
    String normalized = packaging.trim();
    if (normalized.isNotEmpty) {
      normalized = normalized[0].toUpperCase() + normalized.substring(1);
    }
    return normalized;
  }

  Future<List<String>> getSuggestions(String query) async {
    await _ensureInitialized();

    if (query.isEmpty) return [];

    final normalizedQuery = query.toLowerCase().trim();

    return _packagings.where((packaging) {
      return packaging.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  Future<List<String>> getSuggestionsByFirstLetter(String letter) async {
    await _ensureInitialized();

    if (letter.isEmpty) return [];

    final normalizedLetter = letter.toLowerCase().trim();

    return _packagings.where((packaging) {
      return packaging.toLowerCase().startsWith(normalizedLetter);
    }).toList();
  }

  Future<List<String>> getAllPackagings() async {
    await _ensureInitialized();
    return List.from(_packagings);
  }

  Future<void> removePackaging(String packaging) async {
    await _ensureInitialized();

    _packagings.removeWhere((p) => p.toLowerCase() == packaging.toLowerCase());
    await _saveToFile();

    if (kDebugMode) {
      debugPrint('✅ تم حذف العبوة: $packaging');
    }
  }

  Future<void> clearAll() async {
    _packagings.clear();
    await _saveToFile();

    if (kDebugMode) {
      debugPrint('✅ تم مسح جميع العبوات من الفهرس');
    }
  }

  Future<void> _saveToFile() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);

      final jsonString = jsonEncode(_packagings);
      await file.writeAsString(jsonString);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في حفظ فهرس العبوات: $e');
      }
    }
  }

  Future<int> getCount() async {
    await _ensureInitialized();
    return _packagings.length;
  }

  Future<bool> exists(String packaging) async {
    await _ensureInitialized();
    return _packagings.any((p) => p.toLowerCase() == packaging.toLowerCase());
  }
}
