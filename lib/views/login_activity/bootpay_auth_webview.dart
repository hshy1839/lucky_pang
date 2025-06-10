import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BootpayAuthWebView extends StatelessWidget {
  final String url;
  const BootpayAuthWebView({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('본인인증'),
      ),
      body: WebViewWidget(controller: WebViewController()..loadRequest(Uri.parse(url))),
    );
  }
}
