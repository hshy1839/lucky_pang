import 'package:flutter/material.dart';

class LuckyBoxPurchasePage extends StatefulWidget {
  @override
  _LuckyBoxPurchasePageState createState() => _LuckyBoxPurchasePageState();
}

class _LuckyBoxPurchasePageState extends State<LuckyBoxPurchasePage> {
  String selectedBox = '5000';
  int quantity = 1;
  int pointsUsed = 0;
  String paymentMethod = '';
  bool allAgreed = false;
  bool purchaseConfirmed = false;
  bool refundPolicyAgreed = false;

  int get totalAmount => (selectedBox == '5000' ? 5000 : 10000) * quantity - pointsUsed;

  void changeQuantity(int change) {
    setState(() {
      quantity = (quantity + change).clamp(1, 999);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('럭키박스 구매',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  boxSelector('5000'),
                  boxSelector('10000'),
                ],
              ),
              SizedBox(height: 20),
              Text('구매수량'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      quickButton('+5', 5),
                      quickButton('+10', 10),
                      quickButton('+50', 50),
                      quickButton('MAX', 999 - quantity),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(onPressed: () => changeQuantity(-1), icon: Icon(Icons.remove)),
                      Text(quantity.toString()),
                      IconButton(onPressed: () => changeQuantity(1), icon: Icon(Icons.add)),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text('포인트 사용 : $pointsUsed P',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        setState(() => pointsUsed = int.tryParse(val) ?? 0);
                      },
                      decoration: InputDecoration(
                        hintText: '0',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => setState(() => pointsUsed = 1000), // 예시
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
                onChanged: (val) => setState(() => purchaseConfirmed = val ?? false),
              ),
              CheckboxListTile(
                title: Text('교환/환불 정책 동의'),
                value: refundPolicyAgreed,
                onChanged: (val) => setState(() => refundPolicyAgreed = val ?? false),
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
                  // 결제 로직 작성
                },
                child: Text('결제하기', style: TextStyle(color: Colors.white)),
              )
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
          color: isSelected ? Colors.white : Colors.black, // ✅ 선택 여부에 따라 색상 변경
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => selectedBox = price),
      selectedColor: Theme.of(context).primaryColor, // ✅ 선택된 배경색
      backgroundColor: Colors.white, // ✅ 선택 안됐을 때 배경
    );
  }



  Widget quickButton(String label, int change) {
    return ElevatedButton(
      onPressed: () => changeQuantity(change),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        padding: EdgeInsets.zero, // ✅ 내부 여백 제거
        minimumSize: Size(40, 40), // ✅ 버튼 최소 사이즈 지정 (정사각형 느낌)
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4), // 필요하면 모서리 둥글기 조절
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
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black, // 선택 여부에 따라 텍스트 색상
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => paymentMethod = method),
      backgroundColor: Colors.white, // ✅ 선택되지 않았을 때 배경 흰색
      selectedColor: Theme.of(context).primaryColor, // ✅ 선택 시 배경색
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade400), // 테두리 추가(선택사항)
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

}
