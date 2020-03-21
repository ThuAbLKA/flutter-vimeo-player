import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fluttervimeoplayer/src/controllers/vimeo_player_controller.dart';
import 'package:fluttervimeoplayer/src/models/vimeo_meta_data.dart';
import 'package:webview_media/platform_interface.dart';
import 'package:webview_media/webview_flutter.dart';

class RawVimeoPlayer extends StatefulWidget {
  final Key key;
  final void Function(VimeoMetaData metaData) onEnded;

  RawVimeoPlayer({
    this.key,
    this.onEnded,

  }) : super(key: key);

  @override
  _RawVimeoPlayerState createState() => _RawVimeoPlayerState();
}

class _RawVimeoPlayerState extends State<RawVimeoPlayer> with WidgetsBindingObserver {
  final Completer<WebViewController> _webController = Completer<WebViewController>();
  VimeoPlayerController controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _width = window.physicalSize.width;
    _height = window.physicalSize.height;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  double _width = 0.0;
  double _height = 0.0;

  @override void didChangeMetrics() {
    setState(() {
      _width = window.physicalSize.width;
      _height = window.physicalSize.height;
    });
  }

  @override
  Widget build(BuildContext context) {

    double pxHeight = MediaQuery.of(context).size.height;
    double pxWidth = MediaQuery.of(context).size.width;

    controller = VimeoPlayerController.of(context);
    return IgnorePointer(
      ignoring: true,
      child: WebView(
        key: widget.key,
        userAgent: userAgent,
        initialData: WebData(
          data: player(_width),
          baseUrl: 'https://www.vimeo.com',
          encoding: 'utf-8',
          mimeType: 'text/html'
        ),
        javascriptMode: JavascriptMode.unrestricted,
        initialMediaPlaybackPolicy: AutoMediaPlaybackPolicy.always_allow,
        onWebViewCreated: (webController) {
          _webController.complete(webController);
          _webController.future.then(
            (webViewController) {
              controller.updateValue(
                controller.value.copyWith(webViewController: webViewController),
              );
            },
          );
        },
        javascriptChannels: {
          JavascriptChannel(
            name: 'Ready', 
            onMessageReceived: (JavascriptMessage msg) {
              print('player ready');
              if (!controller.value.isReady) {
                controller.updateValue(controller.value.copyWith(isReady: true));
              }
            }
          ),
          JavascriptChannel(
            name: 'VideoPosition',
            onMessageReceived: (JavascriptMessage message) {
              controller.updateValue(controller.value.copyWith(videoPosition: double.parse(message.message)));
            }
          ),
          JavascriptChannel(
            name: 'VideoData',
            onMessageReceived: (JavascriptMessage message) {
              print('VideoData: ' + message.message);
              controller.updateValue(controller.value.copyWith(
                videoTitle: json.decode(message.message)['title'].toString(), 
                videoDuration: double.parse(json.decode(message.message)['duration'].toString()),
                videoWidth: double.parse(json.decode(message.message)['width'].toString()),
                videoHeight: double.parse(json.decode(message.message)['height'].toString()),
              ));
            },
          ),
          JavascriptChannel(
            name: 'StateChange',
            onMessageReceived: (JavascriptMessage msg) {
              switch (msg.message) {
                case '-2':
                  controller.updateValue(controller.value.copyWith(isBuffering: true));
                  break;
                case '-1':
                  print('player ended');
                  controller.updateValue(controller.value.copyWith(isPlaying: false, hasEnded: true));
                  widget.onEnded(new VimeoMetaData(
                    videoDuration: Duration(seconds: controller.value.videoDuration.round()),
                    videoId: controller.initialVideoId,
                    videoTitle: controller.value.videoTitle
                  ));
                  break;
                case '0':
                  controller.updateValue(controller.value.copyWith(isReady: true, isBuffering: false));
                  break;
                case '1':
                  print('player paused');
                  controller.updateValue(controller.value.copyWith(isPlaying: false));
                  break;
                case '2':
                  print('player playing');
                  controller.updateValue(controller.value.copyWith(isPlaying: true));
                  break;
                default:
                  print('default player state');
              }
            }
          )
        },
      )
    );
  }

  String player(double width) {
    var _player = '''<html>
      <head>
      <style>
        html,
        body {
          margin: 0;
          padding: 0;
          overflow: hidden;
          position: fixed;
          transform-origin: left top;
          height: 100%,
          width: 100%
        },
        #vimeo_frame {
          height: 100%,
          width: 100%
        }
      </style>
      <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'>
      </head>
      <body>
        <div id="vimeo_frame"></div>
        <script src="https://player.vimeo.com/api/player.js"></script>
        <script>
        var tag = document.createElement('script');
        var firstScriptTag = document.getElementsByTagName('script')[0];
        firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
        var options = {
          id: ${controller.initialVideoId},
          title: true,
          transparent: true,
          autoplay: ${controller.flags.autoPlay},
          speed: true,
          controls: false,
          dnt: true,
        };
        
        var videoData = {};

        var vimPlayer = new Vimeo.Player('vimeo_frame', options);
        
        vimPlayer.getVideoTitle().then(function(title) {
          videoData['title'] = title;
        });
        
        vimPlayer.getVideoId().then(function(id) {
          videoData['id'] = id;
        });
        
        vimPlayer.getDuration().then(function(duration) {
          videoData['duration'] = duration;
        });

        vimPlayer.on('play', function(data) {
          sendPlayerStateChange(2);
        });

        vimPlayer.on('pause', function(data) {
          sendPlayerStateChange(1);
        });

        vimPlayer.on('bufferstart', function() {
          sendPlayerStateChange(-2);
        });
        vimPlayer.on('bufferend', function() {
          sendPlayerStateChange(0);
        });
        
        vimPlayer.on('loaded', function(id) {
          Ready.postMessage("ready");
          Promise.all([vimPlayer.getVideoTitle(), vimPlayer.getDuration()]).then(function(values) {
            videoData['title'] = values[0];
            videoData['duration'] = values[1];
          });
          Promise.all([vimPlayer.getVideoWidth(), vimPlayer.getVideoHeight()]).then(function(values) {
            videoData['width'] = values[0];
            videoData['height'] = values[1];
            sendVideoData(JSON.stringify(videoData));
            console.log('vidData: ' + JSON.stringify(videoData));
          });
        });

        vimPlayer.on('ended', function(data) {
          sendPlayerStateChange(-1);
        });

        vimPlayer.on('timeupdate', function(seconds) {
          VideoPosition.postMessage(seconds['seconds']);
        });
        
        function sendPlayerStateChange(playerState) {
          StateChange.postMessage(playerState);
        }
        
        function sendVideoData(videoData) {
          VideoData.postMessage(videoData);
        }

        function play() {
          vimPlayer.play();
        }

        function pause() {
          vimPlayer.pause();
        }

        function seekTo(delta) {
          vimPlayer.getCurrentTime().then(function(seconds) {
            console.log('delta: ' + (delta));
            console.log('duration: ' + videoData['duration']);
            if (videoData['duration'] > delta) {
              vimPlayer.setCurrentTime(delta).then(function(t) {
                console.log('seekedto: ' + (t));
              });
            }
          });
        }

        function reset() {
          vimPlayer.unload().then(function(value) {
            vimPlayer.loadVideo(${controller.initialVideoId})
          });
        }
        </script>
      </body>
    </html>''';

    return _player;
  }

  String boolean({@required bool value}) => value ? "'1'" : "'0'";

  String get userAgent => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.90 Safari/537.36';

}