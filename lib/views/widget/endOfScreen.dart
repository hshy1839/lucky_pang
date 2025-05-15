import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EndOfScreen extends StatelessWidget {
  const EndOfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 172,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(5, (index) {
          double width;
          double height;
          double opacity;
          bool isGray = false;

          switch (index) {
            case 0:
              width = 12;
              height = 12;
              opacity = 0.4;
              isGray = true;
              break;
            case 1:
              width = 24;
              height = 24;
              opacity = 0.8;
              isGray = true;
              break;
            case 2:
              width = 32;
              height = 32;
              opacity = 1.0;
              isGray = false;
              break;
            case 3:
              width = 24;
              height = 24;
              opacity = 0.8;
              isGray = true;
              break;
            case 4:
              width = 12;
              height = 12;
              opacity = 0.4;
              isGray = true;
              break;
            default:
              width = 24;
              height = 24;
              opacity = 1.0;
          }

          return Padding(
            padding: EdgeInsets.only(right: index < 4 ? 17 : 0),
            child: Opacity(
              opacity: opacity,
              child: ColorFiltered(
                colorFilter: isGray
                    ? ColorFilter.mode(Colors.grey, BlendMode.srcIn)
                    : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                child: Image.asset(
                  'assets/images/EndOfScreen.png',
                  width: width,
                  height: height,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
