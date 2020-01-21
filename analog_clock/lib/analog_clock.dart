// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:analog_clock/clock_particle.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vector_math/vector_math_64.dart' show radians;

import 'container_hand.dart';
import 'drawn_hand.dart';

import 'particle.dart';

/// Total distance traveled by a second or a minute hand, each second or minute,
/// respectively.
final radiansPerTick = radians(360 / 60);

/// Total distance traveled by an hour hand, each hour, in radians.
final radiansPerHour = radians(360 / 12);

/// A basic analog clock.
///
/// You can do better than this!
class AnalogClock extends StatefulWidget {
  const AnalogClock(this.model);

  final ClockModel model;

  @override
  _AnalogClockState createState() => _AnalogClockState();
}

class _AnalogClockState extends State<AnalogClock>
    with TickerProviderStateMixin {
  var _now = DateTime.now();
  var _temperature = '';
  var _temperatureRange = '';
  var _condition = '';
  var _location = '';
  Timer _timer;
  Timer _timer2;
  AnimationController controller;
  AnimationController flickerController;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    controller = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    flickerController = AnimationController(
        duration: const Duration(milliseconds: 10000), vsync: this);
    flickerController.forward(from: 0);
    // Set the initial values.
    _updateTime();
    _updateModel();
  }

  @override
  void didUpdateWidget(AnalogClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      _temperature = widget.model.temperatureString;
      _temperatureRange = '(${widget.model.low} - ${widget.model.highString})';
      _condition = widget.model.weatherString;
      _location = widget.model.location;
    });
  }

  void _updateTime() {
    setState(() {
      _now = DateTime.now();
      if (_now.second == 59) {
        // controller.forward(from: 0);
        _timer2 = Timer(Duration(milliseconds: 800), () {
          controller.forward(from: 0);
        });
      }
      // Update once per second. Make sure to do it at the beginning of each
      // new second, so that the clock is accurate.
      _timer = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _now.millisecond),
        _updateTime,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> offsetAnimation = Tween(begin: -5.0, end: 5.0)
        .chain(CurveTween(curve: Curves.elasticInOut))
        .animate(controller)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              controller.reverse();
            }
          });
    final Animation<double> flickeringAnimation =
        Tween(begin: 0.0, end: 1.0).animate(flickerController)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              flickerController.repeat();
            }
          });
    // There are many ways to apply themes to your clock. Some are:
    //  - Inherit the parent Theme (see ClockCustomizer in the
    //    flutter_clock_helper package).
    //  - Override the Theme.of(context).colorScheme.
    //  - Create your own [ThemeData], demonstrated in [AnalogClock].
    //  - Create a map of [Color]s to custom keys, demonstrated in
    //    [DigitalClock].

    final customTheme = Theme.of(context).brightness == Brightness.light
        ? Theme.of(context).copyWith(
            // Hour hand.
            primaryColor: Color(0xFF4285F4),
            // Minute hand.
            highlightColor: Color(0xFF8AB4F8),
            // Second hand.
            accentColor: Color(0xFF669DF6),
            backgroundColor: Color(0xFFD2E3FC),
          )
        : Theme.of(context).copyWith(
            primaryColor: Color(0xFFD2E3FC),
            highlightColor: Color(0xFF4285F4),
            accentColor: Color(0xFF8AB4F8),
            backgroundColor: Color(0xFF3C4043),
          );

    final time = DateFormat.Hms().format(DateTime.now());
    return Semantics.fromProperties(
      properties: SemanticsProperties(
        label: 'Analog clock with time $time',
        value: time,
      ),
      child: AspectRatio(
        aspectRatio: 5 / 3,
        child: LayoutBuilder(builder: (context, constraints) {
          return Container(
            color: Colors.black,
            child: Stack(
              children: [
                Center(
                  child: Container(
                    child: Image(
                      image: AssetImage('assets/ring6_bg.jpg'),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: offsetAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      alignment: Alignment.bottomCenter,
                      angle: offsetAnimation.status == AnimationStatus.dismissed
                          ? 0
                          : offsetAnimation.value / 50,
                      child: child,
                    );
                  },
                  child: Center(
                    child: Container(
                      child: Image(
                        image: AssetImage('assets/ring6ring.png'),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(child: Particles(120, false)),
                Positioned.fill(
                  child: ClockParticles(),
                ),
                ContainerHand(
                    color: Colors.transparent,
                    size: 1,
                    angleRadians: _now.minute * radiansPerTick,
                    child: Container(
                      width: 300,
                      height: 300,
                      child: DrawnHand(
                        color: Color.fromRGBO(255, 215, 0, 0.8),
                        thickness: 8,
                        size: 1,
                        angleRadians: _now.hour * radiansPerHour +
                            (_now.minute / 60) * radiansPerHour,
                      ),
                    )),
                ContainerHand(
                  color: Colors.transparent,
                  size: 1,
                  angleRadians: _now.hour * radiansPerHour +
                      (_now.minute / 60) * radiansPerHour,
                  child: Container(
                      width: 300,
                      height: 200,
                      child: DrawnHand(
                        color: Color.fromRGBO(218, 165, 32, 0.9),
                        thickness: 8,
                        size: 1,
                        angleRadians: _now.hour * radiansPerHour +
                            (_now.minute / 60) * radiansPerHour,
                      )),
                ),
                ContainerHand(
                  color: Colors.transparent,
                  size: 0.5,
                  angleRadians: _now.minute * radiansPerTick,
                  child: Transform.translate(
                      offset: Offset(-0, -constraints.maxHeight * 0.5),
                      child: Container(
                        width: constraints.maxHeight * 0.3,
                        height: constraints.maxHeight * 0.3,
                        child: SvgPicture.asset(
                          "assets/present.svg",
                          height: constraints.maxHeight * 0.4,
                          width: constraints.maxHeight * 0.4,
                        ),
                      )),
                ),
                ContainerHand(
                  color: Colors.transparent,
                  size: 0.5,
                  angleRadians: _now.hour * radiansPerHour +
                      (_now.minute / 60) * radiansPerHour,
                  child: Transform.translate(
                      offset: Offset(-0, -constraints.maxHeight * 0.4),
                      child: Container(
                        width: constraints.maxHeight * 0.3,
                        height: constraints.maxHeight * 0.3,
                        child: SvgPicture.asset(
                          "assets/santa.svg",
                          height: constraints.maxHeight * 0.4,
                          width: constraints.maxHeight * 0.4,
                        ),
                      )),
                ),
                ContainerHand(
                  color: Colors.transparent,
                  size: 0.5,
                  angleRadians: _now.second * radiansPerTick,
                  child: Transform.translate(
                    offset: Offset(-0, -constraints.maxHeight * 0.85),
                    child: Container(
                        width: constraints.maxHeight * 0.3,
                        height: constraints.maxHeight * 0.3,
                        child: AnimatedBuilder(
                          animation: flickeringAnimation,
                          builder: (context, child) {
                            return Stack(
                              children: <Widget>[
                                child,
                                ...List.generate(10, (index) {
                                  final rand = Random();
                                  return Positioned(
                                    left: rand.nextDouble() *
                                        constraints.maxHeight *
                                        0.3,
                                    top: rand.nextDouble() *
                                        constraints.maxHeight *
                                        0.3,
                                    child: Opacity(
                                      opacity: (index % 2 == 0
                                          ? (1 - flickeringAnimation.value)
                                              .roundToDouble()
                                          : flickeringAnimation.value
                                              .roundToDouble()),
                                      child: Icon(
                                        Icons.star,
                                        size: rand.nextDouble() * 16 + 16,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            );
                          },
                          child: Shimmer.fromColors(
                            baseColor: Colors.red,
                            highlightColor: Colors.yellow,
                            child: SvgPicture.asset(
                              "assets/deer.svg",
                              height: constraints.maxHeight * 0.4,
                              width: constraints.maxHeight * 0.4,
                            ),
                          ),
                        )),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
