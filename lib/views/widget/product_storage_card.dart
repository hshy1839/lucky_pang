import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../controllers/giftcode_controller.dart';

class ProductStorageCard extends StatefulWidget {
  final String mainImageUrl;
  final String productName;
  final String acquiredAt;
  final String brand;
  final int purchasePrice;
  final int consumerPrice;
  final String dDay; // (미사용: 내부 계산 사용)
  final bool isLocked;
  final VoidCallback onRefundPressed;
  final VoidCallback onDeliveryPressed;
  final VoidCallback onGiftPressed;
  final String orderId;
  final String productId;
  final bool isSelected;
  final ValueChanged<bool?> onSelectChanged;
  final bool isManuallyLocked;
  final ValueChanged<bool> onManualLockChanged;

  const ProductStorageCard({
    super.key,
    required this.mainImageUrl,
    required this.productName,
    required this.brand,
    required this.acquiredAt,
    required this.purchasePrice,
    required this.consumerPrice,
    required this.dDay,
    required this.isLocked,
    required this.onRefundPressed,
    required this.onDeliveryPressed,
    required this.onGiftPressed,
    required this.orderId,
    required this.productId,
    required this.isSelected,
    required this.onSelectChanged,
    required this.isManuallyLocked,
    required this.onManualLockChanged,
  });

  @override
  State<ProductStorageCard> createState() => _ProductStorageCardState();
}

class _ProductStorageCardState extends State<ProductStorageCard> {
  bool _giftCodeExists = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkGiftCode();
  }

  Future<void> _checkGiftCode() async {
    final exists = await GiftCodeController.checkGiftCodeExists(
      type: 'product',
      orderId: widget.orderId,
      productId: widget.productId,
    );

    setState(() {
      _giftCodeExists = exists;
      _loading = false;
    });
  }

  /// 숫자 → "3,000원 박스" 같은 형태로
  String _formatPriceBox(int price) {
    return '${NumberFormat('#,###').format(price)}원 박스';
  }

  /// ✅ MainScreen과 동일한 로직: URL 유효성 체크 → Image.network / placeholder
  Widget _buildMainImage() {
    final url = widget.mainImageUrl.trim();
    final hasUrl = url.isNotEmpty;

    Widget placeholder = Container(
      width: 100.w,
      height: 100.h,
      color: const Color(0xFFF5F6F6),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported,
        size: 36,
        color: Colors.grey[500],
      ),
    );

    if (!hasUrl) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15.r),
        child: placeholder,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(15.r),
      child: Image.network(
        url,
        width: 100.w,
        height: 100.h,
        fit: BoxFit.cover,           // ✅ MainScreen과 동일: cover
        alignment: Alignment.center, // ✅ 중앙 기준 크롭
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.isManuallyLocked;
    final isFullyLocked = isLocked || _giftCodeExists;

    final ddayText = _calculateDDay(widget.acquiredAt); // 폰트/스타일은 기존 유지(17.sp)

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFF0F1F2)),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 체크박스 + (자물쇠 + D-Day)
          Row(
            children: [
              Checkbox(
                value: widget.isSelected,
                onChanged: isFullyLocked ? null : widget.onSelectChanged,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.black;
                  }
                  return Colors.white;
                }),
                checkColor: Colors.white,
              ),
              const Spacer(),
              // 자물쇠 + 보관기한(D-Day) 세로 배치
              GestureDetector(
                onTap: () async {
                  if (!widget.isManuallyLocked) {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('잠금 확인'),
                          content: const Text('해당 상품을 잠금 하시겠습니까?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('아니오', style: TextStyle(color: Theme.of(context).primaryColor)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text('예', style: TextStyle(color: Theme.of(context).primaryColor)),
                            ),
                          ],
                        );
                      },
                    );
                    if (confirm == true) {
                      setState(() {
                        widget.onManualLockChanged(true);
                        widget.onSelectChanged(false);
                      });
                    }
                  } else {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('잠금 해제 확인'),
                          content: const Text('해당 상품의 잠금을 해제하시겠습니까?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('아니오', style: TextStyle(color: Theme.of(context).primaryColor)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text('예', style: TextStyle(color: Theme.of(context).primaryColor)),
                            ),
                          ],
                        );
                      },
                    );
                    if (confirm == true) {
                      setState(() {
                        widget.onManualLockChanged(false);
                      });
                    }
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(
                      widget.isManuallyLocked ? Icons.lock : Icons.lock_open,
                      color: widget.isManuallyLocked ? Colors.green : Colors.blue,
                      size: 20.w,
                    ),
                    SizedBox(height: 6.h),
                    // ✅ 보관기한을 자물쇠 밑으로 이동 (폰트크기 기존 17.sp)
                    Text(
                      ddayText,
                      style: TextStyle(
                        fontSize: 17.sp,
                        color: const Color(0xFF465461),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          /// 이미지 + 텍스트
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildMainImage(),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 15.h),
                    Text(
                      widget.brand,
                      style: TextStyle(fontSize: 12.sp, color: Colors.black),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      widget.productName,
                      style: TextStyle(fontSize: 14.sp, color: const Color(0xFF465461)),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),

                    /// 가격 라인
                    Row(
                      children: [
                        // ✅ 구매가: "5,000원 박스" 형식
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Text(
                              _formatPriceBox(widget.purchasePrice),
                              style: TextStyle(
                                fontSize: 18.sp,
                                color: const Color(0xFFFF5722),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0, // ✅ 밑줄을 더 아래로 내림
                              child: Container(
                                height: 1.5,
                                color: const Color(0xFFFF5722),
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),
                        // ✅ 정가를 오른쪽 끝으로 보내고 취소선 제거
                        Text(
                          '정가: ${NumberFormat('#,###').format(widget.consumerPrice)}원',
                          style: TextStyle(
                            fontSize: 17.sp,
                            color: const Color(0xFF8D969D),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 25.h),

          /// 버튼들
          Row(
            children: [
              Expanded(
                child: _buildOutlinedButton(
                  context,
                  text: '환급하기',
                  onPressed: (!isLocked && !_giftCodeExists)
                      ? widget.onRefundPressed
                      : null,
                  enabled: (!isLocked && !_giftCodeExists),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildOutlinedButton(
                  context,
                  text: _giftCodeExists ? '선물코드 확인' : '선물하기',
                  onPressed: isLocked ? null : widget.onGiftPressed,
                  enabled: !isLocked,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildElevatedButton(
                  context,
                  text: '배송신청',
                  onPressed: (!isLocked && !_giftCodeExists && !_loading)
                      ? widget.onDeliveryPressed
                      : () {},
                  enabled: (!isLocked && !_giftCodeExists && !_loading),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _calculateDDay(String acquiredAt) {
    try {
      final dateOnly = acquiredAt.split(' ').first;
      final acquired = DateTime.parse(dateOnly);
      final expireDate = acquired.add(const Duration(days: 90)).subtract(const Duration(seconds: 1));
      final today = DateTime.now();
      final diff = expireDate.difference(today).inDays;
      if (diff < 0) return '만료됨';
      return 'D-$diff';
    } catch (e) {
      return '';
    }
  }

  Widget _buildOutlinedButton(
      BuildContext context, {
        required String text,
        VoidCallback? onPressed,
        required bool enabled,
      }) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(
            color: enabled
                ? Theme.of(context).primaryColor
                : Theme.of(context).primaryColor.withOpacity(0.3),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: enabled
                ? Theme.of(context).primaryColor
                : Theme.of(context).primaryColor.withOpacity(0.3),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildElevatedButton(
      BuildContext context, {
        required String text,
        required VoidCallback onPressed,
        required bool enabled,
      }) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.disabled)) {
              return Theme.of(context).primaryColor.withOpacity(0.3);
            }
            return Theme.of(context).primaryColor;
          }),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.zero),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
