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
  List<String> _packagingsByInsertionOrder =
      []; // <-- قائمة جديدة لحفظ ترتيب الإضافة
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
        final Map<String, dynamic> jsonData = jsonDecode(jsonString);

        // تحميل البيانات الجديدة مع الترتيب
        if (jsonData.containsKey('packagings') &&
            jsonData.containsKey('insertionOrder')) {
          final List<dynamic> jsonList = jsonData['packagings'];
          final List<dynamic> orderList = jsonData['insertionOrder'];

          _packagings = jsonList.map((item) => item.toString()).toList();
          _packagingsByInsertionOrder =
              orderList.map((item) => item.toString()).toList();

          // ترتيب قائمة الاقتراحات أبجدياً
          _packagings.sort((a, b) => a.compareTo(b));

          // التأكد من تطابق القائمتين في المحتوى
          if (_packagings.length != _packagingsByInsertionOrder.length) {
            _packagingsByInsertionOrder = List.from(_packagings);
          }
        } else {
          // دعم الملفات القديمة
          final List<dynamic> jsonList = jsonDecode(jsonString);
          _packagings = jsonList.map((item) => item.toString()).toList();
          _packagingsByInsertionOrder = List.from(_packagings);
          _packagings.sort((a, b) => a.compareTo(b));
        }

        if (kDebugMode) {
          debugPrint('✅ تم تحميل ${_packagings.length} عبوة من الفهرس');
          debugPrint(
              'ترتيب الإضافة: ${_packagingsByInsertionOrder.join(', ')}');
        }
      } else {
        _packagings = [];
        _packagingsByInsertionOrder = [];
        if (kDebugMode) {
          debugPrint('✅ فهرس العبوات جديد - لا توجد عبوات مخزنة');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في تحميل فهرس العبوات: $e');
      }
      _packagings = [];
      _packagingsByInsertionOrder = [];
    }
  }

  Future<void> savePackaging(String packaging) async {
    await _ensureInitialized();

    if (packaging.trim().isEmpty) return;

    final normalizedPackaging = _normalizePackaging(packaging);

    // التحقق من عدم وجود العبوة مسبقاً
    if (!_packagings
        .any((p) => p.toLowerCase() == normalizedPackaging.toLowerCase())) {
      // إضافة للقائمتين
      _packagings.add(normalizedPackaging);
      _packagingsByInsertionOrder.add(normalizedPackaging);

      // ترتيب قائمة الاقتراحات أبجدياً فقط
      _packagings.sort((a, b) => a.compareTo(b));

      await _saveToFile();

      if (kDebugMode) {
        debugPrint('✅ تم إضافة عبوة جديدة: $normalizedPackaging');
        debugPrint(
            'رقم العبوة حسب ترتيب الإضافة: ${_packagingsByInsertionOrder.indexOf(normalizedPackaging) + 1}');
      }
    }
  }

  String _normalizePackaging(String packaging) {
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

  // دالة جديدة: الحصول على اقتراحات حسب الرقم (ترتيب الإضافة)
  Future<List<String>> getSuggestionsByNumber(String numberQuery) async {
    await _ensureInitialized();

    if (numberQuery.isEmpty) return [];

    try {
      final int queryNumber = int.parse(numberQuery);

      if (queryNumber <= 0 ||
          queryNumber > _packagingsByInsertionOrder.length) {
        return [];
      }

      // عرض عنصر واحد فقط حسب الرقم (ترتيب الإضافة)
      return [_packagingsByInsertionOrder[queryNumber - 1]];
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

  Future<List<String>> getAllPackagings() async {
    await _ensureInitialized();
    return List.from(_packagings);
  }

  // دالة جديدة للحصول على العبوات حسب ترتيب الإضافة
  Future<List<String>> getAllPackagingsByInsertionOrder() async {
    await _ensureInitialized();
    return List.from(_packagingsByInsertionOrder);
  }

  // دالة جديدة للحصول على رقم العبوة حسب ترتيب الإضافة
  Future<int?> getPackagingPosition(String packaging) async {
    await _ensureInitialized();

    final normalizedPackaging = _normalizePackaging(packaging);
    final index = _packagingsByInsertionOrder.indexWhere(
        (p) => p.toLowerCase() == normalizedPackaging.toLowerCase());

    return index >= 0 ? index + 1 : null;
  }

  Future<void> removePackaging(String packaging) async {
    await _ensureInitialized();

    final normalizedPackaging = _normalizePackaging(packaging);

    // إزالة من القائمتين
    _packagings.removeWhere(
        (p) => p.toLowerCase() == normalizedPackaging.toLowerCase());
    _packagingsByInsertionOrder.removeWhere(
        (p) => p.toLowerCase() == normalizedPackaging.toLowerCase());

    await _saveToFile();

    if (kDebugMode) {
      debugPrint('✅ تم حذف العبوة: $packaging');
    }
  }

  Future<void> clearAll() async {
    _packagings.clear();
    _packagingsByInsertionOrder.clear();
    await _saveToFile();

    if (kDebugMode) {
      debugPrint('✅ تم مسح جميع العبوات من الفهرس');
    }
  }

  Future<void> _saveToFile() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);

      // حفظ البيانات مع الترتيب
      final Map<String, dynamic> jsonData = {
        'packagings': _packagings,
        'insertionOrder': _packagingsByInsertionOrder,
      };

      final jsonString = jsonEncode(jsonData);
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
