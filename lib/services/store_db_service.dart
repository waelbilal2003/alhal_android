import 'package:shared_preferences/shared_preferences.dart';

class StoreDbService {
  static final StoreDbService _instance = StoreDbService._internal();
  factory StoreDbService() => _instance;
  StoreDbService._internal();

  static const String _storeNameKey = 'store_name';
  static const String _defaultStoreName = 'المحل الافتراضي';

  Future<void> initializeDatabase() async {
    // لا حاجة للتهيئة في shared_preferences
    await SharedPreferences.getInstance();
  }

  // حفظ اسم المحل
  Future<void> saveStoreName(String storeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storeNameKey, storeName);
  }

  // استرجاع اسم المحل
  Future<String?> getStoreName() async {
    final prefs = await SharedPreferences.getInstance();
    final storeName = prefs.getString(_storeNameKey);

    // إذا لم يكن هناك اسم محفوظ، نقوم بحفظ الاسم الافتراضي وإرجاعه
    if (storeName == null) {
      await saveStoreName(_defaultStoreName);
      return _defaultStoreName;
    }

    return storeName;
  }

  // تحديث اسم المحل
  Future<void> updateStoreName(String newStoreName) async {
    await saveStoreName(newStoreName);
  }

  // حذف اسم المحل
  Future<void> deleteStoreName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storeNameKey);
  }

  // التحقق مما إذا كان اسم المحل موجوداً
  Future<bool> hasStoreName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_storeNameKey);
  }
}
