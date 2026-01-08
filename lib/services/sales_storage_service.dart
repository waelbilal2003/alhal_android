import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/sales_model.dart';

// استيراد debugPrint
import 'package:flutter/foundation.dart';

class SalesStorageService {
  // الحصول على المسار الأساسي للتطبيق
  Future<String> _getBasePath() async {
    Directory? directory;

    if (Platform.isAndroid) {
      // للأندرويد: استخدام External Storage
      directory = await getExternalStorageDirectory();
    } else if (Platform.isWindows) {
      // للويندوز: استخدام Documents
      directory = await getApplicationDocumentsDirectory();
    } else {
      // لباقي المنصات
      directory = await getApplicationDocumentsDirectory();
    }

    return directory!.path;
  }

  // إنشاء اسم الملف بناءً على التاريخ فقط (يومية واحدة لكل تاريخ)
  String _createFileName(String date) {
    // تحويل التاريخ من "2025/12/19" إلى "2025-12-19"
    final dateParts = date.split('/');
    final formattedDate = dateParts.join('-');

    return 'alhal-sales-$formattedDate.json';
  }

  // حفظ مستند المبيعات (يومية كاملة)
  Future<bool> saveSalesDocument(SalesDocument document) async {
    try {
      // الحصول على المسار الأساسي
      final basePath = await _getBasePath();

      // إنشاء مسار المجلد الرئيسي
      final folderPath = '$basePath/AlhalSales';

      // إنشاء المجلد إذا لم يكن موجوداً
      final folder = Directory(folderPath);
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      // إنشاء اسم الملف (يومية واحدة لكل تاريخ)
      final fileName = _createFileName(document.date);
      final filePath = '$folderPath/$fileName';

      // تحويل المستند إلى JSON وحفظه
      final file = File(filePath);
      final jsonString = jsonEncode(document.toJson());
      await file.writeAsString(jsonString);

      if (kDebugMode) {
        debugPrint('✅ تم حفظ يومية المبيعات: $filePath');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في حفظ يومية المبيعات: $e');
      }
      return false;
    }
  }

  // قراءة مستند المبيعات (يومية كاملة)
  Future<SalesDocument?> loadSalesDocument(String date) async {
    try {
      // الحصول على المسار الأساسي
      final basePath = await _getBasePath();

      // إنشاء مسار المجلد الرئيسي
      final folderPath = '$basePath/AlhalSales';

      // إنشاء اسم الملف (يومية واحدة لكل تاريخ)
      final fileName = _createFileName(date);
      final filePath = '$folderPath/$fileName';

      // قراءة الملف
      final file = File(filePath);
      if (!await file.exists()) {
        if (kDebugMode) {
          debugPrint('⚠️ يومية المبيعات غير موجودة للتاريخ: $date');
        }
        return null;
      }

      // قراءة المحتوى وتحويله إلى كائن
      final jsonString = await file.readAsString();
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final document = SalesDocument.fromJson(jsonMap);

      if (kDebugMode) {
        debugPrint('✅ تم تحميل يومية المبيعات: $filePath');
      }

      return document;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في قراءة يومية المبيعات: $e');
      }
      return null;
    }
  }

  // التحقق من وجود يومية لتاريخ معين
  Future<bool> hasDailyJournal(String date) async {
    try {
      // الحصول على المسار الأساسي
      final basePath = await _getBasePath();

      // إنشاء مسار المجلد الرئيسي
      final folderPath = '$basePath/AlhalSales';

      // إنشاء اسم الملف
      final fileName = _createFileName(date);
      final filePath = '$folderPath/$fileName';

      // التحقق من وجود الملف
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في التحقق من وجود يومية المبيعات: $e');
      }
      return false;
    }
  }

  // الحصول على رقم اليومية (يومية واحدة لكل تاريخ - رقم تسلسلي عالمي)
  Future<String> getDailyJournalNumber(String date) async {
    try {
      // الحصول على المسار الأساسي
      final basePath = await _getBasePath();
      final folderPath = '$basePath/AlhalSales';

      // التحقق من وجود يومية لهذا التاريخ
      final hasJournal = await hasDailyJournal(date);

      if (hasJournal) {
        // إذا كانت اليومية موجودة، نحمل رقمها
        final document = await loadSalesDocument(date);
        return document?.recordNumber ?? '1';
      }

      // إذا لم تكن موجودة، نحسب الرقم التالي من جميع اليوميات
      final folder = Directory(folderPath);
      if (!await folder.exists()) {
        return '1';
      }

      // قراءة جميع الملفات واستخراج أكبر رقم يومية
      final files = await folder.list().toList();
      int maxNumber = 0;

      for (var file in files) {
        if (file is File && file.path.endsWith('.json')) {
          try {
            final jsonString = await file.readAsString();
            final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
            final recordNumber =
                int.tryParse(jsonMap['recordNumber'] ?? '0') ?? 0;
            if (recordNumber > maxNumber) {
              maxNumber = recordNumber;
            }
          } catch (e) {
            // تجاهل الملفات التالفة
          }
        }
      }

      return (maxNumber + 1).toString();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في الحصول على رقم يومية المبيعات: $e');
      }
      return '1';
    }
  }

  // حذف يومية كاملة
  Future<bool> deleteSalesDocument(String date) async {
    try {
      // الحصول على المسار الأساسي
      final basePath = await _getBasePath();

      // إنشاء مسار المجلد الرئيسي
      final folderPath = '$basePath/AlhalSales';

      // إنشاء اسم الملف
      final fileName = _createFileName(date);
      final filePath = '$folderPath/$fileName';

      // حذف الملف
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();

        if (kDebugMode) {
          debugPrint('✅ تم حذف يومية المبيعات: $filePath');
        }

        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في حذف يومية المبيعات: $e');
      }
      return false;
    }
  }

  // الحصول على مسار الملف لمشاركته
  Future<String?> getFilePath(String date) async {
    try {
      // الحصول على المسار الأساسي
      final basePath = await _getBasePath();

      // إنشاء مسار المجلد الرئيسي
      final folderPath = '$basePath/AlhalSales';

      // إنشاء اسم الملف
      final fileName = _createFileName(date);
      final filePath = '$folderPath/$fileName';

      // التحقق من وجود الملف
      final file = File(filePath);
      if (await file.exists()) {
        return filePath;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في الحصول على مسار ملف المبيعات: $e');
      }
      return null;
    }
  }

  // دالة: حساب إجمالي المبيعات النقدية ليوم محدد (يومية واحدة)
  Future<double> getTotalCashSales(String date) async {
    double totalCashSales = 0;

    try {
      final doc = await loadSalesDocument(date);
      if (doc != null) {
        for (var sale in doc.sales) {
          // حساب فقط المبيعات النقدية (لا تشمل المبيعات بالدين)
          if (sale.cashOrDebt == 'نقدي') {
            totalCashSales += double.tryParse(sale.total) ?? 0;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error calculating cash sales: $e');
      }
    }

    return totalCashSales;
  }

  // دالة: حساب إجمالي جميع المبيعات (نقدي ودين) ليوم محدد (يومية واحدة)
  Future<double> getTotalSales(String date) async {
    double totalSales = 0;

    try {
      final doc = await loadSalesDocument(date);
      if (doc != null) {
        for (var sale in doc.sales) {
          totalSales += double.tryParse(sale.total) ?? 0;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error calculating total sales: $e');
      }
    }

    return totalSales;
  }

  // الحصول على قائمة أرقام السجلات المتاحة لتاريخ معين
  Future<List<String>> getAvailableRecords(String date) async {
    try {
      // الحصول على المسار الأساسي
      final basePath = await _getBasePath();

      // إنشاء مسار المجلد
      final folderName = _createFolderName(date);
      final folderPath = '$basePath/AlhalSales/$folderName';

      // التحقق من وجود المجلد
      final folder = Directory(folderPath);
      if (!await folder.exists()) {
        return [];
      }

      // قراءة قائمة الملفات
      final files = await folder.list().toList();
      final recordNumbers = <String>[];

      for (var file in files) {
        if (file is File && file.path.endsWith('.json')) {
          // استخراج رقم السجل من اسم الملف
          // مثال: alhal-sales-1-19-12-2025.json
          final fileName = file.path.split('/').last;
          final parts = fileName.split('-');
          if (parts.length >= 3) {
            final recordNumber = parts[2]; // الرقم الثالث هو رقم السجل
            recordNumbers.add(recordNumber);
          }
        }
      }

      // ترتيب الأرقام تصاعدياً
      recordNumbers.sort((a, b) => int.parse(a).compareTo(int.parse(b)));

      return recordNumbers;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في قراءة سجلات المبيعات: $e');
      }
      return [];
    }
  }

  // إنشاء اسم المجلد بناءً على التاريخ
  String _createFolderName(String date) {
    // تحويل التاريخ من "2025/12/19" إلى "2025-12-19"
    final dateParts = date.split('/');
    final formattedDate = dateParts.join('-');

    return 'alhal-sales-$formattedDate';
  }
}
