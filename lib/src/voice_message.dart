import 'package:flutter/material.dart';

// ignore: library_prefixes
import 'package:voice_message_package/src/VoiceMessageController.dart';
import 'package:voice_message_package/src/contact_noises.dart';
import 'package:voice_message_package/src/helpers/utils.dart';

import './helpers/widgets.dart';
import './noises.dart';

/// This is the main controller.
// ignore: must_be_immutable
class VoiceMessage extends StatefulWidget {
  final VoiceMessageController controller;

  const VoiceMessage({Key? key, required this.controller}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _VoiceMessageState createState() => _VoiceMessageState();
}

class _VoiceMessageState extends State<VoiceMessage> with SingleTickerProviderStateMixin {
  VoiceMessageController get controller => widget.controller;

  AnimationController? get _animationController => controller.animationController;

  @override
  void initState() {
    // setState on every notifyListener
    controller.addListener(() {
      if (mounted) setState(() {});
    });

    controller.init(this); // init controller

    super.initState();
  }

  @override
  Widget build(BuildContext context) => _sizerChild(context);

  Container _sizerChild(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: .8.w()),
        constraints: BoxConstraints(maxWidth: 100.w() * .8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(controller.radius),
            bottomLeft: controller.me ? Radius.circular(controller.radius) : const Radius.circular(4),
            bottomRight: !controller.me ? Radius.circular(controller.radius) : const Radius.circular(4),
            topRight: Radius.circular(controller.radius),
          ),
          color: controller.me ? controller.meBgColor : controller.contactBgColor,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w(), vertical: 2.8.w()),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _playButton(context),
              SizedBox(width: 3.w()),
              _durationWithNoise(context),
              SizedBox(width: 2.2.w()),

              /// x2 button will be added here.
              // _speed(context),
            ],
          ),
        ),
      );

  Widget _playButton(BuildContext context) => InkWell(
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: controller.me ? controller.meFgColor : controller.contactPlayIconBgColor,
          ),
          width: 10.w(),
          height: 10.w(),
          child: InkWell(
            onTap: () => !controller.audioConfigurationDone ? null : controller.changePlayingStatus(),
            child: !controller.audioConfigurationDone
                ? Container(
                    padding: const EdgeInsets.all(8),
                    width: 10,
                    height: 0,
                    child: const CircularProgressIndicator(strokeWidth: 1, color: Colors.grey),
                  )
                : Icon(
                    controller.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: controller.me ? controller.mePlayIconColor : controller.contactPlayIconColor,
                    size: 5.w(),
                  ),
          ),
        ),
      );

  Widget _durationWithNoise(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _noise(context),
          SizedBox(height: .3.w()),
          Row(
            children: [
              /// show played badge
              if (!controller.played) Widgets.circle(context, 1.5.w(), controller.me ? controller.meFgColor : controller.contactCircleColor),

              /// show duration
              if (controller.showDuration)
                Padding(
                  padding: EdgeInsets.only(left: 1.2.w()),
                  child: Text(
                    controller.formatDuration!(controller.duration!),
                    style: TextStyle(
                      fontSize: 10,
                      color: controller.me ? controller.meFgColor : controller.contactFgColor,
                    ),
                  ),
                ),
              SizedBox(width: 1.5.w()),
              SizedBox(
                width: 50,
                child: Text(
                  controller.remainingTime,
                  style: TextStyle(
                    fontSize: 10,
                    color: controller.me ? controller.meFgColor : controller.contactFgColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      );

  /// Noise widget of audio.
  Widget _noise(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final newTHeme = theme.copyWith(
      sliderTheme: SliderThemeData(
        trackShape: CustomTrackShape(),
        thumbShape: SliderComponentShape.noThumb,
        minThumbSeparation: 0,
      ),
    );

    ///
    return Theme(
      data: newTHeme,
      child: SizedBox(
        height: 6.5.w(),
        width: controller.noiseWidth,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            controller.me ? const Noises() : const ContactNoise(),
            if (controller.audioConfigurationDone)
              AnimatedBuilder(
                animation: CurvedAnimation(parent: _animationController!, curve: Curves.ease),
                builder: (context, child) {
                  return Positioned(
                    left: _animationController!.value,
                    child: Container(
                      width: controller.noiseWidth,
                      height: 6.w(),
                      color: controller.me ? controller.meBgColor.withOpacity(.4) : controller.contactBgColor.withOpacity(.35),
                    ),
                  );
                },
              ),
            Opacity(
              opacity: .0,
              child: Container(
                width: controller.noiseWidth,
                color: Colors.amber.withOpacity(0),
                child: Slider(
                  min: 0.0,
                  max: controller.maxDurationForSlider,
                  onChangeStart: (__) => controller.stopPlaying(),
                  onChanged: (_) => controller.onChangeSlider(_),
                  value: controller.duration22 + .0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // _speed(BuildContext context) => InkWell(
  //       onTap: () => _toggle2x(),
  //       child: Container(
  //         alignment: Alignment.center,
  //         padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.6.w),
  //         decoration: BoxDecoration(
  //           borderRadius: BorderRadius.circular(2.8.w),
  //           color: controller.meFgColor.withOpacity(.28),
  //         ),
  //         width: 9.8.w,
  //         child: Text(
  //           !x2 ? '1X' : '2X',
  //           style: TextStyle(fontSize: 9.8, color: controller.meFgColor),
  //         ),
  //       ),
  //     );

  @override
  void dispose() {
    controller.stop();
    super.dispose();
  }

  ///
}

///
class CustomTrackShape extends RoundedRectSliderTrackShape {
  ///
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    const double trackHeight = 10;
    final double trackLeft = offset.dx, trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
