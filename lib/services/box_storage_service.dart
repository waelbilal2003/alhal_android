import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/box_model.dart';

// استيراد debugPrint
import 'package:flutter/foundation.dart';

class BoxStorageService {
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

    return 'box-$recordNumber-$formattedDate.json';
  }

  // إنشاء اسم المجلد بناءً على التاريخ
  String _createFolderName(String date) {
    // تحويل التاريخ من "2025/12/19" إلى "2025-12-19"
    final dateParts = date.split('/');
    final formattedDate = dateParts.join('-');

    return 'box-$formattedDate';
  }

  // حفظ مستند الصندوق
  Future<bool> saveBoxDocument(BoxDocument document) async {
    try {
      // الحصول على المسار الأساسي
      final basePath = await _getBasePath();

      // إنشاء مسار المجلد
      final folderName = _createFolderName(document.date);
      final folderPath = '$basePath/BoxTransactions/$folderName';

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
        debugPrint('✅ تم حفظ ملف الصندوق: $filePath');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في حفظ ملف الصندوق: $e');
      }
      return false;
    }
  }

  // قراءة مستند الصندوق (النسخة القديمة - للحفاظ على التوافق)
  Future<BoxDocument?> loadBoxDocument(String date, String recordNumber) async {
    try {
      // الحصول على المسار الأساسي
      final basePath = await _getBasePath();

      // إنشاء مسار المجلد
      final folderName = _createFolderName(date);
      final folderPath = '$basePath/BoxTransactions/$folderName';

      // إنشاء اسم الملف
      final fileName = _createFileName(date, recordNumber);
      final filePath = '$folderPath/$fileName';

      // قراءة الملف
      final file = File(filePath);
      if (!await file.exists()) {
        if (kDebugMode) {
          debugPrint('⚠️ ملف الصندوق غير موجود: $filePath');
        }
        return null;
      }

      // قراءة المحتوى وتحويله إلى كائن
      final jsonString = await file.readAsString();
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final document = BoxDocument.fromJson(jsonMap);

      if (kDebugMode) {
        debugPrint('✅ تم تحميل ملف الصندوق: $filePath');
      }

      return document;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في قراءة ملف الصندوق: $e');
      }
      return null;
    }
  }

  // نسخة جديدة - تحميل يومية الصندوق لتاريخ معين
  Future<BoxDocument?> loadBoxDocumentForDate(String date) async {
    try {
      final basePath = await _getBasePath();
      final folderName = _createFolderName(date);
      final folderPath = '$basePath/BoxTransactions/$folderName';

      final folder = Directory(folderPath);
      if (!await folder.exists()) {
        return null;
      }

      final files = await folder.list().toList();
      if (files.isEmpty) {
        return null;
      }

      // البحث عن أول ملف
      for (var fileEntry in files) {
        if (fileEntry is File && fileEntry.path.endsWith('.json')) {
          final jsonString = await fileEntry.readAsString();
          final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
          return BoxDocument.fromJson(jsonMap);
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في قراءة يومية الصندوق: $e');
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
      final folderPath = '$basePath/BoxTransactions/$folderName';

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
          // مثال: box-1-19-12-2025.json
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
        debugPrint('❌ خطأ في قراءة سجلات الصندوق: $e');
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
  Future<bool> deleteBoxDocument(String date, String recordNumber) async {
    try {
      // الحصول على المسار الأساسي
      final basePath = await _getBasePath();

      // إنشاء مسار المجلد
      final folderName = _createFolderName(date);
      final folderPath = '$basePath/BoxTransactions/$folderName';

      // إنشاء اسم الملف
      final fileName = _createFileName(date, recordNumber);
      final filePath = '$folderPath/$fileName';

      // حذف الملف
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();

        if (kDebugMode) {
          debugPrint('✅ تم حذف ملف الصندوق: $filePath');
        }

        // التحقق من وجود ملفات أخرى في المجلد
        final folder = Directory(folderPath);
        final List<FileSystemEntity> remainingFiles =
            await folder.list().toList();

        // إذا كان المجلد فارغاً، احذفه
        if (remainingFiles.isEmpty) {
          await folder.delete();
          if (kDebugMode) {
            debugPrint('✅ تم حذف مجلد الصندوق الفارغ: $folderPath');
          }
        }

        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في حذف ملف الصندوق: $e');
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
      final folderPath = '$basePath/BoxTransactions/$folderName';

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
        debugPrint('❌ خطأ في الحصول على مسار ملف الصندوق: $e');
      }
      return null;
    }
  }

  // الحصول على إجمالي المقبوضات لتاريخ معين
  Future<double> getTotalReceived(String date) async {
    try {
      final availableRecords = await getAvailableRecords(date);
      double totalReceived = 0;

      for (var recordNum in availableRecords) {
        final doc = await loadBoxDocument(date, recordNum);
        if (doc != null) {
          for (var transaction in doc.transactions) {
            totalReceived += double.tryParse(transaction.received) ?? 0;
          }
        }
      }

      return totalReceived;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في حساب إجمالي المقبوضات: $e');
      }
      return 0;
    }
  }

  // الحصول على إجمالي المدفوعات لتاريخ معين
  Future<double> getTotalPaid(String date) async {
    try {
      final availableRecords = await getAvailableRecords(date);
      double totalPaid = 0;

      for (var recordNum in availableRecords) {
        final doc = await loadBoxDocument(date, recordNum);
        if (doc != null) {
          for (var transaction in doc.transactions) {
            totalPaid += double.tryParse(transaction.paid) ?? 0;
          }
        }
      }

      return totalPaid;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في حساب إجمالي المدفوعات: $e');
      }
      return 0;
    }
  }

  // الحصول على تواريخ اليوميات المتاحة
  Future<List<Map<String, String>>> getAvailableDatesWithNumbers() async {
    try {
      final basePath = await _getBasePath();
      final boxPath = '$basePath/BoxTransactions';

      final folder = Directory(boxPath);
      if (!await folder.exists()) {
        return [];
      }

      final List<FileSystemEntity> folders = await folder.list().toList();
      final datesWithNumbers = <Map<String, String>>[];

      for (var folderEntry in folders) {
        if (folderEntry is Directory) {
          final folderName = folderEntry.path.split('/').last;
          if (folderName.startsWith('box-')) {
            final date = folderName.replaceFirst('box-', '');
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
        debugPrint('❌ خطأ في قراءة تواريخ الصندوق: $e');
      }
      return [];
    }
  }

  // الحصول على رقم اليومية لتاريخ معين
  Future<String> getJournalNumberForDate(String date) async {
    try {
      final document = await loadBoxDocumentForDate(date);
      if (document != null) {
        return document.recordNumber;
      }
      return '1';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في الحصول على رقم يومية الصندوق: $e');
      }
      return '1';
    }
  }

  // الحصول على الرقم التسلسلي التالي
  Future<String> getNextJournalNumber() async {
    try {
      final basePath = await _getBasePath();
      final boxPath = '$basePath/BoxTransactions';

      final folder = Directory(boxPath);
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
        debugPrint('❌ خطأ في الحصول على الرقم التسلسلي التالي للصندوق: $e');
      }
      return '1';
    }
  }
}
