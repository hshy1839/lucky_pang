import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../controllers/qna_controller.dart';

class QnaDetailScreen extends StatefulWidget {
  final String questionId;
  final String title;
  final String date;
  final String content;

  QnaDetailScreen({
    required this.questionId,
    required this.title,
    required this.date,
    required this.content,
  });

  @override
  _QnaDetailScreenState createState() => _QnaDetailScreenState();
}

class _QnaDetailScreenState extends State<QnaDetailScreen> {
  final QnaController _controller = QnaController();
  List<Map<String, dynamic>> answers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnswers();
  }

  Future<void> _fetchAnswers() async {
    try {
      final fetchedAnswers = await _controller.getAnswersByQuestionId(widget.questionId);
      setState(() {
        answers = fetchedAnswers;
        isLoading = false;
      });
    } catch (e) {
      print('답변을 가져오는 중 오류 발생: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '문의 상세',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // 제목
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            // 날짜
            Text(
              widget.date,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 10),
            // 밑줄 추가
            Container(
              height: 1,
              color: Colors.grey[300],
            ),
            SizedBox(height: 16),
            // 문의 내용
            Text(
              widget.content,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 150),
            // 답변 섹션
            isLoading
                ? Center(child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ))
                : answers.isEmpty
                ? Text(
              '아직 답변이 없습니다.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '답변',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 10),
                ...answers.map((answer) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${DateFormat('yyyy-MM-dd').format(DateTime.parse(answer['createdAt']))}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          height: 1,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 8),
                        Text(
                          answer['body'] ?? '답변 내용 없음',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),

                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
