import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../controllers/giftcode_controller.dart';
import 'package:flutter/services.dart';

class CreateGiftCodeScreen extends StatefulWidget {
  final String type; // 'box' 또는 'product'
  final String orderId;
  final String? boxId;
  final String? productId;

  const CreateGiftCodeScreen({
    super.key,
    required this.type,
    required this.orderId,
    this.boxId,
    this.productId,
  });

  @override
  State<CreateGiftCodeScreen> createState() => _CreateGiftCodeScreenState();
}

class _CreateGiftCodeScreenState extends State<CreateGiftCodeScreen> {
  String? giftCode;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingGiftCode(); // 🔍 기존 코드 확인
  }

  Future<void> _loadExistingGiftCode() async {
    setState(() => isLoading = true);

    final exists = await GiftCodeController.checkGiftCodeExists(
      type: widget.type,
      boxId: widget.boxId,
      productId: widget.productId,
      orderId: widget.orderId,
    );

    if (!mounted) return;

    if (exists) {
      final result = await GiftCodeController.createGiftCode(
        type: widget.type,
        boxId: widget.boxId,
        productId: widget.productId,
        orderId: widget.orderId,
      );

      if (result?['success'] == true && result?['code'] != null) {
        setState(() {
          giftCode = result!['code'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _generateGiftCode() async {
    setState(() => isLoading = true);

    final result = await GiftCodeController.createGiftCode(
      type: widget.type,
      boxId: widget.boxId,
      productId: widget.productId,
      orderId: widget.orderId,
    );

    if (!mounted) return;

    final code = result?['code'];
    final success = result?['success'];

    if (success == true && code != null) {
      setState(() {
        giftCode = code;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result?['message'] ?? '코드 확인 중 오류')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(375, 812));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
        title: Text(
          '선물하기',
          style: TextStyle(color: Colors.black, fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 40.h),
          _buildGiftBoxIcon(),
          SizedBox(height: 32.h),
          Text(widget.type == 'box' ? '럭키박스' : '상품', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 8.h),
          Text(
            widget.type == 'box'
                ? '너에겐 어떤 행운이 등장할까?… 🥲'
                : '이 선물을 누군가에게 전달해보세요!',
            style: TextStyle(fontSize: 14.sp, color: Colors.black),
          ),
          SizedBox(height: 60.h),

          if (giftCode == null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: ElevatedButton(
                onPressed: isLoading ? null : _generateGiftCode,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48.h),
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('선물 코드 생성하기', style: TextStyle(color: Colors.white, fontSize: 16.sp)),
              ),
            ),

          if (giftCode != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Column(
                children: [
                  Text('선물 코드가 생성되었습니다:', style: TextStyle(fontSize: 14.sp)),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            giftCode!,
                            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.copy, size: 20.sp),
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: giftCode!));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('코드가 복사되었습니다!')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGiftBoxIcon() {
    return Center(
      child: Container(
        width: 150.w,
        height: 150.w,
        decoration: BoxDecoration(
          color: const Color(0xFFFF5C43),
          borderRadius: BorderRadius.circular(40.r),
        ),
        child: Icon(Icons.card_giftcard, size: 120.sp, color: Colors.white),
      ),
    );
  }
}

