import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:chatview/chatview.dart';
import 'package:chatview/src/widgets/reaction_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class VoiceMessageView extends StatefulWidget {
  const VoiceMessageView({
    Key? key,
    required this.screenWidth,
    required this.message,
    required this.isMessageBySender,
    this.inComingChatBubbleConfig,
    this.outgoingChatBubbleConfig,
    this.onMaxDuration,
    this.messageReactionConfig,
    this.config,
  }) : super(key: key);

  /// Provides configuration related to voice message.
  final VoiceMessageConfiguration? config;

  /// Allow user to set width of chat bubble.
  final double screenWidth;

  /// Provides message instance of chat.
  final Message message;
  final Function(int)? onMaxDuration;

  /// Represents current message is sent by current user.
  final bool isMessageBySender;

  /// Provides configuration of reaction appearance in chat bubble.
  final MessageReactionConfiguration? messageReactionConfig;

  /// Provides configuration of chat bubble appearance from other user of chat.
  final ChatBubble? inComingChatBubbleConfig;

  /// Provides configuration of chat bubble appearance from current user of chat.
  final ChatBubble? outgoingChatBubbleConfig;

  @override
  State<VoiceMessageView> createState() => _VoiceMessageViewState();
}

class _VoiceMessageViewState extends State<VoiceMessageView> {
  late PlayerController controller;
  late StreamSubscription<PlayerState> playerStateSubscription;
  String? _cachedFilePath;
  bool _isInitializing = true;

  final ValueNotifier<PlayerState> _playerState = ValueNotifier(
    PlayerState.stopped,
  );

  PlayerState get playerState => _playerState.value;

  PlayerWaveStyle playerWaveStyle = const PlayerWaveStyle(scaleFactor: 70);

  @override
  void initState() {
    super.initState();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    setState(() {
      _isInitializing = true;
    });

    final messagePath = widget.message.message;

    if (messagePath.startsWith('http')) {
      // Handle remote audio file
      _cachedFilePath = await _getCachedFilePath(messagePath);
      if (_cachedFilePath == null) {
        // Download and cache the file
        _cachedFilePath = await _downloadAndCacheFile(messagePath);
      }
    } else {
      // Handle local audio file
      _cachedFilePath = messagePath;
    }

    if (_cachedFilePath != null) {
      controller =
          PlayerController()
            ..preparePlayer(
              path: _cachedFilePath!,
              noOfSamples:
                  widget.config?.playerWaveStyle?.getSamplesForWidth(
                    widget.screenWidth * 0.5,
                  ) ??
                  playerWaveStyle.getSamplesForWidth(widget.screenWidth * 0.5),
            ).whenComplete(() {
              widget.onMaxDuration?.call(controller.maxDuration);
              if (mounted) {
                setState(() {
                  _isInitializing = false;
                });
              }
            });
      playerStateSubscription = controller.onPlayerStateChanged.listen(
        (state) => _playerState.value = state,
      );
    } else {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<String?> _getCachedFilePath(String url) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final fileName = url.split('/').last;
      final file = File('${cacheDir.path}/$fileName');
      if (await file.exists()) {
        return file.path;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting cached file path: $e');
      return null;
    }
  }

  Future<String?> _downloadAndCacheFile(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final cacheDir = await getTemporaryDirectory();
        final fileName = url.split('/').last;
        final file = File('${cacheDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      }
      return null;
    } catch (e) {
      debugPrint('Error downloading file: $e');
      return null;
    }
  }

  @override
  void dispose() {
    playerStateSubscription.cancel();
    controller.dispose();
    _playerState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration:
              widget.config?.decoration ??
              BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color:
                    widget.isMessageBySender
                        ? widget.outgoingChatBubbleConfig?.color
                        : widget.inComingChatBubbleConfig?.color,
              ),
          padding:
              widget.config?.padding ??
              const EdgeInsets.symmetric(horizontal: 8),
          margin:
              widget.config?.margin ??
              EdgeInsets.symmetric(
                horizontal: 8,
                vertical: widget.message.reaction.reactions.isNotEmpty ? 15 : 0,
              ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isInitializing)
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else
                ValueListenableBuilder<PlayerState>(
                  builder: (context, state, child) {
                    return IconButton(
                      onPressed: _playOrPause,
                      icon:
                          state.isStopped ||
                                  state.isPaused ||
                                  state.isInitialised
                              ? widget.config?.playIcon ??
                                  const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                  )
                              : widget.config?.pauseIcon ??
                                  const Icon(Icons.stop, color: Colors.white),
                    );
                  },
                  valueListenable: _playerState,
                ),
              if (!_isInitializing)
                AudioFileWaveforms(
                  size: Size(widget.screenWidth * 0.50, 60),
                  playerController: controller,
                  waveformType: WaveformType.fitWidth,
                  playerWaveStyle:
                      widget.config?.playerWaveStyle ?? playerWaveStyle,
                  padding:
                      widget.config?.waveformPadding ??
                      const EdgeInsets.only(right: 10),
                  margin: widget.config?.waveformMargin,
                  animationCurve:
                      widget.config?.animationCurve ?? Curves.easeIn,
                  animationDuration:
                      widget.config?.animationDuration ??
                      const Duration(milliseconds: 500),
                  enableSeekGesture: widget.config?.enableSeekGesture ?? true,
                ),
            ],
          ),
        ),
        if (widget.message.reaction.reactions.isNotEmpty)
          ReactionWidget(
            isMessageBySender: widget.isMessageBySender,
            reaction: widget.message.reaction,
            messageReactionConfig: widget.messageReactionConfig,
          ),
      ],
    );
  }

  void _playOrPause() {
    assert(
      defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android,
      "Voice messages are only supported with android and ios platform",
    );
    if (playerState.isInitialised ||
        playerState.isPaused ||
        playerState.isStopped) {
      controller.startPlayer();
      controller.setFinishMode(finishMode: FinishMode.pause);
    } else {
      controller.pausePlayer();
    }
  }
}
