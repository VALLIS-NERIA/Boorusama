import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

//TODO: implement caching video
class PostVideo extends StatefulWidget {
  PostVideo({
    Key key,
    @required this.videoSourceUrl,
    @required this.aspectRatio,
  }) : super(key: key);

  final String videoSourceUrl;
  final double aspectRatio;

  @override
  _PostVideoState createState() => _PostVideoState();
}

class _PostVideoState extends State<PostVideo> {
  VideoPlayerController _videoPlayerController;
  ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    _videoPlayerController =
        VideoPlayerController.network(widget.videoSourceUrl);
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      aspectRatio: widget.aspectRatio,
      autoPlay: true,
      looping: true,
      // Try playing around with some of these other options:

      // showControls: false,
      // materialProgressColors: ChewieProgressColors(
      //   playedColor: Colors.red,
      //   handleColor: Colors.blue,
      //   backgroundColor: Colors.grey,
      //   bufferedColor: Colors.lightGreen,
      // ),
      // placeholder: Container(
      //   color: Colors.grey,
      // ),
      // autoInitialize: true,
    );
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Chewie(controller: _chewieController),
    );
  }
}
