import 'package:flutter/cupertino.dart';
import 'package:fluttervimeoplayer/flutter_vimeo_player.dart';
import 'package:fluttervimeoplayer/src/models/vimeo_meta_data.dart';
import 'package:webview_media/webview_flutter.dart';

class VimeoPlayerValue {
  final bool isReady;
  final bool isPlaying;
  final bool isFullscreen;
  final bool isBuffering;
  final bool hasEnded;
  final String videoTitle;
  final double videoPosition;
  final double videoDuration;
  final double videoWidth;
  final double videoHeight;
  final WebViewController webViewController;


  VimeoPlayerValue({
    this.isReady = false,
    this.isPlaying = false,
    this.isFullscreen = false,
    this.isBuffering = false,
    this.hasEnded = false,
    this.videoTitle,
    this.videoPosition,
    this.videoDuration,
    this.videoWidth,
    this.videoHeight,
    this.webViewController
  });

  VimeoPlayerValue copyWith({
    bool isReady,
    bool isPlaying,
    bool isFullscreen,
    bool isBuffering,
    bool hasEnded,
    String videoTitle,
    double videoPosition,
    double videoDuration,
    double videoWidth,
    double videoHeight,
    WebViewController webViewController
  }) {
    return VimeoPlayerValue(
      isReady: isReady ?? this.isReady,
      isPlaying: isPlaying ?? this.isPlaying,
      isFullscreen: isFullscreen ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      hasEnded: hasEnded ?? this.hasEnded,
      videoTitle: videoTitle ?? this.videoTitle,
      videoDuration: videoDuration ?? this.videoDuration,
      videoWidth: videoWidth ?? this.videoWidth,
      videoHeight: videoHeight ?? this.videoHeight,
      videoPosition: videoPosition ?? this.videoPosition,
      webViewController: webViewController ?? this.webViewController
    );
  }
}

class VimeoPlayerController extends ValueNotifier<VimeoPlayerValue>{

  final String initialVideoId;
  final VimeoPlayerFlags flags;

  VimeoPlayerController({
    @required this.initialVideoId,
    this.flags = const VimeoPlayerFlags()
  }) : assert(initialVideoId != null, 'InitialVideoId is mandetory'), super(VimeoPlayerValue());

  factory VimeoPlayerController.of(BuildContext context) => 
    context.dependOnInheritedWidgetOfExactType<InheritedVimeoPlayer>()
    ?.controller;

  void updateValue(VimeoPlayerValue newValue) => value = newValue;

  void toggleFullscreenMode() => updateValue(value.copyWith(isFullscreen: true));

  void reload() => value.webViewController?.reload();
  
  void play() => _callMethod('play()');
  void pause() => _callMethod('pause()');
  void seekTo(double delta) => _callMethod('seekTo($delta)');
  void reset() => _callMethod('reset()');

  _callMethod(String methodString) {
    if (value.isReady) {
      value.webViewController?.evaluateJavascript(methodString);
    } else {
      print('The controller is not ready for method calls.');
    }
  }

}

class InheritedVimeoPlayer extends InheritedWidget {
  final VimeoPlayerController controller;
  const InheritedVimeoPlayer({
    Key key,
    @required this.controller,
    @required Widget child,
  })  : assert(controller != null), 
  super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return oldWidget.hashCode != controller.hashCode;
  }
}