import 'package:flutter/material.dart';
import 'package:fluttervimeoplayer/src/enums/playback_rate.dart';

class VimeoPlayerFlags {
  final double height;
  final double width;
  final bool autoPause;
  final bool autoPlay;
  final bool background;
  final bool byLine;
  final Color color;
  final bool controls;
  final bool loop;
  final bool muted;
  final bool playsInLine;
  final bool portrait;
  final double speed;
  final bool title;
  final bool transparent;


  const VimeoPlayerFlags({
    this.autoPause = true,
    this.autoPlay = false,
    this.background = false,
    this.byLine = true,
    this.color = const Color.fromARGB(1, 0, 174, 239),
    this.controls = true,
    this.loop = false,
    this.muted = false,
    this.playsInLine = true,
    this.portrait = true,
    this.speed = PlaybackRate.normal,
    this.title = true,
    this.transparent = true,
    this.height = 0,
    this.width = 0,
  });

  VimeoPlayerFlags copyWith({
    double height,
    double width,
    bool autoPause,
    bool autoPlay,
    bool background,
    bool byLine,
    Color color,
    bool controls,
    bool loop,
    bool muted,
    bool playsInLine,
    bool portrait,
    double speed,
    bool title,
    bool transparent
  }) {
    return VimeoPlayerFlags(
      autoPause: autoPause ?? this.autoPause,
      autoPlay: autoPlay ?? this.autoPlay,
      background: background ?? this.background,
      byLine: byLine ?? this.byLine,
      color: color ?? this.color,
      controls: controls ?? this.controls,
      loop: loop ?? this.loop,
      muted: muted ?? this.muted,
      playsInLine: playsInLine ?? this.playsInLine,
      portrait: portrait ?? this.portrait,
      speed: speed ?? this.speed,
      title: title ?? this.title,
      transparent: transparent ?? this.transparent,
      height: height ?? this.height,
      width: width ?? this.width
    );
  }
}