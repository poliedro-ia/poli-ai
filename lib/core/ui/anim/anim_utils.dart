// lib/core/ui/anim/anim_utils.dart
import 'dart:async';
import 'package:flutter/material.dart';

class FadeSlide extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset beginOffset;
  final Curve curve;

  const FadeSlide({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 480),
    this.delay = Duration.zero,
    this.beginOffset = const Offset(0, .06),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<FadeSlide> createState() => _FadeSlideState();
}

class _FadeSlideState extends State<FadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    final curved = CurvedAnimation(parent: _c, curve: widget.curve);
    _fade = Tween<double>(begin: 0, end: 1).animate(curved);
    _slide = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(curved);
    if (widget.delay > Duration.zero) {
      _t = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class ScaleIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double begin;
  final Curve curve;

  const ScaleIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 420),
    this.delay = Duration.zero,
    this.begin = .96,
    this.curve = Curves.easeOutBack,
  });

  @override
  State<ScaleIn> createState() => _ScaleInState();
}

class _ScaleInState extends State<ScaleIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    final curved = CurvedAnimation(parent: _c, curve: widget.curve);
    _scale = Tween<double>(begin: widget.begin, end: 1).animate(curved);
    if (widget.delay > Duration.zero) {
      _t = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}

class ScaleOnTap extends StatefulWidget {
  final Widget child;
  final double pressedScale;
  final Duration duration;
  final VoidCallback? onTap;

  const ScaleOnTap({
    super.key,
    required this.child,
    this.pressedScale = .96,
    this.duration = const Duration(milliseconds: 100),
    this.onTap,
  });

  @override
  State<ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<ScaleOnTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.duration,
      lowerBound: widget.pressedScale,
      upperBound: 1,
      value: 1,
    );
    _s = _c.drive(Tween(begin: widget.pressedScale, end: 1));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.reverse(),
      onTapCancel: () => _c.forward(),
      onTapUp: (_) async {
        await _c.forward();
        widget.onTap?.call();
      },
      child: ScaleTransition(scale: _s, child: widget.child),
    );
  }
}

class StaggerList extends StatelessWidget {
  final List<Widget> children;
  final Duration unit;
  final Duration base;

  const StaggerList({
    super.key,
    required this.children,
    this.unit = const Duration(milliseconds: 60),
    this.base = const Duration(milliseconds: 90),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(children.length, (i) {
        final d = base + unit * i;
        return FadeSlide(delay: d, child: children[i]);
      }),
    );
  }
}

class Shimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const Shimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1300),
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        return ShaderMask(
          shaderCallback: (r) {
            final g = LinearGradient(
              begin: Alignment(-1 - 2 * _c.value, 0),
              end: const Alignment(1, 0),
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(.35),
                Colors.transparent,
              ],
              stops: const [0.35, 0.5, 0.65],
            );
            return g.createShader(r);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
