import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/box_controller.dart';
import '../../controllers/order_screen_controller.dart';
import '../../controllers/point_controller.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../controllers/userinfo_screen_controller.dart';

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
  String? selectedBoxId;
  bool _isFirstBuild = true;
  final userInfoController = UserInfoScreenController();

  final pointController = PointController();
  final storage = FlutterSecureStorage();
  final TextEditingController pointsController = TextEditingController();

  // 🔒 결제 중 오버레이 상태
  bool _submitting = false;

  int get boxPrice {
    final boxController = Provider.of<BoxController>(context, listen: false);
    if (selectedBoxId == null) return 0;
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

  String formatCurrency(int number) {
    return NumberFormat.decimalPattern().format(number);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstBuild) {
      final boxController = Provider.of<BoxController>(context, listen: false);
      boxController.fetchBoxes(); // 🧨 반드시 호출

      setState(() {
        selectedBox = '5000';
        quantity = 1;
        pointsUsed = 0;
        paymentMethod = '';
        allAgreed = false;
        purchaseConfirmed = false;
        refundPolicyAgreed = false;
        selectedBoxId = null;
        pointsController.text = '0';
      });

      loadUserPoints();
      _loadNickname();
      _isFirstBuild = false;
    }
  }

  void _loadNickname() async {
    await userInfoController.fetchUserInfo(context);
    setState(() {});
  }

  void loadUserPoints() async {
    final userId = await storage.read(key: 'userId');
    if (userId == null) return;

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
    final applied = availablePoints >= maxUsable ? maxUsable : availablePoints;
    final formatted = formatCurrency(applied);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        pointsUsed = applied;
        pointsController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 기존 화면
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFF5722),
                  Color(0xFFC622FF),
                ],
                stops: [0.0, 0.7],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  const Text(
                    '두근두근 럭키타임!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '특별한 상품들이 '
                        '${userInfoController.nickname.isNotEmpty ? '${userInfoController.nickname}님' : '당신'}'
                        '을 기다리고 있어요.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                  const SizedBox(height: 50),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: SingleChildScrollView(
                        child: buildContent(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🔒 결제 중 오버레이 (터치 차단 + 반투명 + 로딩)
          if (_submitting) ...[
            const ModalBarrier(dismissible: false, color: Colors.black54),
            Positioned.fill(
              child: AbsorbPointer(
                child: Center(
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Theme.of(context).primaryColor, // 배경 어두워서 흰색이 잘 보여요
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildContent(BuildContext context) {
    final boxController = Provider.of<BoxController>(context, listen: false);

    // 박스가 로드됐고 selectedBoxId가 아직 null이면 첫 박스를 기본 선택
    if (selectedBoxId == null && boxController.boxes.isNotEmpty) {
      selectedBoxId = boxController.boxes.first['_id'];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Consumer<BoxController>(
          builder: (context, boxController, _) {
            if (boxController.isLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
              );
            }
            if (boxController.error != null) {
              return Text('에러: ${boxController.error}');
            }
            if (boxController.boxes.isEmpty) {
              return const Text('박스가 없습니다.');
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: boxController.boxes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 3.0,
              ),
              itemBuilder: (context, i) {
                final box = boxController.boxes[i];
                final isSelected = selectedBoxId == box['_id'];

                return GestureDetector(
                  onTap: _submitting
                      ? null
                      : () => setState(() => selectedBoxId = box['_id']),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isSelected
                          ? [const BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      box['name'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[800],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),

        const SizedBox(height: 40),
        const Center(
          child: Text(
            '구매 박스 수량',
            style: TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 20),
        Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: _submitting ? null : () => changeQuantity(-1),
                  icon: const Icon(Icons.remove),
                  iconSize: 22,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      quantity.toString(),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _submitting ? null : () => changeQuantity(1),
                  icon: const Icon(Icons.add),
                  iconSize: 22,
                ),
              ],
            ),
            const SizedBox(height: 40),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                quickButton('+5개 추가하기', 5),
                quickButton('+10개 추가하기', 10),
                quickButton('+50개 추가하기', 50),
                quickButton('MAX', 999 - quantity),
              ],
            ),
          ],
        ),

        const SizedBox(height: 50),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '보유 포인트',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              '${formatCurrency(availablePoints)} P',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 30),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              enabled: !_submitting,
              controller: pointsController,
              keyboardType: TextInputType.number,
              cursorColor: Colors.black,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              onChanged: (val) {
                String numeric = val.replaceAll(RegExp(r'[^0-9]'), '');
                int input = int.tryParse(numeric) ?? 0;
                if (input > availablePoints) input = availablePoints;
                if (input > boxPrice * quantity) input = boxPrice * quantity;

                final formatted = formatCurrency(input);

                if (pointsUsed != input) {
                  setState(() {
                    pointsUsed = input;
                  });
                }

                if (val != formatted) {
                  pointsController.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                }
              },
              decoration: InputDecoration(
                hintText: '0',
                suffixText: 'P',
                suffixStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  fontSize: 18,
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : applyMaxUsablePoints,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('전액사용', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 50),
        const Center(
          child: Text(
            '결제 수단',
            style: TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: paymentOption('계좌이체'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: paymentOption('신용/체크카드'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),
        CheckboxListTile(
          activeColor: Colors.black,
          checkColor: Colors.white,
          title: const Text(
            '모든 내용을 확인하였으며 결제에 동의합니다.',
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
          value: allAgreed,
          onChanged: _submitting
              ? null
              : (val) {
            setState(() {
              allAgreed = val ?? false;
              purchaseConfirmed = val ?? false;
              refundPolicyAgreed = val ?? false;
            });
          },
        ),
        CheckboxListTile(
          activeColor: Colors.black,
          checkColor: Colors.white,
          title: GestureDetector(
            onTap: _submitting ? null : () => Navigator.pushNamed(context, '/purchase_term'),
            child: const Text('구매 확인 동의', style: TextStyle(color: Colors.blue)),
          ),
          value: purchaseConfirmed,
          onChanged: _submitting ? null : (val) => setState(() => purchaseConfirmed = val ?? false),
        ),
        CheckboxListTile(
          activeColor: Colors.black,
          checkColor: Colors.white,
          title: GestureDetector(
            onTap: _submitting ? null : () => Navigator.pushNamed(context, '/refund_term'),
            child: const Text('교환/환불 정책 동의', style: TextStyle(color: Colors.blue)),
          ),
          value: refundPolicyAgreed,
          onChanged: _submitting ? null : (val) => setState(() => refundPolicyAgreed = val ?? false),
        ),

        const SizedBox(height: 50),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '총 결제금액',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            Text(
              '${formatCurrency(totalAmount)}원',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 30),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: _submitting ? null : handleSubmit,
          child: const Text('결제하기', style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Future<void> handleSubmit() async {
    // 기본 검증
    if (!allAgreed || !purchaseConfirmed || !refundPolicyAgreed) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('안내'),
          content: const Text('모든 약관에 동의해주세요.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('확인')),
          ],
        ),
      );
      return;
    }

    if (totalAmount > 0 && paymentMethod.isEmpty) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('안내'),
          content: const Text('결제 수단을 선택해주세요!'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('확인', style: TextStyle(color: Colors.blue))),
          ],
        ),
      );
      return;
    }

    final boxController = Provider.of<BoxController>(context, listen: false);
    final selectedBox = boxController.boxes.firstWhere(
          (b) => b['_id'] == selectedBoxId,
      orElse: () => null,
    );

    if (selectedBox == null) {
      await showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('박스 선택 오류'),
          content: Text('박스를 선택해주세요.'),
        ),
      );
      return;
    }

    // 🔒 로딩 시작
    setState(() => _submitting = true);

    try {
      // 결제/주문 제출
      await OrderScreenController.submitOrder(
        context: context,
        selectedBoxId: selectedBoxId,
        quantity: quantity,
        totalAmount: totalAmount,
        pointsUsed: pointsUsed,
        paymentMethod: paymentMethod,
      );
      // submitOrder 내부에서 페이지 전환/알림을 처리한다고 가정
    } catch (e) {
      // 에러 알림
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('결제 실패'),
          content: Text('결제 처리 중 오류가 발생했습니다.\n$e'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('확인')),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget quickButton(String label, int change) {
    return ElevatedButton(
      onPressed: _submitting ? null : () => changeQuantity(change),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: EdgeInsets.zero,
        minimumSize: const Size(150, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: Colors.black),
        ),
      ),
      child: Text(label, style: const TextStyle(color: Colors.black)),
    );
  }

  Widget paymentOption(String method) {
    final isSelected = paymentMethod == method;

    return GestureDetector(
      onTap: _submitting
          ? null
          : () {
        setState(() {
          paymentMethod = isSelected ? '' : method; // 이미 선택돼 있으면 해제
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
          method,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
