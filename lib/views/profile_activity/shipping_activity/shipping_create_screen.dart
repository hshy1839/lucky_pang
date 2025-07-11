import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../controllers/shipping_controller.dart';
import 'address_search_screen.dart';

class ShippingCreateScreen extends StatefulWidget {
  const ShippingCreateScreen({super.key});

  @override
  State<ShippingCreateScreen> createState() => _ShippingCreateScreenState();
}

class _ShippingCreateScreenState extends State<ShippingCreateScreen> {
  bool isDefault = false;
  bool isLoading = false;

  final TextEditingController recipientController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController memoController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController zipcodeController = TextEditingController();
  final TextEditingController detailAddressController = TextEditingController();
  final List<String> memoOptions = [
    '부재시 경비실에 맡겨주세요.',
    '부재시 택배함에 넣어주세요.',
    '부재시 집 앞에 놔주세요.',
    '배송 전 연락 바랍니다.',
    '파손의 위험이 있는 상품입니다. 배송 시 유의해주세요.',
    '직접입력'
  ];
  String? selectedMemoOption;

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(375, 812));
    if (isLoading) {
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
        body:  Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }
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
            _buildLabeledField(
              '수령인',
              TextField(
                controller: recipientController,
                decoration: _inputDecoration(),
              ),
            ),
            SizedBox(height: 20.h),
            _buildAddressFields(),
            SizedBox(height: 20.h),
            _buildLabeledField(
              '연락처',
              TextField(
                controller: phoneController,
                decoration: _inputDecoration(),
                keyboardType: TextInputType.phone,
              ),
            ),
            SizedBox(height: 20.h),
            _buildLabeledField(
              '메모',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(
                      canvasColor: Colors.white, // 드롭다운 전체 배경
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedMemoOption,
                      isExpanded: true,
                      decoration: _inputDecoration().copyWith(
                        hintText: '메모를 선택해 주세요',
                      ),
                      items: memoOptions.map((option) => DropdownMenuItem(
                        value: option,
                        child: Text(
                          option,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.black),
                        ),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedMemoOption = value;
                          if (value != '직접입력') {
                            memoController.text = value ?? '';
                          } else {
                            memoController.clear();
                          }
                        });
                      },
                    ),
                  ),
                  // ✅ 직접입력 선택 시에만 입력창 노출
                  if (selectedMemoOption == '직접입력')
                    Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: TextField(
                        controller: memoController,
                        decoration: _inputDecoration().copyWith(hintText: '메모를 직접 입력하세요'),
                        maxLength: 100,
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: 40.h),

            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: () async {
                  final recipient = recipientController.text.trim();
                  final phone = phoneController.text.trim();
                  final memo = (selectedMemoOption == '직접입력')
                      ? memoController.text.trim()
                      : (selectedMemoOption ?? '');
                  final postcode = zipcodeController.text.trim();
                  final address = addressController.text.trim();
                  final address2 = detailAddressController.text.trim();

                  if ([recipient, phone, postcode, address, address2].any((e) => e.isEmpty)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('모든 필수 정보를 입력해주세요.')),
                    );
                    return;
                  }

                  final success = await ShippingController.addShipping(
                    recipient: recipient,
                    phone: phone,
                    memo: memo,
                    postcode: postcode,
                    address: address,
                    address2: address2,
                    isDefault: isDefault,
                  );

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('배송지가 등록되었습니다.')),
                    );
                    Navigator.pop(context, true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('배송지 등록에 실패했습니다.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5C43),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: const Text(
                  '추가하기',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

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
                      onPressed: () async {
                        final selected = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddressSearchScreen(),
                          ),
                        );
                        if (selected != null) {
                          print("선택된 주소: $selected");
                          setState(() {
                            zipcodeController.text = selected['zonecode'] ?? '';
                            addressController.text = selected['address'] ?? '';
                          });
                        }
                      },
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
                      controller: zipcodeController,
                      readOnly: true,
                      decoration: _inputDecoration().copyWith(hintText: '우편번호'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: addressController,
                readOnly: true,
                decoration: _inputDecoration().copyWith(hintText: '기본주소'),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: detailAddressController,
                decoration: _inputDecoration().copyWith(hintText: '상세주소'),
              ),
            ],
          ),
        )
      ],
    );
  }

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
