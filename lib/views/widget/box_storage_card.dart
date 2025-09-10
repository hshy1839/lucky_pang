import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';

import '../../../controllers/order_screen_controller.dart';
import '../../controllers/giftcode_controller.dart';

class BoxStorageCard extends StatefulWidget {
  final String boxName;
  final String createdAt; // ISO string
  final int paymentAmount;
  final int pointUsed;
  final String paymentType; // 'point' | 'card' | 'mixed'
  final String boxId;
  final int boxPrice;
  final String orderId;
  final bool? initialGiftCodeExists;
  /// 서버에서 내려주는 현재 주문 상태 ('paid' | 'cancel_requested' | 'cancelled' | 'refunded' | 'shipped' | 'pending')
  final String status;

  /// 리스트 선택(배치 오픈 등)을 위한 상태
  final bool isSelected;
  final ValueChanged<bool?> onSelectChanged;

  /// 선택/체크박스/버튼 등 전체 비활성화 하고 싶을 때
  final bool isDisabled;

  /// 박스 열기/선물하기 외부 로직 (내부에서 취소요청은 자체 처리)
  final VoidCallback onOpenPressed;
  final VoidCallback onGiftPressed;

  /// (옵션) 취소요청 성공 직후 부모에게 알림(리스트 갱신용)
  final VoidCallback? onCancelled;

  const BoxStorageCard({
    super.key,
    required this.boxName,
    required this.createdAt,
    required this.paymentAmount,
    required this.pointUsed,
    required this.paymentType,
    required this.boxId,
    required this.orderId,
    required this.boxPrice,
    required this.status,
    required this.isSelected,
    required this.onSelectChanged,
    required this.isDisabled,
    required this.onOpenPressed,
    required this.onGiftPressed,
    this.initialGiftCodeExists,

    this.onCancelled, // ← 선택 파라미터
  });

  @override
  State<BoxStorageCard> createState() => _BoxStorageCardState();
}

class _BoxStorageCardState extends State<BoxStorageCard> {
  bool _giftCodeExists = false;
  bool _loading = true;

  late TapGestureRecognizer _cancelTap;

  // 로컬 상태 — 취소요청 성공 시 즉시 UI 반영/숨김
  late String _status;
  bool _hidden = false; // ← 추가: 카드 숨김 플래그

  @override
  void initState() {
    super.initState();
    _status = widget.status;
    _cancelTap = TapGestureRecognizer();

    // 이미 서버에서 알려준 값 쓰기
    _giftCodeExists = widget.initialGiftCodeExists ?? false;
    _loading = false;   // 네트워크 재조회 아예 생략
  }

  @override
  void dispose() {
    _cancelTap.dispose();
    super.dispose();
  }

  Future<void> _checkGiftCode() async {
    final exists = await GiftCodeController.checkGiftCodeExists(
      type: 'box',
      boxId: widget.boxId,
      orderId: widget.orderId,
    );
    if (!mounted) return;
    setState(() {
      _giftCodeExists = exists;
      _loading = false;
    });
    if (exists && widget.isSelected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onSelectChanged(false);
      });
    }
  }

  Future<bool> _confirmCancelDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            '정말 결제를 취소하시겠습니까?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: Text(
              '환불은 영업일 기준 2~3일 소요될 수 있습니다.',
              style: TextStyle(fontSize: 12, color: Color(0xFF8D969D)),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('조금 더 생각해볼게요', style: TextStyle(color: Colors.blue)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('결제 취소'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // 숨김 플래그면 즉시 렌더 제거
    if (_hidden) return const SizedBox.shrink();

    final createdAtDt = DateTime.parse(widget.createdAt);
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(createdAtDt);

    // 취소 가능 기한: 구매 후 7일
    final cancelDeadline = createdAtDt.add(const Duration(days: 7));
    final remainingDays = cancelDeadline.difference(DateTime.now()).inDays;

    // 취소 가능 조건: 로딩X, 선물코드X, 7일 이내, 현재 상태가 paid
    final canCancel = !_loading && !_giftCodeExists && remainingDays > 0 && _status == 'paid';
    final cancelColor = remainingDays > 0 ? const Color(0xFF2EB520) : Colors.red;

    // 버튼/체크박스 제어
    final disabledByStatus = _status == 'cancel_requested' || _status == 'cancelled' || _status == 'refunded' || _status == 'shipped';
    final disableActions = widget.isDisabled || _giftCodeExists || _loading || disabledByStatus;

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

            Align(
              alignment: Alignment.topLeft,
              child: AbsorbPointer(
                absorbing: _giftCodeExists || disabledByStatus,
                child: Checkbox(
                  value: widget.isSelected,
                  onChanged: (_giftCodeExists || disabledByStatus) ? null : widget.onSelectChanged,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  fillColor: MaterialStateProperty.resolveWith<Color>(
                        (states) => states.contains(MaterialState.selected)
                        ? Colors.black
                        : Colors.white,
                  ),
                  checkColor: Colors.white,
                ),
              ),
            ),

          // 이미지 + 정보
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 썸네일
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

              // 텍스트 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 가격 + 결제수단 + 상태뱃지
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
                          '럭키박스',
                          style: TextStyle(fontSize: 13, color: Color(0xFF465461)),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                            style: const TextStyle(fontSize: 10, color: Color(0xFF465461)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 상태 뱃지 (paid는 숨김)
                        if (_status != 'paid') _buildStatusBadge(_status),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 날짜 + 결제취소(클릭 가능) + 남은일
                    Row(
                      children: [
                        Text(
                          '구매날짜: $formattedDate',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF8D969D)),
                        ),
                        const SizedBox(width: 4),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 10, color: cancelColor),
                            children: [
                              TextSpan(
                                text: '결제취소',
                                style: TextStyle(
                                  decoration: canCancel ? TextDecoration.underline : TextDecoration.none,
                                  decorationThickness: 1.5,
                                  decorationColor: cancelColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: _cancelTap
                                  ..onTap = () async {
                                    // 취소 불가 사유 안내
                                    if (!canCancel) {
                                      String reason = '결제 취소가 불가합니다.';
                                      if (_loading) {
                                        reason = '정보를 불러오는 중입니다. 잠시만 기다려주세요.';
                                      } else if (_giftCodeExists) {
                                        reason = '선물코드가 생성된 주문은 결제 취소가 불가합니다.';
                                      } else if (remainingDays <= 0) {
                                        reason = '결제 취소 가능 기한(구매 후 7일)이 지났습니다.';
                                      } else if (_status != 'paid') {
                                        reason = '현재 상태에서는 결제 취소 요청이 불가합니다.';
                                      }
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reason)));
                                      return;
                                    }

                                    final ok = await _confirmCancelDialog(context);
                                    if (!ok || !mounted) return;

                                    // 서버에 취소 요청(patch: cancel_requested)
                                    final success = await OrderScreenController.updateOrderStatus(
                                      orderId: widget.orderId,
                                      status: 'cancel_requested',
                                    );
                                    if (!mounted) return;

                                    if (success) {
                                      setState(() {
                                        _status = 'cancel_requested';
                                        _hidden = true; // ← 성공 즉시 카드 숨김
                                      });
                                      // 부모가 리스트를 다시 불러오길 원하면 콜백도 호출
                                      widget.onCancelled?.call();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('결제 취소 요청이 접수되었습니다.')),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('결제 취소 요청에 실패했습니다. 다시 시도해주세요.')),
                                      );
                                    }
                                  },
                              ),
                              TextSpan(
                                text: remainingDays > 0 ? ' ${remainingDays}일 남음' : ' 불가',
                                style: const TextStyle(
                                  decoration: TextDecoration.none,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
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

          // 버튼 영역 (박스열기 / 선물하기)
          Row(
            children: [
              // 박스열기
              Expanded(
                child: SizedBox(
                  height: 45,
                  child: ElevatedButton(
                    onPressed: disableActions ? null : widget.onOpenPressed,
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                            (states) => states.contains(MaterialState.disabled)
                            ? Theme.of(context).primaryColor.withOpacity(0.3)
                            : Theme.of(context).primaryColor,
                      ),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                    child: const Text(
                      '박스열기',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 선물하기 / 선물코드 확인
              Expanded(
                child: SizedBox(
                  height: 45,
                  child: OutlinedButton(
                    onPressed: () async {
                      if (disableActions) return;
                      await Navigator.pushNamed(
                        context,
                        '/giftcode/create',
                        arguments: {
                          'type': 'box',
                          'boxId': widget.boxId,
                          'orderId': widget.orderId,
                        },
                      );
                      await _checkGiftCode(); // 복귀 후 다시 체크
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Theme.of(context).primaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

  // 상태 뱃지 위젯
  Widget _buildStatusBadge(String status) {
    String label;
    Color border;
    Color text;
    Color bg;

    switch (status) {
      case 'cancel_requested':
        label = '취소요청됨';
        border = Colors.redAccent;
        text = Colors.redAccent;
        bg = Colors.redAccent.withOpacity(0.08);
        break;
      case 'cancelled':
        label = '취소완료';
        border = Colors.grey;
        text = Colors.grey[700]!;
        bg = Colors.grey.withOpacity(0.12);
        break;
      case 'refunded':
        label = '환급완료';
        border = Colors.blueGrey;
        text = Colors.blueGrey;
        bg = Colors.blueGrey.withOpacity(0.08);
        break;
      case 'shipped':
        label = '배송중';
        border = Colors.green;
        text = Colors.green[700]!;
        bg = Colors.green.withOpacity(0.08);
        break;
      case 'pending':
        label = '결제대기';
        border = Colors.orange;
        text = Colors.orange[800]!;
        bg = Colors.orange.withOpacity(0.10);
        break;
      case 'paid':
      default:
      // paid는 호출부에서 이미 숨김 처리
        label = '결제완료';
        border = const Color(0xFF8D969D);
        text = const Color(0xFF465461);
        bg = const Color(0xFFEFF3F6);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: text)),
    );
  }
}
