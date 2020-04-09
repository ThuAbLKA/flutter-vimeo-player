# flutter-vimeo-player

A flutter package wrapping the vimeo player using the https://github.com/vimeo/player.js/. loosely based on youtube_player by https://github.com/sarbagyastha

## * Experimental. Only fully functional on Android

Supported Platforms
* Android

### Android

```dart
VimeoPlayerController controller = VimeoPlayerController(
  initialVideoId: '396660461',
  flags: VimeoPlayerFlags()
);

VimeoPlayer(
  controller: controller,
  onReady: () {
    setState(() {
      this._playerReady = true;
    });
  },
);
```


