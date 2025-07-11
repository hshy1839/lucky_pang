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
  final int boxPrice;
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
    required this.boxPrice,
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
          // 이미지 + 가격/결제정보
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/order_box_image.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ⬇️ 첫줄 (금액, 럭키박스, 결제유형)
                    Row(
                      children: [
                        Text(
                          '${NumberFormat('#,###').format(widget.boxPrice)}원',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          "럭키박스",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF465461),
                          ),
                        ),
                        SizedBox(width: 14),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                              fontSize: 10,
                              color: Color(0xFF465461),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    // ⬇️ 두번째줄 (구매날짜, 결제취소)
                    Row(
                      children: [
                        Text(
                          '구매날짜: $formattedDate',
                          style: TextStyle(fontSize: 10, color: Color(0xFF8D969D)),
                        ),
                        SizedBox(width: 4,),
                        Text(
                          '결제취소 7일 남음',
                          style: TextStyle(fontSize: 10, color: Color(0xFF2EB520)),
                        ),
                      ],
                    ),
                  ],
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
                    onPressed: (_giftCodeExists || _loading) ? null : widget.onOpenPressed,
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
                  height: 45,
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
                        borderRadius: BorderRadius.circular(20),
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
