// ignore_for_file: file_names

import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class StandardButton extends StatelessWidget {
  const StandardButton(
      {super.key,
      required this.child,
      required this.onTap,
      this.tooltipMessage});
  final Widget child;
  final Future<void> Function() onTap;
  final String? tooltipMessage;
  @override
  Widget build(BuildContext context) {
    return Button(
      animationDuration: const Duration(milliseconds: 100),
      slowDownDuration: const Duration(milliseconds: 200),
      onTap: onTap,
      tooltipMessage: tooltipMessage,
      child: child,
    );
  }
}

class CanBeOffStandardButton extends StatelessWidget {
  const CanBeOffStandardButton(
      {super.key,
      required this.child,
      required this.onTap,
      this.onOffTap,
      this.isOff = false,
      this.offOpacity = 0.4,
      this.tooltipMessage});
  final Widget child;
  final bool isOff;
  final double offOpacity;
  final void Function() onTap;
  final void Function()? onOffTap;
  final String? tooltipMessage;
  @override
  Widget build(BuildContext context) {
    if (isOff) {
      return GestureDetector(
          onTap: onOffTap, child: Opacity(opacity: offOpacity, child: child));
    } else {
      return Button(
        animationDuration: const Duration(milliseconds: 100),
        slowDownDuration: const Duration(milliseconds: 50),
        scaleDownFraction: 0.02,
        opateDownFraction: 0.4,
        onTap: onTap,
        tooltipMessage: tooltipMessage,
        child: child,
      );
    }
  }
}

enum TransformEffect { scaleNOpacity, rotate }

class Button extends StatefulWidget {
  const Button(
      {super.key,
      this.shouldOpateDown = true,
      required this.child,
      this.tooltipMessage,
      this.onTap,
      this.hitTestBehavior,
      this.onTapDown,
      this.onTapUp,
      this.onTapCancel,
      this.onLongPress,
      this.onLongPressDown,
      this.onLongPressUp,
      this.onLongPressCancel,
      this.onDoubleTap,
      this.onDoubleTapCancel,
      this.onDoubleTapDown,
      this.onAnimation,
      this.animationDuration,
      this.slowDownDuration,
      this.scaleDownFraction = .03,
      this.opateDownFraction = .5,
      this.shouldTapAfterAnimation = false,
      this.animationCurve,
      this.effect = TransformEffect.scaleNOpacity,
      this.reverseAnimationCurve})
      : assert(opateDownFraction <= 1,
            'Opacity on push down fraction should be less than 1.0'),

        /// i prefer it this way assert that this is never happens
        assert(!(tooltipMessage != null && onLongPress != null),
            'onLongPress and tooltipMessage cannot be provided together');

  final bool shouldOpateDown;
  final bool shouldTapAfterAnimation;
  final Widget child;
  final double scaleDownFraction;
  final double opateDownFraction;
  final Duration? animationDuration;
  final Duration? slowDownDuration;
  final Curve? animationCurve;
  final HitTestBehavior? hitTestBehavior;
  final Curve? reverseAnimationCurve;
  final TransformEffect effect;
  final String? tooltipMessage;

  final void Function()? onTap;
  final void Function(TapDownDetails)? onTapDown;
  final void Function(TapUpDetails)? onTapUp;
  final void Function()? onTapCancel;
  final void Function(LongPressDownDetails)? onLongPressDown;
  final void Function()? onLongPressUp;
  final void Function()? onLongPressCancel;
  final void Function()? onLongPress;
  final void Function()? onDoubleTap;
  final void Function()? onDoubleTapCancel;
  final void Function(TapDownDetails)? onDoubleTapDown;
  final void Function(double opacity)? onAnimation;
  @override
  State<Button> createState() => _ButtonState();
}

class _ButtonState extends State<Button> with SingleTickerProviderStateMixin {
  late Animation<double> animation;
  late AnimationController _controller;
  late Duration animationDuration;
  double opacity = 1.0;

  @override
  void initState() {
    animationDuration =
        widget.animationDuration ?? const Duration(milliseconds: 150);
    _controller = AnimationController(
      vsync: this,
      duration: animationDuration,
    )..addListener(() {
        setState(() {
          opacity = opacityAnimationResolver(animation.value);
        });
        if (widget.onAnimation != null) {
          widget.onAnimation!(animation.value);
        }
      });
    animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
        parent: _controller,
        curve: widget.animationCurve ?? Curves.linear,
        reverseCurve: widget.reverseAnimationCurve ?? const SpringCurve()));
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double opacityAnimationResolver(double scale) {
    return 1 - animation.value * widget.opateDownFraction;
  }

  @override
  Widget build(BuildContext context) {
    var myWidget = widget.effect == TransformEffect.scaleNOpacity
        ? Transform.scale(
            scale: (1 - animation.value * widget.scaleDownFraction),
            child: widget.shouldOpateDown
                ? Opacity(
                    opacity: opacity,
                    child: widget.child,
                  )
                : widget.child,
          )
        : Transform.rotate(
            angle: (animation.value - 1),
            child: widget.child,
          );
    return RepaintBoundary(
      child: GestureDetector(
        behavior: widget.hitTestBehavior,
        onDoubleTapDown: widget.onDoubleTapDown,
        onDoubleTap: widget.onDoubleTap,
        onDoubleTapCancel: widget.onDoubleTapCancel,
        onTap: widget.shouldTapAfterAnimation
            ? () {
                if (widget.onTap != null) {
                  var duration = animationDuration;
                  if (widget.slowDownDuration != null) {
                    duration = Duration(
                        milliseconds: duration.inMilliseconds +
                            widget.slowDownDuration!.inMilliseconds);
                  }
                  Future.delayed(duration, widget.onTap);
                }
              }
            : widget.onTap,
        onLongPress: widget.onLongPress,
        onLongPressUp: widget.onLongPressUp,
        onLongPressCancel: widget.onDoubleTapCancel,
        onLongPressDown: widget.onLongPressDown,
        onTapUp: (details) {
          if (widget.slowDownDuration != null) {
            Future.delayed(widget.slowDownDuration!, () {
              _onTapUp(details);
            });
          } else {
            _onTapUp(details);
          }
        },
        onTapDown: (details) {
          _controller.forward();
          if (widget.onTapDown != null) {
            widget.onTapDown!(details);
          }
        },
        onTapCancel: () async {
          if (widget.slowDownDuration != null) {
            await Future.delayed(widget.slowDownDuration!);
          }
          _controller.reverse();
          if (widget.onTapCancel != null) {
            widget.onTapCancel!();
          }
        },
        child: widget.tooltipMessage != null
            ? Tooltip(
                message: widget.tooltipMessage,
                child: myWidget,
              )
            : myWidget,
      ),
    );
  }

  void _onTapUp(TapUpDetails details) {
    if (mounted) {
      _controller.reverse();
      if (widget.onTapUp != null) {
        widget.onTapUp!(details);
      }
    }
  }
}

class SpringCurve extends Curve {
  const SpringCurve({
    this.a = 0.2,
    this.w = 7,
  });
  final double a;
  final double w;

  @override
  double transformInternal(double t) {
    return -(pow(e, -t / a) * cos(t * w)) + 1;
  }

  static const SpringCurve gelly = SpringCurve(a: .2, w: 3);
}
