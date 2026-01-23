import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

// 1. إضافة واجهة EnhancedIndexService
abstract class EnhancedIndexService {
  Future<List<String>> getEnhancedSuggestions(String query);
}

class SupplierData {
  String name;
  double balance;
  String mobile;
  bool isBalanceLocked; // قفل الرصيد بعد أول عملية أو إدخال أولي

  SupplierData({
    required this.name,
    this.balance = 0.0,
    this.mobile = '',
    this.isBalanceLocked = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'balance': balance,
        'mobile': mobile,
        'isBalanceLocked': isBalanceLocked,
      };

  factory SupplierData.fromJson(dynamic json) {
    if (json is String) {
      return SupplierData(name: json);
    }
    return SupplierData(
      name: json['name'] ?? '',
      balance: (json['balance'] ?? 0.0).toDouble(),
      mobile: json['mobile'] ?? '',
      isBalanceLocked: json['isBalanceLocked'] ?? false,
    );
  }
}

// 2. جعل SupplierIndexService تطبق واجهة EnhancedIndexService
class SupplierIndexService implements EnhancedIndexService {
  static final SupplierIndexService _instance =
      SupplierIndexService._internal();
  factory SupplierIndexService() => _instance;
  SupplierIndexService._internal();

  static const String _fileName = 'supplier_index.json';
  Map<int, SupplierData> _supplierMap = {};
  bool _isInitialized = false;
  int _nextId = 1;

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

          _supplierMap.clear();
          suppliersJson.forEach((key, value) {
            _supplierMap[int.parse(key)] = SupplierData.fromJson(value);
          });

          _nextId = jsonData['nextId'] ?? 1;
        } else {
          _supplierMap.clear();
          if (jsonData is List) {
            for (int i = 0; i < jsonData.length; i++) {
              _supplierMap[i + 1] = SupplierData(name: jsonData[i].toString());
            }
            _nextId = jsonData.length + 1;
          } else if (jsonData.containsKey('suppliers')) {
            final List<dynamic> jsonList = jsonData['suppliers'];
            for (int i = 0; i < jsonList.length; i++) {
              _supplierMap[i + 1] = SupplierData(name: jsonList[i].toString());
            }
            _nextId = jsonList.length + 1;
          }
          await _saveToFile();
        }
      } else {
        _supplierMap.clear();
        _nextId = 1;
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

    if (!_supplierMap.values
        .any((s) => s.name.toLowerCase() == normalizedSupplier.toLowerCase())) {
      _supplierMap[_nextId] = SupplierData(name: normalizedSupplier);
      _nextId++;
      await _saveToFile();
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
        .where(
            (entry) => entry.value.name.toLowerCase().contains(normalizedQuery))
        .map((entry) => entry.value.name)
        .toList();
  }

  // 3. تنفيذ دالة getEnhancedSuggestions المطلوبة من الواجهة
  @override
  Future<List<String>> getEnhancedSuggestions(String query) async {
    await _ensureInitialized();
    if (query.isEmpty) return [];
    final normalizedQuery = query.trim();

    // البحث بالأرقام
    if (RegExp(r'^\d+$').hasMatch(normalizedQuery)) {
      final int? queryNumber = int.tryParse(normalizedQuery);
      if (queryNumber != null && _supplierMap.containsKey(queryNumber)) {
        return [_supplierMap[queryNumber]!.name];
      }
    }

    // البحث النصي
    return await getSuggestions(normalizedQuery);
  }

  Future<List<String>> getAllSuppliers() async {
    await _ensureInitialized();
    final suppliers = _supplierMap.values.map((s) => s.name).toList();
    suppliers.sort((a, b) => a.compareTo(b));
    return suppliers;
  }

  Future<int?> getSupplierPosition(String supplier) async {
    await _ensureInitialized();
    final normalizedSupplier = _normalizeSupplier(supplier);
    for (var entry in _supplierMap.entries) {
      if (entry.value.name.toLowerCase() == normalizedSupplier.toLowerCase()) {
        return entry.key;
      }
    }
    return null;
  }

  Future<void> updateSupplierBalance(String supplierName, double amount) async {
    await _ensureInitialized();
    final normalizedSupplier = _normalizeSupplier(supplierName);
    for (var entry in _supplierMap.entries) {
      if (entry.value.name.toLowerCase() == normalizedSupplier.toLowerCase()) {
        entry.value.balance += amount;
        entry.value.isBalanceLocked = true; // قفل الرصيد بعد أول عملية حسابية
        await _saveToFile();
        return;
      }
    }
  }

  Future<void> setInitialBalance(String supplierName, double balance) async {
    await _ensureInitialized();
    final normalizedSupplier = _normalizeSupplier(supplierName);
    for (var entry in _supplierMap.entries) {
      if (entry.value.name.toLowerCase() == normalizedSupplier.toLowerCase()) {
        if (!entry.value.isBalanceLocked) {
          entry.value.balance = balance;
          await _saveToFile();
        }
        return;
      }
    }
  }

  Future<void> updateSupplierMobile(String supplierName, String mobile) async {
    await _ensureInitialized();
    final normalizedSupplier = _normalizeSupplier(supplierName);
    for (var entry in _supplierMap.entries) {
      if (entry.value.name.toLowerCase() == normalizedSupplier.toLowerCase()) {
        entry.value.mobile = mobile;
        await _saveToFile();
        return;
      }
    }
  }

  Future<void> updateSupplierName(int id, String newName) async {
    await _ensureInitialized();
    if (_supplierMap.containsKey(id)) {
      _supplierMap[id]!.name = _normalizeSupplier(newName);
      await _saveToFile();
    }
  }

  Future<void> removeSupplier(String supplier) async {
    await _ensureInitialized();
    final normalizedSupplier = _normalizeSupplier(supplier);
    int? keyToRemove;
    for (var entry in _supplierMap.entries) {
      if (entry.value.name.toLowerCase() == normalizedSupplier.toLowerCase()) {
        keyToRemove = entry.key;
        break;
      }
    }
    if (keyToRemove != null) {
      _supplierMap.remove(keyToRemove);
      await _saveToFile();
    }
  }

  Future<void> _saveToFile() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);
      final Map<String, dynamic> suppliersJson = {};
      _supplierMap.forEach((key, value) {
        suppliersJson[key.toString()] = value.toJson();
      });
      final Map<String, dynamic> jsonData = {
        'suppliers': suppliersJson,
        'nextId': _nextId,
      };
      await file.writeAsString(jsonEncode(jsonData));
    } catch (e) {
      if (kDebugMode) debugPrint('❌ خطأ في حفظ فهرس الموردين: $e');
    }
  }

  Future<Map<int, SupplierData>> getAllSuppliersWithData() async {
    await _ensureInitialized();
    return Map.from(_supplierMap);
  }

  Future<Map<int, String>> getAllSuppliersWithNumbers() async {
    await _ensureInitialized();
    return _supplierMap.map((key, value) => MapEntry(key, value.name));
  }

  // 4. إضافة دالة للحصول على بيانات مورد معين
  Future<SupplierData?> getSupplierData(String supplierName) async {
    await _ensureInitialized();
    final normalizedSupplier = _normalizeSupplier(supplierName);
    for (var entry in _supplierMap.entries) {
      if (entry.value.name.toLowerCase() == normalizedSupplier.toLowerCase()) {
        return entry.value;
      }
    }
    return null;
  }
}
