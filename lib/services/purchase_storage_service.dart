import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/purchase_model.dart';

// استيراد debugPrint
import 'package:flutter/foundation.dart';

class PurchaseStorageService {
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

    return 'alhal-$recordNumber-$formattedDate.json';
  }

  // إنشاء اسم المجلد بناءً على التاريخ
  String _createFolderName(String date) {
    // تحويل التاريخ من "2025/12/19" إلى "2025-12-19"
    final dateParts = date.split('/');
    final formattedDate = dateParts.join('-');

    return 'alhal-$formattedDate';
  }

  // حفظ مستند المشتريات
  Future<bool> savePurchaseDocument(PurchaseDocument document) async {
    try {
      // الحصول على المسار الأساسي
      final basePath = await _getBasePath();

      // إنشاء مسار المجلد
      final folderName = _createFolderName(document.date);
      final folderPath = '$basePath/AlhalPurchases/$folderName';

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
        debugPrint('✅ تم حفظ الملف: $filePath');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في حفظ الملف: $e');
      }
      return false;
    }
  }

  // قراءة مستند المشتريات
  Future<PurchaseDocument?> loadPurchaseDocument(
      String date, String recordNumber) async {
    try {
      // الحصول على المسار الأساسي
      final basePath = await _getBasePath();

      // إنشاء مسار المجلد
      final folderName = _createFolderName(date);
      final folderPath = '$basePath/AlhalPurchases/$folderName';

      // إنشاء اسم الملف
      final fileName = _createFileName(date, recordNumber);
      final filePath = '$folderPath/$fileName';

      // قراءة الملف
      final file = File(filePath);
      if (!await file.exists()) {
        if (kDebugMode) {
          debugPrint('⚠️ الملف غير موجود: $filePath');
        }
        return null;
      }

      // قراءة المحتوى وتحويله إلى كائن
      final jsonString = await file.readAsString();
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final document = PurchaseDocument.fromJson(jsonMap);

      if (kDebugMode) {
        debugPrint('✅ تم تحميل الملف: $filePath');
      }

      return document;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في قراءة الملف: $e');
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
      final folderPath = '$basePath/AlhalPurchases/$folderName';

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
          // مثال: alhal-1-19-12-2025.json
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
        debugPrint('❌ خطأ في قراءة السجلات: $e');
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
  Future<bool> deletePurchaseDocument(String date, String recordNumber) async {
    try {
      // الحصول على المسار الأساسي
      final basePath = await _getBasePath();

      // إنشاء مسار المجلد
      final folderName = _createFolderName(date);
      final folderPath = '$basePath/AlhalPurchases/$folderName';

      // إنشاء اسم الملف
      final fileName = _createFileName(date, recordNumber);
      final filePath = '$folderPath/$fileName';

      // حذف الملف
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();

        if (kDebugMode) {
          debugPrint('✅ تم حذف الملف: $filePath');
        }

        // التحقق من وجود ملفات أخرى في المجلد
        final folder = Directory(folderPath);
        final remainingFiles = await folder.list().toList();

        // إذا كان المجلد فارغاً، احذفه
        if (remainingFiles.isEmpty) {
          await folder.delete();
          if (kDebugMode) {
            debugPrint('✅ تم حذف المجلد الفارغ: $folderPath');
          }
        }

        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في حذف الملف: $e');
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
      final folderPath = '$basePath/AlhalPurchases/$folderName';

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
        debugPrint('❌ خطأ في الحصول على مسار الملف: $e');
      }
      return null;
    }
  }
}
