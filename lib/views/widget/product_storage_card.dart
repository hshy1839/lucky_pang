import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../controllers/giftcode_controller.dart';

class ProductStorageCard extends StatefulWidget {
  final String imageUrl;
  final String productName;
  final String acquiredAt;
  final int purchasePrice;
  final int consumerPrice;
  final String dDay;
  final bool isLocked;
  final VoidCallback onRefundPressed;
  final VoidCallback onDeliveryPressed;
  final VoidCallback onGiftPressed; // ✅ 외부 콜백으로 전달
  final String orderId;
  final String productId;

  const ProductStorageCard({
    super.key,
    required this.imageUrl,
    required this.productName,
    required this.acquiredAt,
    required this.purchasePrice,
    required this.consumerPrice,
    required this.dDay,
    required this.isLocked,
    required this.onRefundPressed,
    required this.onDeliveryPressed,
    required this.onGiftPressed, // ✅ 콜백 받기
    required this.orderId,
    required this.productId,
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
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.network(widget.imageUrl, width: 60.w, height: 60.w, fit: BoxFit.cover),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.productName, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                    Text(widget.acquiredAt, style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                  ],
                ),
              ),
              Text(widget.dDay, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12.sp)),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('박스 구매가: ${widget.purchasePrice}원', style: TextStyle(fontSize: 12.sp)),
              Text('소비자가: ${widget.consumerPrice}원', style: TextStyle(fontSize: 12.sp)),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              // ✅ 포인트환급 버튼 - 선물코드가 있으면 비활성화
              Expanded(
                child: OutlinedButton(
                  onPressed: _giftCodeExists ? null : widget.onRefundPressed,
                  child: Text(
                    '포인트환급',
                    style: TextStyle(
                      color: _giftCodeExists
                          ? Colors.grey
                          : Theme.of(context).primaryColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),

              // ✅ 선물하기 버튼 - 항상 클릭 가능
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    print('productId: ${widget.productId}');
                    print('orderId: ${widget.orderId}');

                    Navigator.pushNamed(
                      context,
                      '/giftcode/create',
                      arguments: {
                        'type': 'product',
                        'productId': widget.productId,
                        'orderId': widget.orderId,
                      },
                    ).then((_) {
                      _checkGiftCode();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                  child: Text(
                    _giftCodeExists ? '선물코드 확인' : '선물하기',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),

              SizedBox(width: 8.w),

              // ✅ 배송신청 버튼 - 선물코드 있으면 비활성화
              Expanded(
                child: ElevatedButton(
                  onPressed: _giftCodeExists || _loading ? null : widget.onDeliveryPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _giftCodeExists || _loading
                        ? Colors.grey
                        : Theme.of(context).primaryColor,
                  ),
                  child: Text(
                   '배송신청',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }
}
