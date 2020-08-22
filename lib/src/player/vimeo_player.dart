import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:fluttervimeoplayer/src/controllers/vimeo_player_controller.dart';
import 'package:fluttervimeoplayer/src/models/vimeo_meta_data.dart';
import 'package:fluttervimeoplayer/src/player/raw_vimeo_player.dart';
import 'package:positioned_tap_detector/positioned_tap_detector.dart';

class VimeoPlayer extends StatefulWidget {
  final Key key;
  final VimeoPlayerController controller;
  final double height;
  final double width;
  final double aspectRatio;
  int skipDuration;
  final VoidCallback onReady;

  VimeoPlayer({
    this.key,
    @required this.controller,
    this.width,
    this.height,
    this.aspectRatio = 16/9,
    this.skipDuration,
    this.onReady
  }) : super(key: key) {
    if (this.skipDuration == null) {
      this.skipDuration = 5;
    }
  }

  @override
  _VimeoPlayerState createState() => _VimeoPlayerState();
}

class _VimeoPlayerState extends State<VimeoPlayer> with SingleTickerProviderStateMixin {
  VimeoPlayerController controller;
  AnimationController _animationController;
  AnimationController _iconAnimationController;
  bool _initialLoad = true;
  double _position;
  double _aspectRatio;
  bool _seekingF;
  bool _seekingB;
  bool _isPlayerReady;
  bool _centerUiVisible;
  bool _bottomUiVisible;
  double _uiOpacity;
  bool _isBuffering;
  bool _isPlaying;
  int _seekDuration;
  CancelableCompleter completer;
  Timer t;
  Timer t2;
  Animation _playPauseAnimation;

  void listener() async {
    if (controller.value.isReady) {
      if (!_isPlayerReady) {
        widget.onReady();
        setState(() {
          _centerUiVisible = true;
          _isPlayerReady = true;
        });
      }
    }
    setState(() {
      _isPlaying = controller.value.isPlaying;
      _isBuffering = controller.value.isBuffering;
    });
    if (controller.value.videoWidth != null && controller.value.videoHeight != null) {
      setState(() {
        _aspectRatio = (controller.value.videoWidth / controller.value.videoHeight);
      });
    }
    if (controller.value.videoPosition != null) {
      setState(() {
        _position = controller.value.videoPosition;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    controller = widget.controller..addListener(listener);
    _aspectRatio = widget.aspectRatio;
    _position = 0.0;
    _seekingF = false;
    _seekingB = false;
    _bottomUiVisible = false;
    _uiOpacity = 1.0;
    _isPlaying = false;
    _initialLoad = true;
    _isBuffering = false;
    _centerUiVisible = true;
    _isPlayerReady = false;
    _seekDuration = 0;

    completer = CancelableCompleter(onCancel: () {
      print('onCancel');
      setState(() {
        _bottomUiVisible = true;
        _uiOpacity = 1.0;
      });
    });

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600)
    );
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

  _hideUi() {
    setState(() {
      _bottomUiVisible = false;
      _centerUiVisible = false;
      _uiOpacity = 0.0;
    });
  }

  _onPlay() {
    if (controller.value.isPlaying) {
      controller.pause();
      _animationController.forward();
    } else {
      controller.play();
      _animationController.reverse();
    }

    if (_initialLoad) {
      setState(() {
        _initialLoad = false;
        _centerUiVisible = false;
        _bottomUiVisible = true;
      });
    } else {
      setState(() {
        _centerUiVisible = false;
        _bottomUiVisible = true;
      });

      t = Timer(Duration(seconds: 3), () {
        _hideUi();
      });
    }
  }

  _onBottomPlayButton() {
    if (controller.value.isPlaying) {
      controller.pause();
      setState(() {
        _centerUiVisible = true;
        _bottomUiVisible = false;
        _uiOpacity = 1.0;
      });
      if (t != null && t.isActive) {
        t.cancel();
      }
    } else {
      controller.play();
    }
  }

  _onUiTouched() {
    if (t != null && t.isActive) {
      t.cancel();
    }
    if (this._isPlaying) {
      setState(() {
        _bottomUiVisible = true;
        _centerUiVisible = false;
        _uiOpacity = 1.0;
      });
      /* delayed animation */
      t = Timer(Duration(seconds: 3), () {
        _hideUi();
      });
    }    
  }

  _handleDoublTap(TapPosition details) {
    if (t != null && t.isActive) {
      t.cancel();
    }
    if (t2 != null && t2.isActive) {
      t2.cancel();
    }

    setState(() {
      _bottomUiVisible = true;
      _centerUiVisible = false;
      _uiOpacity = 1.0;
    });
    if (details.global.dx > MediaQuery.of(context).size.width / 2) {
      setState(() {
        _seekingF = true;
        _seekDuration = _seekDuration + widget.skipDuration;
      });
      /* seek fwd */
      controller.seekTo(_position + widget.skipDuration);
    } else {
      setState(() {
        _seekingB = true;
        _seekDuration = _seekDuration - widget.skipDuration;
      });
      /* seek Backward */
      controller.seekTo(_position - widget.skipDuration);
    }
    /* delayed animation */
    t = Timer(Duration(seconds: 3), () {
      _hideUi();
    });
    t2 = Timer(Duration(seconds: 1),() {
      setState(() {
        _seekingF = false;
        _seekingB = false;
        _seekDuration = 0;
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
                      _bottomUiVisible = false;
                      _centerUiVisible = true;
                      _initialLoad = true;
                    });
                    controller.reload();
                  },
                ),
                PositionedTapDetector(
                  onTap: (TapPosition position) {
                    _onUiTouched();
                  },
                  onDoubleTap: _handleDoublTap,
                  child: AnimatedOpacity(
                    opacity: _uiOpacity,
                    curve: Interval(0.5,1),
                    duration: Duration(milliseconds: 600),
                    child: controller.value.isReady ? Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.transparent, Colors.black],
                          stops: [0.0,0.75,1],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter
                        )
                      ),
                      child: controller.value.isReady ?
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            _seekingB ? Row(
                              children: <Widget>[
                                Text(
                                  '${_seekDuration.toString()}s',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18
                                  ),
                                ),
                                Icon(
                                  Icons.fast_rewind,
                                  color: Colors.white,
                                ),
                              ],
                            ) : SizedBox(),
                            _isBuffering ?
                            CircularProgressIndicator(
                              strokeWidth: 4,
                            )
                            :
                            _centerUiVisible ? FloatingActionButton(
                              elevation: 0,
                              backgroundColor: Colors.white54,
                              child: Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 34,
                              ),
                              onPressed: () {
                                _onPlay();
                              }
                            ): SizedBox(),
                            _seekingF ? Row(
                              children: <Widget>[
                                Icon(
                                  Icons.fast_forward,
                                  color: Colors.white,
                                ),
                                Text(
                                  '${_seekDuration.toString()}s',
                                  style: TextStyle(
                                    color: Colors.white,                                    
                                  ),
                                )
                              ],
                            ) : SizedBox(),
                          ],
                        ),
                      ) : SizedBox(width: 1,),
                    ) : SizedBox(),
                  ),
                ),
                controller.value.isReady && _bottomUiVisible && !_initialLoad ?
                Positioned(
                  height: height * 0.05,
                  bottom: 0,
                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: 500),
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
                            /* pause button clicked */
                            _onBottomPlayButton();
                          },
                        ),
                        Container(
                          width: width * 0.6,
                          child: Slider(
                            onChangeStart: (val) {
                              setState(() {
                                _seekingF = true;
                              });
                            },
                            label: _getTimestamp(),
                            onChangeEnd: (end) {
                              controller.seekTo(end.roundToDouble());
                              setState(() {
                                _seekingF = false;
                              });
                            },
                            inactiveColor: Colors.blueGrey,
                            min: 0,
                            max: controller.value.videoDuration != null ? controller.value.videoDuration + 1.0 : 0.0,
                            value: _position,
                            onChanged: (value) {
                              if (!_seekingF) {
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
                            _getTimestamp() + "",
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