import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../routes/base_url.dart';

class DanalAuthWebView extends StatefulWidget {
  final String initialUrl;
  final void Function(String result)? onAuthComplete;

  const DanalAuthWebView({
    super.key,
    required this.initialUrl,
    this.onAuthComplete,
  });

  @override
  State<DanalAuthWebView> createState() => _DanalAuthWebViewState();
}

class _DanalAuthWebViewState extends State<DanalAuthWebView> {
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            if (request.url.contains('${BaseUrl.value}/danal-auth/callback')) {
              // ✅ 인증 완료 URL 감지
              final uri = Uri.parse(request.url);
              final result = uri.queryParameters['result'] ?? 'unknown';
              widget.onAuthComplete?.call(result);
              Navigator.of(context).pop();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('본인인증'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
