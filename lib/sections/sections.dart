import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../content/models.dart';
import '../widgets/common.dart';
import '../widgets/effects.dart';
import '../widgets/phone.dart';

/// Builds the widget for any parsed section.
Widget buildSection(PortfolioSection section) => switch (section) {
  SummarySection s => _Paragraphs(s.paragraphs),
  SkillsSection s => _Skills(s),
  ExperienceSection s => _Experience(s),
  ProjectsSection s => _Projects(s),
  PackagesSection s => _Packages(s),
  EducationSection s => _Education(s),
  ListSection s => _SimpleList(s),
  TextSection s => _Text(s),
  ContactSection s => ContactBody(s),
};

TextStyle? _muted(BuildContext context) {
  final theme = Theme.of(context);
  return theme.textTheme.bodyLarge?.copyWith(
    color: theme.colorScheme.onSurfaceVariant,
    height: 1.7,
  );
}

class _Paragraphs extends StatelessWidget {
  const _Paragraphs(this.paragraphs);
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 820),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final p in paragraphs)
            Reveal(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: InlineText(
                  p,
                  style: _muted(context)?.copyWith(fontSize: 17),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Skills extends StatelessWidget {
  const _Skills(this.section);
  final SkillsSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final all = [
      for (final g in section.groups)
        for (final s in g.skills) (s, iconForLabel(g.title)),
    ];
    final half = (all.length / 2).ceil();

    Widget pill((String, IconData) item) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.$2, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            item.$1,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return Column(
      children: [
        Reveal(
          child: Column(
            children: [
              Marquee(children: [for (final i in all.take(half)) pill(i)]),
              const SizedBox(height: 12),
              Marquee(
                reverse: true,
                speed: 32,
                children: [for (final i in all.skip(half)) pill(i)],
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        ResponsiveGrid(
          minItemWidth: 320,
          children: [
            for (final group in section.groups)
              HoverCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary.withValues(
                                  alpha: 0.2,
                                ),
                                theme.colorScheme.secondary.withValues(
                                  alpha: 0.2,
                                ),
                              ],
                            ),
                          ),
                          child: Icon(
                            iconForLabel(group.title),
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            group.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [for (final s in group.skills) Tag(s)],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Experience extends StatelessWidget {
  const _Experience(this.section);
  final ExperienceSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final narrow = isNarrow(context);
    return Column(
      children: [
        for (final (i, job) in section.jobs.indexed)
          Reveal(
            // The rail is positioned against the card so it always matches
            // the card's real height (IntrinsicHeight mis-measures wrapped text).
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: (narrow ? 20 : 40) + (narrow ? 10 : 16),
                    bottom: 28,
                  ),
                  child: HoverCard(
                    padding: EdgeInsets.all(narrow ? 20 : 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            Text(
                              job.role,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (job.period.isNotEmpty) Tag(job.period),
                          ],
                        ),
                        const SizedBox(height: 6),
                        GradientText(
                          job.company,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        BulletList(job.points),
                      ],
                    ),
                  ),
                ),
                // Timeline rail with a glowing node per job.
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: narrow ? 20 : 40,
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == 0 ? scheme.primary : scheme.surface,
                          border: Border.all(color: scheme.primary, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.6),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                scheme.primary.withValues(alpha: 0.6),
                                scheme.secondary.withValues(alpha: 0.1),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Projects extends StatefulWidget {
  const _Projects(this.section);
  final ProjectsSection section;

  @override
  State<_Projects> createState() => _ProjectsState();
}

class _ProjectsState extends State<_Projects> {
  final _scroll = ScrollController();
  String? _group;
  double _itemExtent = 1;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // The list is reused across filters (never re-keyed), so the controller
  // only ever has one position; this guards the brief moments it has none.
  bool get _attached => _scroll.positions.length == 1;

  /// Moves one phone left or right, landing exactly on a snap point.
  void _step(int direction) {
    if (!_attached) return;
    final pos = _scroll.position;
    final index = (pos.pixels / _itemExtent).round() + direction;
    _scroll.animateTo(
      (index * _itemExtent).clamp(0, pos.maxScrollExtent).toDouble(),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = widget.section.groups;
    final projects = widget.section.projects
        .where((p) => _group == null || p.group == _group)
        .toList();
    final phoneWidth = fluid(context, 180, 220);
    const gap = 24.0;
    _itemExtent = phoneWidth + 30 + gap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (groups.length > 1)
                    for (final g in [null, ...groups])
                      ChoiceChip(
                        label: Text(g ?? 'All'),
                        selected: _group == g,
                        onSelected: (_) {
                          setState(() => _group = g);
                          if (_attached) _scroll.jumpTo(0);
                        },
                      ),
                ],
              ),
            ),
            IconButton.outlined(
              tooltip: 'Previous',
              onPressed: () => _step(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              tooltip: 'Next',
              onPressed: () => _step(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final viewport = constraints.maxWidth;
            // Side padding lets the first and last phones reach the centre.
            final side = math.max(0.0, (viewport - _itemExtent) / 2);
            return SizedBox(
              height: phoneWidth * 2.05 + 260,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: PointerDeviceKind.values.toSet(),
                  scrollbars: false,
                ),
                child: ListView.builder(
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  physics: SnapScrollPhysics(
                    itemExtent: _itemExtent,
                    parent: const BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(side, 32, side, 32),
                  itemExtent: _itemExtent,
                  itemCount: projects.length,
                  itemBuilder: (context, i) => AnimatedBuilder(
                    animation: _scroll,
                    builder: (context, child) {
                      // Cover-flow: distance from the centre, in items.
                      final offset = _attached ? _scroll.offset : 0.0;
                      final d =
                          (side +
                              i * _itemExtent +
                              _itemExtent / 2 -
                              offset -
                              viewport / 2) /
                          _itemExtent;
                      final a = d.abs().clamp(0.0, 2.0);
                      return Opacity(
                        opacity: 1 - a * 0.25,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(d.clamp(-1.5, 1.5) * -0.22)
                            ..scaleByDouble(1 - a * 0.08, 1 - a * 0.08, 1, 1),
                          child: child,
                        ),
                      );
                    },
                    child: Center(
                      child: Reveal(
                        delay: Duration(milliseconds: 80 * (i % 5)),
                        child: _ProjectPhone(
                          projects[i],
                          phoneWidth: phoneWidth,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ProjectPhone extends StatelessWidget {
  const _ProjectPhone(this.project, {required this.phoneWidth});
  final Project project;
  final double phoneWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: phoneWidth + 30,
      child: Column(
        children: [
          MouseRegion(
            cursor: project.url.isEmpty
                ? MouseCursor.defer
                : SystemMouseCursors.click,
            child: GestureDetector(
              onTap: project.url.isEmpty ? null : () => openUrl(project.url),
              child: Tilt3D(
                maxAngle: 0.3,
                child: PhoneFrame(
                  width: phoneWidth,
                  glow: false,
                  screen: ProjectScreen(project),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  project.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (project.url.isNotEmpty) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
          if (project.category.isNotEmpty) ...[
            const SizedBox(height: 8),
            Tag(project.category),
          ],
          if (project.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              project.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Packages extends StatelessWidget {
  const _Packages(this.section);
  final PackagesSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.paragraphs.isNotEmpty) ...[
          _Paragraphs(section.paragraphs),
          const SizedBox(height: 8),
        ],
        ResponsiveGrid(
          minItemWidth: 420,
          children: [for (final pkg in section.packages) _TerminalCard(pkg)],
        ),
      ],
    );
  }
}

/// A package shown as a terminal window running `flutter pub add`.
class _TerminalCard extends StatelessWidget {
  const _TerminalCard(this.pkg);
  final Package pkg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mono = theme.textTheme.bodyMedium?.copyWith(
      fontFamily: 'monospace',
      height: 1.6,
    );
    final command = 'flutter pub add ${pkg.name}';

    return HoverCard(
      padding: EdgeInsets.zero,
      onTap: () => openUrl(pkg.url),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                for (final c in const [
                  Color(0xFFFF5F57),
                  Color(0xFFFEBC2E),
                  Color(0xFF28C840),
                ])
                  Container(
                    width: 11,
                    height: 11,
                    margin: const EdgeInsets.only(right: 7),
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '~/${pkg.name}',
                    overflow: TextOverflow.ellipsis,
                    style: mono?.copyWith(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy command',
                  iconSize: 16,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: command));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copied: $command'),
                        behavior: SnackBarBehavior.floating,
                        width: 360,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: mono,
                    children: [
                      TextSpan(
                        text: '\$ ',
                        style: TextStyle(color: scheme.secondary),
                      ),
                      const TextSpan(text: 'flutter pub add '),
                      TextSpan(
                        text: pkg.name,
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (pkg.description.isNotEmpty)
                  Text(
                    '// ${pkg.description}',
                    style: mono?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: const Color(0xFF28C840),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Published on pub.dev',
                        overflow: TextOverflow.ellipsis,
                        style: mono?.copyWith(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Icon(Icons.north_east, size: 16, color: scheme.primary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Education extends StatelessWidget {
  const _Education(this.section);
  final EducationSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ResponsiveGrid(
      minItemWidth: 420,
      children: [
        for (final e in section.entries)
          HoverCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.school_outlined, color: theme.colorScheme.primary),
                const SizedBox(height: 14),
                Text(
                  e.degree,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (e.institution.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    e.institution,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (e.period.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Tag(e.period),
                ],
                if (e.notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  BulletList([for (final n in e.notes) Bullet(n)]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _SimpleList extends StatelessWidget {
  const _SimpleList(this.section);
  final ListSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ResponsiveGrid(
      minItemWidth: 300,
      children: [
        for (final item in section.items)
          HoverCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.workspace_premium_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Text extends StatelessWidget {
  const _Text(this.section);
  final TextSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Paragraphs(section.paragraphs),
        if (section.bullets.isNotEmpty)
          Reveal(child: BulletList(section.bullets)),
      ],
    );
  }
}

class ContactBody extends StatelessWidget {
  const ContactBody(this.section, {super.key});
  final ContactSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final narrow = isNarrow(context);
    return Reveal(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: narrow ? 20 : 48,
          vertical: narrow ? 40 : 64,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
          ),
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.4,
            colors: [
              theme.colorScheme.secondary.withValues(alpha: 0.16),
              theme.colorScheme.primary.withValues(alpha: 0.04),
            ],
          ),
        ),
        child: Column(
          children: [
            if (section.headline.isNotEmpty) ...[
              GradientText(
                section.headline,
                textAlign: TextAlign.center,
                style:
                    (narrow
                            ? theme.textTheme.headlineMedium
                            : theme.textTheme.displaySmall)
                        ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
            ],
            if (section.intro.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: InlineText(
                  section.intro,
                  style: _muted(context)?.copyWith(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 32),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                if (section.email.isNotEmpty)
                  GlowButton(
                    label: section.email,
                    icon: Icons.mail_outline,
                    onPressed: () => openUrl('mailto:${section.email}'),
                  ),
                if (section.resumeUrl.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => openUrl(section.resumeUrl),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Resume'),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final link in section.links)
                  TextButton.icon(
                    onPressed: () => openUrl(link.url),
                    icon: Icon(iconForLabel(link.label), size: 18),
                    label: Text(link.label),
                  ),
              ],
            ),
            if (section.location.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      section.location,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (section.coffeeUrl.isNotEmpty) ...[
              const SizedBox(height: 36),
              Text(
                'Enjoying my work? Fuel the next build.',
                textAlign: TextAlign.center,
                style: _muted(context),
              ),
              const SizedBox(height: 14),
              CoffeeButton(onPressed: () => openUrl(section.coffeeUrl)),
            ],
          ],
        ),
      ),
    );
  }
}
