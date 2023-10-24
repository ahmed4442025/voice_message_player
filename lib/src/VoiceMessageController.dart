import 'dart:async';
import 'dart:io';
import 'package:just_audio/just_audio.dart' as jsAudio;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:voice_message_package/src/helpers/colors.dart';
import 'package:voice_message_package/src/helpers/utils.dart';

class VoiceMessageController extends ChangeNotifier {
  final String? audioSrc;
  Future<File>? audioFile;
  final Duration? duration;
  final bool showDuration;
  final List<double>? waveForm;
  final double radius;

  final int noiseCount;
  final Color meBgColor, meFgColor, contactBgColor, contactFgColor, contactCircleColor, mePlayIconColor, contactPlayIconColor, contactPlayIconBgColor;
  final bool played, me;
  Function()? onPlay;
  String Function(Duration duration)? formatDuration;

  VoiceMessageController({
    required this.me,
    this.audioSrc,
    this.audioFile,
    this.duration,
    this.formatDuration,
    this.showDuration = false,
    this.waveForm,
    this.noiseCount = 27,
    this.meBgColor = AppColors.pink,
    this.contactBgColor = const Color(0xffffffff),
    this.contactFgColor = AppColors.pink,
    this.contactCircleColor = Colors.red,
    this.mePlayIconColor = Colors.black,
    this.contactPlayIconColor = Colors.black26,
    this.radius = 12,
    this.contactPlayIconBgColor = Colors.grey,
    this.meFgColor = const Color(0xffffffff),
    this.played = false,
    this.onPlay,
  });

  late StreamSubscription stream;
  final AudioPlayer _player = AudioPlayer();
  final double maxNoiseHeight = 6.w(), noiseWidth = 28.5.w();
  Duration? _audioDuration;
  double maxDurationForSlider = .0000001;
  bool isPlaying = false, x2 = false, audioConfigurationDone = false;
  int duration22 = 00;
  String remainingTime = '';
  AnimationController? animationController;

  // =================== init ====================
  void init(TickerProvider tt) {
    formatDuration ??= (Duration duration) {
      return duration.toString().substring(2, 11);
    };

    _setDuration(tt);
    stream = _player.onPlayerStateChanged.listen((event) {
      switch (event) {
        case PlayerState.stopped:
          break;
        case PlayerState.playing:
          break;
        case PlayerState.paused:
          isPlaying = false;
          notifyListeners();
          break;
        case PlayerState.completed:
          _player.seek(const Duration(milliseconds: 0));
          duration22 = _audioDuration!.inMilliseconds;
          remainingTime = formatDuration!(_audioDuration!);
          notifyListeners();
          break;
        default:
          break;
      }
    });
    _player.onPositionChanged.listen(
      (Duration p)  {
        remainingTime = p.toString().substring(2, 11);
        notifyListeners();
      },
    );
  }

  void _startPlaying() async {
    if (audioFile != null) {
      String path = (await audioFile!).path;
      debugPrint("> _startPlaying path $path");
      await _player.play(DeviceFileSource(path));
    } else if (audioSrc != null) {
      await _player.play(UrlSource(audioSrc!));
    }
    animationController!.forward();
  }

  stopPlaying() async {
    await _player.pause();
    animationController!.stop();
  }

  void _setDuration(TickerProvider tt) async {
    if (duration != null) {
      _audioDuration = duration;
    } else {
      _audioDuration = await jsAudio.AudioPlayer().setUrl(audioSrc!);
    }
    duration22 = _audioDuration!.inMilliseconds;
    maxDurationForSlider = duration22 + .0;

    ///
    animationController = AnimationController(
      vsync: tt,
      lowerBound: 0,
      upperBound: noiseWidth,
      duration: _audioDuration,
    );

    ///
    animationController!.addListener(() {
      if (animationController!.isCompleted) {
        animationController!.reset();
        isPlaying = false;
        x2 = false;
        notifyListeners();
      }
    });
    _setAnimationConfiguration(_audioDuration!);
  }

  void _setAnimationConfiguration(Duration audioDuration) async {
      remainingTime = formatDuration!(audioDuration);
      notifyListeners();
    debugPrint("_setAnimationConfiguration $remainingTime");
    _completeAnimationConfiguration();
  }

  void _completeAnimationConfiguration() {
    audioConfigurationDone = true;
    notifyListeners();
  }

  // void _toggle2x() {
  //   x2 = !x2;
  //   _controller!.duration = _duration(seconds: x2 ? _duration ~/ 2 : _duration);
  //   if (_controller!.isAnimating) _controller!.forward();
  //   _player.setPlaybackRate(x2 ? 2 : 1);
  //   setState(() {});
  // }

  void changePlayingStatus() async {
    if (onPlay != null) onPlay!();
    isPlaying ? stopPlaying() : _startPlaying();
    isPlaying = !isPlaying;
    notifyListeners();
  }

  onChangeSlider(double d) async {
    if (isPlaying) changePlayingStatus();
    duration22 = d.round();
    animationController?.value = (noiseWidth) * duration22 / maxDurationForSlider;
    remainingTime = formatDuration!(_audioDuration!);
    await _player.seek(Duration(milliseconds: duration22));
    notifyListeners();
  }

  // dispose
  void stop() {
    stream.cancel();
    _player.dispose();
    animationController?.dispose();
  }
}
