import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../routes/base_url.dart';


class BoxController with ChangeNotifier {
  List<dynamic> _boxes = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get boxes => _boxes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final FlutterSecureStorage storage = FlutterSecureStorage(); // ✅ SecureStorage 선언


  // ✅ 박스 리스트 불러오기
  Future<void> fetchBoxes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final token = await storage.read(key: 'token');

    try {
      final response = await http.get(
        Uri.parse('${BaseUrl.value}:7778/api/box'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['boxes'] is List) {
          _boxes = data['boxes'];
        } else {
          _error = '박스 데이터를 불러올 수 없습니다.';
        }
      } else {
        _error = '서버 오류: ${response.statusCode}';
      }
    } catch (e) {
      _error = '네트워크 오류: $e';
    }

    _isLoading = false;
    notifyListeners();
  }
}
