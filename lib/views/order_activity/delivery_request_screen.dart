import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../controllers/shipping_controller.dart';
import '../../../controllers/order_screen_controller.dart';
import '../../controllers/point_controller.dart';
import '../../controllers/shipping_order_controller.dart';
import '../../routes/base_url.dart';
import '../widget/shipping_card.dart';

class DeliveryRequestScreen extends StatefulWidget {
  @override
  _DeliveryRequestScreenState createState() => _DeliveryRequestScreenState();
}

class _DeliveryRequestScreenState extends State<DeliveryRequestScreen> {
  int usedPoints = 0;
  int totalPoints = 0;
  String selectedPayment = '';
  bool agreedAll = false;
  bool agreedPurchase = false;
  bool agreedReturn = false;
  final TextEditingController _pointsController = TextEditingController();
  final PointController _pointController = PointController();
  final numberFormat = NumberFormat('#,###');

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
    _fetchUserPoints();
  }

  void _fetchUserPoints() async {
    final userId = await _getUserId();
    if (userId != null) {
      final total = await _pointController.fetchUserTotalPoints(userId);
      setState(() {
        totalPoints = total;
      });
    }
  }

  Future<String?> _getUserId() async {
    const _storage = FlutterSecureStorage();
    return await _storage.read(key: 'userId');
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

  void applyMaxUsablePoints() {
    final shippingFee = product['shippingFee'] ?? 0;
    final applied = totalPoints >= shippingFee ? shippingFee : totalPoints;
    final formatted = numberFormat.format(applied);
    setState(() {
      usedPoints = applied;
      _pointsController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
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
                    width: 100.w,
                    height: 100.w,
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
              SizedBox(height: 50.h),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/shippingCreate');
                },
                icon: Icon(Icons.add, color: Colors.white),
                label: Text('배송지 추가하기', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48.h),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              SizedBox(height: 20),
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
                        width: 300.w,
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
                          onDeleted: () async {
                            await _fetchShipping();
                            if (selectedShippingId == id) {
                              setState(() {
                                selectedShippingId = shippingList.isNotEmpty ? shippingList.first['_id'] : null;
                                selectedShipping = shippingList.isNotEmpty ? shippingList.first : null;
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
              SizedBox(height: 40.h),

              /// 💡 [아래부터 완전히 LuckyBoxPurchasePage 스타일] 💡
              // 1. 보유포인트 (Row)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '보유 포인트',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 18.sp,
                    ),
                  ),
                  Text(
                    '${numberFormat.format(totalPoints)} P',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                      fontSize: 18.sp,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 30),
              // 2. 포인트 입력창 & 전액사용 버튼 (Row)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pointsController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: '0',
                        suffixText: 'P',
                        suffixStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                          fontSize: 16.sp,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        String numeric = val.replaceAll(RegExp(r'[^0-9]'), '');
                        int input = int.tryParse(numeric) ?? 0;
                        if (input > totalPoints) input = totalPoints;
                        if (input > (product['shippingFee'] ?? 0)) input = product['shippingFee'] ?? 0;

                        final formatted = numberFormat.format(input);

                        if (usedPoints != input) {
                          setState(() {
                            usedPoints = input;
                          });
                        }
                        if (val != formatted) {
                          _pointsController.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(offset: formatted.length),
                          );
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: applyMaxUsablePoints,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    child: Text('전액사용', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),

              SizedBox(height: 40),

              // 3. 결제수단 (ChoiceChip)
              const Text(
                '결제 수단',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: _paymentOption('계좌이체'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: _paymentOption('신용/체크카드'),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40),
              CheckboxListTile(
                activeColor: Colors.black,
                checkColor: Colors.white,
                title: const Text('모든 내용을 확인하였으며 결제에 동의합니다.',
                    style: TextStyle(fontSize: 16, color: Colors.black)),
                value: agreedAll,
                onChanged: (val) {
                  setState(() {
                    agreedAll = val ?? false;
                    agreedPurchase = val ?? false;
                    agreedReturn = val ?? false;
                  });
                },
              ),
              CheckboxListTile(
                activeColor: Colors.black,
                checkColor: Colors.white,
                title: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/purchase_term'),
                  child: const Text('구매 확인 동의', style: TextStyle(color: Colors.blue)),
                ),
                value: agreedPurchase,
                onChanged: (val) => setState(() => agreedPurchase = val ?? false),
              ),
              CheckboxListTile(
                activeColor: Colors.black,
                checkColor: Colors.white,
                title: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/refund_term'),
                  child: const Text('교환/환불 정책 동의', style: TextStyle(color: Colors.blue)),
                ),
                value: agreedReturn,
                onChanged: (val) => setState(() => agreedReturn = val ?? false),
              ),

              SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '총 결제금액',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    '${numberFormat.format(totalAmount)}원',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!agreedAll || !agreedPurchase || !agreedReturn) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('안내'),
                          content: Text('모든 약관에 동의해주세요.'),
                          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('확인'))],
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
                          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('확인'))],
                        ),
                      );
                      return;
                    }
                    if (totalAmount > 0 && selectedPayment.isEmpty) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('안내'),
                          content: Text('결제 수단을 선택해주세요.'),
                          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('확인'))],
                        ),
                      );
                      return;
                    }

                    // 여기만 ShippingOrderController로 변경
                    await ShippingOrderController.submitShippingOrder(
                      context: context,
                      orderId: orderId,
                      shippingId: selectedShippingId!,
                      totalAmount: totalAmount,
                      pointsUsed: usedPoints,
                      paymentMethod: selectedPayment.isEmpty ? 'point' : selectedPayment,
                    );
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: Text('결제하기', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentOption(String title) {
    final isSelected = selectedPayment == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPayment = isSelected ? '' : title;
        });
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade400),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
