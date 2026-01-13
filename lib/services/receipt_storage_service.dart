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

  // حفظ مستند الاستلام (النسخة القديمة)
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

  // قراءة مستند الاستلام (النسخة القديمة)
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
      final List<FileSystemEntity> files = await folder.list().toList();
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
        final List<FileSystemEntity> remainingFiles =
            await folder.list().toList();

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
  Future<String?> getFilePath(String date, [String? recordNumber]) async {
    try {
      // الحصول على المسار الأساسي
      final basePath = await _getBasePath();

      // إنشاء مسار المجلد
      final folderName = _createFolderName(date);
      final folderPath = '$basePath/Receipts/$folderName';

      if (recordNumber != null) {
        // إنشاء اسم الملف
        final fileName = _createFileName(date, recordNumber);
        final filePath = '$folderPath/$fileName';

        // التحقق من وجود الملف
        final file = File(filePath);
        if (await file.exists()) {
          return filePath;
        }
      } else {
        // إذا لم يتم تحديد رقم السجل، نرجع أول ملف
        final folder = Directory(folderPath);
        if (!await folder.exists()) {
          return null;
        }

        final List<FileSystemEntity> files = await folder.list().toList();
        for (var fileEntry in files) {
          if (fileEntry is File && fileEntry.path.endsWith('.json')) {
            return fileEntry.path;
          }
        }
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

  // دالة جديدة: تحميل يومية الاستلام لتاريخ معين
  Future<ReceiptDocument?> loadReceiptDocumentForDate(String date) async {
    try {
      final basePath = await _getBasePath();
      final folderName = _createFolderName(date);
      final folderPath = '$basePath/Receipts/$folderName';

      final folder = Directory(folderPath);
      if (!await folder.exists()) {
        return null;
      }

      final List<FileSystemEntity> files = await folder.list().toList();
      if (files.isEmpty) {
        return null;
      }

      // البحث عن أول ملف
      for (var fileEntry in files) {
        if (fileEntry is File && fileEntry.path.endsWith('.json')) {
          final jsonString = await fileEntry.readAsString();
          final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
          return ReceiptDocument.fromJson(jsonMap);
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في قراءة يومية الاستلام: $e');
      }
      return null;
    }
  }

  // الحصول على تواريخ اليوميات المتاحة
  Future<List<Map<String, String>>> getAvailableDatesWithNumbers() async {
    try {
      final basePath = await _getBasePath();
      final receiptsPath = '$basePath/Receipts';

      final folder = Directory(receiptsPath);
      if (!await folder.exists()) {
        return [];
      }

      final List<FileSystemEntity> folders = await folder.list().toList();
      final datesWithNumbers = <Map<String, String>>[];

      for (var folderEntry in folders) {
        if (folderEntry is Directory) {
          final folderName = folderEntry.path.split('/').last;
          if (folderName.startsWith('receipt-')) {
            final date = folderName.replaceFirst('receipt-', '');
            final formattedDate = date.replaceAll('-', '/');

            final List<FileSystemEntity> files =
                await folderEntry.list().toList();
            if (files.isNotEmpty) {
              File? firstFile;
              for (var fileEntry in files) {
                if (fileEntry is File && fileEntry.path.endsWith('.json')) {
                  firstFile = fileEntry;
                  break;
                }
              }

              if (firstFile != null) {
                final jsonString = await firstFile.readAsString();
                final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
                final journalNumber =
                    jsonMap['recordNumber']?.toString() ?? '1';

                datesWithNumbers.add({
                  'date': formattedDate,
                  'journalNumber': journalNumber,
                });
              }
            }
          }
        }
      }

      datesWithNumbers.sort((a, b) {
        final numA = int.tryParse(a['journalNumber'] ?? '0') ?? 0;
        final numB = int.tryParse(b['journalNumber'] ?? '0') ?? 0;
        return numA.compareTo(numB);
      });

      return datesWithNumbers;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في قراءة تواريخ الاستلام: $e');
      }
      return [];
    }
  }

/*
  // حساب المجاميع
  Map<String, String> _calculateTotals(List<Receipt> receipts) {
    double totalCount = 0;
    double totalStanding = 0;
    double totalPayment = 0;
    double totalLoad = 0;

    for (var receipt in receipts) {
      try {
        totalCount += double.tryParse(receipt.count) ?? 0;
        totalStanding += double.tryParse(receipt.standing) ?? 0;
        totalPayment += double.tryParse(receipt.payment) ?? 0;
        totalLoad += double.tryParse(receipt.load) ?? 0;
      } catch (e) {}
    }

    return {
      'totalCount': totalCount.toStringAsFixed(0),
      'totalStanding': totalStanding.toStringAsFixed(2),
      'totalPayment': totalPayment.toStringAsFixed(2),
      'totalLoad': totalLoad.toStringAsFixed(2),
    };
  }
*/
  // الحصول على رقم اليومية لتاريخ معين
  Future<String> getJournalNumberForDate(String date) async {
    try {
      final document = await loadReceiptDocumentForDate(date);
      if (document != null) {
        return document.recordNumber;
      }
      return '1';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في الحصول على رقم يومية الاستلام: $e');
      }
      return '1';
    }
  }

  // الحصول على الرقم التسلسلي التالي
  Future<String> getNextJournalNumber() async {
    try {
      final basePath = await _getBasePath();
      final receiptsPath = '$basePath/Receipts';

      final folder = Directory(receiptsPath);
      if (!await folder.exists()) {
        return '1';
      }

      final List<FileSystemEntity> folders = await folder.list().toList();
      int maxJournalNumber = 0;

      for (var folderEntry in folders) {
        if (folderEntry is Directory) {
          final List<FileSystemEntity> files =
              await folderEntry.list().toList();
          if (files.isNotEmpty) {
            File? firstFile;
            for (var fileEntry in files) {
              if (fileEntry is File && fileEntry.path.endsWith('.json')) {
                firstFile = fileEntry;
                break;
              }
            }

            if (firstFile != null) {
              final jsonString = await firstFile.readAsString();
              final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
              final journalNumber =
                  int.tryParse(jsonMap['recordNumber'] ?? '0') ?? 0;

              if (journalNumber > maxJournalNumber) {
                maxJournalNumber = journalNumber;
              }
            }
          }
        }
      }

      return (maxJournalNumber + 1).toString();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في الحصول على الرقم التسلسلي التالي للاستلام: $e');
      }
      return '1';
    }
  }
}
