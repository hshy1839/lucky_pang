import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../controllers/order_screen_controller.dart';
import '../../main.dart';
import '../../routes/base_url.dart'; // 경로에 맞게 수정

class BoxOpenScreen extends StatefulWidget {
  const BoxOpenScreen({super.key});

  @override
  State<BoxOpenScreen> createState() => _BoxOpenScreenState();
}

class _BoxOpenScreenState extends State<BoxOpenScreen> {
  Map<String, dynamic>? orderData;
  bool loading = true;
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      final orderId = args?['orderId'];

      if (orderId != null) {
        _loadOrderData(orderId);
        _isInit = true;
      }
    }
  }

  Future<void> _loadOrderData(String orderId) async {
    final data = await OrderScreenController.unboxOrder(orderId);

    setState(() {
      orderData = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat('#,###', 'ko_KR');

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final product = orderData?['unboxedProduct']?['product'];

    final productName = product?['name'] ?? '상품명 없음';
    final brand = product?['brand'] ?? '브랜드 없음';
    final imageUrl = product?['mainImage'] != null
        ? '${BaseUrl.value}:7778${product?['mainImage']}'
        : '';
    final price = product?['consumerPrice'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 80.h),
              Text(
                '당첨을 축하드립니다!',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 40.h),

              // 상품 이미지
              ClipRRect(
                borderRadius: BorderRadius.circular(50.r),
                child: Image.network(
                  imageUrl,
                  width: 260.w,
                  height: 260.w,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/default_product.png',
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),

              SizedBox(height: 24.h),

              // 브랜드/상품명
              Column(
                children: [
                  Text(
                    brand,
                    style: TextStyle(fontSize: 16.sp, ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    productName,
                    style: TextStyle(fontSize: 14.sp, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              SizedBox(height: 40.h),

              // 정가
              Text(
                '정가: ${formatCurrency.format(price)}원',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF5722),
                ),
              ),
              SizedBox(height: 36.h),

              // 버튼들
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MainScreenWithFooter(initialTabIndex: 2),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFF5722)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16.h), // 내부 패딩 추가
                  ),
                  child: const Text(
                    '박스 보관함',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFFFF5722),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MainScreenWithFooter(initialTabIndex: 4),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16.h), // 내부 패딩 추가
                  ),
                  child: const Text(
                    '박스 다시 구매하기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 80,)
            ],
          ),
        ),
      ),
      ),
    );
  }
}
