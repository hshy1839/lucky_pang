import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UnboxWeeklyRanking extends StatefulWidget {
  final List<Map<String, dynamic>> unboxedOrders;

  const UnboxWeeklyRanking({super.key, required this.unboxedOrders});

  @override
  State<UnboxWeeklyRanking> createState() => _UnboxWeeklyRankingState();
}

class _UnboxWeeklyRankingState extends State<UnboxWeeklyRanking> {
  late Timer _timer;
  late Duration _timeLeft;

  @override
  void initState() {
    super.initState();
    _updateTimeLeft();
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      _updateTimeLeft();
    });
  }

  void _updateTimeLeft() {
    final now = DateTime.now();
    final sunday = now.add(Duration(days: DateTime.sunday - now.weekday));
    final endTime = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
    setState(() {
      _timeLeft = endTime.difference(now);
    });
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return '${days}D ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} 🔥';
  }

  List<Map<String, dynamic>> _getRanking(List<Map<String, dynamic>> orders) {
    final Map<String, int> userTotals = {};

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1)); // 이번주 월요일
    final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day); // 월요일 00:00
    final endOfWeek = startOfWeek.add(const Duration(days: 7)).subtract(const Duration(seconds: 1)); // 일요일 23:59:59

    for (var order in orders) {
      final user = order['user'];
      final nickname = user?['nickname'] ?? '익명';

      final createdAtStr = order['createdAt'];
      final createdAt = DateTime.tryParse(createdAtStr ?? '');
      if (createdAt == null || createdAt.isBefore(startOfWeek) || createdAt.isAfter(endOfWeek)) {
        continue;
      }

      final int price = (order['unboxedProduct']?['product']?['consumerPrice'] ?? 0).toInt();
      userTotals[nickname] = (userTotals[nickname] ?? 0) + price;
    }

    final rankedList = userTotals.entries
        .map((e) => {'username': e.key, 'total': e.value})
        .toList();

    rankedList.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
    return rankedList;
  }


  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rankingList = _getRanking(widget.unboxedOrders);

    return Container(
      color: Colors.white,
      child: ListView(
        padding: EdgeInsets.only(bottom: 100.h),
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD54F), Color(0xFFFFA726)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('랭킹전 종료까지', style: TextStyle(fontSize: 14.sp)),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_timeLeft),
                        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Text('랭킹전 룰', style: TextStyle(fontSize: 13.sp)),
                          SizedBox(width: 4.w),
                          const RankingRuleTooltip(),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          for (int i = 0; i < rankingList.length && i < 10; i++)
            _buildUser(
              rank: '${i + 1}위',
              name: rankingList[i]['username'],
              amount: '${_formatCurrency(rankingList[i]['total'])}원 만큼 획득',
              point: _calculatePoint(i, rankingList[i]['total']),
              isFirst: i == 0,
            ),
        ],
      ),
    );
  }

  String _calculatePoint(int index, int total) {
    double rate;

    if (index == 0) {
      rate = 0.02;
    } else if (index == 1) {
      rate = 0.015;
    } else if (index == 2) {
      rate = 0.01;
    } else {
      rate = 0.009;
    }

    final point = (total * rate).floor(); // 소수점 버림
    return '${_formatCurrency(point)} P';
  }


  String _formatCurrency(int number) {
    return number.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  }

  Widget _buildUser({
    required String rank,
    required String name,
    required String amount,
    required String point,
    bool isFirst = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Container(
        decoration: BoxDecoration(
          color: isFirst ? Colors.white : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: isFirst
              ? [BoxShadow(color: Colors.black12, blurRadius: 6.r, offset: Offset(0, 2))]
              : [],
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey.shade300,
            child: Text(rank, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
          subtitle: Text(amount, style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
          trailing: Text(point, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }


}

class RankingRuleTooltip extends StatelessWidget {
  const RankingRuleTooltip({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          barrierColor: Colors.transparent,
          builder: (context) {
            return Stack(
              children: [
                Positioned(
                  top: 400.h,
                  right: 16.w,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 280.w,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('<참여방법>', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                          SizedBox(height: 4.h),
                          Text('1) 기간 내 럭키박스를 구매해 상품을 언박싱해요.', style: TextStyle(fontSize: 12.sp)),
                          Text('2) 획득한 상품의 소비자가로 매겨진 자신의 순위를 확인해요.', style: TextStyle(fontSize: 12.sp)),
                          SizedBox(height: 10.h),
                          Text('<보상>', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                          SizedBox(height: 4.h),
                          Text('1위: 소비자가 총액 2% 포인트', style: TextStyle(fontSize: 12.sp)),
                          Text('2위: 소비자가 총액 1.5% 포인트', style: TextStyle(fontSize: 12.sp)),
                          Text('3위: 소비자가 총액 1% 포인트', style: TextStyle(fontSize: 12.sp)),
                          Text('4위: 소비자가 총액 0.9% 포인트', style: TextStyle(fontSize: 12.sp)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      child: Icon(Icons.help_outline, size: 16.sp),
    );
  }
}

