// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import '../../controllers/order_screen_controller.dart'; // OrderScreenController를 import
// import '../../controllers/product_controller.dart';
//
// class aOrderScreen extends StatefulWidget {
//   final String productId;
//   final List<Map<String, dynamic>> sizes;
//   final int totalAmount;
//
//   const aOrderScreen({
//     Key? key,
//     required this.productId,
//     required this.sizes,
//     required this.totalAmount,
//   }) : super(key: key);
//
//   @override
//   _aOrderScreenState createState() => _aOrderScreenState();
// }
//
// class _aOrderScreenState extends State<aOrderScreen> {
//   Map<String, dynamic>? productInfo;
//   bool isLoading = true;
//   String? address; // 배송지 정보
//   String code = ''; // 쿠폰 코드
//   int discountAmount = 0; // 할인 금액
//   bool isCouponValid = false; // 쿠폰 유효성
//   String? couponName;
//   String? discountType;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchProductInfo();
//     fetchShippingInfo();
//   }
//
//   Future<void> fetchProductInfo() async {
//     final productsController = ProductController();
//     try {
//       final info = await productsController.getProductInfoById(widget.productId);
//       setState(() {
//         productInfo = info;
//         isLoading = false;
//       });
//     } catch (e) {
//       print('제품 정보를 불러오는 중 오류 발생: $e');
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   Future<void> fetchShippingInfo() async {
//     try {
//       final shippingInfo = await OrderScreenController.getShipping();
//       if (shippingInfo.containsKey('shipping')) {
//         final shippingAddress = shippingInfo['shipping']['shippingAddress'];
//         setState(() {
//           address = shippingAddress['address'] ?? '';
//         });
//       }
//     } catch (e) {
//       print('기존 배송 정보 로드 실패: $e');
//     }
//   }
//
//   Future<void> applyCoupon() async {
//     if (code.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('쿠폰 코드를 입력하세요.')),
//       );
//       return;
//     }
//
//     try {
//       final response = await OrderScreenController.verifyCoupon(code);
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         setState(() {
//           discountAmount = data['discountValue'];
//           isCouponValid = true;
//           // 추가로 쿠폰 정보를 상태에 저장
//           couponName = data['name'] ?? '';
//           discountType = data['discountType'] ?? '';
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('쿠폰이 적용되었습니다!')),
//         );
//       } else {
//         setState(() {
//           discountAmount = 0;
//           isCouponValid = false;
//           couponName = '';
//           discountType = '';
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('유효하지 않은 쿠폰 코드입니다.')),
//         );
//       }
//     } catch (e) {
//       print('쿠폰 검증 중 오류 발생: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('쿠폰 검증 중 오류가 발생했습니다.')),
//       );
//     }
//   }
//
//
//   Future<void> _handleOrderSubmission() async {
//     if (address == null || address!.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('배송지를 입력해주세요.')),
//       );
//       return;
//     }
//
//     try {
//       final List<Map<String, dynamic>> items = [
//         {
//           'productId': widget.productId,
//           'productName': productInfo?['name'] ?? '제품명 없음',
//           'sizes': widget.sizes,
//           'price': productInfo?['price'] ?? 0,
//           'totalPrice': widget.totalAmount,
//         }
//       ];
//
//       final response = await OrderScreenController.addToOrder(
//         account: [],
//         items: items,
//         totalAmount: (widget.totalAmount - discountAmount).toDouble(),
//         address: address!,
//       );
//
//       if (response.statusCode == 201) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('주문이 성공적으로 완료되었습니다.')),
//         );
//         Navigator.pop(context); // 주문 성공 시 이전 화면으로 돌아가기
//       } else if (response.statusCode == 400) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('품절된 상품 입니다.')),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('주문 실패: ${response.body}')),
//         );
//       }
//     } catch (e) {
//       print('주문 중 오류 발생: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('주문 중 오류가 발생했습니다.')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         title: Text(
//           '주문 화면',
//           style: TextStyle(color: Colors.black, fontSize: 18),
//         ),
//         centerTitle: true,
//         iconTheme: IconThemeData(color: Colors.black),
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : productInfo == null
//           ? Center(child: Text('제품 정보를 불러올 수 없습니다.'))
//           : SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 20.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildSectionTitle('주문 상품 '),
//               Divider(thickness: 1),
//               _buildProductRow(productInfo!),
//               Divider(thickness: 1),
//               _buildClickableRow('배송지 정보', '확인'),
//               Divider(thickness: 1),
//               _buildSectionTitle('쿠폰'),
//               _buildCouponInputRow(),
//               Divider(thickness: 1),
//               _buildPriceDetails(widget.totalAmount - discountAmount),
//               Divider(thickness: 1),
//               SizedBox(height: 30),
//               _buildPayButton(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildCouponInputRow() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Expanded(
//               child: TextField(
//                 decoration: InputDecoration(
//                   labelText: '쿠폰 코드 입력',
//                   border: OutlineInputBorder(),
//                 ),
//                 onChanged: (value) {
//                   setState(() {
//                     code = value;
//                   });
//                 },
//               ),
//             ),
//             SizedBox(width: 10),
//             ElevatedButton(
//               onPressed: applyCoupon,
//               child: Text('적용'),
//             ),
//           ],
//         ),
//         SizedBox(height: 10),
//         if (isCouponValid) // 쿠폰이 유효한 경우에만 표시
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 '쿠폰 이름: $couponName',
//                 style: TextStyle(fontSize: 16, color: Colors.black),
//               ),
//               Text(
//                 '할인 금액: ${discountType == 'percentage' ? '$discountAmount%' : '₩$discountAmount'}',
//                 style: TextStyle(fontSize: 16, color: Colors.black),
//               ),
//             ],
//           ),
//       ],
//     );
//   }
//
//
//
//   Widget _buildPayButton() {
//     // 할인 금액 계산
//     final int discountedAmount = discountType == 'percentage'
//         ? (widget.totalAmount * (1 - discountAmount / 100)).toInt() // percentage 계산
//         : widget.totalAmount - discountAmount; // fixed 금액 계산
//
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: _handleOrderSubmission,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.red,
//           padding: EdgeInsets.symmetric(vertical: 15),
//         ),
//         child: Text(
//           '₩ $discountedAmount 결제하기',
//           style: TextStyle(color: Colors.white, fontSize: 16),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPriceDetails(int totalAmount) {
//     // 할인 금액 계산
//     final int discountedAmount = discountType == 'percentage'
//         ? (widget.totalAmount * (1 - (discountAmount.clamp(0, 100) / 100))).toInt() // 백분율을 0~100으로 제한
//         : (widget.totalAmount - discountAmount).clamp(0, widget.totalAmount).toInt(); // 고정 금액이 총 금액보다 크지 않도록 제한
//
//
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text('총 금액:'),
//         Text('₩ $discountedAmount'),
//       ],
//     );
//   }
//
//   Widget _buildClickableRow(String title, String actionText) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(title, style: TextStyle(fontSize: 16)),
//         GestureDetector(
//           onTap: () {
//             _showAddressInputSheet(context);
//           },
//           child: Text(actionText, style: TextStyle(color: Colors.blue)),
//         ),
//       ],
//     );
//   }
//
//   void _showAddressInputSheet(BuildContext context) async {
//     String name = '';
//     String phone = '';
//     String addressInput = ''; // 기존 address와 변수명 충돌 방지
//     String address2 = '';
//     String postalCode = '';
//
//     // 기존 배송 정보 가져오기
//     try {
//       final shippingInfo = await OrderScreenController.getShipping();
//       if (shippingInfo.containsKey('shipping')) {
//         final shippingAddress = shippingInfo['shipping']['shippingAddress'];
//         name = shippingAddress['name'] ?? '';
//         phone = shippingAddress['phone'] ?? '';
//         addressInput = shippingAddress['address'] ?? '';
//         address2 = shippingAddress['address2'] ?? '';
//         postalCode = shippingAddress['postalCode'] ?? '';
//       }
//     } catch (e) {
//       print('배송 정보 로드 실패: $e');
//     }
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (BuildContext context) {
//         return Padding(
//           padding: EdgeInsets.only(
//             top: 20,
//             left: 16,
//             right: 16,
//             bottom: MediaQuery.of(context).viewInsets.bottom,
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               TextField(
//                 controller: TextEditingController(text: name),
//                 decoration: InputDecoration(labelText: '수령인 이름'),
//                 onChanged: (value) {
//                   name = value;
//                 },
//               ),
//               SizedBox(height: 10),
//               TextField(
//                 controller: TextEditingController(text: phone),
//                 decoration: InputDecoration(labelText: '연락처'),
//                 onChanged: (value) {
//                   phone = value;
//                 },
//               ),
//               SizedBox(height: 10),
//               TextField(
//                 controller: TextEditingController(text: addressInput),
//                 decoration: InputDecoration(labelText: '주소'),
//                 onChanged: (value) {
//                   addressInput = value;
//                 },
//               ),
//               SizedBox(height: 10),
//               TextField(
//                 controller: TextEditingController(text: address2),
//                 decoration: InputDecoration(labelText: '상세 주소'),
//                 onChanged: (value) {
//                   address2 = value;
//                 },
//               ),
//               SizedBox(height: 10),
//               TextField(
//                 controller: TextEditingController(text: postalCode),
//                 decoration: InputDecoration(labelText: '우편번호'),
//                 onChanged: (value) {
//                   postalCode = value;
//                 },
//               ),
//               SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () async {
//                   // 서버에 데이터 저장
//                   try {
//                     final response = await OrderScreenController.addToShipping(
//                       name: name,
//                       phone: phone,
//                       address: addressInput,
//                       address2: address2,
//                       postalCode: postalCode,
//                     );
//
//                     if (response.statusCode == 201 || response.statusCode == 200) {
//                       // 성공적으로 저장된 경우, 상태 업데이트
//                       setState(() {
//                         address = addressInput; // 즉시 `address` 상태 업데이트
//                       });
//
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('배송지가 성공적으로 저장되었습니다.')),
//                       );
//                       Navigator.pop(context); // 입력 완료 후 닫기
//                     } else {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('배송지 저장에 실패했습니다: ${response.body}')),
//                       );
//                     }
//                   } catch (e) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('오류 발생: $e')),
//                     );
//                   }
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.black,
//                   minimumSize: Size(double.infinity, 50),
//                 ),
//                 child: Text('배송지 저장', style: TextStyle(color: Colors.white)),
//               ),
//               SizedBox(height: 20),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildSectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 15.0),
//       child: Text(
//         title,
//         style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//       ),
//     );
//   }
//
//   Widget _buildProductRow(Map<String, dynamic> productInfo) {
//     // 상품의 총 수량 계산
//     int totalQuantity = widget.sizes.fold<int>(0, (sum, item) => sum + (item['quantity'] as int? ?? 0));
//
//     return Row(
//       children: [
//         Container(
//           width: 80,
//           height: 80,
//           decoration: BoxDecoration(
//             border: Border.all(color: Colors.grey[300]!),
//             borderRadius: BorderRadius.circular(5),
//           ),
//           child: productInfo['mainImageUrl'] != null
//               ? Image.network(
//             productInfo['mainImageUrl'],
//             fit: BoxFit.cover,
//             errorBuilder: (context, error, stackTrace) {
//               return Icon(Icons.error, color: Colors.grey);
//             },
//           )
//               : Icon(Icons.image, size: 50, color: Colors.grey),
//         ),
//         SizedBox(width: 15),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 productInfo['category'] ?? '설명 없음',
//                 style: TextStyle(color: Colors.grey),
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//               Text(
//                 productInfo['name'] ?? '제품명 없음',
//                 style: TextStyle(color: Colors.black),
//               ),
//
//               SizedBox(height: 8),
//               Row(
//                 children: [
//                   Text(
//                     '₩ ${productInfo['price'] ?? '0'}',
//                     style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18),
//                   ),
//                   SizedBox(width: 8),
//                   Text(
//                     '수량: $totalQuantity개',
//                     style: TextStyle(color: Colors.grey, fontSize: 12),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildCouponRow() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text('쿠폰: 없음'),
//       ],
//     );
//   }
//
//
// }
