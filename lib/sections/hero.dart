import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../content/models.dart';
import '../widgets/common.dart';
import '../widgets/effects.dart';
import '../widgets/phone.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({
    super.key,
    required this.portfolio,
    required this.onNavigate,
  });
  final Portfolio portfolio;

  /// Scrolls to the section with the given id.
  final void Function(String id) onNavigate;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 1000;

    final text = _HeroText(portfolio: portfolio, onNavigate: onNavigate);
    final devices = Parallax(
      factor: wide ? 0.18 : 0.08,
      child: _HeroDevices(portfolio: portfolio, compact: !wide),
    );

    return Container(
      constraints: BoxConstraints(
        minHeight: (size.height * 0.92).clamp(0, 940),
      ),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxContentWidth + 80),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            fluid(context, 16, 32),
            fluid(context, 96, 120),
            fluid(context, 16, 32),
            fluid(context, 40, 72),
          ),
          child: wide
              ? Row(
                  children: [
                    Expanded(flex: 6, child: text),
                    const SizedBox(width: 24),
                    Expanded(flex: 5, child: devices),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    text,
                    SizedBox(height: fluid(context, 40, 64)),
                    devices,
                  ],
                ),
        ),
      ),
    );
  }
}

class _HeroText extends StatelessWidget {
  const _HeroText({required this.portfolio, required this.onNavigate});
  final Portfolio portfolio;
  final void Function(String id) onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final contact = portfolio.contact;
    final projects = portfolio.sections
        .whereType<ProjectsSection>()
        .firstOrNull;

    // Elements enter one after another.
    var order = 0;
    Widget step(Widget child) => Reveal(
      delay: Duration(milliseconds: 120 * order++),
      child: child,
    );

    // The ongoing job, if any, so the badge says where you work now.
    final current = portfolio.sections
        .whereType<ExperienceSection>()
        .expand((s) => s.jobs)
        .where((j) => j.period.toLowerCase().contains('present'))
        .firstOrNull;

    final nameSize = width >= 1000
        ? (width * 0.052).clamp(56.0, 80.0)
        : (width * 0.11).clamp(40.0, 64.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        step(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              color: scheme.primary.withValues(alpha: 0.1),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _PulseDot(),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    current == null
                        ? "Hi, I'm"
                        : 'Currently at ${current.company}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Reveal.builder(
          delay: Duration(milliseconds: 120 * order++),
          duration: const Duration(milliseconds: 1400),
          builder: (context, t) => StaggeredText(
            portfolio.displayName,
            progress: t,
            byLetter: true,
            gradient: true,
            style: theme.textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.08,
              fontSize: nameSize,
              letterSpacing: -nameSize * 0.04,
            ),
          ),
        ),
        const SizedBox(height: 18),
        step(
          Text(
            portfolio.roleTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: fluid(context, 20, 26),
            ),
          ),
        ),
        if (portfolio.platforms.isNotEmpty) ...[
          const SizedBox(height: 10),
          step(
            Wrap(
              children: [
                Text(
                  'Shipping apps for ',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                    fontSize: fluid(context, 18, 22),
                  ),
                ),
                Typewriter(
                  words: portfolio.platforms,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: fluid(context, 18, 22),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (portfolio.tagline.isNotEmpty) ...[
          const SizedBox(height: 20),
          step(
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Text(
                portfolio.tagline,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: fluid(context, 16, 18),
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 32),
        step(
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (projects != null)
                Magnetic(
                  child: GlowButton(
                    label: 'View my work',
                    icon: Icons.arrow_downward,
                    onPressed: () => onNavigate(projects.id),
                  ),
                ),
              if (contact != null)
                Magnetic(
                  child: OutlinedButton(
                    onPressed: () => onNavigate(contact.id),
                    child: const Text('Get in touch'),
                  ),
                ),
              if (contact != null && contact.resumeUrl.isNotEmpty)
                TextButton.icon(
                  onPressed: () => openUrl(contact.resumeUrl),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Resume'),
                ),
            ],
          ),
        ),
        if (contact != null &&
            (contact.links.isNotEmpty ||
                contact.email.isNotEmpty ||
                contact.phone.isNotEmpty)) ...[
          const SizedBox(height: 20),
          step(
            Wrap(
              spacing: 4,
              children: [
                if (contact.email.isNotEmpty)
                  Magnetic(
                    strength: 0.4,
                    child: IconButton(
                      tooltip: 'Email',
                      onPressed: () => openUrl('mailto:${contact.email}'),
                      icon: const Icon(Icons.mail_outline),
                    ),
                  ),
                if (contact.phone.isNotEmpty)
                  Magnetic(
                    strength: 0.4,
                    child: IconButton(
                      tooltip: 'Call',
                      onPressed: () => openUrl(contact.phoneUrl),
                      icon: const Icon(Icons.phone_outlined),
                    ),
                  ),
                for (final link in contact.links)
                  Magnetic(
                    strength: 0.4,
                    child: IconButton(
                      tooltip: link.label,
                      onPressed: () => openUrl(link.url),
                      icon: Icon(iconForLabel(link.label)),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (portfolio.stats.isNotEmpty) ...[
          SizedBox(height: fluid(context, 32, 44)),
          step(
            LayoutBuilder(
              builder: (context, constraints) {
                // Four across when there's room, otherwise a 2×2 grid.
                const gap = 12.0;
                final columns = constraints.maxWidth >= 540
                    ? math.min(4, portfolio.stats.length)
                    : 2;
                final cardWidth = math.min(
                  (constraints.maxWidth - gap * (columns - 1)) / columns,
                  170.0,
                );
                // Cards in a row share the tallest card's height.
                final stats = portfolio.stats;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: gap,
                  children: [
                    for (var i = 0; i < stats.length; i += columns)
                      IntrinsicHeight(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: gap,
                          children: [
                            for (final s in stats.skip(i).take(columns))
                              SizedBox(
                                width: cardWidth,
                                child: _StatCard(stat: s),
                              ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _HeroDevices extends StatelessWidget {
  const _HeroDevices({required this.portfolio, required this.compact});
  final Portfolio portfolio;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final notifications = [
      const LockNotification(
        'CI/CD',
        'Pipeline passed ✓',
        Icons.rocket_launch,
        body: 'Release build ready for the stores',
      ),
      for (final s in portfolio.stats.take(2))
        LockNotification('Highlights', '${s.value} ${s.label}', Icons.bolt),
    ];

    // One short skill from each group orbits the phone.
    final skills = portfolio.sections
        .whereType<SkillsSection>()
        .expand((s) => s.groups)
        .map((g) => g.skills.firstOrNull)
        .whereType<String>()
        .where((s) => s.length <= 14)
        .take(6)
        .toList();

    final firstProject = portfolio.sections
        .whereType<ProjectsSection>()
        .expand((s) => s.projects)
        .firstOrNull;

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final phoneWidth = compact
            ? (available * 0.55).clamp(190.0, 240.0)
            : 270.0;
        // Keep orbiting chips (about 110px wide) on screen.
        final radiusX = math.min(
          phoneWidth * (compact ? 0.8 : 0.95),
          available / 2 - 60,
        );

        final main = Floating(
          child: Tilt3D(
            restY: -0.18,
            restX: 0.06,
            child: PhoneFrame(
              width: phoneWidth,
              screen: LockScreen(
                photo: portfolio.photo,
                initials: portfolio.initials,
                notifications: notifications,
              ),
            ),
          ),
        );

        // The phone rises into place, then settles.
        return Reveal.builder(
          delay: const Duration(milliseconds: 300),
          duration: const Duration(milliseconds: 1300),
          builder: (context, t) {
            final settle = Curves.easeOutBack.transform(t.clamp(0.0, 1.0));
            return Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, 80 * (1 - settle)),
                child: Transform.scale(
                  scale: 0.85 + 0.15 * settle,
                  child: SizedBox(
                    height: phoneWidth * 2.05 + 80,
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Ambient glow behind the devices.
                        Container(
                          width: phoneWidth * 1.8,
                          height: phoneWidth * 1.8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                scheme.secondary.withValues(alpha: 0.25),
                                scheme.primary.withValues(alpha: 0.08),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        if (firstProject != null && !compact)
                          Transform.translate(
                            // Fans out from behind the main phone.
                            offset: Offset(-phoneWidth * 0.55 * settle, 40),
                            child: Transform.rotate(
                              angle: -0.16 * settle,
                              child: Opacity(
                                opacity: 0.85,
                                child: Floating(
                                  distance: 8,
                                  period: const Duration(seconds: 7),
                                  child: PhoneFrame(
                                    width: phoneWidth * 0.78,
                                    glow: false,
                                    screen: ProjectScreen(firstProject),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (skills.isEmpty || radiusX < phoneWidth * 0.6)
                          main
                        else
                          Orbit(
                            radiusX: radiusX,
                            radiusY: phoneWidth * 0.75,
                            items: [for (final s in skills) _OrbitChip(s)],
                            child: main,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _OrbitChip extends StatelessWidget {
  const _OrbitChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            blurRadius: 16,
          ),
        ],
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});
  final Stat stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return HoverCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (b) => LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
            ).createShader(b),
            child: CountUp(
              stat.value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (stat.label.isNotEmpty)
            Text(
              stat.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: 10,
      height: 10,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 10 * (0.6 + _controller.value),
              height: 10 * (0.6 + _controller.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.5 * (1 - _controller.value)),
              ),
            ),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
