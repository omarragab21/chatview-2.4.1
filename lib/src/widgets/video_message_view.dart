import 'dart:io';

import 'package:chatview_utils/chatview_utils.dart';
import 'package:chatview/src/extensions/extensions.dart';
import 'package:chatview/src/models/models.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'reaction_widget.dart';
import 'share_icon.dart';

class VideoMessageView extends StatefulWidget {
  const VideoMessageView({
    Key? key,
    required this.message,
    required this.isMessageBySender,
    this.videoMessageConfig,
    this.messageReactionConfig,
    this.highlightVideo = false,
    this.highlightScale = 1.2,
  }) : super(key: key);

  /// Provides message instance of chat.
  final Message message;

  /// Represents current message is sent by current user.
  final bool isMessageBySender;

  /// Provides configuration for video message appearance.
  final VideoMessageConfiguration? videoMessageConfig;

  /// Provides configuration of reaction appearance in chat bubble.
  final MessageReactionConfiguration? messageReactionConfig;

  /// Represents flag of highlighting video when user taps on replied video.
  final bool highlightVideo;

  /// Provides scale of highlighted video when user taps on replied video.
  final double highlightScale;

  @override
  State<VideoMessageView> createState() => _VideoMessageViewState();
}

class _VideoMessageViewState extends State<VideoMessageView> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;

  String get videoUrl => widget.message.message;

  Widget get iconButton => ShareIcon(
    shareIconConfig: widget.videoMessageConfig?.shareIconConfig,
    imageUrl: videoUrl,
  );

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    if (videoUrl.isUrl) {
      _controller = VideoPlayerController.network(videoUrl);
    } else if (videoUrl.fromMemory) {
      _controller = VideoPlayerController.file(File(videoUrl));
    } else {
      _controller = VideoPlayerController.file(File(videoUrl));
    }

    try {
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  void _openFullScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FullScreenVideoView(
              videoUrl: videoUrl,
              controller: _controller,
            ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
          widget.isMessageBySender
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
      children: [
        if (widget.isMessageBySender &&
            !(widget.videoMessageConfig?.hideShareIcon ?? false))
          iconButton,
        Stack(
          children: [
            GestureDetector(
              onTap: _togglePlayPause,
              child: Transform.scale(
                scale: 1.0,
                alignment:
                    widget.isMessageBySender
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                child: Container(
                  padding:
                      widget.videoMessageConfig?.padding ?? EdgeInsets.zero,
                  margin:
                      widget.videoMessageConfig?.margin ??
                      EdgeInsets.only(
                        top: 6,
                        right: widget.isMessageBySender ? 6 : 0,
                        left: widget.isMessageBySender ? 0 : 6,
                        bottom:
                            widget.message.reaction.reactions.isNotEmpty
                                ? 15
                                : 0,
                      ),
                  height: widget.videoMessageConfig?.height ?? 200,
                  width: widget.videoMessageConfig?.width ?? 150,
                  child: ClipRRect(
                    borderRadius:
                        widget.videoMessageConfig?.borderRadius ??
                        BorderRadius.circular(14),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isInitialized)
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: VideoPlayer(_controller),
                          )
                        else
                          const Center(child: CircularProgressIndicator()),
                        if (_isInitialized)
                          IconButton(
                            icon: Icon(
                              _isPlaying
                                  ? widget
                                          .videoMessageConfig
                                          ?.pauseIcon
                                          ?.icon ??
                                      Icons.pause
                                  : widget.videoMessageConfig?.playIcon?.icon ??
                                      Icons.play_arrow,
                              color: Colors.white,
                              size: 50,
                            ),
                            onPressed: () {
                              if (!_isPlaying) {
                                _openFullScreen();
                              } else {
                                _togglePlayPause();
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (widget.message.reaction.reactions.isNotEmpty)
              ReactionWidget(
                isMessageBySender: widget.isMessageBySender,
                reaction: widget.message.reaction,
                messageReactionConfig: widget.messageReactionConfig,
              ),
          ],
        ),
        if (!widget.isMessageBySender &&
            !(widget.videoMessageConfig?.hideShareIcon ?? false))
          iconButton,
      ],
    );
  }
}

class FullScreenVideoView extends StatefulWidget {
  const FullScreenVideoView({
    Key? key,
    required this.videoUrl,
    required this.controller,
  }) : super(key: key);

  final String videoUrl;
  final VideoPlayerController controller;

  @override
  State<FullScreenVideoView> createState() => _FullScreenVideoViewState();
}

class _FullScreenVideoViewState extends State<FullScreenVideoView> {
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: widget.controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(widget.controller),
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  color: Colors.transparent,
                  child: Center(
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _togglePlayPause() {
    setState(() {
      if (widget.controller.value.isPlaying) {
        widget.controller.pause();
        _isPlaying = false;
      } else {
        widget.controller.play();
        _isPlaying = true;
      }
    });
  }
}
