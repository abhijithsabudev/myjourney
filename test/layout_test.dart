import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:portfolio/content/markdown_parser.dart';
import 'package:portfolio/main.dart';

/// Lays out the whole page with the real content at several screen sizes and
/// fails on any overflow ("yellow and black stripes") or other render error.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final portfolio = parsePortfolio(File(contentAsset).readAsStringSync());

  for (final size in const [Size(1440, 900), Size(1024, 768), Size(390, 844)]) {
    testWidgets('no overflow at ${size.width.toInt()}×${size.height.toInt()}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(PortfolioApp(portfolio: portfolio));
      // Scroll through the page so every section is built and laid out.
      final scrollable = find.byType(Scrollable).first;
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        await tester.drag(
          scrollable,
          Offset(0, -size.height * 0.8),
          warnIfMissed: false,
        );
      }
      await tester.pump(const Duration(seconds: 1));
    });
  }

  testWidgets('hero entrance finishes on a phone-sized screen', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(PortfolioApp(portfolio: portfolio));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Every Opacity above the hero's buttons should be fully visible.
    for (final label in ['View my work', 'Get in touch']) {
      final opacities = tester.widgetList<Opacity>(
        find.ancestor(of: find.text(label), matching: find.byType(Opacity)),
      );
      expect(opacities.map((o) => o.opacity), everyElement(1.0), reason: label);
    }
  });
}
