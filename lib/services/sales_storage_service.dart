import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/sales_model.dart';
import 'package:flutter/foundation.dart';

class SalesStorageService {
  Future<String> _getBasePath() async {
    Directory? directory;

    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();
    } else if (Platform.isWindows) {
      directory = await getApplicationDocumentsDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    return directory!.path;
  }

  // اسم الملف الآن يحتوي فقط على التاريخ - مثل المشتريات
  String _createFileName(String date) {
    final dateParts = date.split('/');
    final formattedDate = dateParts.join('-');
    return 'sales-$formattedDate.json'; // فقط sales بدلاً من purchases
  }

  // حفظ مستند المبيعات (ملف واحد لكل تاريخ) - مثل المشتريات
  Future<bool> saveSalesDocument(SalesDocument document) async {
    try {
      final basePath = await _getBasePath();
      final folderPath = '$basePath/AlhalJournals';

      // إنشاء مجلد اليوميات إذا لم يكن موجوداً
      final folder = Directory(folderPath);
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      // اسم الملف: sales-YYYY-MM-DD.json
      final fileName = _createFileName(document.date);
      final filePath = '$folderPath/$fileName';

      // قراءة الملف الحالي إذا كان موجوداً
      final file = File(filePath);
      SalesDocument? existingDocument;

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        existingDocument = SalesDocument.fromJson(jsonMap);
      }

      // دمج السجلات
      List<Sale> mergedSales = [];
      if (existingDocument != null) {
        // الاحتفاظ بسجلات البائعين الآخرين
        for (var existing in existingDocument.sales) {
          bool found = false;
          for (var newSale in document.sales) {
            // إذا كان نفس السجل لنفس البائع، نستبدله
            if (existing.serialNumber == newSale.serialNumber &&
                existing.sellerName == newSale.sellerName) {
              found = true;
              break;
            }
          }
          if (!found) {
            mergedSales.add(existing);
          }
        }
      }

      // إضافة السجلات الجديدة/المعدلة
      mergedSales.addAll(document.sales);

      // ترتيب السجلات حسب الرقم المسلسل
      mergedSales.sort((a, b) =>
          int.parse(a.serialNumber).compareTo(int.parse(b.serialNumber)));

      // تحديث الأرقام المسلسلة
      for (int i = 0; i < mergedSales.length; i++) {
        mergedSales[i] = Sale(
          serialNumber: (i + 1).toString(),
          material: mergedSales[i].material,
          affiliation: mergedSales[i].affiliation,
          sValue: mergedSales[i].sValue,
          count: mergedSales[i].count,
          packaging: mergedSales[i].packaging,
          standing: mergedSales[i].standing,
          net: mergedSales[i].net,
          price: mergedSales[i].price,
          total: mergedSales[i].total,
          cashOrDebt: mergedSales[i].cashOrDebt,
          empties: mergedSales[i].empties,
          customerName: mergedSales[i].customerName,
          sellerName: mergedSales[i].sellerName,
        );
      }

      // الحصول على الرقم النهائي للسجل
      final String finalRecordNumber;
      if (existingDocument != null &&
          existingDocument.recordNumber.isNotEmpty) {
        finalRecordNumber = existingDocument.recordNumber;
      } else {
        finalRecordNumber = await getNextRecordNumber(document.date);
      }

      // تحديث المجاميع
      final totals = _calculateSalesTotals(mergedSales);

      final updatedDocument = SalesDocument(
        recordNumber: finalRecordNumber,
        date: document.date,
        sellerName: document.sellerName,
        storeName: document.storeName,
        dayName: document.dayName,
        sales: mergedSales,
        totals: totals,
      );

      // حفظ المستند المحدث
      final updatedJsonString = jsonEncode(updatedDocument.toJson());
      await file.writeAsString(updatedJsonString);

      if (kDebugMode) {
        debugPrint('✅ تم حفظ سجل المبيعات رقم $finalRecordNumber: $filePath');
        debugPrint('📊 عدد السجلات: ${mergedSales.length}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في حفظ سجل المبيعات: $e');
      }
      return false;
    }
  }

  // دالة مساعدة لحساب مجاميع المبيعات
  Map<String, String> _calculateSalesTotals(List<Sale> sales) {
    double totalCount = 0;
    double totalBase = 0;
    double totalNet = 0;
    double totalGrand = 0;

    for (var sale in sales) {
      try {
        totalCount += double.tryParse(sale.count) ?? 0;
        totalBase += double.tryParse(sale.standing) ?? 0;
        totalNet += double.tryParse(sale.net) ?? 0;
        totalGrand += double.tryParse(sale.total) ?? 0;
      } catch (e) {}
    }

    return {
      'totalCount': totalCount.toStringAsFixed(0),
      'totalBase': totalBase.toStringAsFixed(2),
      'totalNet': totalNet.toStringAsFixed(2),
      'totalGrand': totalGrand.toStringAsFixed(2),
    };
  }

  // قراءة مستند المبيعات
  Future<SalesDocument?> loadSalesDocument(
      String date, String recordNumber) async {
    try {
      // الحصول على المسار الأساسي
      final basePath = await _getBasePath();

      // إنشاء مسار المجلد
      final folderPath = '$basePath/AlhalJournals';

      // إنشاء اسم الملف
      final fileName = _createFileName(date);
      final filePath = '$folderPath/$fileName';

      // قراءة الملف
      final file = File(filePath);
      if (!await file.exists()) {
        if (kDebugMode) {
          debugPrint('⚠️ ملف المبيعات غير موجود: $filePath');
        }
        return null;
      }

      // قراءة المحتوى وتحويله إلى كائن
      final jsonString = await file.readAsString();
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final document = SalesDocument.fromJson(jsonMap);

      if (kDebugMode) {
        debugPrint('✅ تم تحميل ملف المبيعات: $filePath');
      }

      return document;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في قراءة ملف المبيعات: $e');
      }
      return null;
    }
  }

  // الحصول على قائمة أرقام السجلات المتاحة لتاريخ معين
  Future<List<String>> getAvailableRecords(String date) async {
    try {
      final basePath = await _getBasePath();
      final folderPath = '$basePath/AlhalJournals';
      final fileName = _createFileName(date);
      final filePath = '$folderPath/$fileName';

      // التحقق من وجود الملف
      final file = File(filePath);
      if (!await file.exists()) {
        return [];
      }

      // في الهيكل الجديد، الملف الواحد يحتوي كل السجلات
      // لذا نرجع قائمة تحتوي على رقم السجل الوحيد
      final jsonString = await file.readAsString();
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final recordNumber = jsonMap['recordNumber']?.toString() ?? '1';

      return [recordNumber];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في قراءة سجلات المبيعات: $e');
      }
      return [];
    }
  }

  // الحصول على الرقم التالي المتاح لسجل جديد
  Future<String> getNextRecordNumber(String date) async {
    try {
      final file = await _getSalesFile(date);
      if (!await file.exists()) {
        return '1';
      }

      // قراءة الرقم الموجود في الملف
      final jsonString = await file.readAsString();
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final currentNumber = int.tryParse(jsonMap['recordNumber'] ?? '1') ?? 1;

      return currentNumber.toString(); // نفس الرقم (ملف واحد لكل تاريخ)
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في الحصول على الرقم التسلسلي التالي: $e');
      }
      return '1';
    }
  }

  // دالة مساعدة للحصول على ملف المبيعات
  Future<File> _getSalesFile(String date) async {
    final basePath = await _getBasePath();
    final folderPath = '$basePath/AlhalJournals';
    final fileName = _createFileName(date);
    return File('$folderPath/$fileName');
  }

  // حذف سجل معين
  Future<bool> deleteSalesDocument(String date, String recordNumber) async {
    try {
      // الحصول على المسار الأساسي
      final basePath = await _getBasePath();

      // إنشاء مسار المجلد
      final folderPath = '$basePath/AlhalJournals';

      // إنشاء اسم الملف
      final fileName = _createFileName(date);
      final filePath = '$folderPath/$fileName';

      // حذف الملف
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();

        if (kDebugMode) {
          debugPrint('✅ تم حذف ملف المبيعات: $filePath');
        }

        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في حذف ملف المبيعات: $e');
      }
      return false;
    }
  }

  // الحصول على مسار الملف لمشاركته
  Future<String?> getFilePath(String date, String recordNumber) async {
    try {
      final basePath = await _getBasePath();
      final folderPath = '$basePath/AlhalJournals';
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

  // دالة جديدة: حساب إجمالي المبيعات النقدية ليوم محدد
  Future<double> getTotalCashSales(String date) async {
    double totalCashSales = 0;

    try {
      final doc = await loadSalesDocument(date, '1'); // ملف واحد لكل تاريخ
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

  // دالة جديدة: حساب إجمالي جميع المبيعات (نقدي ودين)
  Future<double> getTotalSales(String date) async {
    double totalSales = 0;

    try {
      final doc = await loadSalesDocument(date, '1'); // ملف واحد لكل تاريخ
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

  // الحصول على التواريخ المتاحة مع أرقام اليوميات - مثل المشتريات بالضبط
  Future<List<Map<String, String>>> getAvailableDatesWithNumbers() async {
    try {
      final basePath = await _getBasePath();
      final folderPath = '$basePath/AlhalJournals'; // نفس مجلد المشتريات

      final folder = Directory(folderPath);
      if (!await folder.exists()) {
        return [];
      }

      final files = await folder.list().toList();
      final datesWithNumbers = <Map<String, String>>[];

      for (var file in files) {
        if (file is File && file.path.endsWith('.json')) {
          try {
            final fileName = file.path.split('/').last;
            // البحث فقط عن ملفات المبيعات sales-
            if (fileName.startsWith('sales-')) {
              final jsonString = await file.readAsString();
              final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
              final date = jsonMap['date']?.toString() ?? '';
              final journalNumber = jsonMap['recordNumber']?.toString() ?? '1';

              if (date.isNotEmpty) {
                datesWithNumbers.add({
                  'date': date,
                  'journalNumber': journalNumber,
                  'fileName': fileName,
                });
              }
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('❌ خطأ في قراءة ملف: ${file.path}, $e');
            }
          }
        }
      }

      // ترتيب حسب رقم اليومية (تصاعدي) - مثل المشتريات بالضبط
      datesWithNumbers.sort((a, b) {
        final numA = int.tryParse(a['journalNumber'] ?? '0') ?? 0;
        final numB = int.tryParse(b['journalNumber'] ?? '0') ?? 0;
        return numA.compareTo(numB);
      });

      return datesWithNumbers;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في قراءة التواريخ: $e');
      }
      return [];
    }
  }
}
