import 'dart:ui';

import 'package:flutter/material.dart';

import 'content/models.dart';
import 'sections/hero.dart';
import 'sections/sections.dart';
import 'widgets/common.dart';
import 'widgets/effects.dart';

const _navHeight = 68.0;

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.portfolio, required this.themeMode});

  final Portfolio portfolio;
  final ValueNotifier<ThemeMode> themeMode;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scroll = ScrollController();
  final _topKey = GlobalKey();
  late final _keys = {
    for (final s in widget.portfolio.sections) s.id: GlobalKey(),
  };

  /// Id of the section currently under the nav bar, for highlighting.
  final _active = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateActive);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _active.dispose();
    super.dispose();
  }

  void _updateActive() {
    final threshold = MediaQuery.sizeOf(context).height * 0.35;
    String? active;
    for (final entry in _keys.entries) {
      final box = entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      if (box.localToGlobal(Offset.zero).dy <= threshold) active = entry.key;
    }
    _active.value = active;
  }

  void _scrollTo(String? id) {
    final target = id == null ? _topKey : _keys[id];
    final ctx = target?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  void _openMenu(List<PortfolioSection> sections) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close menu',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 550),
      pageBuilder: (context, animation, _) => _MenuOverlay(
        animation: animation,
        sections: sections,
        active: _active.value,
        onNavigate: (id) {
          Navigator.of(context).pop();
          // Let the menu start closing before the page moves.
          Future.delayed(
            const Duration(milliseconds: 150),
            () => _scrollTo(id),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = widget.portfolio;
    final navSections = portfolio.sections
        .where((s) => s.navLabel != null)
        .toList();
    final width = MediaQuery.sizeOf(context).width;
    final compactNav = width < 1100;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _NavBar(
        name: portfolio.displayName,
        sections: compactNav ? const [] : navSections,
        active: _active,
        showMenu: compactNav,
        themeMode: widget.themeMode,
        onNavigate: _scrollTo,
        onMenu: () => _openMenu(navSections),
      ),
      body: CursorGlow(
        child: Stack(
          children: [
            Positioned.fill(child: ParticleField(count: width < 720 ? 28 : 60)),
            SingleChildScrollView(
              controller: _scroll,
              child: SmoothWheelScroll(
                controller: _scroll,
                child: Column(
                  children: [
                    HeroSection(
                      key: _topKey,
                      portfolio: portfolio,
                      onNavigate: _scrollTo,
                    ),
                    for (final (i, s) in portfolio.sections.indexed)
                      SectionShell(
                        key: _keys[s.id],
                        number: i + 1,
                        title: s.title,
                        child: buildSection(s),
                      ),
                    _Footer(name: portfolio.displayName),
                  ],
                ),
              ),
            ),
            // Scroll progress, just under the nav bar.
            Positioned(
              top: MediaQuery.paddingOf(context).top + _navHeight,
              left: 0,
              right: 0,
              child: _ScrollProgress(_scroll),
            ),
            Positioned(
              right: fluid(context, 16, 32),
              bottom: fluid(context, 16, 32),
              child: _BackToTop(_scroll, onTap: () => _scrollTo(null)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget implements PreferredSizeWidget {
  const _NavBar({
    required this.name,
    required this.sections,
    required this.active,
    required this.showMenu,
    required this.themeMode,
    required this.onNavigate,
    required this.onMenu,
  });

  final String name;
  final List<PortfolioSection> sections;
  final ValueNotifier<String?> active;
  final bool showMenu;
  final ValueNotifier<ThemeMode> themeMode;
  final void Function(String? id) onNavigate;
  final VoidCallback onMenu;

  @override
  Size get preferredSize => const Size.fromHeight(_navHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: theme.colorScheme.surface.withValues(alpha: 0.7),
          child: SafeArea(
            bottom: false,
            child: Container(
              height: preferredSize.height,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: maxContentWidth + 64,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: fluid(context, 8, 24),
                  ),
                  child: Row(
                    children: [
                      Flexible(
                        child: TextButton(
                          onPressed: () => onNavigate(null),
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      ValueListenableBuilder(
                        valueListenable: active,
                        builder: (context, activeId, _) => Row(
                          children: [
                            for (final s in sections)
                              _NavItem(
                                label: s.navLabel!,
                                selected: s.id == activeId,
                                onTap: () => onNavigate(s.id),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: dark ? 'Light mode' : 'Dark mode',
                        onPressed: () => themeMode.value = dark
                            ? ThemeMode.light
                            : ThemeMode.dark,
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 450),
                          transitionBuilder: (child, animation) =>
                              RotationTransition(
                                turns: Tween(
                                  begin: 0.5,
                                  end: 1.0,
                                ).animate(animation),
                                child: ScaleTransition(
                                  scale: animation,
                                  child: child,
                                ),
                              ),
                          child: Icon(
                            dark
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                            key: ValueKey(dark),
                          ),
                        ),
                      ),
                      if (showMenu)
                        IconButton(
                          tooltip: 'Menu',
                          onPressed: onMenu,
                          icon: const Icon(Icons.menu_rounded),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Nav link with an animated gradient underline when hovered or active.
class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final on = widget.selected || _hover;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: on ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: widget.selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
                child: Text(widget.label),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                height: 2,
                width: widget.selected ? 22 : (_hover ? 12 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [scheme.primary, scheme.secondary],
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

/// Full-screen blurred menu whose links cascade in.
class _MenuOverlay extends StatelessWidget {
  const _MenuOverlay({
    required this.animation,
    required this.sections,
    required this.active,
    required this.onNavigate,
  });

  final Animation<double> animation;
  final List<PortfolioSection> sections;
  final String? active;
  final void Function(String id) onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);

    return AnimatedBuilder(
      animation: fade,
      builder: (context, child) => BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 20 * fade.value,
          sigmaY: 20 * fade.value,
        ),
        child: ColoredBox(
          color: scheme.surface.withValues(alpha: 0.85 * fade.value),
          child: child,
        ),
      ),
      child: SafeArea(
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned(
                top: 12,
                right: 16,
                child: FadeTransition(
                  opacity: fade,
                  child: IconButton(
                    tooltip: 'Close',
                    iconSize: 28,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 72),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final (i, s) in sections.indexed)
                        _cascade(
                          i,
                          TextButton(
                            onPressed: () => onNavigate(s.id),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  (i + 1).toString().padLeft(2, '0'),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: scheme.primary,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(width: 14),
                                s.id == active
                                    ? GradientText(
                                        s.navLabel!,
                                        style: theme.textTheme.headlineMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      )
                                    : Text(
                                        s.navLabel!,
                                        style: theme.textTheme.headlineMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: scheme.onSurface,
                                            ),
                                      ),
                              ],
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
      ),
    );
  }

  Widget _cascade(int i, Widget child) {
    final start = (0.1 + i * 0.06).clamp(0.0, 0.6);
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(
        start,
        (start + 0.45).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.6),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Text(
        '© ${DateTime.now().year} $name · Built with Flutter',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

double _progressOf(ScrollController scroll) {
  if (!scroll.hasClients || !scroll.position.hasContentDimensions) return 0;
  final max = scroll.position.maxScrollExtent;
  return max == 0 ? 0 : (scroll.offset / max).clamp(0.0, 1.0);
}

class _ScrollProgress extends StatelessWidget {
  const _ScrollProgress(this.scroll);
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: scroll,
      builder: (context, _) => Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: _progressOf(scroll),
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.secondary],
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Appears after scrolling down; the ring shows how far through the page you
/// are.
class _BackToTop extends StatelessWidget {
  const _BackToTop(this.scroll, {required this.onTap});
  final ScrollController scroll;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: scroll,
      builder: (context, _) {
        final visible = scroll.hasClients && scroll.offset > 600;
        return IgnorePointer(
          ignoring: !visible,
          child: AnimatedScale(
            scale: visible ? 1 : 0.4,
            duration: const Duration(milliseconds: 350),
            curve: visible ? Curves.easeOutBack : Curves.easeIn,
            child: AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: Magnetic(
                strength: 0.3,
                child: Tooltip(
                  message: 'Back to top',
                  child: Material(
                    shape: const CircleBorder(),
                    color: scheme.surfaceContainer.withValues(alpha: 0.9),
                    elevation: 6,
                    shadowColor: scheme.primary.withValues(alpha: 0.4),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onTap,
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 46,
                              height: 46,
                              child: CircularProgressIndicator(
                                value: _progressOf(scroll),
                                strokeWidth: 2.5,
                                color: scheme.primary,
                                backgroundColor: scheme.outlineVariant,
                              ),
                            ),
                            Icon(
                              Icons.arrow_upward_rounded,
                              color: scheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
