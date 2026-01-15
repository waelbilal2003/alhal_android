import 'package:flutter/material.dart';

/// دالة مساعدة لعرض اقتراحات عمودية خارجية تشغل كامل الشاشة
/// من أعلى الشاشة إلى أسفلها
class VerticalSuggestionsWidget {
  /// بناء نافذة الاقتراحات التي تشغل الشاشة بأكملها
  static Widget _buildFullScreenOverlay(
    BuildContext context,
    List<String> suggestions,
    int rowIndex,
    Function(String, int) onSuggestionSelected,
    Function() onClose,
    Color primaryColor,
  ) {
    final appBarHeight = AppBar().preferredSize.height;

    return Positioned.fill(
      top: appBarHeight, // يبدأ من أسفل الـ AppBar مباشرة
      child: Container(
        color: Colors.white.withOpacity(0.98),
        child: Column(
          children: [
            // زر الإغلاق في الأعلى
            Container(
              height: 40,
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey[700]),
                    onPressed: onClose,
                    tooltip: 'إغلاق الاقتراحات',
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Text(
                      '${suggestions.length} اقتراح',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // قائمة الاقتراحات تشغل باقي الشاشة
            Expanded(
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: index == 0
                          ? primaryColor.withOpacity(0.1)
                          : Colors.transparent,
                      border: Border(
                        bottom:
                            BorderSide(color: Colors.grey[200]!, width: 0.5),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // حفظ الدالة في متغير محلي أولاً
                          final selectedSuggestion = suggestions[index];
                          final selectedRowIndex = rowIndex;
                          final onSelected = onSuggestionSelected;
                          final closeFunc = onClose;

                          // تنفيذ الإجراءات بالتسلسل
                          closeFunc(); // إغلاق النافذة أولاً

                          // تأخير بسيط ثم تنفيذ الاختيار
                          Future.delayed(const Duration(milliseconds: 50), () {
                            onSelected(selectedSuggestion, selectedRowIndex);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16.0,
                            horizontal: 20.0,
                          ),
                          width: double.infinity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // رقم الاقتراح
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: index == 0
                                      ? primaryColor
                                      : primaryColor.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    (index + 1).toString(),
                                    style: TextStyle(
                                      color: index == 0
                                          ? Colors.white
                                          : primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              // النص
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Text(
                                    suggestions[index],
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[800],
                                      fontWeight: index == 0
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    textAlign: TextAlign.right,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              // أيقونة التأكيد للأول
                              if (index == 0)
                                Icon(
                                  Icons.check_circle,
                                  color: primaryColor,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// دالة مساعدة لتحديد ما إذا يجب عرض الاقتراحات أو إخفاؤها
  static Widget? getSuggestionsOverlay({
    required BuildContext context,
    required int? activeRowIndex,
    required int currentRowIndex,
    required List<String> suggestions,
    required String suggestionType,
    required Function(String, int) onSuggestionSelected,
    required Function() onClose,
  }) {
    if (activeRowIndex != currentRowIndex || suggestions.isEmpty) {
      return null;
    }

    // تحديد اللون المناسب حسب النوع
    Color primaryColor;
    switch (suggestionType) {
      case 'material':
        primaryColor = Colors.blue;
        break;
      case 'packaging':
        primaryColor = Colors.green;
        break;
      case 'supplier':
        primaryColor = Colors.orange;
        break;
      case 'customer':
        primaryColor = Colors.purple;
        break;
      default:
        primaryColor = Colors.blue;
    }

    return _buildFullScreenOverlay(
      context,
      suggestions,
      currentRowIndex,
      onSuggestionSelected,
      onClose,
      primaryColor,
    );
  }
}
