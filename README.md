# flutter-vimeo-player

A flutter package wrapping the vimeo player using the https://github.com/vimeo/player.js/. loosely based on youtube_player by https://github.com/sarbagyastha

## * Experimental. Only fully functional on Android

### General Initialization

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

#### Feel free to fork!

## Update 200628
* Added ```SkipDuration``` parameter, which defaults to 5 seconds
```dart
VimeoPlayerController controller = VimeoPlayerController(
  initialVideoId: '396660461',
  skipDuration: 10,
  flags: VimeoPlayerFlags()
);
```

* Added double tap to seek
  - When double tapped in the right side, fast forwards the video with incremental steps of defined 'SkipDuration'
  - When double tapped in the left side, rewinds the video with decremental stepd of defined 'SkipDuration'

