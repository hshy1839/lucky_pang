import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import '../../../controllers/shipping_controller.dart';
import '../../controllers/point_controller.dart';
import '../../controllers/shipping_order_controller.dart';
import '../../controllers/product_controller.dart'; // 👈 추가: 상세조회 사용
import '../../routes/base_url.dart';
import '../widget/shipping_card.dart';

class DeliveryRequestScreen extends StatefulWidget {
  @override
  _DeliveryRequestScreenState createState() => _DeliveryRequestScreenState();
}

class _DeliveryRequestScreenState extends State<DeliveryRequestScreen> {
  // ── 상태값
  int usedPoints = 0;
  int totalPoints = 0;
  String selectedPayment = '';
  bool agreedAll = false;
  bool agreedPurchase = false;
  bool agreedReturn = false;

  final TextEditingController _pointsController = TextEditingController();
  final PointController _pointController = PointController();
  final ProductController _productController = ProductController(); // 👈 추가
  final numberFormat = NumberFormat('#,###');

  Map<String, dynamic>? selectedShipping;
  bool isLoading = true;
  String? selectedShippingId;
  List<Map<String, dynamic>> shippingList = [];

  late Map<String, dynamic> product; // 네비 args에서 받는 초기 product(간략)
  late String orderId;
  late dynamic box;

  // 서버 상세 조회로 받은 배송비를 별도 보관(없으면 null)
  int? _shippingFeeFromApi;

  // ── 유틸
  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().replaceAll(RegExp(r'[^0-9-]'), '')) ?? 0;
  }

  int get shippingFee {
    // API 우선, 없으면 product, 그래도 없으면 box
    final apiFee = _shippingFeeFromApi;
    if (apiFee != null && apiFee > 0) return apiFee;
    final pFee = _asInt(product['shippingFee']);
    if (pFee > 0) return pFee;
    return _asInt(box?['shippingFee']);
  }

  int get totalAmount {
    final calculated = shippingFee - usedPoints;
    return calculated < 0 ? 0 : calculated;
  }

  // ── 라이프사이클
  @override
  void initState() {
    super.initState();
    _fetchShipping();
    _fetchUserPoints();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // args 읽고 상품 상세 조회 시작
    final args =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      product = Map<String, dynamic>.from(args['product'] ?? {});
      orderId = args['orderId']?.toString() ?? '';
      box = args['box'];

      // productId 결정: product['_id'] 우선, 없으면 args['productId']
      final productId =
          product['_id']?.toString() ?? args['productId']?.toString();

      if (productId != null && productId.isNotEmpty) {
        _loadProductDetail(productId); // 👈 상세 조회로 shippingFee 받아옴
      } else {
        // productId가 없는 경우에도 UI는 뜨도록 isLoading만 내려줌
        setState(() => isLoading = false);
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  // ── 데이터 로드
  Future<void> _loadProductDetail(String productId) async {
    try {
      final detail = await _productController.getProductInfoById(productId);
      // 안전하게 숫자 변환
      final fee = _asInt(detail['shippingFee']);
      setState(() {
        _shippingFeeFromApi = fee > 0 ? fee : null;

        // 화면에서 사용할 product에 일부 필드 보강(이름/브랜드/이미지 등도 최신화 원하면 아래 merge)
        if (detail.isNotEmpty) {
          product = {
            ...product,
            'name': detail['name'] ?? product['name'],
            'brand': detail['brand'] ?? product['brand'],
            'mainImageUrl': detail['mainImageUrl'] ?? product['mainImageUrl'],
            'shippingFee': detail['shippingFee'] ?? product['shippingFee'],
          };
        }
        isLoading = false;
      });
    } catch (e) {
      debugPrint('[DeliveryRequest] getProductInfoById error: $e');
      // 실패해도 UI는 뜨게
      setState(() => isLoading = false);
    }
  }

  void _fetchUserPoints() async {
    final userId = await _getUserId();
    if (userId != null) {
      final total = await _pointController.fetchUserTotalPoints(userId);
      if (!mounted) return;
      setState(() => totalPoints = total);
    }
  }

  Future<String?> _getUserId() async {
    const _storage = FlutterSecureStorage();
    return await _storage.read(key: 'userId');
  }

  Future<void> _fetchShipping() async {
    final list = await ShippingController.getUserShippings();
    if (!mounted) return;
    setState(() {
      shippingList = list;
      selectedShippingId = list.isNotEmpty
          ? (list.firstWhere((s) => s['is_default'] == true,
          orElse: () => list.first))['_id']
          : null;
    });
  }

  void applyMaxUsablePoints() {
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

  // ── 이미지 URL 유틸
  String _sanitizeAbsolute(String value) {
    final v = value.trim();
    if (v.isEmpty) return v;
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    final httpsIdx = v.indexOf('https://');
    if (httpsIdx > 0) return v.substring(httpsIdx);
    final httpIdx = v.indexOf('http://');
    if (httpIdx > 0) return v.substring(httpIdx);
    if ((v.startsWith('"') && v.endsWith('"')) ||
        (v.startsWith("'") && v.endsWith("'"))) {
      return v.substring(1, v.length - 1);
    }
    return v;
  }

  String get _server => '${BaseUrl.value}:7778';

  String? _buildProductImageUrl(dynamic raw) {
    if (raw == null) return null;
    String s = raw.toString().trim();
    if (s.isEmpty) return null;

    s = _sanitizeAbsolute(s);

    if (s.startsWith('$_server/media/')) return s;
    if (s.startsWith('$_server/uploads/')) return s;

    if (s.startsWith('/uploads/')) return '$_server$s';

    if (s.startsWith('http://') || s.startsWith('https://')) {
      final uri = Uri.tryParse(s);
      final lower = s.toLowerCase();
      final isHeic = lower.endsWith('.heic') || lower.contains('.heic?');

      if (isHeic) {
        final rawPath = uri?.path ?? '';
        final key = rawPath.startsWith('/') ? rawPath.substring(1) : rawPath;
        final encodedKey = key.split('/').map(Uri.encodeComponent).join('/');
        final out = '$_server/media/$encodedKey';
        debugPrint('[DeliveryRequest] HEIC proxy: $out');
        return out;
      }
      return s;
    }

    final key = s.startsWith('/') ? s.substring(1) : s;
    final encodedKey = key.split('/').map(Uri.encodeComponent).join('/');
    return '$_server/media/$encodedKey';
  }

  // ── UI
  @override
  Widget build(BuildContext context) {
    final args =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('배송신청')),
        body: const Center(child: Text('상품 정보가 없습니다')),
      );
    }

    final productImgUrl = _buildProductImageUrl(
      product['mainImageUrl'] ?? product['mainImage'] ?? product['image'],
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('배송신청')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 상단 상품 정보
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: SizedBox(
                      width: 100.w,
                      height: 100.w,
                      child: productImgUrl != null
                          ? CachedNetworkImage(
                        imageUrl: productImgUrl,
                        fit: BoxFit.cover,
                        placeholder: (c, _) => const Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        ),
                        errorWidget: (c, _, __) =>
                            Container(color: Colors.grey[200]),
                      )
                          : Container(color: Colors.grey[200]),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('[${product['brand'] ?? ''}] ${product['name'] ?? ''}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp)),
                        SizedBox(height: 8.h),
                        Text('배송비: ${numberFormat.format(shippingFee)}원'),
                        const Text('수량: 1개'),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 50.h),

              // ── 배송지 추가
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.pushNamed(context, '/shippingCreate');
                  await _fetchShipping();
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('배송지 추가하기',
                    style: TextStyle(color: Colors.white)),
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
                                selectedShippingId = shippingList.isNotEmpty
                                    ? shippingList.first['_id']
                                    : null;
                                selectedShipping = shippingList.isNotEmpty
                                    ? shippingList.first
                                    : null;
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

              // ── 포인트 영역
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

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pointsController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                          fontSize: 16.sp, fontWeight: FontWeight.bold),
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
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 16.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide:
                          BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide:
                          BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        String numeric =
                        val.replaceAll(RegExp(r'[^0-9]'), '');
                        int input = int.tryParse(numeric) ?? 0;
                        if (input > totalPoints) input = totalPoints;
                        if (input > shippingFee) input = shippingFee;

                        final formatted = numberFormat.format(input);

                        if (usedPoints != input) {
                          setState(() => usedPoints = input);
                        }
                        if (val != formatted) {
                          _pointsController.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(
                                offset: formatted.length),
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
                    child: const Text('전액사용',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),

              SizedBox(height: 40),

              // ── 결제수단
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

              // ── 약관
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
                  child: const Text('구매 확인 동의',
                      style: TextStyle(color: Colors.blue)),
                ),
                value: agreedPurchase,
                onChanged: (val) =>
                    setState(() => agreedPurchase = val ?? false),
              ),
              CheckboxListTile(
                activeColor: Colors.black,
                checkColor: Colors.white,
                title: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/refund_term'),
                  child: const Text('교환/환불 정책 동의',
                      style: TextStyle(color: Colors.blue)),
                ),
                value: agreedReturn,
                onChanged: (val) =>
                    setState(() => agreedReturn = val ?? false),
              ),

              SizedBox(height: 50),

              // ── 합계
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
                          backgroundColor: Colors.white,
                          title: const Text('안내'),
                          content: const Text('모든 약관에 동의해주세요.'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(),
                              child: const Text('확인',
                                  style: TextStyle(color: Colors.blue)),
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
                          backgroundColor: Colors.white,
                          title: const Text('안내'),
                          content: const Text('배송지를 선택해주세요.'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(),
                              child: const Text('확인',
                                  style: TextStyle(color: Colors.blue)),
                            )
                          ],
                        ),
                      );
                      return;
                    }
                    if (totalAmount > 0 && selectedPayment.isEmpty) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: Colors.white,
                          title: const Text('안내'),
                          content: const Text('결제 수단을 선택해주세요.'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(),
                              child: const Text('확인',
                                  style: TextStyle(color: Colors.blue)),
                            )
                          ],
                        ),
                      );
                      return;
                    }

                    await ShippingOrderController.submitShippingOrder(
                      context: context,
                      orderId: orderId,
                      shippingId: selectedShippingId!,
                      totalAmount: totalAmount,
                      pointsUsed: usedPoints,
                      paymentMethod:
                      totalAmount == 0 ? 'point' : selectedPayment,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: const Text('결제하기',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),

              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── 결제수단 버튼
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
