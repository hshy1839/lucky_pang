import 'package:flutter/material.dart';

import '../../controllers/qna_controller.dart'; // QnaController 경로에 맞게 수정

class QnaCreateScreen extends StatefulWidget {
  @override
  _QnaCreateScreenState createState() => _QnaCreateScreenState();
}

class _QnaCreateScreenState extends State<QnaCreateScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final QnaController _qnaController = QnaController();

  void _submitQna() async {
    final String title = _titleController.text.trim();
    final String body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('제목과 내용을 모두 입력해주세요.')),
      );
      return;
    }

    final success = await _qnaController.createQna(title, body);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('문의가 성공적으로 등록되었습니다.')),
      );
      Navigator.pop(context); // 이전 화면으로 이동
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('문의 등록에 실패했습니다. 다시 시도해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '1:1 문의',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _bodyController,
              decoration: InputDecoration(
                labelText: '내용',
                border: OutlineInputBorder(),
              ),
              maxLines: 8,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _submitQna,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: Text(
                '등록하기',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
