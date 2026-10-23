import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../content/models.dart';

/// Logical size every screen is designed at; [PhoneFrame] scales it to fit.
const _screen = Size(200, 426);

/// A modern phone with bezel, dynamic island and side buttons.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({
    super.key,
    required this.width,
    required this.screen,
    this.glow = true,
  });

  final double width;

  /// Content designed at 200×426 logical pixels.
  final Widget screen;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final height = width * 2.05;
    final bezel = width * 0.035;
    final radius = width * 0.16;

    Widget button(double top, double length, {bool right = false}) =>
        Positioned(
          top: height * top,
          left: right ? null : -2.5,
          right: right ? -2.5 : null,
          child: Container(
            width: 3,
            height: height * length,
            decoration: BoxDecoration(
              color: const Color(0xFF3A3F4B),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          button(0.17, 0.05),
          button(0.25, 0.09),
          button(0.36, 0.09),
          button(0.26, 0.13, right: true),
          Container(
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF5B6272),
                  Color(0xFF15181F),
                  Color(0xFF3A3F4B),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 40,
                  offset: const Offset(0, 30),
                ),
                if (glow)
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.22),
                    blurRadius: 70,
                    spreadRadius: -10,
                  ),
              ],
            ),
            child: Container(
              padding: EdgeInsets.all(bezel),
              decoration: BoxDecoration(
                color: const Color(0xFF08090C),
                borderRadius: BorderRadius.circular(radius - 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius - bezel),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox.fromSize(size: _screen, child: screen),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        margin: EdgeInsets.only(top: width * 0.03),
                        width: width * 0.3,
                        height: width * 0.085,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(width),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({this.time = '9:41'});
  final String time;
  static const color = Colors.white;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: color,
      fontSize: 9,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 9, 16, 0),
      child: Row(
        children: [
          Text(time, style: style),
          const Spacer(),
          Icon(Icons.signal_cellular_alt, size: 10, color: color),
          const SizedBox(width: 3),
          Icon(Icons.wifi, size: 10, color: color),
          const SizedBox(width: 3),
          Icon(Icons.battery_full, size: 11, color: color),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Project screens

const _palettes = [
  [Color(0xFF14B8A6), Color(0xFF0E7490)],
  [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  [Color(0xFFF97316), Color(0xFFEF4444)],
  [Color(0xFF0EA5E9), Color(0xFF2563EB)],
  [Color(0xFFEC4899), Color(0xFF8B5CF6)],
  [Color(0xFF22C55E), Color(0xFF0D9488)],
  [Color(0xFFF59E0B), Color(0xFFEA580C)],
];

IconData iconForCategory(String category) {
  final c = category.toLowerCase();
  if (c.contains('fitness') || c.contains('gym')) return Icons.fitness_center;
  if (c.contains('bank') || c.contains('finance')) return Icons.account_balance;
  if (c.contains('insurance')) return Icons.health_and_safety;
  if (c.contains('tele') || c.contains('health') || c.contains('clinic')) {
    return Icons.medical_services;
  }
  if (c.contains('commerce') || c.contains('shop')) return Icons.shopping_bag;
  if (c.contains('learn') || c.contains('edu')) return Icons.school;
  if (c.contains('taxi') || c.contains('ride')) return Icons.local_taxi;
  if (c.contains('theme') || c.contains('design')) return Icons.palette;
  if (c.contains('web') || c.contains('desktop')) return Icons.desktop_mac;
  return Icons.apps;
}

/// The project's screenshot if it has one, otherwise a generated app screen.
class ProjectScreen extends StatelessWidget {
  const ProjectScreen(this.project, {super.key});
  final Project project;

  @override
  Widget build(BuildContext context) {
    final mock = _MockAppScreen(project);
    if (project.image.isEmpty) return mock;
    return Image.asset(
      project.image,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => mock,
    );
  }
}

class _MockAppScreen extends StatelessWidget {
  const _MockAppScreen(this.project);
  final Project project;

  @override
  Widget build(BuildContext context) {
    final seed = project.title.codeUnits.fold(0, (a, b) => a + b);
    final colors = _palettes[seed % _palettes.length];
    final bars = [
      for (var i = 0; i < 7; i++) 0.3 + ((seed * (i + 3)) % 70) / 100,
    ];
    const body = Color(0xFFF3F5FA);

    Widget skeleton(double width, {double height = 6, Color? color}) =>
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color ?? const Color(0xFFDDE2EC),
            borderRadius: BorderRadius.circular(height),
          ),
        );

    Widget listRow(IconData icon) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: colors[0].withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: colors[0]),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                skeleton(70, color: const Color(0xFFC7CEDB)),
                const SizedBox(height: 5),
                skeleton(110),
              ],
            ),
          ),
        ],
      ),
    );

    final icon = iconForCategory(project.category);
    return ColoredBox(
      color: body,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _StatusBar(),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              project.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 8.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 70,
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final (i, b) in bars.indexed)
                          FractionallySizedBox(
                            heightFactor: b,
                            child: Container(
                              width: 12,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(
                                  alpha: i == bars.length - 2 ? 1 : 0.55,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      skeleton(60, height: 7, color: const Color(0xFF9AA4B8)),
                      const Spacer(),
                      skeleton(24, height: 7, color: colors[0]),
                    ],
                  ),
                  const SizedBox(height: 10),
                  listRow(icon),
                  listRow(Icons.insights),
                  listRow(Icons.notifications_none),
                ],
              ),
            ),
          ),
          Container(
            height: 44,
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(Icons.home_rounded, size: 17, color: colors[0]),
                const Icon(Icons.search, size: 17, color: Color(0xFFB4BCCB)),
                const Icon(
                  Icons.bar_chart_rounded,
                  size: 17,
                  color: Color(0xFFB4BCCB),
                ),
                const Icon(
                  Icons.person_outline,
                  size: 17,
                  color: Color(0xFFB4BCCB),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lock screen

class LockNotification {
  const LockNotification(this.app, this.title, this.icon, {this.body = ''});
  final String app;
  final String title;
  final String body;
  final IconData icon;
}

/// iOS-style lock screen: the photo as wallpaper (treated for a black and
/// white image), a live clock and notifications that pop in one by one.
class LockScreen extends StatefulWidget {
  const LockScreen({
    super.key,
    required this.photo,
    required this.initials,
    required this.notifications,
  });

  final String photo;
  final String initials;
  final List<LockNotification> notifications;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  Timer? _timer;
  var _now = DateTime.now();
  var _step = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      setState(() {
        _now = DateTime.now();
        // Show notifications one by one, hold, then start again.
        _step = (_step + 1) % (widget.notifications.length + 6);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final time =
        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';
    final date =
        '${_days[_now.weekday - 1]}, ${_now.day} ${_months[_now.month - 1]}';

    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1F2937),
            scheme.secondary.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Align(
        alignment: const Alignment(0, -0.2),
        child: Text(
          widget.initials,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 72,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ),
      ),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.photo.isEmpty)
          fallback
        else
          // Force greyscale so the accent tint below sits evenly on top.
          ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              0.2126, 0.7152, 0.0722, 0, 0, //
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0, 0, 0, 1, 0,
            ]),
            child: Image.asset(
              widget.photo,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.4),
              errorBuilder: (_, _, _) => fallback,
            ),
          ),
        // Subtle duotone wash in the brand colours.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary.withValues(alpha: 0.18),
                Colors.transparent,
                scheme.secondary.withValues(alpha: 0.22),
              ],
            ),
          ),
        ),
        // Scrims keep the clock and notifications readable on any photo.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, 0.3, 0.5, 1],
              colors: [
                Colors.black.withValues(alpha: 0.45),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: 0.85),
              ],
            ),
          ),
        ),
        Column(
          children: [
            _StatusBar(time: time),
            const SizedBox(height: 22),
            Text(
              date,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              time,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 54,
                fontWeight: FontWeight.w600,
                height: 1.05,
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  for (final (i, n) in widget.notifications.indexed)
                    _NotificationCard(n, visible: i < _step),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final icon in [Icons.flashlight_on, Icons.photo_camera])
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                      child: Icon(icon, size: 14, color: Colors.white),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: 70,
              height: 3.5,
              margin: const EdgeInsets.only(bottom: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard(this.n, {required this.visible});
  final LockNotification n;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const duration = Duration(milliseconds: 450);
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: duration,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 0.4),
        duration: duration,
        curve: Curves.easeOutBack,
        child: AnimatedScale(
          scale: visible ? 1 : 0.92,
          duration: duration,
          curve: Curves.easeOutBack,
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    gradient: LinearGradient(
                      colors: [scheme.primary, scheme.secondary],
                    ),
                  ),
                  child: Icon(n.icon, size: 13, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              n.app.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 6.5,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Text(
                            'now',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 6.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        n.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (n.body.isNotEmpty)
                        Text(
                          n.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 7.5,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
