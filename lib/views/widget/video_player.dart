import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class OpenBoxVideoScreen extends StatefulWidget {
  final String? orderId; // 단일 오픈
  final List<String>? orderIds; // 다수 오픈
  final bool isBatch;

  const OpenBoxVideoScreen({
    Key? key,
    this.orderId,
    this.orderIds,
    this.isBatch = false,
  }) : super(key: key);

  @override
  State<OpenBoxVideoScreen> createState() => _OpenBoxVideoScreenState();
}

class _OpenBoxVideoScreenState extends State<OpenBoxVideoScreen> {
  late VideoPlayerController _controller;
  bool _videoFinished = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/boxOpen_video.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });

    _controller.addListener(() {
      if (_controller.value.position >= _controller.value.duration && !_videoFinished) {
        _videoFinished = true;
        _navigateAfterVideo();
      }
    });
  }

  void _navigateAfterVideo() {
    if (widget.isBatch && widget.orderIds != null && widget.orderIds!.isNotEmpty) {
      Navigator.of(context).pushReplacementNamed(
        '/boxesOpen',
        arguments: {
          'orderIds': widget.orderIds!,
        },
      );
    } else if (widget.orderId != null) {
      Navigator.of(context).pushReplacementNamed(
        '/boxOpen',
        arguments: {'orderId': widget.orderId},
      );
    } else {
      Navigator.of(context).pop(); // 예외 처리
    }
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!_videoFinished) {
            _videoFinished = true;
            _navigateAfterVideo();
          }
        },
        child: _controller.value.isInitialized
            ? SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
        )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
