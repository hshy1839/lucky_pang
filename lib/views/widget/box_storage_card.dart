import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../controllers/giftcode_controller.dart';

class BoxStorageCard extends StatefulWidget {
  final String boxName;
  final String createdAt;
  final int paymentAmount;
  final int pointUsed;
  final String paymentType;
  final VoidCallback onOpenPressed;
  final VoidCallback onGiftPressed;
  final String boxId;
  final String orderId;

  const BoxStorageCard({
    super.key,
    required this.boxName,
    required this.createdAt,
    required this.paymentAmount,
    required this.pointUsed,
    required this.paymentType,
    required this.onOpenPressed,
    required this.onGiftPressed,
    required this.boxId,
    required this.orderId,
  });

  @override
  State<BoxStorageCard> createState() => _BoxStorageCardState();
}

class _BoxStorageCardState extends State<BoxStorageCard> {
  bool _giftCodeExists = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkGiftCode();
  }

  Future<void> _checkGiftCode() async {
    if (_giftCodeExists) return; // 이미 존재하면 재요청하지 않음

    final exists = await GiftCodeController.checkGiftCodeExists(
      type: 'box',
      boxId: widget.boxId,
      orderId: widget.orderId,
    );

    setState(() {
      _giftCodeExists = exists;
      _loading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(widget.createdAt));
    final totalPrice = widget.paymentAmount + widget.pointUsed;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFF0F1F2)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 박스 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/order_box_image.png',
              width: 320,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 12),

          // 가격 및 결제정보
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${NumberFormat('#,###').format(totalPrice)}원 ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: "럭키박스",
                      style: TextStyle(fontSize: 14, color: Color(0xFF465461)
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFF8D969D)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.paymentType == 'point'
                      ? '포인트 결제'
                      : widget.paymentType == 'card'
                      ? '카드 결제'
                      : '기타 결제',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF465461),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
          Text(
            '구매날짜: $formattedDate',
            style: TextStyle(fontSize: 12, color: Color(0xFF8D969D)
            ),
          ),
          Text(
            '결제취소 7일 남음',
            style: TextStyle(fontSize: 12, color: Color(0xFF2EB520)
            ),
          ),
          ],
          ),
          SizedBox(height: 12),

          // 버튼들
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 45,
                    child: ElevatedButton(
                      onPressed: (_giftCodeExists || _loading) ? null : widget.onOpenPressed, // ✅ 비활성화 로직
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                          if (states.contains(MaterialState.disabled)) {
                            return Theme.of(context).primaryColor.withOpacity(0.3); // ✅ 흐릿한 색
                          }
                          return Theme.of(context).primaryColor; // ✅ 일반 색
                        }),
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // ✅ 동일한 radius
                          ),
                        ),
                      ),
                      child: const Text(
                        '박스열기',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 45, // ✅ 높이 52로 고정
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/giftcode/create',
                          arguments: {
                            'type': 'box',
                            'boxId': widget.boxId,
                            'orderId': widget.orderId,
                          },
                        ).then((_) {
                          _checkGiftCode();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        _giftCodeExists ? '선물코드 확인' : '선물하기',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
