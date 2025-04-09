import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  Future<String> _loadTermsText() async {
    return await rootBundle.loadString('assets/terms/privacy.txt');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('개인정보처리방침'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      body: FutureBuilder(
        future: _loadTermsText(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('개인정보처리방침을 불러오는 중 오류가 발생했습니다.'));
          } else {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Text(
                  snapshot.data ?? '',
                  style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
