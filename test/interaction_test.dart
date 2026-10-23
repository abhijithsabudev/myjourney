import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/widgets/common.dart';

import 'helpers.dart';

void main() {
  // A tap that lands on the wrong widget is a test bug; fail loudly.
  setUpAll(() => WidgetController.hitTestWarningShouldBeFatal = true);

  group('projects carousel', () {
    for (final size in [desktop, phone]) {
      testWidgets('filters switch repeatedly without errors (${size.width})', (
        tester,
      ) async {
        await pumpApp(tester, size);
        final groups = projectsSection.groups;
        expect(groups.length, greaterThan(1));
        await bringIntoView(tester, carouselFinder);

        // Every filter, twice over, plus "All", checking the item count.
        for (final g in [...groups, null, ...groups, null]) {
          final chip = find.widgetWithText(ChoiceChip, g ?? 'All');
          await bringIntoView(tester, chip);
          await tester.tap(chip);
          await settle(tester, const Duration(milliseconds: 600));
          final expected = projectsSection.projects
              .where((p) => g == null || p.group == g)
              .length;
          expect(
            carousel(tester).childrenDelegate.estimatedChildCount,
            expected,
            reason: 'filter ${g ?? 'All'}',
          );
          expect(carousel(tester).controller!.offset, 0);
        }
      });
    }

    testWidgets('arrows and drags always settle on a phone', (tester) async {
      await pumpApp(tester, desktop);
      await bringIntoView(tester, find.byTooltip('Next'));
      final controller = carousel(tester).controller!;
      final extent = carousel(tester).itemExtent!;

      void expectSnapped() {
        final ratio = controller.offset / extent;
        final atEnd =
            (controller.offset - controller.position.maxScrollExtent).abs() < 1;
        expect(
          (ratio - ratio.round()).abs() < 0.01 || atEnd,
          isTrue,
          reason: 'offset ${controller.offset} not on a snap point',
        );
      }

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byTooltip('Next'));
        await settle(tester, const Duration(milliseconds: 900));
        expectSnapped();
      }
      expect(controller.offset, greaterThan(0));

      await tester.tap(find.byTooltip('Previous'));
      await settle(tester, const Duration(milliseconds: 900));
      expectSnapped();

      // A short mouse drag that stops between phones snaps back to one.
      await tester.dragFrom(
        tester.getCenter(carouselFinder),
        Offset(-extent * 0.4, 0),
        kind: PointerDeviceKind.mouse,
      );
      await settle(tester);
      expectSnapped();

      // A fling past the end stays in bounds.
      await tester.fling(carouselFinder, const Offset(-3000, 0), 4000);
      await settle(tester, const Duration(seconds: 2));
      expect(
        controller.offset,
        lessThanOrEqualTo(controller.position.maxScrollExtent + 0.5),
      );
      expectSnapped();
    });

    testWidgets('filter after scrolling resets to the first phone', (
      tester,
    ) async {
      await pumpApp(tester, desktop);
      await bringIntoView(tester, carouselFinder);
      await bringIntoView(tester, find.byTooltip('Next'));
      await tester.tap(find.byTooltip('Next'));
      await settle(tester);
      final chip = find.widgetWithText(
        ChoiceChip,
        projectsSection.groups.first,
      );
      await tester.tap(chip);
      await settle(tester);
      expect(carousel(tester).controller!.offset, 0);
    });
  });

  group('navigation', () {
    testWidgets('each desktop nav link scrolls its section under the bar', (
      tester,
    ) async {
      await pumpApp(tester, desktop);
      final shells = find.byType(SectionShell);

      for (final s in navSections) {
        // The nav copy of the label is the one inside the top bar.
        final link = find
            .text(s.navLabel!)
            .hitTestable()
            .evaluate()
            .where((e) => tester.getCenter(find.byWidget(e.widget)).dy < 70);
        expect(link, isNotEmpty, reason: 'nav link ${s.navLabel}');
        await tester.tapAt(tester.getCenter(find.byWidget(link.first.widget)));
        await settle(tester);

        final index = portfolio.sections.indexOf(s);
        final top = tester.getTopLeft(shells.at(index)).dy;
        // Sections near the end may stop short because the page bottoms out.
        final atBottom =
            (pageScroll(tester).offset -
                    pageScroll(tester).position.maxScrollExtent)
                .abs() <
            1;
        expect(
          top.abs() < 2 || atBottom,
          isTrue,
          reason: '${s.navLabel} landed at $top',
        );
      }
    });

    testWidgets('phone menu opens, navigates and closes', (tester) async {
      await pumpApp(tester, phone);
      expect(find.byTooltip('Menu'), findsOneWidget);

      // Close with the close button.
      await tester.tap(find.byTooltip('Menu'));
      await settle(tester, const Duration(milliseconds: 800));
      for (final s in navSections) {
        expect(find.text(s.navLabel!), findsWidgets);
      }
      await tester.tap(find.byTooltip('Close'));
      await settle(tester, const Duration(milliseconds: 800));
      expect(find.byTooltip('Close'), findsNothing);

      // Navigate through every menu entry.
      for (final s in navSections) {
        await tester.tap(find.byTooltip('Menu'));
        await settle(tester, const Duration(milliseconds: 800));
        await tester.tap(find.text(s.navLabel!).last);
        await settle(tester, const Duration(milliseconds: 1600));
        expect(
          find.byTooltip('Close'),
          findsNothing,
          reason: 'menu should close after ${s.navLabel}',
        );
      }
      expect(pageScroll(tester).offset, greaterThan(0));
    });

    testWidgets('back-to-top appears after scrolling and returns to the top', (
      tester,
    ) async {
      await pumpApp(tester, desktop);
      final controller = pageScroll(tester);
      controller.jumpTo(controller.position.maxScrollExtent * 0.6);
      await settle(tester, const Duration(milliseconds: 600));

      await tester.tap(find.byTooltip('Back to top'));
      await settle(tester);
      expect(controller.offset, lessThan(1));
    });

    testWidgets('mouse wheel scrolls smoothly; trackpad deltas pass through', (
      tester,
    ) async {
      await pumpApp(tester, desktop);
      final controller = pageScroll(tester);
      final center = tester.getCenter(find.byType(SingleChildScrollView));

      final mouse = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(mouse.hover(center));
      await tester.sendEventToBinding(mouse.scroll(const Offset(0, 300)));
      await tester.pump(); // the animation starts on the next frame
      await tester.pump(const Duration(milliseconds: 100));
      final midway = controller.offset;
      expect(midway, inExclusiveRange(0, 330)); // still easing
      await settle(tester, const Duration(milliseconds: 800));
      expect(controller.offset, closeTo(330, 1));

      // Wheel steps queue up rather than restarting from the current spot.
      await tester.sendEventToBinding(mouse.scroll(const Offset(0, 300)));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.sendEventToBinding(mouse.scroll(const Offset(0, 300)));
      await settle(tester, const Duration(milliseconds: 900));
      expect(controller.offset, closeTo(990, 1));

      // Small trackpad-like deltas move immediately.
      await tester.sendEventToBinding(mouse.scroll(const Offset(0, 20)));
      await tester.pump();
      expect(controller.offset, closeTo(1010, 1));

      // Scrolling up past the top clamps at zero.
      await tester.sendEventToBinding(mouse.scroll(const Offset(0, -5000)));
      await settle(tester);
      expect(controller.offset, 0);
    });
  });

  group('controls', () {
    testWidgets('theme toggles between dark and light', (tester) async {
      await pumpApp(tester, desktop);
      Brightness brightness() =>
          Theme.of(tester.element(find.byType(Scaffold))).brightness;
      expect(brightness(), Brightness.dark);
      await tester.tap(find.byTooltip('Light mode'));
      await settle(tester);
      expect(brightness(), Brightness.light);
      await tester.tap(find.byTooltip('Dark mode'));
      await settle(tester);
      expect(brightness(), Brightness.dark);
    });

    testWidgets('links open the right URLs', (tester) async {
      final launcher = await pumpApp(tester, desktop);
      final contact = portfolio.contact!;

      // Hero social icons.
      for (final link in contact.links) {
        await tester.tap(find.byTooltip(link.label).first);
        await tester.pump();
        expect(launcher.launched.last, link.url);
      }

      // Email button in the contact panel.
      final email = find.text(contact.email);
      await bringIntoView(tester, email);
      await tester.tap(email);
      await tester.pump();
      expect(launcher.launched.last, 'mailto:${contact.email}');

      // A package card opens pub.dev.
      final pkg = find.textContaining('~/');
      await bringIntoView(tester, pkg);
      await tester.tap(pkg.first);
      await tester.pump();
      expect(launcher.launched.last, startsWith('https://pub.dev/packages/'));
    });

    testWidgets('copy button copies the pub add command', (tester) async {
      await pumpApp(tester, desktop);
      final copy = find.byTooltip('Copy command');
      await bringIntoView(tester, copy);
      await tester.tap(copy.first);
      await tester.pump();
      expect(find.textContaining('Copied: flutter pub add '), findsOneWidget);
      await settle(tester, const Duration(seconds: 5));
    });

    testWidgets('hovering interactive elements is error-free', (tester) async {
      await pumpApp(tester, desktop);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);

      // Sweep the pointer across the whole hero (phones, buttons, chips).
      for (var y = 80.0; y < 880; y += 60) {
        for (var x = 20.0; x < 1440; x += 120) {
          await mouse.moveTo(Offset(x, y));
          await tester.pump(const Duration(milliseconds: 16));
        }
      }
      // And across the carousel phones.
      await bringIntoView(tester, carouselFinder);
      final rect = tester.getRect(carouselFinder);
      for (var x = rect.left; x < rect.right; x += 40) {
        await mouse.moveTo(Offset(x, rect.center.dy));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await mouse.moveTo(const Offset(-10, -10));
      await settle(tester);
    });
  });

  group('responsiveness', () {
    testWidgets('resizing live across breakpoints is error-free', (
      tester,
    ) async {
      await pumpApp(tester, desktop);
      pageScroll(tester).jumpTo(1500);
      for (final w in const <double>[
        1280,
        1099,
        1000,
        820,
        719,
        600,
        390,
        320,
        1440,
      ]) {
        tester.view.physicalSize = Size(w, 800);
        await settle(tester, const Duration(milliseconds: 400));
      }
    });

    testWidgets('narrowest phone (320px) lays out cleanly', (tester) async {
      await pumpApp(tester, const Size(320, 640));
      final controller = pageScroll(tester);
      while (controller.offset < controller.position.maxScrollExtent) {
        controller.jumpTo(controller.offset + 500);
        await settle(tester, const Duration(milliseconds: 200));
      }
    });

    testWidgets('light theme on a phone lays out cleanly', (tester) async {
      await pumpApp(tester, phone);
      await tester.tap(find.byTooltip('Light mode'));
      await settle(tester);
      final controller = pageScroll(tester);
      while (controller.offset < controller.position.maxScrollExtent) {
        controller.jumpTo(controller.offset + 600);
        await settle(tester, const Duration(milliseconds: 200));
      }
    });

    testWidgets('reduced motion still renders everything', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpApp(tester, desktop);
      final controller = pageScroll(tester);
      while (controller.offset < controller.position.maxScrollExtent) {
        controller.jumpTo(controller.offset + 700);
        await settle(tester, const Duration(milliseconds: 200));
      }
    });
  });
}
