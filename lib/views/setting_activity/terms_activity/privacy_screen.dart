import 'package:flutter/material.dart';
import '../../../controllers/term_controller.dart'; // TermController 가져오기

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  Future<String?> _loadPrivacyTerm() async {
    return await TermController.getTermByCategory('privacyTerm');
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
      body: FutureBuilder<String?>(
        future: _loadPrivacyTerm(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text('개인정보처리방침을 불러오는 중 오류가 발생했습니다.'));
          } else {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Text(
                  snapshot.data!,
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
