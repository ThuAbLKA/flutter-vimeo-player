import 'dart:convert';

class VimeoMetaData {
  final String videoId;
  final String videoTitle;
  final Duration videoDuration;

  const VimeoMetaData({
    this.videoId = '',
    this.videoTitle = '',
    this.videoDuration = const Duration(),
  });

  factory VimeoMetaData.fromRawData(String rawData) {
    Map<String, dynamic> parsedData = jsonDecode(rawData);
    var durationInMs = (((parsedData['duration'] ?? 0) as double) * 1000).floor();
    return VimeoMetaData(
      videoId: parsedData[''],
      videoTitle: parsedData[''],
      videoDuration: parsedData['']
    );
  }

  @override
  String toString() {
    return '$runtimeType('
    'videoId: $videoId, '
    'videoTitle: $videoTitle, '
    'duration: ${videoDuration.inSeconds} sec.';
  }
}