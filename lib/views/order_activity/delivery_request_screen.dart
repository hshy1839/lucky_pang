import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../controllers/shipping_controller.dart';
import '../../../controllers/shipping_order_controller.dart';
import '../../../controllers/order_screen_controller.dart';
import '../../routes/base_url.dart';
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

  int get totalAmount {
    final shippingFee = product['shippingFee'] ?? 0;
    final calculated = shippingFee - usedPoints;
    return calculated < 0 ? 0 : calculated;
  }

  late Map<String, dynamic> product;
  late String orderId;
  late dynamic box;

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

    product = args['product'];
    orderId = args['orderId'];
    final decidedAt = args['decidedAt'];
    box = args['box'];

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
              Row(
                children: [
                  Image.network(
                    '${BaseUrl.value}:7778${product['mainImage']}',
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
                          onEdit: () {},
                          onDelete: () {},
                        ),
                      );
                    },
                  ),
                ),
              ],
              SizedBox(height: 24.h),
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
                        final shippingFee = product['shippingFee'] ?? 0;
                        usedPoints = totalPoints >= shippingFee ? shippingFee : totalPoints;
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
                  children: [TextSpan(text: '구매 확인 동의', style: TextStyle(color: Colors.blue))],
                )),
                value: agreedPurchase,
                onChanged: (val) => setState(() => agreedPurchase = val ?? false),
              ),
              CheckboxListTile(
                title: Text.rich(TextSpan(
                  children: [TextSpan(text: '교환/환불 정책 동의', style: TextStyle(color: Colors.blue))],
                )),
                value: agreedReturn,
                onChanged: (val) => setState(() => agreedReturn = val ?? false),
              ),
              SizedBox(height: 24.h),
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
                  onPressed: () async {
                    if (!agreedAll || !agreedPurchase || !agreedReturn) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('안내'),
                          content: Text('모든 약관에 동의해주세요.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('확인'),
                            )
                          ],
                        ),
                      );
                      return;
                    }

                    if (selectedShippingId == null) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('안내'),
                          content: Text('배송지를 선택해주세요.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('확인'),
                            )
                          ],
                        ),
                      );
                      return;
                    }

                    if (selectedPayment.isEmpty) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('안내'),
                          content: Text('결제 수단을 선택해주세요.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('확인'),
                            )
                          ],
                        ),
                      );
                      return;
                    }

                    if (selectedPayment == '신용/체크카드') {
                      await OrderScreenController.requestCardPayment(
                        context: context,
                        boxId: box['_id'],
                        boxName: box['name'],
                        amount: totalAmount,
                      );
                      return;
                    }

                    final mappedPaymentType = selectedPayment == '신용/체크카드'
                        ? 'card'
                        : selectedPayment == '계좌이체'
                        ? 'bank'
                        : selectedPayment == '카카오페이'
                        ? 'kakaopay'
                        : 'point';

                    final success = await ShippingOrderController.createShippingOrder(
                      productId: product['_id'],
                      shippingId: selectedShippingId!,
                      orderId: orderId,
                      paymentType: mappedPaymentType,
                      shippingFee: product['shippingFee'] ?? 0,
                      pointUsed: usedPoints,
                      paymentAmount: totalAmount,
                    );

                    if (success) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('결제 완료'),
                          content: Text('결제가 완료되었습니다!'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).pushReplacementNamed('/main');
                              },
                              child: Text('확인'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('결제 실패'),
                          content: Text('결제 처리 중 오류가 발생했습니다.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('확인'),
                            ),
                          ],
                        ),
                      );
                    }
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
