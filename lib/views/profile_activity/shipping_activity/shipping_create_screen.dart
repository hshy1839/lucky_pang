import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ShippingCreateScreen extends StatefulWidget {
  const ShippingCreateScreen({super.key});

  @override
  State<ShippingCreateScreen> createState() => _ShippingCreateScreenState();
}

class _ShippingCreateScreenState extends State<ShippingCreateScreen> {
  bool isDefault = false;

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(375, 812));

    return Scaffold(
      appBar: AppBar(
        title: const Text('배송지 수정/배송지 추가',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            _buildLabeledField('수령인', TextField(decoration: _inputDecoration())),
            SizedBox(height: 20.h),
            _buildAddressFields(),
            SizedBox(height: 20.h),
            _buildLabeledField('연락처',
                TextField(decoration: _inputDecoration(), keyboardType: TextInputType.phone)),
            SizedBox(height: 24.h),
            Row(
              children: [
                Checkbox(
                  value: isDefault,
                  onChanged: (val) => setState(() => isDefault = val ?? false),
                ),
                const Text('기본배송지로 지정'),
              ],
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5C43),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: const Text(
                  '추가하기',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // ✅ 왼쪽 라벨 + 오른쪽 위젯 조합
  Widget _buildLabeledField(String label, Widget field) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70.w,
          child: Text(
            label,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: field),
      ],
    );
  }

  // ✅ 주소 3줄 (주소검색 버튼 포함)
  Widget _buildAddressFields() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70.w,
          child: Text(
            '주소',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 100.w,
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Text('주소검색', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: TextField(
                      decoration: _inputDecoration(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              TextField(decoration: _inputDecoration()),
              SizedBox(height: 8.h),
              TextField(decoration: _inputDecoration()),
            ],
          ),
        )
      ],
    );
  }

  // ✅ 사각형 입력창 스타일
  InputDecoration _inputDecoration() {
    return InputDecoration(
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Theme.of(context).primaryColor),
      ),
    );
  }
}
