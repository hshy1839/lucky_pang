import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../controllers/order_screen_controller.dart';
import '../../../routes/base_url.dart';
import '../../widget/ranking_screen_widget/ranking_tab_bar_header.dart';
import '../../widget/ranking_screen_widget/unbox_realtime_list.dart';
import '../../widget/ranking_screen_widget/unbox_weekly_ranking.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  bool showRealtimeLog = true;
  List<Map<String, dynamic>> unboxedOrders = [];
  int highestPrice = 0;
  int totalPrice = 0;
  ScrollController _scrollController = ScrollController();
  bool isCollapsed = false;

  @override
  void initState() {
    super.initState();
    fetchUnboxedLogs();
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        setState(() {
          isCollapsed = _scrollController.offset > 200.h;
        });
      }
    });
  }

  Future<void> fetchUnboxedLogs() async {
    final orders = await OrderScreenController.getAllUnboxedOrders();

    final now = DateTime.now();
    final startDate = showRealtimeLog
        ? now.subtract(const Duration(hours: 24))
        : now.subtract(const Duration(days: 6));

    final filteredOrders = orders.where((order) {
      final createdAtStr = order['createdAt'];
      if (createdAtStr == null) return false;
      final createdAt = DateTime.tryParse(createdAtStr);
      if (createdAt == null) return false;
      return createdAt.isAfter(startDate);
    }).toList();

    int maxPrice = 0;
    int sumPrice = 0;
    for (var order in filteredOrders) {
      final product = order['unboxedProduct']?['product'];
      final rawPrice = product?['price'] ?? 0;
      final price = rawPrice is int ? rawPrice : (rawPrice as num).toInt();
      if (price > maxPrice) maxPrice = price;
      sumPrice += price;
    }

    setState(() {
      unboxedOrders = filteredOrders;
      highestPrice = maxPrice;
      totalPrice = sumPrice;
    });
  }

  String _formatShortNumber(int number) {
    if (number >= 1000000) {
      return (number / 1000000).toStringAsFixed(1) + 'M';
    } else if (number >= 1000) {
      return (number / 1000).toStringAsFixed(1) + 'K';
    } else {
      return number.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(375, 812));
    final today = DateTime.now();
    final weekAgo = today.subtract(const Duration(days: 6));
    final dateFormat = "${weekAgo.year}-${weekAgo.month.toString().padLeft(2, '0')}-${weekAgo.day.toString().padLeft(2, '0')}"
        " - ${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    return Scaffold(
        backgroundColor: Color(0xFFFF5C43),
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: 480.h,
              pinned: true,
              backgroundColor: const Color(0xFFFF5C43),
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final top = constraints.biggest.height;
                  return FlexibleSpaceBar(
                    background: Padding(
                      padding: EdgeInsets.only(top: 40.h),
                      child: isCollapsed
                          ? _buildCompactStatHeader()
                          : Column(
                        children: [
                          Text(
                            showRealtimeLog ? '지금 언박싱하는 사람들' : '이번주 언박싱 랭킹',
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            showRealtimeLog ? '최근 24시간' : dateFormat,
                            style: TextStyle(fontSize: 12.sp, color: Colors.white),
                          ),
                          SizedBox(height: 20.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Column(
                              children: [
                                buildUnboxStatCard(
                                  title: '언박싱 최고가',
                                  value: _formatNumber(highestPrice),
                                  unit: '원',
                                  backgroundColor: Color(0xFF021526),
                                  backgroundImage: 'assets/images/ranking_images/unboxing_high.png',
                                ),
                                buildUnboxStatCard(
                                  title: '언박싱 횟수',
                                  value: '${unboxedOrders.length}',
                                  unit: '회',
                                  backgroundColor: Color(0xFF021526),
                                  backgroundImage: 'assets/images/ranking_images/unboxing_try.png',
                                ),
                                buildUnboxStatCard(
                                  title: '누적 최고가',
                                  value: _formatNumber(totalPrice),
                                  unit: '원',
                                  backgroundColor: Color(0xFF021526),
                                  backgroundImage: 'assets/images/ranking_images/unboxing_max.png',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: RankingTabBarHeader(
                isSelected: showRealtimeLog,
                onTap: (selected) {
                  setState(() {
                    showRealtimeLog = selected;
                    fetchUnboxedLogs();
                  });
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                height: 350.h,
                child: showRealtimeLog
                    ? SingleChildScrollView(
                  child: UnboxRealtimeList(unboxedOrders: unboxedOrders),
                )
                    : const SingleChildScrollView(
                  child: UnboxWeeklyRanking(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStatHeader() {
    return Padding(
      padding: EdgeInsets.only(top: 90.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _circleStat("${_formatShortNumber(highestPrice)}", "언박싱 최고가"),
          _circleStat("${_formatShortNumber(unboxedOrders.length)}", "언박싱 횟수"),
          _circleStat("${_formatShortNumber(totalPrice)}", "누적 최고가"),
        ],
      ),
    );
  }

  Widget _circleStat(String value, String label) {
    return Column(
      children: [
        Container(
          width: 60.w,
          height: 60.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF021526),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 4.r, offset: Offset(0, 2)),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp),
          ),
        ),
        SizedBox(height: 4.h),
        Text(label, style: TextStyle(color: Colors.white, fontSize: 12.sp)),
      ],
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  }

  Widget buildUnboxStatCard({
    required String title,
    required String value,
    required String unit,
    Color? backgroundColor,
    String? backgroundImage,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.black,
        borderRadius: BorderRadius.circular(10.r),
        image: backgroundImage != null
            ? DecorationImage(
          image: AssetImage(backgroundImage),
          fit: BoxFit.cover,
          opacity: 0.4,
        )
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12.sp, color: Colors.white.withOpacity(0.8))),
              SizedBox(height: 6.h),
              Text(value, style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          Text(unit, style: TextStyle(fontSize: 14.sp, color: Colors.white.withOpacity(0.9))),
        ],
      ),
    );
  }
}