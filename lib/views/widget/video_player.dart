import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class OpenBoxVideoScreen extends StatefulWidget {
  final String orderId;
  const OpenBoxVideoScreen({Key? key, required this.orderId}) : super(key: key);

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

    _controller.addListener(() async {
      if (_controller.value.position >= _controller.value.duration && !_videoFinished) {
        _videoFinished = true;
        // 자연스럽게 영상에서 바로 boxOpen으로 push!
        Navigator.of(context).pushReplacementNamed(
          '/boxOpen',
          arguments: {'orderId': widget.orderId},
        );
      }
    });
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
      body: _controller.value.isInitialized
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
    );
  }
}
