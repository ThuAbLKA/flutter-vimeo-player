import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:fluttervimeoplayer/src/controllers/vimeo_player_controller.dart';
import 'package:fluttervimeoplayer/src/models/vimeo_meta_data.dart';
import 'package:fluttervimeoplayer/src/player/raw_vimeo_player.dart';
import 'package:webview_media/webview_flutter.dart';

class VimeoPlayer extends StatefulWidget {
  final Key key;
  final VimeoPlayerController controller;
  final double height;
  final double width;
  final double aspectRatio;
  final VoidCallback onReady;

  VimeoPlayer({
    this.key,
    @required this.controller,
    this.width,
    this.height,
    this.aspectRatio = 16/9,
    this.onReady
  }) : super(key: key);

  @override
  _VimeoPlayerState createState() => _VimeoPlayerState();
}

class _VimeoPlayerState extends State<VimeoPlayer> {
  VimeoPlayerController controller;
  WebViewController _cachedWebController;
  bool _initialLoad = true;
  double _position;
  double _aspectRatio;
  bool _seeking;
  bool _uiVisible;
  double _uiOpacity;
  bool _isBuffering;
  bool _isPlaying;
  CancelableCompleter completer;
  Timer t;

  void listener() async {
    if (_initialLoad && controller.value.isReady) {
      setState(() {
        _initialLoad = false;
      });
      widget.onReady();
    }
    if (_initialLoad && controller.value.isFullscreen) {
      controller.updateValue(controller.value.copyWith(isFullscreen: true));
    }
    if (controller.value.videoPosition != null) {
      setState(() {
        _position = controller.value.videoPosition;
      });
    }
    if (controller.value.videoWidth != null && controller.value.videoHeight != null) {
      setState(() {
        _aspectRatio = (controller.value.videoWidth / controller.value.videoHeight);
      });
    }
    setState(() {
      _isPlaying = controller.value.isPlaying;
      _isBuffering = controller.value.isBuffering;
    });

  }

  @override
  void initState() {
    super.initState();
    controller = widget.controller..addListener(listener);
    _aspectRatio = widget.aspectRatio;
    _position = 0.0;
    _seeking = false;
    _uiVisible = true;
    _uiOpacity = 1.0;
    _isPlaying = false;

    completer = CancelableCompleter(onCancel: () {
      print('onCancel');
      setState(() {
        _uiVisible = true;
        _uiOpacity = 1.0;
      });
    });

  }

  @override
  void didUpdateWidget(VimeoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.controller?.removeListener(listener);
    widget.controller?.addListener(listener);
  }

  @override
  void dispose() {
    controller.removeListener(listener);
    controller.dispose();
    super.dispose();
  }

  _showHideUi() {
    setState(() {
      if (!_uiVisible) {
          _uiVisible = true;
          _uiOpacity = 1.0;
      }

      if (t != null && t.isActive) {
        t.cancel();
      }

      t = Timer(Duration(seconds: 3), () {
        setState(() {
          _uiOpacity = 0.0;
          _uiVisible = false;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Material(
      elevation: 0,
      color: Colors.black,
      child: InheritedVimeoPlayer(
        controller: controller,
        child: Container(
          width: widget.width ?? MediaQuery.of(context).size.width,
          child: AspectRatio(
            aspectRatio: _aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              overflow: Overflow.visible,
              children: <Widget>[
                RawVimeoPlayer(
                  key: widget.key,
                  onEnded: (VimeoMetaData metadata) {
                    print('ended!');
                    setState(() {
                      _uiOpacity = 1.0;
                      _uiVisible = true;
                    });
                  },
                ),
                GestureDetector(
                  onTap: () {
                    print('touched');
                    _showHideUi();
                  },
                  child: AnimatedOpacity(
                    opacity: _uiOpacity,
                    duration: Duration(seconds: 1),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black],
                          stops: [0.0, 2],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter
                        )
                      ),
                      child: controller.value.isReady && _uiVisible ?
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            FloatingActionButton(
                              elevation: 0,
                              backgroundColor: Colors.transparent,
                              onPressed: () {
                                _showHideUi();
                                controller.seekTo(_position - 15);
                              },
                              child: Icon(
                                Icons.fast_rewind
                              ),
                            ),
                            _isBuffering ?
                            CircularProgressIndicator(
                              strokeWidth: 4,
                            )
                            :
                            FloatingActionButton(
                              elevation: 0,
                              backgroundColor: Colors.white54,
                              child: Icon(
                                controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white54,
                                size: 22,
                              ),
                              onPressed: () {
                                _showHideUi();
                                controller.value.isPlaying ?
                                controller.pause() :
                                controller.play();
                              },
                            ),
                            FloatingActionButton(
                              elevation: 0,
                              backgroundColor: Colors.transparent,
                              onPressed: () {
                                _showHideUi();
                                controller.seekTo(_position + 15);
                              },
                              child: Icon(
                                Icons.fast_forward
                              ),
                            ),
                          ],
                          
                        ),
                      ) : SizedBox(width: 1,),
                    ),
                  ),
                ),
                controller.value.isReady && _uiVisible ?
                Positioned(
                  height: height * 0.05,
                  bottom: 0,
                  child: AnimatedOpacity(
                    duration: Duration(seconds: 2),
                    opacity: _uiOpacity,
                    child: Flex(
                      direction: Axis.horizontal,
                      children: <Widget>[
                        GestureDetector(
                          child: Container(
                            height: height * 0.05,
                            width: width * 0.1,
                            child: Icon(
                              controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                            ),
                          ),
                          onTap: () {
                            _showHideUi();
                            controller.value.isPlaying ?
                            controller.pause() :
                            controller.play();
                          },
                        ),
                        Container(
                          width: width * 0.6,
                          child: Slider(
                            onChangeStart: (val) {
                              setState(() {
                                _seeking = true;
                              });
                            },
                            onChangeEnd: (end) {
                              print('value changed: ' + end.toString());
                              controller.seekTo(end.roundToDouble());
                              setState(() {
                                _seeking = false;
                              });
                            },
                            inactiveColor: Colors.blueGrey,
                            min: 0,
                            max: controller.value.videoDuration??0 + 0.5??0,
                            value: _position,
                            onChanged: (value) {
                              if (!_seeking) {
                                setState(() {
                                  if (value >= 0 && value <= _position)
                                  _position = value;
                                });
                              }
                            },
                          ),
                        ),
                        Container(
                          child: Text(
                            _getTimestamp(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10
                            ),
                          ),
                        ),
                        GestureDetector(
                          child: Container(
                            width: width * 0.1,
                            child: Icon(
                              Icons.settings,
                              color: Colors.white,
                            ),
                          ),
                          onTap: () {
                            _showHideUi();
                          },
                        ),
                        GestureDetector(
                          child: Container(
                            width: width * 0.1,
                            child: Icon(
                              Icons.fullscreen,
                              color: Colors.white,
                            ),
                          ),
                          onTap: () {
                            _showHideUi();
                          },
                        )
                      ]
                    ),
                  ),
                ):
                SizedBox(height: 1,)
              ],
            ),
          ),
        ),
      ),
    );
  }

  _formatDuration(Duration time) {
    var ret = '';
    if (time.inHours > 0) {
      if (time.inHours < 10) {
        ret += '0${time.inHours}:';
      } else {
        ret += '${time.inHours}:';
      }
    }
    if (time.inSeconds > 0) {
      if (time.inSeconds < 10) {
        ret += '0${time.inSeconds}';
      } else {
        ret += '${time.inSeconds}';
      }
    } else {
      ret += '00';
    }

    return ret;

  }

  String _printDuration(Duration duration) {
    String twoDigits(int n) {
      if (n >= 10) return "$n";
      return "0$n";
    }

    var ret = '';

    String twoDigitHours = twoDigits(duration.inHours.remainder(60));
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (twoDigitHours != '00') {
      ret += '$twoDigitHours:';
    }
    ret += '$twoDigitMinutes:';
    ret += '$twoDigitSeconds';


    return ret == '' ? '0:00' : ret;
  }

  _getTimestamp() {
    var position = _printDuration(new Duration(seconds: (controller.value.videoPosition??0).round()));
    var duration = _printDuration(new Duration(seconds: (controller.value.videoDuration??0).round()));

    return '$position/$duration';
  }
}