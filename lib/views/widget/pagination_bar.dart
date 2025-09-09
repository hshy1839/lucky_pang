import 'package:flutter/material.dart';

class PaginationBar extends StatelessWidget {
  final int currentPage; // 1-based
  final int totalItems;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  /// 1페이지만 있어도 보일지
  final bool showWhenSinglePage;

  /// totalItems==0이어도 1페이지로 보일지
  final bool showWhenEmpty;

  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.totalItems,
    required this.pageSize,
    required this.onPageChanged,
    this.showWhenSinglePage = true,
    this.showWhenEmpty = false,
  });

  int get totalPages {
    if (totalItems <= 0) return showWhenEmpty ? 1 : 0;
    return ((totalItems + pageSize - 1) ~/ pageSize);
  }

  @override
  Widget build(BuildContext context) {
    final tp = totalPages;
    if (tp == 0) return const SizedBox.shrink();
    if (tp == 1 && !showWhenSinglePage) return const SizedBox.shrink();

    // 현재 페이지를 기준으로 최대 5칸짜리 윈도우 구성
    // 예) 1~5, 2~6, 3~7 ... (끝으로 갈수록 오른쪽으로 붙음)
    final maxWindow = 5;
    final maxStart = (tp - maxWindow + 1).clamp(1, tp); // 윈도우 시작의 최댓값
    final int start = (() {
      // 보통 currentPage-2로 시작해 가운데에 두되, 1~maxStart 범위로 클램프
      final s = currentPage - 2;
      if (s < 1) return 1;
      if (s > maxStart) return maxStart;
      return s;
    })();
    final int end = (start + maxWindow - 1).clamp(1, tp);

    final pages = <int>[];
    for (int p = start; p <= end; p++) {
      pages.add(p);
    }

    Widget numBtn(int p) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: OutlinedButton(
        onPressed: p == currentPage ? null : () => onPageChanged(p),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(40, 36),
          side: BorderSide(
            color: p == currentPage
                ? Theme.of(context).primaryColor
                : const Color(0xFFE5E7EB),
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          '$p',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: p == currentPage
                ? Theme.of(context).primaryColor
                : const Color(0xFF6B7280),
          ),
        ),
      ),
    );

    Widget iconBtn({
      required IconData icon,
      required bool enabled,
      required VoidCallback onTap,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: IconButton(
          onPressed: enabled ? onTap : null,
          icon: Icon(icon, size: 20),
          color:
          enabled ? Theme.of(context).primaryColor : const Color(0xFF9CA3AF),
          splashRadius: 18,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
        ),
      );
    }

    final canPrev = currentPage > 1;
    final canNext = currentPage < tp;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        iconBtn(
          icon: Icons.chevron_left,
          enabled: canPrev,
          onTap: () => onPageChanged(currentPage - 1),
        ),
        ...pages.map(numBtn),
        iconBtn(
          icon: Icons.chevron_right,
          enabled: canNext,
          onTap: () => onPageChanged(currentPage + 1),
        ),
      ],
    );
  }
}
