import 'package:flutter/material.dart';

class Motion extends InheritedWidget {
  final Duration base;
  const Motion({super.key, required this.base, required super.child});

  static Motion of(BuildContext context) {
    final m = context.dependOnInheritedWidgetOfExactType<Motion>();
    return m ??
        const Motion(base: Duration(milliseconds: 300), child: SizedBox());
  }

  @override
  bool updateShouldNotify(covariant Motion oldWidget) => base != oldWidget.base;
}

class Entry extends StatefulWidget {
  final Widget child;
  final Duration? delay;
  final Duration? duration;
  final double dy;
  final double dx;
  final double beginScale;
  final Curve curve;
  final bool enabled;
  const Entry({
    super.key,
    required this.child,
    this.delay,
    this.duration,
    this.dy = 12,
    this.dx = 0,
    this.beginScale = 1.0,
    this.curve = Curves.easeOutCubic,
    this.enabled = true,
  });

  @override
  State<Entry> createState() => _EntryState();
}

class _EntryState extends State<Entry> with SingleTickerProviderStateMixin {
  late final AnimationController c;
  late final Animation<double> fade;
  late final Animation<Offset> slide;
  late final Animation<double> scale;

  @override
  void initState() {
    super.initState();
    c = AnimationController(
      vsync: this,
      duration: widget.duration ?? const Duration(milliseconds: 500),
    );
    final curved = CurvedAnimation(parent: c, curve: widget.curve);
    fade = Tween<double>(begin: 0, end: 1).animate(curved);
    slide = Tween<Offset>(
      begin: Offset(widget.dx / 100, widget.dy / 100),
      end: Offset.zero,
    ).animate(curved);
    scale = Tween<double>(begin: widget.beginScale, end: 1).animate(curved);
    Future<void>.delayed(widget.delay ?? Duration.zero, () {
      if (mounted && widget.enabled) c.forward();
      if (mounted && !widget.enabled) c.value = 1;
    });
  }

  @override
  void didUpdateWidget(covariant Entry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && c.value != 1) c.value = 1;
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: ScaleTransition(scale: scale, child: widget.child),
      ),
    );
  }
}

class Stagger extends StatelessWidget {
  final List<Widget> children;
  final Duration interval;
  final Duration startDelay;
  final double dy;
  final double dx;
  final double beginScale;
  final Curve curve;
  final bool enabled;
  const Stagger({
    super.key,
    required this.children,
    this.interval = const Duration(milliseconds: 70),
    this.startDelay = Duration.zero,
    this.dy = 10,
    this.dx = 0,
    this.beginScale = 1.0,
    this.curve = Curves.easeOutCubic,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(children.length, (i) {
        return Entry(
          delay: startDelay + interval * i,
          dy: dy,
          dx: dx,
          beginScale: beginScale,
          curve: curve,
          enabled: enabled,
          child: children[i],
        );
      }),
    );
  }
}

class Switcher extends StatelessWidget {
  final Widget child;
  final Duration duration;
  const Switcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 350),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (w, anim) {
        final slide = Tween<Offset>(
          begin: const Offset(0, .08),
          end: Offset.zero,
        ).animate(anim);
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(position: slide, child: w),
        );
      },
      child: child,
    );
  }
}
