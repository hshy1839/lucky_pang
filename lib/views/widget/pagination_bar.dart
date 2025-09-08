import 'package:flutter/material.dart';

class PaginationBar extends StatelessWidget {
  final int currentPage; // 1-based
  final int totalItems;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final int maxButtons; // 노출 버튼 수 (가운데 정렬, 양끝 ... 처리)

  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.totalItems,
    required this.pageSize,
    required this.onPageChanged,
    this.maxButtons = 7,
  });

  int get totalPages =>
      (totalItems <= 0) ? 1 : ((totalItems + pageSize - 1) ~/ pageSize);

  List<int> _visiblePages() {
    final tp = totalPages;
    if (tp <= maxButtons) {
      return List.generate(tp, (i) => i + 1);
    }

    final half = maxButtons ~/ 2; // 7 -> 3
    int start = currentPage - half;
    int end = currentPage + half;

    if (start < 1) {
      end += (1 - start);
      start = 1;
    }
    if (end > tp) {
      start -= (end - tp);
      end = tp;
    }
    if (start < 1) start = 1;

    return List.generate(end - start + 1, (i) => start + i);
  }

  @override
  Widget build(BuildContext context) {
    final tp = totalPages;
    if (tp <= 1) return const SizedBox.shrink();

    final pages = _visiblePages();
    final showLeftEllipsis = pages.first > 1;
    final showRightEllipsis = pages.last < tp;

    Widget numBtn(int p) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: OutlinedButton(
        onPressed: p == currentPage ? null : () => onPageChanged(p),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          side: BorderSide(
            color: p == currentPage
                ? Theme.of(context).primaryColor
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          '$p',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: p == currentPage
                ? Theme.of(context).primaryColor
                : const Color(0xFF6B7280),
          ),
        ),
      ),
    );

    Widget dot() => const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Text('...', style: TextStyle(color: Color(0xFF9CA3AF))),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (showLeftEllipsis) numBtn(1),
          if (showLeftEllipsis) dot(),

          ...pages.map(numBtn),

          if (showRightEllipsis) dot(),
          if (showRightEllipsis) numBtn(totalPages),
        ],
      ),
    );
  }
}
