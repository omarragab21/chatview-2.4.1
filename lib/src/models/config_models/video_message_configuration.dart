import 'package:flutter/material.dart';
import '../../values/typedefs.dart';
import 'image_message_configuration.dart';

/// A configuration model class for video message bubble.
class VideoMessageConfiguration {
  const VideoMessageConfiguration({
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
    this.margin,
    this.decoration,
    this.height,
    this.width,
    this.borderRadius,
    this.playIcon,
    this.pauseIcon,
    this.hideShareIcon = false,
    this.shareIconConfig,
    this.onTap,
  });

  /// Applies padding to message bubble.
  final EdgeInsets padding;

  /// Applies margin to message bubble.
  final EdgeInsets? margin;

  /// BoxDecoration for video message bubble.
  final BoxDecoration? decoration;

  /// Height of video message bubble.
  final double? height;

  /// Width of video message bubble.
  final double? width;

  /// Border radius for video message bubble.
  final BorderRadius? borderRadius;

  /// Icon for playing the video.
  final Icon? playIcon;

  /// Icon for pausing video.
  final Icon? pauseIcon;

  /// Whether to hide the share icon.
  final bool hideShareIcon;

  /// Configuration for the share icon
  final ShareIconConfiguration? shareIconConfig;

  /// Callback when video is tapped
  final MessageCallBack? onTap;
}
