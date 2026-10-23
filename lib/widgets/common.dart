import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../content/models.dart';
import 'effects.dart';

const maxContentWidth = 1100.0;

bool isNarrow(BuildContext context) => MediaQuery.sizeOf(context).width < 720;

/// Scales smoothly from [min] on a 360px-wide phone to [max] at 1440px.
double fluid(BuildContext context, double min, double max) {
  final t = ((MediaQuery.sizeOf(context).width - 360) / (1440 - 360)).clamp(
    0.0,
    1.0,
  );
  return min + (max - min) * t;
}

/// Opens absolute URLs as-is and resolves relative paths (e.g. `resume.pdf`)
/// against the page URL so they work under a GitHub Pages sub-path.
Future<void> openUrl(String url) {
  final uri = Uri.parse(url);
  return launchUrl(uri.hasScheme ? uri : Uri.base.resolveUri(uri));
}

IconData iconForLabel(String label) {
  final l = label.toLowerCase();
  if (l.contains('github')) return Icons.code;
  if (l.contains('linkedin')) return Icons.work_outline;
  if (l.contains('pub')) return Icons.inventory_2_outlined;
  if (l.contains('mail')) return Icons.mail_outline;
  if (l.contains('phone')) return Icons.phone_outlined;
  if (l.contains('twitter') || l == 'x') return Icons.alternate_email;
  if (l.contains('medium') || l.contains('blog')) return Icons.article_outlined;
  if (l.contains('platform')) return Icons.devices_outlined;
  if (l.contains('architect')) return Icons.account_tree_outlined;
  if (l.contains('state')) return Icons.sync_alt;
  if (l.contains('native')) return Icons.memory_outlined;
  if (l.contains('backend') || l.contains('data')) {
    return Icons.storage_outlined;
  }
  if (l.contains('integration')) return Icons.extension_outlined;
  if (l.contains('test') || l.contains('quality')) {
    return Icons.verified_outlined;
  }
  if (l.contains('ci') || l.contains('delivery')) {
    return Icons.rocket_launch_outlined;
  }
  if (l.contains('ai')) return Icons.auto_awesome_outlined;
  return Icons.link;
}

/// Fades and slides its child in the first time it scrolls into view.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required Widget this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 700),
  }) : builder = null;

  /// Custom reveal: [builder] receives the eased progress (0 → 1).
  const Reveal.builder({
    super.key,
    required Widget Function(BuildContext context, double progress)
    this.builder,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 1100),
  }) : child = null;

  final Widget? child;
  final Widget Function(BuildContext context, double progress)? builder;
  final Duration delay;
  final Duration duration;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  // The delay is part of the animation itself (an Interval) rather than a
  // timer, so staggered items always finish together with their frames.
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.duration + widget.delay,
  );
  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      widget.delay.inMicroseconds /
          (widget.duration + widget.delay).inMicroseconds,
      1,
      curve: Curves.easeOutCubic,
    ),
  );
  ScrollPosition? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _position?.removeListener(_check);
    // The page scroll, even when nested inside a horizontal list.
    _position = Scrollable.maybeOf(context, axis: Axis.vertical)?.position;
    _position?.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_controller.status != AnimationStatus.dismissed || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final top = box.localToGlobal(Offset.zero).dy;
    if (top < MediaQuery.sizeOf(context).height * 0.92) {
      _position?.removeListener(_check);
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final builder = widget.builder;
    if (builder != null) {
      return AnimatedBuilder(
        animation: _progress,
        builder: (context, _) => builder(context, _progress.value),
      );
    }
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final t = _progress.value;
        return Opacity(
          opacity: t,
          child: Transform.scale(
            scale: 0.96 + 0.04 * t,
            child: FractionalTranslation(
              translation: Offset(0, 0.1 * (1 - t)),
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Centered, width-limited page section with a numbered heading.
class SectionShell extends StatelessWidget {
  const SectionShell({
    super.key,
    required this.number,
    required this.title,
    required this.child,
  });

  final int number;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final narrow = isNarrow(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxContentWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: fluid(context, 16, 32),
            vertical: fluid(context, 48, 88),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Reveal.builder(
                builder: (context, t) => Row(
                  children: [
                    Opacity(
                      opacity: t.clamp(0.0, 1.0),
                      child: Text(
                        number.toString().padLeft(2, '0'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: StaggeredText(
                        title,
                        progress: t,
                        gradient: true,
                        style:
                            (narrow
                                    ? theme.textTheme.headlineSmall
                                    : theme.textTheme.headlineLarge)
                                ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // The rule draws itself in from the left.
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: Curves.easeInOutCubic.transform(
                            t.clamp(0.0, 1.0),
                          ),
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary.withValues(
                                    alpha: 0.5,
                                  ),
                                  theme.colorScheme.outlineVariant.withValues(
                                    alpha: 0,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: narrow ? 24 : 36),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Lays children out in equal-width columns that wrap based on available width.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 300,
    this.spacing = 20,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            ((constraints.maxWidth + spacing) / (minItemWidth + spacing))
                .floor()
                .clamp(1, 4);
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var i = 0; i < children.length; i++)
              SizedBox(
                width: width,
                child: Reveal(
                  delay: Duration(milliseconds: 60 * (i % columns)),
                  child: children[i],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Bordered card that lifts slightly on hover and is optionally tappable.
class HoverCard extends StatefulWidget {
  const HoverCard({super.key, required this.child, this.onTap, this.padding});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
          padding: widget.padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hover
                  ? scheme.primary.withValues(alpha: 0.6)
                  : scheme.outlineVariant,
            ),
            boxShadow: [
              if (_hover)
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class Tag extends StatelessWidget {
  const Tag(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// Renders text with `**bold**` segments and `[text](url)` shown as plain text.
class InlineText extends StatelessWidget {
  const InlineText(
    this.text, {
    super.key,
    this.style,
    this.lead,
    this.textAlign,
  });
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  /// Optional bold lead-in rendered before [text] (e.g. a bullet label).
  final String? lead;

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.bodyLarge;
    final bold = base?.copyWith(
      fontWeight: FontWeight.w700,
      color: Theme.of(context).colorScheme.onSurface,
    );
    final source = text.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
      (m) => m.group(1)!,
    );
    final parts = source.split('**');
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          if (lead != null) TextSpan(text: '$lead: ', style: bold),
          for (var i = 0; i < parts.length; i++)
            TextSpan(text: parts[i], style: i.isOdd ? bold : null),
        ],
      ),
      textAlign: textAlign,
    );
  }
}

class BulletList extends StatelessWidget {
  const BulletList(this.items, {super.key});
  final List<Bullet> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      height: 1.6,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 12),
                  child: Icon(
                    Icons.arrow_right_alt,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: InlineText(item.text, lead: item.label, style: style),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Filled gradient button with a soft glow.
class GlowButton extends StatefulWidget {
  const GlowButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const ink = Color(0xFF041014);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              colors: [scheme.primary, scheme.secondary],
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: _hover ? 0.5 : 0.28),
                blurRadius: _hover ? 28 : 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 18, color: ink),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Buy Me a Coffee pill in the service's own yellow, lifting on hover.
class CoffeeButton extends StatefulWidget {
  const CoffeeButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<CoffeeButton> createState() => _CoffeeButtonState();
}

class _CoffeeButtonState extends State<CoffeeButton> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    const yellow = Color(0xFFFFDD00);
    const ink = Color(0xFF0D0C22);
    return Semantics(
      button: true,
      label: 'Buy me a coffee',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(
              color: yellow,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: yellow.withValues(alpha: _hover ? 0.45 : 0.22),
                  blurRadius: _hover ? 26 : 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            // Scales down rather than clipping on the narrowest phones.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedRotation(
                    turns: _hover ? -0.04 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.local_cafe, size: 20, color: ink),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Buy me a coffee',
                    style: TextStyle(color: ink, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
