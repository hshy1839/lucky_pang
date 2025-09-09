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

    // 페이지 목록 구성: 현재 페이지는 항상 노출
    final List<Object> tokens = []; // int(페이지) 또는 String('...')

    void addPage(int p) => tokens.add(p);
    void addDots() {
      if (tokens.isEmpty || tokens.last == '...') return;
      tokens.add('...');
    }

    if (tp <= 7) {
      // 페이지 수가 적으면 전부 표시
      for (int i = 1; i <= tp; i++) addPage(i);
    } else {
      // 항상 첫 페이지
      addPage(1);

      if (currentPage <= 3) {
        // 앞쪽에 있을 때: 1 2 3 4 … tp
        addPage(2);
        addPage(3);
        addPage(4);
        addDots();
        addPage(tp);
      } else if (currentPage >= tp - 2) {
        // 뒤쪽에 있을 때: 1 … tp-3 tp-2 tp-1 tp
        addDots();
        addPage(tp - 3);
        addPage(tp - 2);
        addPage(tp - 1);
        addPage(tp);
      } else {
        // 중간: 1 … cp-1 cp cp+1 … tp
        addDots();
        addPage(currentPage - 1);
        addPage(currentPage);
        addPage(currentPage + 1);
        addDots();
        addPage(tp);
      }
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

    Widget dot() => const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Text('…', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
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
          color: enabled ? Theme.of(context).primaryColor : const Color(0xFF9CA3AF),
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

        ...tokens.map((t) {
          if (t is String) return dot();
          return numBtn(t as int);
        }).toList(),

        iconBtn(
          icon: Icons.chevron_right,
          enabled: canNext,
          onTap: () => onPageChanged(currentPage + 1),
        ),
      ],
    );
  }
}
