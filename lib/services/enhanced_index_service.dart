import 'package:flutter/foundation.dart';
import 'material_index_service.dart';
import 'packaging_index_service.dart';
import 'supplier_index_service.dart';
import 'customer_index_service.dart';

// دالة مساعدة واحدة للبحث المتقدم في جميع أنواع الفهارس
Future<List<String>> getEnhancedSuggestions(
    dynamic indexService, String query) async {
  if (query.isEmpty) return [];

  final normalizedQuery = query.trim();

  // محاولة البحث كرقم أولاً
  if (RegExp(r'^\d+$').hasMatch(normalizedQuery)) {
    try {
      // استخدم الدالة getEnhancedSuggestions الموجودة في كل فهرس
      if (indexService is MaterialIndexService) {
        return await indexService.getEnhancedSuggestions(normalizedQuery);
      } else if (indexService is PackagingIndexService) {
        return await indexService.getEnhancedSuggestions(normalizedQuery);
      } else if (indexService is SupplierIndexService) {
        return await indexService.getEnhancedSuggestions(normalizedQuery);
      } else if (indexService is CustomerIndexService) {
        return await indexService.getEnhancedSuggestions(normalizedQuery);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في البحث الرقمي المتقدم: $e');
      }
    }
  }

  // البحث كنص باستخدام الدالة الأصلية
  return await indexService.getSuggestions(normalizedQuery);
}
