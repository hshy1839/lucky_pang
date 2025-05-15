import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Footer extends StatelessWidget {
  final Function(int) onTabTapped;
  final int selectedIndex;

  const Footer({
    super.key,
    required this.onTabTapped,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: false, // 기본적으로 포인터를 받음
      child: Stack(
        children: [
          // ✅ 기본 레이어 (터치 차단용 흰색 박스)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {}, // 이벤트 소비해서 아래로 안 내려감
            child: Container(
              height: 75,
              width: double.infinity,
              color: Colors.transparent,
            ),
          ),

          // ✅ Footer 본체
          SizedBox(
            height: 75,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                BottomAppBar(
                  color: Colors.white,
                  child: SizedBox(
                    height: 68,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildFooterItem(
                            context,
                            imagePath: 'assets/icons/footer_icons/home_icon.svg',
                            label: '홈',
                            index: 0,
                          ),
                        ),
                        Expanded(
                          child: _buildFooterItem(
                            context,
                            imagePath: 'assets/icons/footer_icons/trophy_icon.svg',
                            label: '랭킹',
                            index: 1,
                          ),
                        ),
                        const SizedBox(width: 70), // 중앙 버튼 자리
                        Expanded(
                          child: _buildFooterItem(
                            context,
                            imagePath: 'assets/icons/footer_icons/inbox_icon.svg',
                            label: '보관함',
                            index: 2,
                          ),
                        ),
                        Expanded(
                          child: _buildFooterItem(
                            context,
                            imagePath: 'assets/icons/footer_icons/user-round_icon.svg',
                            label: '내 정보',
                            index: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ✅ 중앙 럭키박스 버튼
                Positioned(
                  top: -10,
                  child: GestureDetector(
                    onTap: () => onTabTapped(4),
                    child: SvgPicture.asset(
                      'assets/icons/footer_icons/boxButton_icon.svg',
                      width: 60,
                      height: 60,
                    ),
                  ),
                ),
              ],
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
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            imagePath.endsWith('.svg')
                ? SvgPicture.asset(
              imagePath,
              width: 20,
              height: 20,
              color: color,
            )
                : Image.asset(
              imagePath,
              width: 25,
              height: 25,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
