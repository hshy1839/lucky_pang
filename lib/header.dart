import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 로고와 장바구니 아이콘 + 검색창 묶음
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: Column(
              children: [
                // 첫 번째 줄: 로고와 장바구니 아이콘
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                    Image.asset(
                      'assets/icons/app_icon.jpg',
                      width: 50, // 원하는 크기로 조절 가능
                      height: 50,
                      fit: BoxFit.contain,
                    ),
                    Text("럭키탕", style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w900, fontSize: 22),),
                    ]
                    ),
                    IconButton(
                      icon: Icon(Icons.shopping_cart_outlined, color:Colors.black, size: 28,),
                      onPressed: () {
                        // 장바구니 화면으로 이동
                        Navigator.pushNamed(context, '/cart');
                      },
                    ),
                  ],
                ),
                SizedBox(height: 8.0), // 줄 간격
                // 두 번째 줄: 검색창
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: '검색어를 입력하세요',
                          hintStyle: TextStyle(color: Colors.grey),
                          contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide.none, // 테두리 제거
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide.none, // 비활성화 상태에서도 테두리 제거
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide.none, // 포커스 상태에서도 테두리 제거
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.search, color: Colors.grey),
                            onPressed: () {
                              // 검색어 가져오기
                              final searchQuery = _searchController.text.trim();

                              if (searchQuery.isNotEmpty) {
                                // 검색 페이지로 이동
                                Navigator.pushNamed(
                                  context,
                                  '/searchProduct',
                                  arguments: {'query': _searchController.text.trim()}, // 검색어 전달
                                );
                                print("보낸 메시지 :${searchQuery}");
                              } else {
                                // 검색어가 비어있으면 메시지 표시
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('검색어를 입력해주세요.')),
                                );
                              }
                            },
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
