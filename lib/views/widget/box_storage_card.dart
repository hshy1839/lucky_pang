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
  final bool isSelected;
  final ValueChanged<bool?> onSelectChanged;
  final bool isDisabled;

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
    required this.isSelected,
    required this.onSelectChanged,
    required this.isDisabled,
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
    final formattedDate =
    DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(widget.createdAt));
    final purchaseDate = DateTime.parse(widget.createdAt);
    final cancelDeadline = purchaseDate.add(const Duration(days: 7));
    final remainingDays = cancelDeadline.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFF0F1F2)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isDisabled)
            Align(
              alignment: Alignment.topLeft,
              child: AbsorbPointer(
                absorbing: _giftCodeExists,
                child: Checkbox(
                  value: widget.isSelected,
                  onChanged:
                  _giftCodeExists ? null : widget.onSelectChanged,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  fillColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                      if (states.contains(MaterialState.selected)) {
                        return Colors.black;
                      }
                      return Colors.white;
                    },
                  ),
                  checkColor: Colors.white,
                ),
              ),
            ),

          // 이미지 + 정보
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${NumberFormat('#,###').format(widget.boxPrice)}원',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          "럭키박스",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF465461),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF8D969D)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.paymentType == 'point'
                                ? '포인트 결제'
                                : widget.paymentType == 'card'
                                ? '카드 결제'
                                : '기타 결제',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF465461),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '구매날짜: $formattedDate',
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFF8D969D)),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          remainingDays > 0
                              ? '결제취소 $remainingDays일 남음'
                              : '결제취소 불가',
                          style: TextStyle(
                            fontSize: 10,
                            color: remainingDays > 0
                                ? const Color(0xFF2EB520)
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 버튼 영역
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 45,
                  child: ElevatedButton(
                    onPressed: (_giftCodeExists || _loading)
                        ? null
                        : widget.onOpenPressed,
                    style: ButtonStyle(
                      backgroundColor:
                      MaterialStateProperty.resolveWith<Color>(
                            (states) => states.contains(MaterialState.disabled)
                            ? Theme.of(context).primaryColor.withOpacity(0.3)
                            : Theme.of(context).primaryColor,
                      ),
                      shape: MaterialStateProperty.all<
                          RoundedRectangleBorder>(
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
              const SizedBox(width: 12),
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
                      side: BorderSide(
                          color: Theme.of(context).primaryColor),
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
