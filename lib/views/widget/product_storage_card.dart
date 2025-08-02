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
  final String dDay;
  final bool isLocked;
  final VoidCallback onRefundPressed;
  final VoidCallback onDeliveryPressed;
  final VoidCallback onGiftPressed;
  final String orderId;
  final String productId;
  final bool isSelected;
  final ValueChanged<bool?> onSelectChanged;

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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFF0F1F2)),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 체크박스
          Align(
            alignment: Alignment.topLeft,
            child: Checkbox(
              value: widget.isSelected,
              onChanged: widget.onSelectChanged,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),

          /// 이미지 + 텍스트
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15.r),
                child: Image.network(
                  widget.mainImageUrl,
                  width: 100.w,
                  height: 100.h,
                  fit: BoxFit.cover,
                ),
              ),
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
                      style: TextStyle(fontSize: 14.sp, color: Color(0xFF465461)),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Text(
                          '${NumberFormat('#,###').format(widget.purchasePrice)} 원',
                          style: TextStyle(
                            fontSize: 18.sp,
                            color: Color(0xFFFF5722),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          '정가: ${NumberFormat('#,###').format(widget.consumerPrice)}원',
                          style: TextStyle(
                            fontSize: 17.sp,
                            color: Color(0xFF8D969D),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          _calculateDDay(widget.acquiredAt),
                          style: TextStyle(
                            fontSize: 17.sp,
                            color: Color(0xFF465461),
                            fontWeight: FontWeight.bold,
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
                  onPressed: !_giftCodeExists ? widget.onRefundPressed : null,
                  enabled: !_giftCodeExists,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildOutlinedButton(
                  context,
                  text: _giftCodeExists ? '선물코드 확인' : '선물하기',
                  onPressed: widget.onGiftPressed,
                  enabled: true,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildElevatedButton(
                  context,
                  text: '배송신청',
                  onPressed: widget.onDeliveryPressed,
                  enabled: !_giftCodeExists && !_loading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// D-xx 계산
  String _calculateDDay(String acquiredAt) {
    try {
      final dateOnly = acquiredAt.split(' ').first; // '2025-06-11'
      final acquired = DateTime.parse(dateOnly); // 2025-06-11 00:00:00
      final expireDate = acquired.add(Duration(days: 2)).subtract(Duration(seconds: 1)); // 90일 후 23:59:59
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
