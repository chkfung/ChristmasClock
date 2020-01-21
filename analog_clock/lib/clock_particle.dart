import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:simple_animations/simple_animations/animation_progress.dart';
import 'package:simple_animations/simple_animations/multi_track_tween.dart';
import 'package:simple_animations/simple_animations/rendering.dart';

class ClockParticles extends StatefulWidget {
  ClockParticles();

  @override
  _ClockClockParticlesState createState() => _ClockClockParticlesState();
}

class _ClockClockParticlesState extends State<ClockParticles> {
  final Random random = Random();

  final List<ClockParticleModel> ClockParticles = [];

  _ClockClockParticlesState() {}

  @override
  void initState() {
    super.initState();
    List.generate(60, (index) {
      List.generate(index, (_) {
        ClockParticles.add(ClockParticleModel(index, random));
        // ClockParticles.add(ClockParticleModel(
        //     index, x_constraint, y_constraint, mediaQuery, random));
      });
    });
    // List.generate(widget.numberOfClockParticles, (index) {
    //   ClockParticles.add(ClockParticleModel(
    //       index, x_constraint, y_constraint, mediaQuery, random));
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Rendering(
      startTime: Duration(seconds: 0),
      onTick: _simulateClockParticles,
      builder: (context, time) {
        return CustomPaint(
          painter:
              ClockParticlePainter(ClockParticles, time, DateTime.now().second),
        );
      },
    );
  }

  _simulateClockParticles(Duration time) {
    ClockParticles.forEach((particle) => particle.maintainRestart(time));
  }
}

class ClockParticleModel {
  final int index;
  Animatable snowTween;
  Animatable explodeTween;
  double size;
  Offset startPosition;
  Offset endPosition;
  AnimationProgress snowAnimationProgress;
  AnimationProgress burstAnimationProgress;
  Random random;

  ClockParticleModel(this.index, this.random) {
    restart();
    burst();
  }

  restart({Duration time = Duration.zero}) {
    final initialPosX = -0.2 + 1.4 * random.nextDouble();
    var percent = min(index / 60, 100);

    var afterPosX = (0.25 + (0.5) * random.nextDouble());
    var afterPosY =
        (0.08 + (1 - percent) * 0.84 + (0.84 * percent) * random.nextDouble());
    var dx = (afterPosX - 0.5).abs();
    var dy = (afterPosY - 0.5).abs() * 3 / 5;
    var r = 0.25;

    while (dx * dx + dy * dy > r * r) {
      afterPosX = (0.25 + (0.5) * random.nextDouble());
      afterPosY = (0.08 +
          (1 - percent) * 0.84 +
          (0.84 * percent) * random.nextDouble());
      dx = (afterPosX - 0.5).abs();
      dy = (afterPosY - 0.5).abs() * 3 / 5;
    }

    startPosition = Offset(initialPosX, -0.2);
    endPosition = Offset(afterPosX, afterPosY);
    final duration = Duration(milliseconds: 500 + random.nextInt(2000));

    snowTween = MultiTrackTween([
      Track("x").add(
          duration, Tween(begin: startPosition.dx, end: endPosition.dx),
          curve: Curves.easeInOutSine),
      Track("y").add(
          duration, Tween(begin: startPosition.dy, end: endPosition.dy),
          curve: Curves.easeIn),
      Track("scale")
          .add(duration, Tween(begin: 1, end: 1), curve: Curves.easeIn),
    ]);
    snowAnimationProgress = AnimationProgress(
        duration: duration, startTime: Duration(seconds: (index % 60)));
    size = 0.01 + random.nextDouble() * 0.04;
  }

  burst() {
    final animDuration = 1000;
    explodeTween = MultiTrackTween([
      Track("x").add(
          Duration(milliseconds: animDuration),
          Tween(
              begin: endPosition.dx,
              end: endPosition.dx +
                  (random.nextDouble() / 6 * (random.nextBool() ? 1 : -1))),
          curve: Curves.easeInOutSine),
      Track("y").add(Duration(milliseconds: animDuration),
          Tween(begin: endPosition.dy, end: 1 + random.nextDouble()),
          curve: Curves.easeInBack),
      Track("scale").add(
          Duration(milliseconds: animDuration), Tween(begin: 1, end: 0.5),
          curve: Curves.easeInBack),
    ]);
    burstAnimationProgress = AnimationProgress(
        duration: Duration(milliseconds: animDuration),
        startTime: Duration(milliseconds: 0 + random.nextInt(500)));
  }

  maintainRestart(Duration time) {}
}

class ClockParticlePainter extends CustomPainter {
  List<ClockParticleModel> ClockParticles;
  Duration time;
  int seconds;

  ClockParticlePainter(this.ClockParticles, this.time, this.seconds);

  Random random = Random();
  @override
  void paint(Canvas canvas, Size size) {
    final millis = DateTime.now().second * 1000 + DateTime.now().millisecond;
    final paint = Paint()
      ..color = Colors.white
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.5); //.withAlpha(50);

    var pts = List<Offset>();
    ClockParticles.forEach((particle) {
      if (millis < 1500) {
        var progress = particle.burstAnimationProgress
            .progress(Duration(milliseconds: millis));
        final animation = particle.explodeTween.transform(progress);

        final position =
            Offset(animation["x"] * size.width, animation["y"] * size.height);
        canvas.drawCircle(position,
            size.width * 0.2 * particle.size * animation["scale"], paint);
      } else {
        var progress = particle.snowAnimationProgress
            .progress(Duration(milliseconds: millis));
        final animation = particle.snowTween.transform(progress);
        final position =
            Offset(animation["x"] * size.width, animation["y"] * size.height);
        canvas.drawCircle(position,
            size.width * 0.2 * particle.size * animation["scale"], paint);
        final path = Path();
        path.addOval(Rect.fromCircle(
            center: position,
            radius: size.width * 0.2 * particle.size * animation["scale"]));
      }
    });
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
