// lib/widgets/enhanced_suggestions.dart
import 'package:flutter/material.dart';
import 'vertical_suggestions_widget.dart';

class EnhancedSuggestions {
  static OverlayEntry? _overlayEntry;
  static bool _isVisible = false;
  static String _currentQuery = '';
  static int? _currentRowIndex;
  static List<String> _currentSuggestions = [];
  static bool _isProcessing = false;
  static DateTime? _lastShowTime;
  static const Duration _debounceDuration = Duration(milliseconds: 150);
  static String?
      _currentFieldType; // 'material', 'packaging', 'supplier', 'customer'

  // دالة مساعدة لمقارنة القوائم
  static bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  // إخفاء الاقتراحات
  static void hide({bool force = false}) {
    // لا نخفي إذا لم نكن في وضع الإخفاء القسري
    if (!force && _isVisible) {
      // فقط نخفي إذا مرت فترة كافية منذ آخر ظهور
      if (_lastShowTime != null &&
          DateTime.now().difference(_lastShowTime!) <
              Duration(milliseconds: 500)) {
        return;
      }
    }

    if (_overlayEntry != null) {
      try {
        _overlayEntry?.remove();
      } catch (e) {
        // تجاهل الخطأ - قد يكون الـ Overlay غير موجود
      }
      _overlayEntry = null;
      _isVisible = false;
      _currentQuery = '';
      _currentRowIndex = null;
      _currentSuggestions = [];
      _currentFieldType = null;
      _isProcessing = false;
    }
  }

  // إخفاء قسري (للتوافق مع الكود القديم)
  static void forceHide() {
    hide(force: true);
  }

  // إظهار الاقتراحات العمودية
  static void showVerticalSuggestions({
    required BuildContext context,
    required List<String> suggestions,
    required Function(String) onSuggestionSelected,
    required Offset position,
    required String query,
    required int rowIndex,
    String? fieldType,
    double maxWidth = 300,
    double maxHeight = 300,
    Color primaryColor = Colors.blue,
    int maxSuggestionsToShow = 15,
  }) {
    // إذا كنا في منتصف معالجة، انتظر
    if (_isProcessing) return;

    // تسجيل وقت العرض
    _lastShowTime = DateTime.now();
    _isProcessing = true;

    // لا تظهر اقتراحات فارغة
    if (query.isEmpty || suggestions.isEmpty) {
      _isProcessing = false;
      hide(force: true);
      return;
    }

    // التحقق إذا كان نفس الحقل ونفس الاستعلام ونفس الاقتراحات
    bool isSameField = _currentRowIndex == rowIndex &&
        _currentFieldType == fieldType &&
        _currentQuery == query;

    bool hasSameSuggestions = _areListsEqual(_currentSuggestions, suggestions);

    // إذا كان نفس الشيء وكان ظاهراً بالفعل، لا تفعل شيئاً
    if (_isVisible && isSameField && hasSameSuggestions) {
      _isProcessing = false;
      return;
    }

    // إذا تغير الحقل، إخفاء القديم
    if (_isVisible &&
        (_currentRowIndex != rowIndex || _currentFieldType != fieldType)) {
      hide(force: true);
    }

    // تحديث البيانات الحالية
    _currentQuery = query;
    _currentRowIndex = rowIndex;
    _currentSuggestions = List.from(suggestions);
    _currentFieldType = fieldType;

    final OverlayState? overlayState = Overlay.of(context, rootOverlay: true);

    if (overlayState == null) {
      _isProcessing = false;
      return;
    }

    // إزالة Overlay القديم إذا كان موجوداً
    if (_overlayEntry != null) {
      try {
        _overlayEntry?.remove();
      } catch (e) {
        // تجاهل الخطأ
      }
      _overlayEntry = null;
    }

    // إنشاء Overlay جديد
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: position.dx,
          top: position.dy + 2,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: maxHeight,
              ),
              child: VerticalSuggestionsWidget(
                suggestions: suggestions,
                onSuggestionSelected: (suggestion) {
                  _isProcessing = false;
                  hide(force: true);
                  onSuggestionSelected(suggestion);
                },
                primaryColor: primaryColor,
                maxHeight: maxHeight - 50,
                maxSuggestionsToShow: maxSuggestionsToShow,
              ),
            ),
          ),
        );
      },
    );

    try {
      // التأخير قليلاً لضمان استقرار الواجهة
      Future.delayed(const Duration(milliseconds: 10), () {
        if (_overlayEntry != null && overlayState.mounted) {
          overlayState.insert(_overlayEntry!);
          _isVisible = true;
        }
        _isProcessing = false;
      });
    } catch (e) {
      _overlayEntry = null;
      _isVisible = false;
      _isProcessing = false;
    }
  }

  // الحصول على حالة الظهور
  static bool get isVisible => _isVisible;

  // الحصول على الاستعلام الحالي
  static String get currentQuery => _currentQuery;

  // الحصول على صف الحقل الحالي
  static int? get currentRowIndex => _currentRowIndex;

  // الحصول على نوع الحقل الحالي
  static String? get currentFieldType => _currentFieldType;

  // تحديث الاستعلام الحالي
  static void updateCurrentQuery(String query, int rowIndex,
      {String? fieldType}) {
    _currentQuery = query;
    _currentRowIndex = rowIndex;
    if (fieldType != null) {
      _currentFieldType = fieldType;
    }
  }

  // تنظيف جميع البيانات
  static void clear() {
    hide(force: true);
    _currentQuery = '';
    _currentRowIndex = null;
    _currentSuggestions = [];
    _currentFieldType = null;
    _isProcessing = false;
    _lastShowTime = null;
  }
}
