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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.card_giftcard, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('럭키박스 결제 정보', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('$formattedDate  결제 완료', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('결제취소 7일 남음', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  '${widget.paymentType == 'point' ? '포인트결제' : '카드결제'}\n박스구매 ${totalPrice}원',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _giftCodeExists || _loading ? null : widget.onOpenPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _giftCodeExists || _loading
                      ? Colors.grey
                      : Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                ),
                child: Text(
                  _giftCodeExists ? '선물코드 있음' : '박스열기',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
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
                    _checkGiftCode(); // ✅ 돌아온 직후 상태 다시 확인
                  });
                },
                child: Text(
                  '선물하기',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
      ],
    );
  }
}
