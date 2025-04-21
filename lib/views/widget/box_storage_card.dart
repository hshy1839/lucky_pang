import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BoxStorageCard extends StatelessWidget {
  final String boxName;
  final String createdAt;
  final int paymentAmount;
  final int pointUsed; // ✅ 추가됨
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
    required this.pointUsed, // ✅ 추가됨
    required this.paymentType,
    required this.onOpenPressed,
    required this.onGiftPressed,
    required this.boxId,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(createdAt));
    final totalPrice = paymentAmount + pointUsed; // ✅ 총 구매 금액 계산

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
                  '${paymentType == 'point' ? '포인트결제' : '카드결제'}\n박스구매 ${totalPrice.toString()}원',
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
                onPressed: onOpenPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                ),
                child: const Text('박스열기',
                style: TextStyle(
                  color: Colors.white,
                ),),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/giftcode/create',
                    arguments: {'type': 'box', 'boxId': boxId, 'orderId': orderId},
                  );
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
