import 'package:flutter/material.dart';
import 'package:fluttervimeoplayer/flutter_vimeo_player.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  VimeoPlayerController controller;
  bool _playerReady = false;
  String _videoTitle;

  @override
  void initState() {
    super.initState();

    this._videoTitle = 'Loading...';

    this.controller = VimeoPlayerController(
      initialVideoId: '396660461',
      flags: VimeoPlayerFlags()
    )..addListener(listener);
  }

  void listener() async {
    if (_playerReady) {
      setState(() {
        this._videoTitle = controller.value.videoTitle;
      });
    }
  }

  @override
  void dispose() {
    this.controller.removeListener(listener);
    this.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Text(_videoTitle),
            VimeoPlayer(
              controller: controller,
              skipDuration: 10,
              onReady: () {
                setState(() {
                  this._playerReady = true;
                });
              },
            ),
            Text(_videoTitle + (controller.value.isBuffering ? " Buffering" : controller.value.isPlaying ? " Playing" : " Ready!") ),
          ],
        )
      ),
    );
  }
}
