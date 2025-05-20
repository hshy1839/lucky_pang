import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';


class DanalAuthWebView extends StatelessWidget {
  final String htmlContent;
  const DanalAuthWebView({required this.htmlContent, super.key});

  @override
  Widget build(BuildContext context) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(htmlContent);

    return Scaffold(
      appBar: AppBar(title: const Text("본인인증")),
      body: WebViewWidget(controller: controller),
    );
  }
}
