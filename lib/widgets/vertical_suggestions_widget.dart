import 'package:flutter/material.dart';

/// دالة مساعدة لعرض اقتراحات عمودية تمتد على كامل ارتفاع الشاشة
/// من أعلى الشاشة إلى أسفلها مع تثبيت العرض عند عرض الحقل الحالي
class VerticalSuggestionsWidget {
  /// بناء نافذة الاقتراحات التي تشغل كامل ارتفاع الشاشة
  static Widget _buildFullHeightOverlay(
    BuildContext context,
    List<String> suggestions,
    int rowIndex,
    Function(String, int) onSuggestionSelected,
    Function() onClose,
    Color primaryColor,
    double fieldWidth,
    double fieldLeft,
  ) {
    final appBarHeight = AppBar().preferredSize.height;
    final screenHeight = MediaQuery.of(context).size.height;

    // العرض يثبت عند عرض الحقل الحالي
    // الارتفاع يمتد من أسفل الـ AppBar إلى أسفل الشاشة
    return Positioned(
      top: appBarHeight, // يبدأ من أسفل الـ AppBar مباشرة
      left: fieldLeft, // نفس موقع الحقل أفقيًا
      width: fieldWidth, // نفس عرض الحقل
      height: screenHeight - appBarHeight, // كامل ارتفاع الشاشة المتبقي
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 3,
            ),
          ],
          border: Border.all(
            color: primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // رأس النافذة - ثابت في الأعلى
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
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
                    icon: Icon(Icons.close, size: 20, color: Colors.grey[700]),
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                  Text(
                    '${suggestions.length} اقتراح',
                    style: TextStyle(
                      fontSize: 13,
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // قائمة الاقتراحات - تمتد لملء باقي المساحة
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
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
                            final selectedSuggestion = suggestions[index];
                            final selectedRowIndex = rowIndex;
                            final onSelected = onSuggestionSelected;
                            final closeFunc = onClose;

                            closeFunc();
                            Future.delayed(const Duration(milliseconds: 50),
                                () {
                              onSelected(selectedSuggestion, selectedRowIndex);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 10.0,
                            ),
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // رقم الاقتراح
                                Container(
                                  width: 28,
                                  height: 28,
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
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),

                                // النص (يأخذ المساحة المتبقية)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0),
                                    child: Text(
                                      suggestions[index],
                                      style: TextStyle(
                                        fontSize: 14,
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

                                // أيقونة السهم للأول
                                if (index == 0)
                                  Icon(
                                    Icons.arrow_back_ios_new,
                                    color: primaryColor,
                                    size: 16,
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

  /// دالة مساعدة لتحديد ما إذا يجب عرض الاقتراحات أو إخفاؤها
  static Widget? getSuggestionsOverlay({
    required BuildContext context,
    required int? activeRowIndex,
    required int currentRowIndex,
    required List<String> suggestions,
    required String suggestionType,
    required Function(String, int) onSuggestionSelected,
    required Function() onClose,
    double? fieldWidth,
    double? fieldLeft,
  }) {
    if (activeRowIndex != currentRowIndex ||
        suggestions.isEmpty ||
        fieldWidth == null ||
        fieldLeft == null) {
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

    return _buildFullHeightOverlay(
      context,
      suggestions,
      currentRowIndex,
      onSuggestionSelected,
      onClose,
      primaryColor,
      fieldWidth,
      fieldLeft,
    );
  }
}
