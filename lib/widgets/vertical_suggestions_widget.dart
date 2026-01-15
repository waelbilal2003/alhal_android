import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VerticalSuggestionsWidget extends StatefulWidget {
  final List<String> suggestions;
  final Function(String) onSuggestionSelected;
  final Color primaryColor;
  final Color backgroundColor;
  final double maxHeight;
  final int maxSuggestionsToShow;
  final BuildContext? parentContext; // <-- إضافة هذا

  const VerticalSuggestionsWidget({
    Key? key,
    required this.suggestions,
    required this.onSuggestionSelected,
    this.primaryColor = Colors.blue,
    this.backgroundColor = Colors.white,
    this.maxHeight = 200.0,
    this.maxSuggestionsToShow = 10,
    this.parentContext, // <-- إضافة هذا
  }) : super(key: key);

  @override
  _VerticalSuggestionsWidgetState createState() =>
      _VerticalSuggestionsWidgetState();
}

class _VerticalSuggestionsWidgetState extends State<VerticalSuggestionsWidget> {
  final ScrollController _scrollController = ScrollController();
  int _selectedIndex = 0;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
    // طلب التركيز عند الإنشاء
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(VerticalSuggestionsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // فقط إذا تغيرت الاقتراحات فعلاً
    if (!_areListsEqual(widget.suggestions, oldWidget.suggestions)) {
      _selectedIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _scrollController.hasClients &&
            widget.suggestions.isNotEmpty) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event.runtimeType.toString().contains('RawKeyDownEvent')) {
      // السهم للأسفل
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % widget.suggestions.length;
        });
        _scrollToSelected();
      }
      // السهم للأعلى
      else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1) % widget.suggestions.length;
          if (_selectedIndex < 0)
            _selectedIndex = widget.suggestions.length - 1;
        });
        _scrollToSelected();
      }
      // Enter
      else if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        if (_selectedIndex < widget.suggestions.length) {
          widget.onSuggestionSelected(widget.suggestions[_selectedIndex]);
        }
      }
      // Tab
      else if (event.logicalKey == LogicalKeyboardKey.tab) {
        // تجاهل Tab لنسمح بالانتقال الطبيعي بين الحقول
      }
    }
  }

  void _scrollToSelected() {
    if (_scrollController.hasClients && widget.suggestions.isNotEmpty) {
      final itemHeight = 40.0;
      final selectedOffset = _selectedIndex * itemHeight;
      final viewportHeight = widget.maxHeight;

      if (selectedOffset < _scrollController.offset) {
        // التمرير للأعلى
        _scrollController.animateTo(
          selectedOffset,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      } else if (selectedOffset + itemHeight >
          _scrollController.offset + viewportHeight) {
        // التمرير للأسفل
        _scrollController.animateTo(
          selectedOffset + itemHeight - viewportHeight,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.suggestions.isEmpty) {
      return Container();
    }

    final List<String> suggestionsToShow =
        widget.suggestions.length > widget.maxSuggestionsToShow
            ? widget.suggestions.sublist(0, widget.maxSuggestionsToShow)
            : widget.suggestions;

    // حساب المسافة من أسفل الشاشة لتعديل الموضع
    double bottomPadding = 0;
    if (widget.parentContext != null) {
      final mediaQuery = MediaQuery.of(widget.parentContext!);
      final keyboardHeight = mediaQuery.viewInsets.bottom;
      if (keyboardHeight > 0) {
        // إذا ظهر الكيبورد، نضيف مسافة إضافية
        bottomPadding = keyboardHeight + 10;
      }
    }

    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: widget.maxHeight,
          minWidth: 250,
        ),
        margin: EdgeInsets.only(bottom: bottomPadding), // <-- تعديل الهامش
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // رأس القائمة
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.primaryColor.withOpacity(0.1),
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: 16,
                    color: widget.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.suggestions.length} اقتراح',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.keyboard_arrow_up,
                            size: 12, color: widget.primaryColor),
                        Icon(Icons.keyboard_arrow_down,
                            size: 12, color: widget.primaryColor),
                        const SizedBox(width: 2),
                        Text(
                          'للتنقل',
                          style: TextStyle(
                            fontSize: 10,
                            color: widget.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // قائمة الاقتراحات
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.zero,
                  itemCount: suggestionsToShow.length,
                  itemBuilder: (context, index) {
                    final suggestion = suggestionsToShow[index];
                    final isSelected = index == _selectedIndex;

                    return Material(
                      color: isSelected
                          ? widget.primaryColor.withOpacity(0.15)
                          : Colors.transparent,
                      child: InkWell(
                        onTap: () => widget.onSuggestionSelected(suggestion),
                        onHover: (hovering) {
                          if (hovering && mounted) {
                            setState(() {
                              _selectedIndex = index;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: index < suggestionsToShow.length - 1
                                  ? BorderSide(
                                      color: Colors.grey[200]!, width: 0.5)
                                  : BorderSide.none,
                            ),
                          ),
                          child: Row(
                            children: [
                              // رقم العنصر
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? widget.primaryColor
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    (index + 1).toString(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // نص الاقتراح
                              Expanded(
                                child: Text(
                                  suggestion,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? widget.primaryColor
                                        : Colors.grey[800],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // مؤشر التحديد
                              if (isSelected)
                                Icon(
                                  Icons.keyboard_arrow_left,
                                  size: 18,
                                  color: widget.primaryColor,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // تذييل القائمة
            if (widget.suggestions.length > widget.maxSuggestionsToShow)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'عرض ${widget.maxSuggestionsToShow} من ${widget.suggestions.length}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
