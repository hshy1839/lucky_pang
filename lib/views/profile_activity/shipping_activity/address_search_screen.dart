import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AddressSearchScreen extends StatelessWidget {
  const AddressSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterPostMessage',
        onMessageReceived: (message) {
          final result = jsonDecode(message.message);
          Navigator.pop(context, result); // zonecode, address 전달
        },
      )
      ..loadRequest(Uri.parse('http://192.168.219.107:7778/kakao_postcode.html')); // 🔥 변경된 부분

    return Scaffold(
      appBar: AppBar(
        title: const Text('주소 검색'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
        elevation: 0,
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
