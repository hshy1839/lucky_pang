import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../controllers/shipping_controller.dart';
import '../../widget/shipping_card.dart';

class ShippingInfoScreen extends StatefulWidget {
  const ShippingInfoScreen({super.key});

  @override
  State<ShippingInfoScreen> createState() => _ShippingInfoScreenState();
}

class _ShippingInfoScreenState extends State<ShippingInfoScreen> {
  List<Map<String, dynamic>> shippingList = [];
  bool isLoading = true;
  String? selectedShippingId;

  @override
  void initState() {
    super.initState();
    fetchShippings();
  }

  Future<void> fetchShippings() async {
    final list = await ShippingController.getUserShippings();
    setState(() {
      shippingList = list;
      selectedShippingId = list.isNotEmpty
          ? (list.firstWhere((s) => s['is_default'] == true, orElse: () => list.first))['_id']
          : null;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(375, 812));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
        title: const Text(
          '배송지 목록',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : shippingList.isEmpty
          ? buildEmptyState(context)
          : buildShippingCards(context),
    );
  }

  /// 배송지 없을 때 보여줄 UI
  Widget buildEmptyState(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          SizedBox(height: 60.h),
          Image.asset(
            'assets/images/shipping_missing.png',
            width: double.infinity,
          ),
          SizedBox(height: 24.h),
          Text(
            '아직 등록된 배송지가 없습니다',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF465461),
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            '배송지 추가 후 상품 배송이 가능합니다',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF465461),
            ),
          ),
          SizedBox(height: 40.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/shippingCreate');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5C43),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
                child: Text(
                  '배송지 추가하기',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 배송지 목록 있을 때: Delivery UI 스타일
  Widget buildShippingCards(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/shippingCreate');
            },
            icon: const Icon(Icons.add),
            label: const Text('배송지 추가하기'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 48.h),
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.black,
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 150.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: shippingList.length,
              itemBuilder: (context, index) {
                final shipping = shippingList[index];
                final id = shipping['_id'];
                return Container(
                  width: 250.w,
                  margin: EdgeInsets.only(right: 12.w),
                  child: ShippingCard(
                    shipping: shipping,
                    isSelected: selectedShippingId == id,
                    onTap: () {
                      setState(() {
                        selectedShippingId = id;
                      });
                    },
                    onEdit: () {},
                    onDelete: () {},
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
