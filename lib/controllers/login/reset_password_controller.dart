import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../routes/base_url.dart';

class ResetPasswordController {
  static Future<bool> sendTemporaryPassword({
    required String email,
    required BuildContext context,
  }) async {
    final url = Uri.parse('${BaseUrl.value}:7778/api/users/reset-password');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        _showDialog(context, '성공', '임시 비밀번호가 이메일로 전송되었습니다.');
        return true;
      } else {
        final data = jsonDecode(response.body);
        _showDialog(context, '실패', data['message'] ?? '비밀번호 재설정에 실패했습니다.');
        return false;
      }
    } catch (e) {
      _showDialog(context, '오류', '서버 통신 중 오류가 발생했습니다.');
      return false;
    }
  }

  static void _showDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
