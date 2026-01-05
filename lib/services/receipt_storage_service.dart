import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/receipt_model.dart';

// استيراد debugPrint
import 'package:flutter/foundation.dart';

class ReceiptStorageService {
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

    return 'receipt-$recordNumber-$formattedDate.json';
  }

  // إنشاء اسم المجلد بناءً على التاريخ
  String _createFolderName(String date) {
    // تحويل التاريخ من "2025/12/19" إلى "2025-12-19"
    final dateParts = date.split('/');
    final formattedDate = dateParts.join('-');

    return 'receipt-$formattedDate';
  }

  // حفظ مستند الاستلام
  Future<bool> saveReceiptDocument(ReceiptDocument document) async {
    try {
      // الحصول على المسار الأساسي
      final basePath = await _getBasePath();

      // إنشاء مسار المجلد
      final folderName = _createFolderName(document.date);
      final folderPath = '$basePath/Receipts/$folderName';

      // إنشاء المجلد إذا لم يكن موجوداً
      final folder = Directory(folderPath);
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      // إنشاء اسم الملف
      final fileName = _createFileName(document.date, document.recordNumber);
      final filePath = '$folderPath/$fileName';

      // تحويل المستند إلى JSON وحفظه
      final file = File(filePath);
      final jsonString = jsonEncode(document.toJson());
      await file.writeAsString(jsonString);

      if (kDebugMode) {
        debugPrint('✅ تم حفظ ملف الاستلام: $filePath');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في حفظ ملف الاستلام: $e');
      }
      return false;
    }
  }

  // قراءة مستند الاستلام
  Future<ReceiptDocument?> loadReceiptDocument(
      String date, String recordNumber) async {
    try {
      // الحصول على المسار الأساسي
      final basePath = await _getBasePath();

      // إنشاء مسار المجلد
      final folderName = _createFolderName(date);
      final folderPath = '$basePath/Receipts/$folderName';

      // إنشاء اسم الملف
      final fileName = _createFileName(date, recordNumber);
      final filePath = '$folderPath/$fileName';

      // قراءة الملف
      final file = File(filePath);
      if (!await file.exists()) {
        if (kDebugMode) {
          debugPrint('⚠️ ملف الاستلام غير موجود: $filePath');
        }
        return null;
      }

      // قراءة المحتوى وتحويله إلى كائن
      final jsonString = await file.readAsString();
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final document = ReceiptDocument.fromJson(jsonMap);

      if (kDebugMode) {
        debugPrint('✅ تم تحميل ملف الاستلام: $filePath');
      }

      return document;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في قراءة ملف الاستلام: $e');
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
      final folderPath = '$basePath/Receipts/$folderName';

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
          // مثال: receipt-1-19-12-2025.json
          final fileName = file.path.split('/').last;
          final parts = fileName.split('-');
          if (parts.length >= 2) {
            final recordNumber = parts[1]; // الرقم الثاني هو رقم السجل
            recordNumbers.add(recordNumber);
          }
        }
      }

      // ترتيب الأرقام تصاعدياً
      recordNumbers.sort((a, b) => int.parse(a).compareTo(int.parse(b)));

      return recordNumbers;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في قراءة سجلات الاستلام: $e');
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
  Future<bool> deleteReceiptDocument(String date, String recordNumber) async {
    try {
      // الحصول على المسار الأساسي
      final basePath = await _getBasePath();

      // إنشاء مسار المجلد
      final folderName = _createFolderName(date);
      final folderPath = '$basePath/Receipts/$folderName';

      // إنشاء اسم الملف
      final fileName = _createFileName(date, recordNumber);
      final filePath = '$folderPath/$fileName';

      // حذف الملف
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();

        if (kDebugMode) {
          debugPrint('✅ تم حذف ملف الاستلام: $filePath');
        }

        // التحقق من وجود ملفات أخرى في المجلد
        final folder = Directory(folderPath);
        final remainingFiles = await folder.list().toList();

        // إذا كان المجلد فارغاً، احذفه
        if (remainingFiles.isEmpty) {
          await folder.delete();
          if (kDebugMode) {
            debugPrint('✅ تم حذف مجلد الاستلام الفارغ: $folderPath');
          }
        }

        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في حذف ملف الاستلام: $e');
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
      final folderPath = '$basePath/Receipts/$folderName';

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
        debugPrint('❌ خطأ في الحصول على مسار ملف الاستلام: $e');
      }
      return null;
    }
  }

  // دالة جديدة: حساب إجمالي الدفعة من شاشة الاستلام
  Future<double> getTotalPayment(String date) async {
    double totalPayment = 0;

    try {
      final records = await getAvailableRecords(date);

      for (var recordNum in records) {
        final doc = await loadReceiptDocument(date, recordNum);
        if (doc != null) {
          // إذا كان totals غير nullable، نستخدمه مباشرة
          totalPayment +=
              double.tryParse(doc.totals['totalPayment'] ?? '0') ?? 0;
        }
      }
    } catch (e) {
      print('Error calculating total payment: $e');
    }

    return totalPayment;
  }

// دالة جديدة: حساب إجمالي الحمولة من شاشة الاستلام
  Future<double> getTotalLoad(String date) async {
    double totalLoad = 0;

    try {
      final records = await getAvailableRecords(date);

      for (var recordNum in records) {
        final doc = await loadReceiptDocument(date, recordNum);
        if (doc != null) {
          // إذا كان totals غير nullable، نستخدمه مباشرة
          totalLoad += double.tryParse(doc.totals['totalLoad'] ?? '0') ?? 0;
        }
      }
    } catch (e) {
      print('Error calculating total load: $e');
    }

    return totalLoad;
  }
}
