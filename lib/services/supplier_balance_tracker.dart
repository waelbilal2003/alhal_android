import 'dart:async';
import 'package:flutter/foundation.dart';
import 'supplier_index_service.dart';

class SupplierBalanceTracker {
  static final SupplierBalanceTracker _instance =
      SupplierBalanceTracker._internal();
  factory SupplierBalanceTracker() => _instance;
  SupplierBalanceTracker._internal();

  final SupplierIndexService _service = SupplierIndexService();
  final Map<String, double> _pendingChanges = {};
  Timer? _debounceTimer;

  // تسجيل تغيير في الوقت الفعلي
  void recordChange(
      String supplierName, double amount, String transactionType) {
    final normalizedName = _normalizeName(supplierName);

    if (!_pendingChanges.containsKey(normalizedName)) {
      _pendingChanges[normalizedName] = 0.0;
    }

    switch (transactionType) {
      case 'purchase_debt': // a (+)
      case 'box_received': // b (+)
        _pendingChanges[normalizedName] =
            _pendingChanges[normalizedName]! + amount;
        break;
      case 'box_paid': // c (-)
      case 'receipt_payment': // d (-)
      case 'receipt_load': // d (-)
        _pendingChanges[normalizedName] =
            _pendingChanges[normalizedName]! - amount;
        break;
      default:
        _pendingChanges[normalizedName] =
            _pendingChanges[normalizedName]! + amount;
    }

    if (kDebugMode) {
      print(
          '📊 تتبع: ${_normalizeName(supplierName)} | النوع: $transactionType | المبلغ: $amount');
    }

    // تأخير الحفظ لمدة 300ms لتجميع العمليات
    _debounceTimer?.cancel();
    _debounceTimer =
        Timer(const Duration(milliseconds: 300), _savePendingChanges);
  }

  Future<void> _savePendingChanges() async {
    if (_pendingChanges.isEmpty) return;

    final Map<String, double> changesCopy = Map.from(_pendingChanges);
    _pendingChanges.clear();

    for (var entry in changesCopy.entries) {
      if (entry.value != 0) {
        try {
          await _service.updateSupplierBalance(entry.key, entry.value);
          if (kDebugMode) {
            print('✅ حفظ: ${entry.key} = ${entry.value.toStringAsFixed(2)}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ خطأ في حفظ ${entry.key}: $e');
          }
        }
      }
    }
  }

  String _normalizeName(String name) {
    String normalized = name.trim();
    if (normalized.isNotEmpty) {
      normalized = normalized[0].toUpperCase() + normalized.substring(1);
    }
    return normalized;
  }

  // إلغاء التتبع
  void dispose() {
    _debounceTimer?.cancel();
    _savePendingChanges(); // حفظ أي عمليات متبقية
  }

  // إلغاء جميع التغييرات المعلقة
  void cancelPendingChanges() {
    _pendingChanges.clear();
    _debounceTimer?.cancel();
  }
}
