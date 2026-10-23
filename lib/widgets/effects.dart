import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

bool _reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Slowly drifting dots joined by faint lines when close together.
class ParticleField extends StatefulWidget {
  const ParticleField({super.key, this.count = 60});
  final int count;

  @override
  State<ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<ParticleField>
    with SingleTickerProviderStateMixin {
  final _random = math.Random(7);
  final _frame = ValueNotifier(0);
  late final List<_Particle> _particles = List.generate(
    widget.count,
    (_) => _Particle(
      _random.nextDouble(),
      _random.nextDouble(),
      (_random.nextDouble() - 0.5) * 0.02,
      (_random.nextDouble() - 0.5) * 0.02,
      1 + _random.nextDouble() * 1.5,
    ),
  );
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion(context)) {
      _ticker.stop();
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    for (final p in _particles) {
      p.x = (p.x + p.vx * dt) % 1;
      p.y = (p.y + p.vy * dt) % 1;
    }
    _frame.value++;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _ParticlePainter(
          _particles,
          Theme.of(context).colorScheme.primary,
          _frame,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _Particle {
  _Particle(this.x, this.y, this.vx, this.vy, this.radius);
  double x, y;
  final double vx, vy, radius;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.particles, this.color, Listenable repaint)
    : super(repaint: repaint);

  final List<_Particle> particles;
  final Color color;
  static const _linkDistance = 140.0;

  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      for (final p in particles) Offset(p.x * size.width, p.y * size.height),
    ];
    final line = Paint()..strokeWidth = 1;
    for (var i = 0; i < points.length; i++) {
      for (var j = i + 1; j < points.length; j++) {
        final d = (points[i] - points[j]).distance;
        if (d < _linkDistance) {
          line.color = color.withValues(alpha: 0.16 * (1 - d / _linkDistance));
          canvas.drawLine(points[i], points[j], line);
        }
      }
    }
    final dot = Paint()..color = color.withValues(alpha: 0.45);
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], particles[i].radius, dot);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.color != color;
}

/// Soft spotlight that follows the mouse over [child].
class CursorGlow extends StatefulWidget {
  const CursorGlow({super.key, required this.child});
  final Widget child;

  @override
  State<CursorGlow> createState() => _CursorGlowState();
}

class _CursorGlowState extends State<CursorGlow> {
  final _position = ValueNotifier<Offset?>(null);

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      opaque: false,
      onHover: (e) => _position.value = e.localPosition,
      onExit: (_) => _position.value = null,
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _GlowPainter(
                  _position,
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter(this.position, this.color) : super(repaint: position);
  final ValueNotifier<Offset?> position;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = position.value;
    if (p == null) return;
    const radius = 320.0;
    canvas.drawCircle(
      p,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.09), color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: p, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.color != color;
}

/// Text filled with the primary → secondary gradient.
class GradientText extends StatelessWidget {
  const GradientText(this.text, {super.key, this.style, this.textAlign});
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        colors: [scheme.primary, scheme.secondary],
      ).createShader(bounds),
      child: Text(text, style: style, textAlign: textAlign),
    );
  }
}

/// Tilts [child] in 3D towards the mouse pointer.
class Tilt3D extends StatefulWidget {
  const Tilt3D({
    super.key,
    required this.child,
    this.maxAngle = 0.25,
    this.restX = 0,
    this.restY = 0,
  });

  final Widget child;

  /// Maximum rotation in radians at the card edge.
  final double maxAngle;

  /// Resting rotation when the pointer is away.
  final double restX, restY;

  @override
  State<Tilt3D> createState() => _Tilt3DState();
}

class _Tilt3DState extends State<Tilt3D> {
  Offset _tilt = Offset.zero;
  bool _hover = false;

  void _update(Offset local) {
    final size = context.size;
    if (size == null || size.isEmpty) return;
    setState(() {
      _hover = true;
      _tilt = Offset(
        (local.dx / size.width - 0.5) * 2,
        (local.dy / size.height - 0.5) * 2,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final target = _hover
        ? Offset(_tilt.dx * widget.maxAngle, -_tilt.dy * widget.maxAngle)
        : Offset(widget.restY, widget.restX);
    return MouseRegion(
      onHover: (e) => _update(e.localPosition),
      onExit: (_) => setState(() => _hover = false),
      child: TweenAnimationBuilder<Offset>(
        tween: Tween(end: target),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        builder: (context, angle, child) => Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateX(angle.dy)
            ..rotateY(angle.dx),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Gently bobs [child] up and down.
class Floating extends StatefulWidget {
  const Floating({
    super.key,
    required this.child,
    this.distance = 10,
    this.period = const Duration(seconds: 5),
  });
  final Widget child;
  final double distance;
  final Duration period;

  @override
  State<Floating> createState() => _FloatingState();
}

class _FloatingState extends State<Floating>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.translate(
        offset: Offset(
          0,
          math.sin(_controller.value * 2 * math.pi) * widget.distance,
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Chips circling [child] on an ellipse.
class Orbit extends StatefulWidget {
  const Orbit({
    super.key,
    required this.child,
    required this.items,
    required this.radiusX,
    required this.radiusY,
    this.period = const Duration(seconds: 40),
  });

  final Widget child;
  final List<Widget> items;
  final double radiusX, radiusY;
  final Duration period;

  @override
  State<Orbit> createState() => _OrbitState();
}

class _OrbitState extends State<Orbit> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final n = widget.items.length;
        final placed = [
          for (var i = 0; i < n; i++)
            () {
              final angle = (_controller.value + i / n) * 2 * math.pi;
              // Items at the bottom of the ellipse are "in front".
              final depth = (math.sin(angle) + 1) / 2;
              return (
                depth,
                Transform.translate(
                  offset: Offset(
                    math.cos(angle) * widget.radiusX,
                    math.sin(angle) * widget.radiusY,
                  ),
                  child: Transform.scale(
                    scale: 0.8 + depth * 0.25,
                    child: Opacity(
                      opacity: 0.45 + depth * 0.55,
                      child: widget.items[i],
                    ),
                  ),
                ),
              );
            }(),
        ]..sort((a, b) => a.$1.compareTo(b.$1));
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            for (final p in placed)
              if (p.$1 < 0.5) p.$2,
            child!,
            for (final p in placed)
              if (p.$1 >= 0.5) p.$2,
          ],
        );
      },
      child: widget.child,
    );
  }
}

/// An endless, auto-scrolling horizontal row. Pauses on hover.
class Marquee extends StatefulWidget {
  const Marquee({
    super.key,
    required this.children,
    this.height = 48,
    this.speed = 40,
    this.reverse = false,
  });

  final List<Widget> children;
  final double height;

  /// Pixels per second.
  final double speed;
  final bool reverse;

  @override
  State<Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<Marquee> with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;
  bool _paused = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion(context)) {
      _ticker.stop();
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (_paused || !_scroll.hasClients) return;
    _scroll.jumpTo(_scroll.offset + widget.speed * dt);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) return const SizedBox.shrink();
    return MouseRegion(
      onEnter: (_) => _paused = true,
      onExit: (_) => _paused = false,
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) => const LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [0, 0.1, 0.9, 1],
        ).createShader(bounds),
        child: SizedBox(
          height: widget.height,
          child: ListView.builder(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            reverse: widget.reverse,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: widget.children[i % widget.children.length],
            ),
          ),
        ),
      ),
    );
  }
}

/// Counts the number in [value] (e.g. "10+") up from zero.
class CountUp extends StatelessWidget {
  const CountUp(this.value, {super.key, this.style});
  final String value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final m = RegExp(r'^(\D*)(\d+)(.*)$').firstMatch(value);
    if (m == null) return Text(value, style: style);
    final target = int.parse(m.group(2)!);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target.toDouble()),
      duration: const Duration(milliseconds: 1800),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) =>
          Text('${m.group(1)}${v.round()}${m.group(3)}', style: style),
    );
  }
}

/// Types and deletes each of [words] in turn, with a blinking cursor.
class Typewriter extends StatefulWidget {
  const Typewriter({super.key, required this.words, this.style});
  final List<String> words;
  final TextStyle? style;

  @override
  State<Typewriter> createState() => _TypewriterState();
}

class _TypewriterState extends State<Typewriter> {
  Timer? _timer;
  var _word = 0;
  var _chars = 0;
  var _deleting = false;
  var _hold = 0;
  var _ticks = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 70), (_) => _tick());
  }

  void _tick() {
    if (widget.words.isEmpty) return;
    final word = widget.words[_word % widget.words.length];
    setState(() {
      _ticks++;
      if (_hold > 0) {
        _hold--;
      } else if (!_deleting) {
        if (_chars < word.length) {
          _chars++;
        } else {
          _deleting = true;
          _hold = 22;
        }
      } else if (_chars > 0) {
        _chars--;
      } else {
        _deleting = false;
        _word++;
        _hold = 4;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.words.isEmpty) return const SizedBox.shrink();
    final word = widget.words[_word % widget.words.length];
    final cursorOn = (_ticks ~/ 7).isEven || (!_deleting && _hold == 0);
    return Text.rich(
      TextSpan(
        style: widget.style,
        children: [
          TextSpan(text: word.substring(0, _chars.clamp(0, word.length))),
          TextSpan(
            text: '▍',
            style: TextStyle(
              color:
                  (widget.style?.color ?? Theme.of(context).colorScheme.primary)
                      .withValues(alpha: cursorOn ? 1 : 0),
            ),
          ),
        ],
      ),
    );
  }
}

/// Turns coarse mouse-wheel steps into eased scrolling. Place it *inside* the
/// scroll view (around its content) so it claims wheel events before the
/// scrollable does. Trackpads, which already send fine-grained deltas, pass
/// straight through.
class SmoothWheelScroll extends StatefulWidget {
  const SmoothWheelScroll({
    super.key,
    required this.controller,
    required this.child,
  });
  final ScrollController controller;
  final Widget child;

  @override
  State<SmoothWheelScroll> createState() => _SmoothWheelScrollState();
}

class _SmoothWheelScrollState extends State<SmoothWheelScroll>
    with SingleTickerProviderStateMixin {
  // Glides towards [_target] frame by frame with jumpTo. (animateTo would
  // block pointer input while running, so a second wheel step mid-glide
  // would bypass this widget and cut the motion short.)
  late final Ticker _ticker;
  double? _target;
  double? _lastSet;
  Duration _last = Duration.zero;

  ScrollPosition get _pos => widget.controller.position;

  @override
  void initState() {
    super.initState();
    // Created eagerly: a lazy ticker first touched in dispose() would look up
    // ancestors of an already-deactivated element.
    _ticker = createTicker(_tick);
  }

  void _onSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final dy = event.scrollDelta.dy;
    if (dy == 0 || !widget.controller.hasClients) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      final pos = _pos;
      double clamp(double v) =>
          v.clamp(pos.minScrollExtent, pos.maxScrollExtent).toDouble();
      // Trackpads already send fine-grained deltas: apply them directly.
      if (dy.abs() < 40 || _reduceMotion(context)) {
        _stop();
        pos.jumpTo(clamp(pos.pixels + dy));
        return;
      }
      _target = clamp((_target ?? pos.pixels) + dy * 1.1);
      if (!_ticker.isActive) {
        _last = Duration.zero;
        _lastSet = pos.pixels;
        _ticker.start();
      }
    });
  }

  void _tick(Duration elapsed) {
    final target = _target;
    if (target == null || !widget.controller.hasClients) return _stop();
    final pos = _pos;
    // Something else moved the page (drag, nav link, keyboard): yield to it.
    if (_lastSet != null && (pos.pixels - _lastSet!).abs() > 0.5) {
      return _stop();
    }
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final remaining = target - pos.pixels;
    if (remaining.abs() < 0.5) {
      pos.jumpTo(target);
      return _stop();
    }
    // Exponential ease-out: covers ~1 - e^(-10t) of the distance.
    final next = pos.pixels + remaining * (1 - math.exp(-10 * dt));
    pos.jumpTo(next);
    _lastSet = pos.pixels;
  }

  void _stop() {
    _target = null;
    _lastSet = null;
    if (_ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Translucent so wheel events over empty space are caught too, not just
    // over painted widgets.
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerSignal: _onSignal,
      child: widget.child,
    );
  }
}

/// Shifts [child] by a fraction of the page scroll offset for depth.
class Parallax extends StatelessWidget {
  const Parallax({super.key, required this.child, this.factor = 0.3});
  final Widget child;

  /// Positive values make the child lag behind the scroll.
  final double factor;

  @override
  Widget build(BuildContext context) {
    final position = Scrollable.maybeOf(context, axis: Axis.vertical)?.position;
    if (position == null || _reduceMotion(context)) return child;
    return AnimatedBuilder(
      animation: position,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, position.pixels.clamp(0, 1200) * factor),
        child: child,
      ),
      child: child,
    );
  }
}

/// Pulls [child] slightly towards the mouse pointer while hovered.
class Magnetic extends StatefulWidget {
  const Magnetic({super.key, required this.child, this.strength = 0.25});
  final Widget child;
  final double strength;

  @override
  State<Magnetic> createState() => _MagneticState();
}

class _MagneticState extends State<Magnetic> {
  var _offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (e) {
        final size = context.size;
        if (size == null) return;
        setState(
          () => _offset =
              (e.localPosition - size.center(Offset.zero)) * widget.strength,
        );
      },
      onExit: (_) => setState(() => _offset = Offset.zero),
      child: TweenAnimationBuilder<Offset>(
        tween: Tween(end: _offset),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, o, child) =>
            Transform.translate(offset: o, child: child),
        child: widget.child,
      ),
    );
  }
}

/// Text whose words (or letters) slide up from a mask one after another.
/// [progress] runs 0 → 1; drive it with `Reveal.builder`.
class StaggeredText extends StatelessWidget {
  const StaggeredText(
    this.text, {
    super.key,
    required this.progress,
    this.style,
    this.byLetter = false,
    this.gradient = false,
    this.textAlign = TextAlign.start,
  });

  final String text;
  final double progress;
  final TextStyle? style;
  final bool byLetter;
  final bool gradient;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final words = text.split(' ');
    final n = byLetter ? text.replaceAll(' ', '').length : words.length;
    // Each unit animates over half the timeline, starting in sequence.
    double unitT(int i) {
      final start = n <= 1 ? 0.0 : i / (n - 1) * 0.5;
      return Curves.easeOutCubic.transform(
        ((progress - start) / 0.5).clamp(0.0, 1.0),
      );
    }

    Widget unit(String s, int i) => ClipRect(
      child: FractionalTranslation(
        translation: Offset(0, 1 - unitT(i)),
        child: Opacity(
          opacity: unitT(i),
          child: Text(s, style: style),
        ),
      ),
    );

    // Words stay intact so lines only break between them.
    var index = 0;
    final children = <Widget>[];
    for (var w = 0; w < words.length; w++) {
      final word = w == words.length - 1 ? words[w] : '${words[w]} ';
      if (byLetter) {
        final letters = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final ch in word.split(''))
              ch == ' ' ? Text(' ', style: style) : unit(ch, index++),
          ],
        );
        // A word wider than the line shrinks to fit instead of overflowing.
        children.add(
          LayoutBuilder(
            builder: (context, constraints) => ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: FittedBox(fit: BoxFit.scaleDown, child: letters),
            ),
          ),
        );
      } else {
        children.add(unit(word, index++));
      }
    }

    Widget wrap = Wrap(
      alignment: switch (textAlign) {
        TextAlign.center => WrapAlignment.center,
        TextAlign.end || TextAlign.right => WrapAlignment.end,
        _ => WrapAlignment.start,
      },
      children: children,
    );

    if (gradient) {
      final scheme = Theme.of(context).colorScheme;
      wrap = ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => LinearGradient(
          colors: [scheme.primary, scheme.secondary],
        ).createShader(bounds),
        child: wrap,
      );
    }
    return Semantics(label: text, excludeSemantics: true, child: wrap);
  }
}

/// Snaps a list with fixed-size items so one item always settles centred.
class SnapScrollPhysics extends ScrollPhysics {
  const SnapScrollPhysics({required this.itemExtent, super.parent});
  final double itemExtent;

  @override
  SnapScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      SnapScrollPhysics(itemExtent: itemExtent, parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tolerance = toleranceFor(position);
    var item = position.pixels / itemExtent;
    if (velocity < -tolerance.velocity) {
      item -= 0.5;
    } else if (velocity > tolerance.velocity) {
      item += 0.5;
    }
    final target = (item.roundToDouble() * itemExtent)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if ((target - position.pixels).abs() < tolerance.distance) return null;
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }
}
