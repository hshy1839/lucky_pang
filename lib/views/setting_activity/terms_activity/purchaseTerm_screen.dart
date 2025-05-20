import 'package:flutter/material.dart';
import '../../../controllers/term_controller.dart'; // TermController 가져오기

class PurchasetermScreen extends StatelessWidget {
  const PurchasetermScreen({super.key});

  Future<String?> _loadPurchaseTerm() async {
    return await TermController.getTermByCategory('purchaseTerm');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('구매 확인 약관'),
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
        future: _loadPurchaseTerm(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text('구매 확인 약관을 불러오는 중 오류가 발생했습니다.'));
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
