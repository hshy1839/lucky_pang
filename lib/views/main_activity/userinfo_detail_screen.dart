import 'package:flutter/material.dart';
import '../../controllers/userinfo_screen_controller.dart'; // UserInfoScreenController 경로에 맞게 수정

class UserDetailScreen extends StatefulWidget {
  @override
  _UserDetailScreenState createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();

  final UserInfoScreenController _userInfoController = UserInfoScreenController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 사용자 데이터 로드
  Future<void> _loadUserData() async {
    await _userInfoController.fetchUserInfo(context);
    setState(() {
      nameController.text = _userInfoController.nickname;
      usernameController.text = _userInfoController.email;
      phoneNumberController.text = _userInfoController.phoneNumber;
    });
  }

  // 사용자 데이터 저장
  Future<void> _saveUserData() async {
    try {
      final updatedName = nameController.text;
      final updatedPhoneNumber = phoneNumberController.text;

      // 서버에 사용자 정보 업데이트 요청
      await _userInfoController.updateUserInfo(context, updatedName, updatedPhoneNumber);

      // 저장 완료 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("사용자 정보가 성공적으로 저장되었습니다.")),
      );
    } catch (error) {
      // 오류 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("사용자 정보를 저장하는 중 오류가 발생했습니다.")),
      );
      print("사용자 정보 저장 오류: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "개인 정보 수정",
          style: TextStyle(color: Colors.black, fontSize: 15.0, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아이디 (읽기 전용)
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: "아이디",
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey), // 밑줄 색상 회색
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey), // 포커스 밑줄 색상 회색
                  ),
                ),
                readOnly: true,
              ),
              SizedBox(height: 16.0),

              // 이름
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "이름",
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey), // 밑줄 색상 회색
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey), // 포커스 밑줄 색상 회색
                  ),
                ),
              ),
              SizedBox(height: 16.0),

              // 전화번호
              TextField(
                controller: phoneNumberController,
                decoration: InputDecoration(
                  labelText: "전화번호",
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey), // 밑줄 색상 회색
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey), // 포커스 밑줄 색상 회색
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),

              SizedBox(height: 60.0),
              Center(
                child: ElevatedButton(
                  onPressed: _saveUserData,
                  child: Text(
                    "저장",
                    style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // 버튼 배경색
                    padding: EdgeInsets.symmetric(horizontal: 80.0, vertical: 20.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
