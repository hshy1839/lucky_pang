import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상품 정보
              Row(
                children: [
                  Image.network('http://172.30.1.22:7778${product['mainImage']}', width: 80.w, height: 80.w),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('[${product['brand']}] ${product['name']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                        SizedBox(height: 8.h),
                        Text('배송비: ${product['shippingFee'] ?? 0}원'),
                        Text('수량: 1개'),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // 배송지 추가하기
              ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.add),
                label: Text('배송지 추가하기'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48.h),
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black,
                ),
              ),
              SizedBox(height: 24.h),

              // 포인트
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
                  ElevatedButton(onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      child: Text('전액사용',
                      style: TextStyle(color: Colors.white),)),
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
                  Text('${product['shippingFee'] ?? 0}원', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                ],
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: () {},
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
      label: Text(title, style: TextStyle(color: isSelected? Colors.white : Theme.of(context).primaryColor),),
      selected: isSelected,
      selectedColor: Theme.of(context).primaryColor,
      onSelected: (_) => setState(() => selectedPayment = title),
      backgroundColor: Colors.white,
    );
  }
}
