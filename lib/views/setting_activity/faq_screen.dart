import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../controllers/faq_screen_controller.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int expandedIndex = -1;
  bool isLoading = true;

  final List<String> categories = [
    '일반', '계정', '구매/환불', '배송', '포인트', '오류/개선', '결제',
  ];

  Map<String, List<Map<String, String>>> faqData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    _fetchFaqData();
  }

  Future<void> _fetchFaqData() async {
    final controller = FaqScreenController();
    final data = await controller.fetchFaq();

    // 카테고리별로 정리
    Map<String, List<Map<String, String>>> organized = {};
    for (String category in categories) {
      organized[category] = data
          .where((item) => (item['category']?.toString() ?? '') == category)
          .map((item) => {
        'question': item['question']?.toString() ?? '',
        'answer': item['answer']?.toString() ?? '',
      })
          .toList();
    }

    setState(() {
      faqData = organized;
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text('FAQ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            color: Colors.white,
            height: 48.h,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.black,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              tabs: categories.map((e) => Tab(text: e)).toList(),
              onTap: (_) => setState(() => expandedIndex = -1),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade300),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: categories.map((category) {
                final faqList = faqData[category] ?? [];

                return ListView.separated(
                  padding: EdgeInsets.only(bottom: 24.h),
                  itemCount: faqList.length + 1,
                  separatorBuilder: (_, index) => index < faqList.length
                      ? Divider(height: 1, color: Colors.grey.shade300)
                      : const SizedBox.shrink(),
                  itemBuilder: (context, index) {
                    if (index < faqList.length) {
                      final isExpanded = expandedIndex == index;
                      final item = faqList[index];
                      return ExpansionTile(
                        title: Text('Q. ${item['question']!}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                        onExpansionChanged: (expanded) {
                          setState(() => expandedIndex = expanded ? index : -1);
                        },
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            child: Text('A. ${item['answer']!}', style: TextStyle(color: Colors.grey.shade600)),
                          )
                        ],
                      );
                    } else {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 32.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('찾으시는 결과가 없으신가요?', style: TextStyle(color: Colors.grey)),
                            SizedBox(width: 4.w),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/qna');
                              },
                              child: const Text(
                                '1:1 문의',
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
