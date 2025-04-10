import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int expandedIndex = -1;

  final List<String> categories = [
    '일반', '계정', '구매/환불', '배송', '포인트', '오류/개선', '결제',
  ];

  final Map<String, List<Map<String, String>>> faqData = {
    '일반': [
      {
        'question': '럭키탱은 어떤 어플인가요?',
        'answer': '럭키탱은 다양한 상품을 랜덤으로 받을 수 있는 럭키박스 쇼핑 앱입니다.'
      },
      {
        'question': '럭키박스는 어떻게 사용하나요?',
        'answer': '럭키박스를 구매한 직후 [바로 박스 열기]를 클릭해 즉시 상품을 획득할 수 있어요.\n\n상품을 바로 열어보지 않는다면 [박스 보관함]에 박스가 보관돼요.\n\n상품을 언박싱하고 싶을 때 하단 4번째 탭, [박스 보관함]에서 [박스열기]를 클릭하면 상품을 획득할 수 있어요.\n\n박스에서는 메인화면의 전체 상품이 랜덤으로 등장합니다.'
      },
      {
        'question': '획득한 상품은 어디서 확인하나요?',
        'answer': '상품은 마이페이지 > 박스 보관함 또는 상품 보관함에서 확인하실 수 있어요.'
      },
      {
        'question': '언박싱한 상품이 사라졌어요.',
        'answer': '일시적인 네트워크 오류일 수 있습니다. 다시 시도해 주세요.'
      },
      {
        'question': '럭키박스를 환불하고 싶어요. (I want to refund my Lucky Box.)',
        'answer': '언박싱되지 않은 박스는 환불이 가능하며, 고객센터로 문의 주세요.'
      },
      {
        'question': '실수로 상품을 환급했어요. 복구 가능한가요?',
        'answer': '환급은 취소가 불가능하므로 신중히 진행해 주세요.'
      },
    ],
    // 다른 카테고리들도 동일한 구조로 추가 가능
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
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
      body: Column(
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
                final List<Map<String, String>> faqList = faqData[category] ?? [];
                return ListView.separated(
                  padding: EdgeInsets.only(bottom: 24.h),
                  itemCount: faqList.length + 1, // 👈 Row 하나 더 추가
                  separatorBuilder: (_, index) =>
                  index < faqList.length ? Divider(height: 1, color: Colors.grey.shade300) : SizedBox.shrink(),
                  itemBuilder: (context, index) {
                    if (index < faqList.length) {
                      final isExpanded = expandedIndex == index;
                      final item = faqList[index];
                      return ExpansionTile(
                        title: Text('Q. ${item['question']!}', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      // ⬇️ 마지막에 나타나는 Row
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 32.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('찾으시는 결과가 없으신가요?', style: TextStyle(color: Colors.grey)),
                            SizedBox(width: 4.w),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/qna');
                              },
                              child: Text(
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