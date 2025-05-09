import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../controllers/shipping_controller.dart';
import '../widget/shipping_card.dart';

class DeliveryRequestScreen extends StatefulWidget {
  @override
  _DeliveryRequestScreenState createState() => _DeliveryRequestScreenState();
}

class _DeliveryRequestScreenState extends State<DeliveryRequestScreen> {
  int usedPoints = 0;
  int totalPoints = 17000;
  String selectedPayment = '';
  bool agreedAll = false;
  bool agreedPurchase = false;
  bool agreedReturn = false;

  Map<String, dynamic>? selectedShipping;
  bool isLoading = true;
  String? selectedShippingId;
  List<Map<String, dynamic>> shippingList = [];


  @override
  void initState() {
    super.initState();
    _fetchShipping();
  }

  Future<void> _fetchShipping() async {
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
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: Text('배송신청')),
        body: Center(child: Text('상품 정보가 없습니다')),
      );
    }

    final product = args['product'];
    final orderId = args['orderId'];
    final decidedAt = args['decidedAt'];
    final box = args['box'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('배송신청')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상품 정보
              Row(
                children: [
                  Image.network(
                    'http://192.168.219.107:7778${product['mainImage']}',
                    width: 80.w,
                    height: 80.w,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('[${product['brand']}] ${product['name']}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                        SizedBox(height: 8.h),
                        Text('배송비: ${product['shippingFee'] ?? 0}원'),
                        Text('수량: 1개'),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // 배송지 추가 버튼
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/shippingCreate');
                },
                icon: Icon(Icons.add),
                label: Text('배송지 추가하기'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48.h),
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black,
                ),
              ),

              // 배송지 카드 표시
              if (shippingList.isNotEmpty) ...[
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
                              selectedShipping = shipping;
                            });
                          },
                          onEdit: () {
                            // TODO: 수정
                          },
                          onDelete: () {
                            // TODO: 삭제
                          },
                        ),
                      );
                    },
                  ),
                ),

              ],

              SizedBox(height: 24.h),

              // 포인트 사용
              Text('보유 포인트: ${totalPoints.toString()} P', style: TextStyle(fontSize: 14.sp)),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(hintText: '0'),
                      onChanged: (val) {
                        setState(() {
                          usedPoints = int.tryParse(val) ?? 0;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        usedPoints = totalPoints;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    child: Text('전액사용', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              // 결제수단
              Text('결제수단', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
              Wrap(
                spacing: 10.w,
                children: [
                  _buildPaymentOption('계좌이체'),
                  _buildPaymentOption('신용/체크카드'),
                  _buildPaymentOption('카카오페이'),
                ],
              ),
              SizedBox(height: 24.h),

              // 안내 문구
              Text(
                '상품은 2~7 영업일 이내에 받아보실 수 있습니다.\n단, 상품의 종류나 신청 시기, 지역 등의 원인에 의해 배송이 지연될 수 있다는 점 참고 부탁드립니다.',
                style: TextStyle(color: Colors.grey, fontSize: 12.sp),
              ),
              SizedBox(height: 24.h),

              // 동의 체크박스
              CheckboxListTile(
                title: Text('모든 내용을 확인하였으며 결제에 동의합니다.'),
                value: agreedAll,
                onChanged: (val) {
                  setState(() {
                    agreedAll = val ?? false;
                    agreedPurchase = val!;
                    agreedReturn = val!;
                  });
                },
              ),
              CheckboxListTile(
                title: Text.rich(TextSpan(
                  children: [
                    TextSpan(text: '구매 확인 동의', style: TextStyle(color: Colors.blue)),
                  ],
                )),
                value: agreedPurchase,
                onChanged: (val) => setState(() => agreedPurchase = val ?? false),
              ),
              CheckboxListTile(
                title: Text.rich(TextSpan(
                  children: [
                    TextSpan(text: '교환/환불 정책 동의', style: TextStyle(color: Colors.blue)),
                  ],
                )),
                value: agreedReturn,
                onChanged: (val) => setState(() => agreedReturn = val ?? false),
              ),

              SizedBox(height: 24.h),

              // 결제하기 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('총 결제금액', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                  Text('${product['shippingFee'] ?? 0}원',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                ],
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: 결제 로직
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text('결제하기', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String title) {
    final isSelected = selectedPayment == title;
    return ChoiceChip(
      label: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Theme.of(context).primaryColor,
        ),
      ),
      selected: isSelected,
      selectedColor: Theme.of(context).primaryColor,
      onSelected: (_) => setState(() => selectedPayment = title),
      backgroundColor: Colors.white,
    );
  }
}
