import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('al_hal_market.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // جدول المواد (المنتجات)
    await db.execute('''
      CREATE TABLE materials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        unit TEXT DEFAULT 'كغ',
        default_price REAL DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // جدول الزبائن
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        balance REAL DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // جدول الموردين
    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        balance REAL DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // جدول العمال/الموظفين
    await db.execute('''
      CREATE TABLE employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        role TEXT DEFAULT 'محاسب',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // جدول اليوميات
    await db.execute('''
      CREATE TABLE dailies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        daily_number INTEGER NOT NULL,
        date TEXT NOT NULL,
        employee_id INTEGER,
        total_cash REAL DEFAULT 0,
        total_debt REAL DEFAULT 0,
        type TEXT DEFAULT 'عامة',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (employee_id) REFERENCES employees (id)
      )
    ''');

    // جدول الفواتير
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number INTEGER NOT NULL,
        date TEXT NOT NULL,
        daily_id INTEGER,
        customer_id INTEGER,
        supplier_id INTEGER,
        employee_id INTEGER,
        type TEXT NOT NULL,
        total_amount REAL DEFAULT 0,
        cash_amount REAL DEFAULT 0,
        debt_amount REAL DEFAULT 0,
        down_payment REAL DEFAULT 0,
        commission_fee REAL DEFAULT 0,
        loading_fee REAL DEFAULT 0,
        car_rent REAL DEFAULT 0,
        other_expenses REAL DEFAULT 0,
        net_amount REAL DEFAULT 0,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (daily_id) REFERENCES dailies (id),
        FOREIGN KEY (customer_id) REFERENCES customers (id),
        FOREIGN KEY (supplier_id) REFERENCES suppliers (id),
        FOREIGN KEY (employee_id) REFERENCES employees (id)
      )
    ''');

    // جدول عناصر الفاتورة
    await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        material_id INTEGER NOT NULL,
        relation TEXT,
        quantity REAL NOT NULL,
        gross_weight REAL DEFAULT 0,
        net_weight REAL DEFAULT 0,
        price REAL NOT NULL,
        total REAL NOT NULL,
        empties REAL DEFAULT 0,
        collateral REAL DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE,
        FOREIGN KEY (material_id) REFERENCES materials (id)
      )
    ''');

    // إدراج بيانات أولية
    await _insertInitialData(db);
  }

  Future<void> _insertInitialData(Database db) async {
    // إضافة موظف افتراضي
    await db.insert('employees', {
      'name': 'المدير العام',
      'role': 'مدير',
    });

    // إضافة بعض المواد الأساسية
    final materials = [
      'طماطم',
      'خيار',
      'بطاطا',
      'بصل',
      'كوسا',
      'باذنجان',
      'فليفلة',
      'فول',
      'فاصولياء',
      'ملفوف'
    ];

    for (var material in materials) {
      await db.insert('materials', {
        'name': material,
        'unit': 'كغ',
        'default_price': 0,
      });
    }
  }

  // عمليات CRUD للمواد
  Future<int> insertMaterial(Map<String, dynamic> material) async {
    final db = await database;
    return await db.insert('materials', material);
  }

  Future<List<Map<String, dynamic>>> getAllMaterials() async {
    final db = await database;
    return await db.query('materials', orderBy: 'name ASC');
  }

  Future<int> updateMaterial(int id, Map<String, dynamic> material) async {
    final db = await database;
    return await db.update(
      'materials',
      material,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteMaterial(int id) async {
    final db = await database;
    return await db.delete(
      'materials',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // عمليات CRUD للزبائن
  Future<int> insertCustomer(Map<String, dynamic> customer) async {
    final db = await database;
    return await db.insert('customers', customer);
  }

  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    final db = await database;
    return await db.query('customers', orderBy: 'name ASC');
  }

  Future<int> updateCustomer(int id, Map<String, dynamic> customer) async {
    final db = await database;
    return await db.update(
      'customers',
      customer,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // عمليات CRUD للموردين
  Future<int> insertSupplier(Map<String, dynamic> supplier) async {
    final db = await database;
    return await db.insert('suppliers', supplier);
  }

  Future<List<Map<String, dynamic>>> getAllSuppliers() async {
    final db = await database;
    return await db.query('suppliers', orderBy: 'name ASC');
  }

  Future<int> updateSupplier(int id, Map<String, dynamic> supplier) async {
    final db = await database;
    return await db.update(
      'suppliers',
      supplier,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteSupplier(int id) async {
    final db = await database;
    return await db.delete(
      'suppliers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // عمليات CRUD للموظفين
  Future<int> insertEmployee(Map<String, dynamic> employee) async {
    final db = await database;
    return await db.insert('employees', employee);
  }

  Future<List<Map<String, dynamic>>> getAllEmployees() async {
    final db = await database;
    return await db.query('employees', orderBy: 'name ASC');
  }

  // عمليات CRUD لليوميات
  Future<int> insertDaily(Map<String, dynamic> daily) async {
    final db = await database;
    return await db.insert('dailies', daily);
  }

  Future<List<Map<String, dynamic>>> getAllDailies() async {
    final db = await database;
    return await db.query('dailies', orderBy: 'date DESC, id DESC');
  }

  Future<Map<String, dynamic>?> getDailyByDateAndNumber(
      String date, int dailyNumber) async {
    final db = await database;
    final results = await db.query(
      'dailies',
      where: 'date = ? AND daily_number = ?',
      whereArgs: [date, dailyNumber],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> getNextDailyNumber(String date) async {
    final db = await database;
    final results = await db.rawQuery(
      'SELECT MAX(daily_number) as max_number FROM dailies WHERE date = ?',
      [date],
    );
    final maxNumber = results.first['max_number'];
    return maxNumber != null ? (maxNumber as int) + 1 : 1;
  }

  // عمليات CRUD للفواتير
  Future<int> insertInvoice(Map<String, dynamic> invoice) async {
    final db = await database;
    return await db.insert('invoices', invoice);
  }

  Future<List<Map<String, dynamic>>> getAllInvoices() async {
    final db = await database;
    return await db.query('invoices', orderBy: 'date DESC, id DESC');
  }

  Future<List<Map<String, dynamic>>> getInvoicesByDaily(int dailyId) async {
    final db = await database;
    return await db.query(
      'invoices',
      where: 'daily_id = ?',
      whereArgs: [dailyId],
      orderBy: 'invoice_number ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getInvoicesByCustomer(
      int customerId) async {
    final db = await database;
    return await db.query(
      'invoices',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getInvoicesBySupplier(
      int supplierId) async {
    final db = await database;
    return await db.query(
      'invoices',
      where: 'supplier_id = ?',
      whereArgs: [supplierId],
      orderBy: 'date DESC',
    );
  }

  Future<int> updateInvoice(int id, Map<String, dynamic> invoice) async {
    final db = await database;
    return await db.update(
      'invoices',
      invoice,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteInvoice(int id) async {
    final db = await database;
    return await db.delete(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getNextInvoiceNumber(String date, String type) async {
    final db = await database;
    final results = await db.rawQuery(
      'SELECT MAX(invoice_number) as max_number FROM invoices WHERE date = ? AND type = ?',
      [date, type],
    );
    final maxNumber = results.first['max_number'];
    return maxNumber != null ? (maxNumber as int) + 1 : 1;
  }

  // عمليات CRUD لعناصر الفاتورة
  Future<int> insertInvoiceItem(Map<String, dynamic> item) async {
    final db = await database;
    return await db.insert('invoice_items', item);
  }

  Future<List<Map<String, dynamic>>> getInvoiceItems(int invoiceId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT ii.*, m.name as material_name, m.unit as material_unit
      FROM invoice_items ii
      LEFT JOIN materials m ON ii.material_id = m.id
      WHERE ii.invoice_id = ?
      ORDER BY ii.id ASC
    ''', [invoiceId]);
  }

  Future<int> updateInvoiceItem(int id, Map<String, dynamic> item) async {
    final db = await database;
    return await db.update(
      'invoice_items',
      item,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteInvoiceItem(int id) async {
    final db = await database;
    return await db.delete(
      'invoice_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllInvoiceItems(int invoiceId) async {
    final db = await database;
    return await db.delete(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
  }

  // إغلاق قاعدة البيانات
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // حذف قاعدة البيانات (للاختبار فقط)
  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'al_hal_market.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
