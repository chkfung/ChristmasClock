import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:simple_animations/simple_animations/animation_progress.dart';
import 'package:simple_animations/simple_animations/multi_track_tween.dart';
import 'package:simple_animations/simple_animations/rendering.dart';

class Particles extends StatefulWidget {
  final int numberOfParticles;
  final bool isClockModel;
  Particles(this.numberOfParticles, this.isClockModel);

  @override
  _ParticlesState createState() => _ParticlesState(isClockModel);
}

class _ParticlesState extends State<Particles> {
  final bool isClockModel;
  final Random random = Random();

  final List<ParticleModel> particles = [];

  _ParticlesState(this.isClockModel);

  @override
  void initState() {
    List.generate(widget.numberOfParticles, (index) {
      particles.add(ParticleModel(random));
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Rendering(
      startTime: Duration(seconds: 30),
      onTick: _simulateParticles,
      builder: (context, time) {
        return CustomPaint(
          painter: ParticlePainter(particles, time, DateTime.now().second),
        );
      },
    );
  }

  _simulateParticles(Duration time) {
    particles.forEach((particle) => particle.maintainRestart(time));
  }
}

class ParticleModel {
  Animatable tween;
  double size;
  AnimationProgress animationProgress;
  Random random;

  ParticleModel(this.random) {
    restart();
  }

  restart({Duration time = Duration.zero}) {
    final initialPosX = -0.2 + 1.4 * random.nextDouble();
    final afterPosX = initialPosX + initialPosX * random.nextDouble();
    final startPosition = Offset(initialPosX, -0.2);
    final endPosition = Offset(afterPosX, 1.2);
    final duration = Duration(milliseconds: 500 + random.nextInt(2000));

    tween = MultiTrackTween([
      Track("x").add(
          duration, Tween(begin: startPosition.dx, end: endPosition.dx),
          curve: Curves.easeInOutSine),
      Track("y").add(
          duration, Tween(begin: startPosition.dy, end: endPosition.dy),
          curve: Curves.easeIn),
    ]);
    animationProgress = AnimationProgress(duration: duration, startTime: time);
    size = 0.01 + random.nextDouble() * 0.04;
  }

  maintainRestart(Duration time) {
    if (animationProgress.progress(time) == 1.0) {
      restart(time: time);
    }
  }
}

class ParticlePainter extends CustomPainter {
  List<ParticleModel> particles;
  Duration time;
  int seconds;

  ParticlePainter(this.particles, this.time, this.seconds);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.5); //.withAlpha(50);

    particles.forEach((particle) {
      var progress = particle.animationProgress.progress(time);
      final animation = particle.tween.transform(progress);
      final position =
          Offset(animation["x"] * size.width, animation["y"] * size.height);
      canvas.drawCircle(position, size.width * 0.2 * particle.size, paint);

      // final path = Path();
      // path.addOval(Rect.fromCircle(
      //     center: position, radius: size.width * 0.2 * particle.size));
      // canvas.drawShadow(path, Colors.white, 10.0, false);
    });
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
