import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart'; // لاستخدام kIsWeb
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'; // لدعم الويب

class StoreDbService {
  static final StoreDbService _instance = StoreDbService._internal();
  factory StoreDbService() => _instance;
  StoreDbService._internal();

  static Database? _database;
  static bool _isInitialized = false; // مؤشر للتحقق من التهيئة

  Future<Database> get database async {
    if (_database != null) return _database!;
    await initializeDatabase(); // ضمان التهيئة
    return _database!;
  }

  Future<void> initializeDatabase() async {
    if (_isInitialized) return;
    _database = await _initDB();
    _isInitialized = true;
  }

  Future<Database> _initDB() async {
    // تهيئة المصنع لدعم الويب
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'alhal_store.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE store_config(
            id INTEGER PRIMARY KEY,
            store_name TEXT
          )
        ''');
        // إضافة اسم المحل الافتراضي عند الإنشاء
        await db.insert(
          'store_config',
          {'id': 1, 'store_name': 'المحل الافتراضي'},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      },
    );
  }

  // حفظ اسم المحل
  Future<void> saveStoreName(String storeName) async {
    final db = await database;
    // يتم تخزين اسم محل واحد فقط، لذا سنستخدم id ثابت (1)
    await db.insert(
      'store_config',
      {'id': 1, 'store_name': storeName},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // استرجاع اسم المحل
  Future<String?> getStoreName() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'store_config',
      where: 'id = ?',
      whereArgs: [1],
    );

    if (maps.isNotEmpty) {
      return maps.first['store_name'] as String;
    }
    return null;
  }
}
