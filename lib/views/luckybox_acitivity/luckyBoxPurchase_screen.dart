import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/box_controller.dart';
import '../../controllers/order_screen_controller.dart';
import '../../controllers/point_controller.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LuckyBoxPurchasePage extends StatefulWidget {
  @override
  _LuckyBoxPurchasePageState createState() => _LuckyBoxPurchasePageState();
}

class _LuckyBoxPurchasePageState extends State<LuckyBoxPurchasePage> {
  String selectedBox = '5000';
  int quantity = 1;
  int availablePoints = 0;
  int pointsUsed = 0;
  String paymentMethod = '';
  bool allAgreed = false;
  bool purchaseConfirmed = false;
  bool refundPolicyAgreed = false;
  List<dynamic> boxes = [];
  String? selectedBoxId;

  final pointController = PointController();
  final storage = FlutterSecureStorage();
  final TextEditingController pointsController = TextEditingController();

  int get boxPrice {
    final boxController = Provider.of<BoxController>(context, listen: false);
    final selectedBox = boxController.boxes.firstWhere(
      (b) => b['_id'] == selectedBoxId,
      orElse: () => null,
    );
    return selectedBox != null ? (selectedBox['price'] as int) : 0;
  }

  int get price => (boxPrice * quantity).clamp(0, double.infinity).toInt();

  int get totalAmount {
    final calculated = price - pointsUsed;
    return calculated < 0 ? 0 : calculated;
  }

  @override
  void initState() {
    super.initState();
    loadUserPoints();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BoxController>(context, listen: false).fetchBoxes();
    });
  }

  void loadUserPoints() async {
    final userId = await storage.read(key: 'userId');
    if (userId == null) {
      print('userId not found in secure storage');
      return;
    }

    int fetchedPoints = await pointController.fetchUserTotalPoints(userId);
    setState(() {
      availablePoints = fetchedPoints;
      pointsUsed = 0;
      pointsController.text = '0';
    });
  }

  void changeQuantity(int change) {
    setState(() {
      quantity = (quantity + change).clamp(1, 999);
    });
  }

  void applyMaxUsablePoints() {
    final maxUsable = boxPrice * quantity;

    setState(() {
      if (availablePoints >= maxUsable) {
        pointsUsed = maxUsable;
      } else {
        pointsUsed = availablePoints;
      }
      pointsController.text = pointsUsed.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('럭키박스 구매',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  '두근두근 럭키타임!\n특별한 상품들이 당신을 기다리고 있어요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 30),
              Consumer<BoxController>(
                builder: (context, boxController, _) {
                  if (boxController.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (boxController.error != null) {
                    return Text('에러: ${boxController.error}');
                  }

                  return Wrap(
                    spacing: 8,
                    children: boxController.boxes.map<Widget>((box) {
                      final isSelected = selectedBoxId == box['_id'];
                      return ChoiceChip(
                        label: Text('${box['name']}'),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            selectedBoxId = box['_id'];
                            applyMaxUsablePoints();
                            // 필요하면 price 등도 box['price']로 저장
                          });
                        },
                        selectedColor: Theme.of(context).primaryColor,
                      );
                    }).toList(),
                  );
                },
              ),
              SizedBox(height: 20),
              Text('구매수량'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 1,
                    children: [
                      quickButton('+5', 5),
                      quickButton('+10', 10),
                      quickButton('+50', 50),
                      quickButton('MAX', 999 - quantity),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                          onPressed: () => changeQuantity(-1),
                          icon: Icon(Icons.remove)),
                      Text(quantity.toString()),
                      IconButton(
                          onPressed: () => changeQuantity(1),
                          icon: Icon(Icons.add)),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                '상품 금액  \t  ${price.toString()}원',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text('보유 포인트 : $availablePoints P',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.w500)),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: pointsController,
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        int input = int.tryParse(val) ?? 0;
                        setState(() {
                          pointsUsed =
                              input > availablePoints ? availablePoints : input;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: '0',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: applyMaxUsablePoints,
                    child: Text('전액사용'),
                  ),
                ],
              ),
              SizedBox(height: 30),
              Text('결제수단'),
              Wrap(
                spacing: 10,
                children: [
                  paymentOption('계좌이체'),
                  paymentOption('신용/체크카드'),
                  paymentOption('카카오페이'),
                ],
              ),
              SizedBox(height: 20),
              CheckboxListTile(
                title: Text('모든 내용을 확인하였으며 결제에 동의합니다.'),
                value: allAgreed,
                onChanged: (val) => setState(() => allAgreed = val ?? false),
              ),
              CheckboxListTile(
                title: Text('구매 확인 동의'),
                value: purchaseConfirmed,
                onChanged: (val) =>
                    setState(() => purchaseConfirmed = val ?? false),
              ),
              CheckboxListTile(
                title: Text('교환/환불 정책 동의'),
                value: refundPolicyAgreed,
                onChanged: (val) =>
                    setState(() => refundPolicyAgreed = val ?? false),
              ),
              SizedBox(height: 20),
              Text(
                '총 결제금액  \t  ${totalAmount.toString()}원',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: () {
                  if (!allAgreed || !purchaseConfirmed || !refundPolicyAgreed) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: Colors.white,
                        title: Text('안내'),
                        content: Text('모든 약관에 동의해주세요.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('확인',
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor)),
                          ),
                        ],
                      ),
                    );
                    return;
                  }

                  if (totalAmount > 0 && paymentMethod.isEmpty) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: Colors.white,
                        title: Text('안내'),
                        content: Text('결제 수단을 선택해주세요!'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('확인',
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor)),
                          ),
                        ],
                      ),
                    );
                    return;
                  }

                  if (paymentMethod == '신용/체크카드') {
                    final boxController = Provider.of<BoxController>(context, listen: false);
                    final selectedBox = boxController.boxes.firstWhere(
                          (b) => b['_id'] == selectedBoxId,
                      orElse: () => null,
                    );

                    if (selectedBox == null) {
                      showDialog(
                        context: context,
                        builder: (_) => const AlertDialog(
                          title: Text('박스 선택 오류'),
                          content: Text('박스를 선택해주세요.'),
                        ),
                      );
                      return;
                    }

                     OrderScreenController.requestCardPayment(
                      context: context,
                      boxId: selectedBox['_id'],
                      boxName: selectedBox['name'],
                      amount: totalAmount,
                    );
                    return;
                  }
                  // ✅ 주문 요청 함수 호출
                  OrderScreenController.submitOrder(
                    context: context,
                    selectedBoxId: selectedBoxId,
                    quantity: quantity,
                    totalAmount: totalAmount,
                    pointsUsed: pointsUsed,
                    paymentMethod: paymentMethod,
                  );
                },
                child: Text('결제하기', style: TextStyle(color: Colors.white)),
              ),
              SizedBox(height: 100,),
            ],
          ),
        ),
      ),

    );
  }

  Widget boxSelector(String price) {
    final isSelected = selectedBox == price;

    return ChoiceChip(
      label: Text(
        '${int.parse(price).toStringAsFixed(0)}원 박스',
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() {
        selectedBox = price;
        applyMaxUsablePoints(); // 박스 변경 시에도 포인트 자동 적용
      }),
      selectedColor: Theme.of(context).primaryColor,
      backgroundColor: Colors.white,
    );
  }

  Widget quickButton(String label, int change) {
    return ElevatedButton(
      onPressed: () => changeQuantity(change),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        padding: EdgeInsets.zero,
        minimumSize: Size(40, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget paymentOption(String method) {
    final isSelected = paymentMethod == method;

    return ChoiceChip(
      label: Text(
        method,
        style: TextStyle(color: isSelected ? Colors.white : Colors.black),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => paymentMethod = method),
      backgroundColor: Colors.white,
      selectedColor: Theme.of(context).primaryColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
