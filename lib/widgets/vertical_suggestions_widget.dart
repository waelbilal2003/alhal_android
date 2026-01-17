import 'package:flutter/material.dart';

/// دالة مساعدة لعرض اقتراحات أفقية في شريط AppBar
/// تظهر على يسار العنوان
class HorizontalSuggestionsWidget {
  /// بناء نافذة الاقتراحات الأفقية في AppBar
  static Widget? buildHorizontalSuggestionsInAppBar({
    required BuildContext context,
    required List<String> suggestions,
    required String suggestionType,
    required Function(String) onSuggestionSelected,
    required Function() onClose,
    required Color primaryColor,
  }) {
    if (suggestions.isEmpty) {
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

    return Container(
      margin: const EdgeInsets.only(right: 16), // مسافة بين الاقتراحات والعنوان
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
          border: Border.all(
            color: primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width * 0.4, // أقصى عرض 40% من الشاشة
          maxHeight: 200, // أقصى ارتفاع
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // رأس النافذة - ثابت في الأعلى
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: Colors.grey[700]),
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  Text(
                    '${suggestions.length} اقتراح',
                    style: TextStyle(
                      fontSize: 12,
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // قائمة الاقتراحات
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        color: index == 0
                            ? primaryColor.withOpacity(0.08)
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
                            onClose();
                            Future.delayed(const Duration(milliseconds: 50),
                                () {
                              onSuggestionSelected(suggestions[index]);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 8.0,
                            ),
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // رقم الاقتراح
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: index == 0
                                        ? primaryColor
                                        : primaryColor.withOpacity(0.1),
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
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),

                                // النص (يأخذ المساحة المتبقية)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Text(
                                      suggestions[index],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[800],
                                        fontWeight: index == 0
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                      textAlign: TextAlign.right,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),

                                // أيقونة السهم للأول
                                if (index == 0)
                                  Icon(
                                    Icons.arrow_back_ios_new,
                                    color: primaryColor,
                                    size: 14,
                                    textDirection: TextDirection.ltr,
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
            ),
          ],
        ),
      ),
    );
  }

  /// دالة مساعدة لتحديد ما إذا يجب عرض الاقتراحات في AppBar
  static Widget? getAppBarSuggestions({
    required BuildContext context,
    required List<String> suggestions,
    required String suggestionType,
    required Function(String) onSuggestionSelected,
    required Function() onClose,
  }) {
    if (suggestions.isEmpty) {
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

    return buildHorizontalSuggestionsInAppBar(
      context: context,
      suggestions: suggestions,
      suggestionType: suggestionType,
      onSuggestionSelected: onSuggestionSelected,
      onClose: onClose,
      primaryColor: primaryColor,
    );
  }
}
