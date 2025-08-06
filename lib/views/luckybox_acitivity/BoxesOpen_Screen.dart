import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../controllers/order_screen_controller.dart';
import '../../main.dart';
import '../../routes/base_url.dart';

class BoxesopenScreen extends StatefulWidget {
  final List<String> orderIds;

  const BoxesopenScreen({super.key, required this.orderIds});

  @override
  State<BoxesopenScreen> createState() => _BoxesopenScreenState();
}

class _BoxesopenScreenState extends State<BoxesopenScreen> {
  List<Map<String, dynamic>> unboxedProducts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final List<Map<String, dynamic>> temp = [];

    for (final orderId in widget.orderIds) {
      final data = await OrderScreenController.unboxOrder(orderId);
      final product = data?['unboxedProduct']?['product'];

      if (product != null) {
        temp.add({
          'productName': product['name'],
          'brand': product['brand'],
          'mainImageUrl': product['mainImage'] != null
              ? '${BaseUrl.value}:7778${product['mainImage']}'
              : null,
          'consumerPrice': product['consumerPrice'] ?? 0,
        });
      }
    }

    setState(() {
      unboxedProducts = temp;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat('#,###', 'ko_KR');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        )
            : Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 30.h),
                Text(
                  '당첨을 축하드립니다!',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.h),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: GridView.builder(
                      itemCount: unboxedProducts.length,
                      gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10.h,
                        crossAxisSpacing: 12.w,
                        childAspectRatio: 0.6,
                      ),
                      itemBuilder: (context, index) {
                        final product = unboxedProducts[index];
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
                            border:
                            Border.all(color: const Color(0xFFE5E5E5)),
                            color: Colors.white,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12.r),
                                  topRight: Radius.circular(12.r),
                                ),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: product['mainImageUrl'] != null
                                      ? Image.network(
                                    product['mainImageUrl'],
                                    fit: BoxFit.cover,
                                  )
                                      : const Icon(Icons.image,
                                      size: 48),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.w),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['brand'] ?? '',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      product['productName'] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: const Color(0xFF465461),
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      '정가: ${currency.format(product['consumerPrice'])}원',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 80.h), // 버튼 띄울 공간 확보
              ],
            ),

            // ✅ 닫기 버튼을 하단에 고정, 배경 없음
            Positioned(
              bottom: 16.h,
              left: 24.w,
              right: 24.w,
              child: SizedBox(
                height: 48.h,
                child:   ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MainScreenWithFooter(initialTabIndex: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722), // ✅ 배경색을 기존 border 색상으로
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    elevation: 0, // 그림자 제거
                  ),
                  child: const Text(
                    '박스 보관함',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white, // ✅ 텍스트 색상 흰색
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
