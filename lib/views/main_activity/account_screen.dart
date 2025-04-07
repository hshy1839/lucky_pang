import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AccountScreen extends StatefulWidget {
  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  List<Map<String, String>> accounts = []; // 계좌 정보를 저장하는 리스트
  bool _isLoading = true; // 로딩 상태 관리

  @override
  void initState() {
    super.initState();
    _fetchAccounts(); // 초기화 시 계좌 정보 가져오기
  }

  Future<void> _fetchAccounts() async {
    try {
      final response = await http.get(
        Uri.parse('http://172.30.50.104:7776/api/accountInfo'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body)['accounts'];

        setState(() {
          accounts = responseData.map((account) {
            return {
              'bankName': account['bankName']?.toString() ?? '',
              'accountHolder': account['accountName']?.toString() ?? '',
              'accountNumber': account['accountNumber']?.toString() ?? '',
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch account data');
      }
    } catch (e) {
      print('계좌 정보를 불러오는 중 오류 발생: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '계좌 정보',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : accounts.isEmpty
          ? Center(
        child: Text(
          '등록된 계좌 정보가 없습니다.',
          style: TextStyle(
            fontSize: 16.0,
            color: Colors.grey,
          ),
        ),
      )
          : ListView.builder(
        itemCount: accounts.length,
        itemBuilder: (context, index) {
          final account = accounts[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Card(
              color: Colors.white, // 카드 배경색을 흰색으로 설정
              elevation: 2.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '은행명',
                      style: TextStyle(fontSize: 15.0, color: Colors.black),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      account['bankName'] ?? '은행명 없음',
                      style: TextStyle(
                          fontSize: 20.0, color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      '예금주',
                      style: TextStyle(fontSize: 15.0, color: Colors.black),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      account['accountHolder'] ?? '예금주 없음',
                      style: TextStyle(
                          fontSize: 20.0, color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      '계좌번호',
                      style: TextStyle(fontSize: 15.0, color: Colors.black),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      account['accountNumber'] ?? '계좌번호 없음',
                      style: TextStyle(
                          fontSize: 28.0, color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 35.0),
                    Text(
                      '* 위에 계좌에 입금해주시면 됩니다.',
                      style: TextStyle(fontSize: 14.0, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
