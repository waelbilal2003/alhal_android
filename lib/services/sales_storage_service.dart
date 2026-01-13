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

  // إنشاء اسم الملف بناءً على التاريخ ورقم السجل
  String _createFileName(String date, String recordNumber) {
    // تحويل التاريخ من "2025/12/19" إلى "2025-12-19"
    final dateParts = date.split('/');
    final formattedDate = dateParts.join('-');

    return 'alhal-sales-$recordNumber-$formattedDate.json';
  }

  // إنشاء اسم المجلد بناءً على التاريخ
  String _createFolderName(String date) {
    // تحويل التاريخ من "2025/12/19" إلى "2025-12-19"
    final dateParts = date.split('/');
    final formattedDate = dateParts.join('-');

    return 'alhal-sales-$formattedDate';
  }

  // حفظ مستند المبيعات
  // يجب إضافة هذه الدالة إلى SalesStorageService
  Future<bool> saveSalesDocument(SalesDocument document,
      {String? recordNumber}) async {
    try {
      final basePath = await _getBasePath();
      final folderName = _createFolderName(document.date);
      final folderPath = '$basePath/AlhalSales/$folderName';

      // إنشاء المجلد إذا لم يكن موجوداً
      final folder = Directory(folderPath);
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      // اسم الملف: alhal-sales-{رقم السجل}-{التاريخ}.json
      final fileName = _createFileName(document.date, document.recordNumber);
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
      if (recordNumber != null) {
        finalRecordNumber = recordNumber;
      } else if (existingDocument != null &&
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
      final folderName = _createFolderName(date);
      final folderPath = '$basePath/AlhalSales/$folderName';

      // إنشاء اسم الملف
      final fileName = _createFileName(date, recordNumber);
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

  // الحصول على الرقم التالي المتاح لسجل جديد
  Future<String> getNextRecordNumber(String date) async {
    final existingRecords = await getAvailableRecords(date);

    if (existingRecords.isEmpty) {
      return '1';
    }

    // الحصول على أكبر رقم وإضافة 1
    final lastNumber = int.parse(existingRecords.last);
    return (lastNumber + 1).toString();
  }

  // حذف سجل معين
  Future<bool> deleteSalesDocument(String date, String recordNumber) async {
    try {
      // الحصول على المسار الأساسي
      final basePath = await _getBasePath();

      // إنشاء مسار المجلد
      final folderName = _createFolderName(date);
      final folderPath = '$basePath/AlhalSales/$folderName';

      // إنشاء اسم الملف
      final fileName = _createFileName(date, recordNumber);
      final filePath = '$folderPath/$fileName';

      // حذف الملف
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();

        if (kDebugMode) {
          debugPrint('✅ تم حذف ملف المبيعات: $filePath');
        }

        // التحقق من وجود ملفات أخرى في المجلد
        final folder = Directory(folderPath);
        final remainingFiles = await folder.list().toList();

        // إذا كان المجلد فارغاً، احذفه
        if (remainingFiles.isEmpty) {
          await folder.delete();
          if (kDebugMode) {
            debugPrint('✅ تم حذف مجلد المبيعات الفارغ: $folderPath');
          }
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
      // الحصول على المسار الأساسي
      final basePath = await _getBasePath();

      // إنشاء مسار المجلد
      final folderName = _createFolderName(date);
      final folderPath = '$basePath/AlhalSales/$folderName';

      // إنشاء اسم الملف
      final fileName = _createFileName(date, recordNumber);
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
      final records = await getAvailableRecords(date);

      for (var recordNum in records) {
        final doc = await loadSalesDocument(date, recordNum);
        if (doc != null) {
          for (var sale in doc.sales) {
            // حساب فقط المبيعات النقدية (لا تشمل المبيعات بالدين)
            if (sale.cashOrDebt == 'نقدي') {
              totalCashSales += double.tryParse(sale.total) ?? 0;
            }
          }
        }
      }
    } catch (e) {
      print('Error calculating cash sales: $e');
    }

    return totalCashSales;
  }

  // دالة جديدة: حساب إجمالي جميع المبيعات (نقدي ودين)
  Future<double> getTotalSales(String date) async {
    double totalSales = 0;

    try {
      final records = await getAvailableRecords(date);

      for (var recordNum in records) {
        final doc = await loadSalesDocument(date, recordNum);
        if (doc != null) {
          for (var sale in doc.sales) {
            totalSales += double.tryParse(sale.total) ?? 0;
          }
        }
      }
    } catch (e) {
      print('Error calculating total sales: $e');
    }

    return totalSales;
  }

  Future<List<Map<String, String>>> getAvailableDatesWithNumbers() async {
    try {
      final basePath = await _getBasePath();
      final folderPath = '$basePath/AlhalJournals';

      final folder = Directory(folderPath);
      if (!await folder.exists()) {
        return [];
      }

      final files = await folder.list().toList();
      final datesWithNumbers = <Map<String, String>>[];

      for (var file in files) {
        if (file is File && file.path.endsWith('.json')) {
          try {
            final jsonString = await file.readAsString();
            final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
            final date = jsonMap['date']?.toString() ?? '';
            final journalNumber = jsonMap['recordNumber']?.toString() ?? '1';
            final fileName = file.path.split('/').last;

            if (fileName.startsWith('sales-') && date.isNotEmpty) {
              datesWithNumbers.add({
                'date': date,
                'journalNumber': journalNumber,
                'fileName': fileName,
              });
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('❌ خطأ في قراءة ملف: ${file.path}, $e');
            }
          }
        }
      }

      // ترتيب حسب رقم اليومية (تصاعدي)
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
