import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  final Function(int) onTabTapped;
  final int selectedIndex;

  Footer({required this.onTabTapped, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96, // Footer 전체 높이
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // 하단 바
          BottomAppBar(
            color: Colors.white,
            child: SizedBox(
              height: 68,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFooterItem(
                    context,
                    imagePath: 'assets/icons/footer_icons/home_icon.png',
                    label: '홈',
                    index: 0,
                  ),
                  _buildFooterItem(
                    context,
                    imagePath: 'assets/icons/footer_icons/trophy_icon.png',
                    label: '랭킹',
                    index: 1,
                  ),
                  SizedBox(width: 70), // 중앙 럭키박스 자리 확보
                  _buildFooterItem(
                    context,
                    imagePath: 'assets/icons/footer_icons/inbox_icon.png',
                    label: '보관함',
                    index: 2,
                  ),
                  _buildFooterItem(
                    context,
                    imagePath: 'assets/icons/footer_icons/user-round_icon.png',
                    label: '내 정보',
                    index: 3,
                  ),
                ],
              ),
            ),
          ),

          // 중앙 럭키박스 (위로 띄우기)
          Positioned(
            top: 5, // 96 - 68 = 28 → 위로 튀어나오도록
            child: GestureDetector(
              onTap: () => onTabTapped(4),
              child: Image.asset(
                'assets/icons/footer_icons/boxButton_icon.png',
                width: 70,
                height: 70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterItem(
      BuildContext context, {
        required String imagePath,
        required String label,
        required int index,
      }) {
    final isSelected = selectedIndex == index;
    final color = isSelected ? Theme.of(context).primaryColor : const Color(0xFF465461);

    return GestureDetector(
      onTap: () => onTabTapped(index),
      child: SizedBox(
        width: 72, // 디자이너 기준 138/2 or 65~72 사이에서 균형
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: 25,
              height: 25,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
