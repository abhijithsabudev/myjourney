import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:portfolio/content/markdown_parser.dart';
import 'package:portfolio/content/models.dart';
import 'package:portfolio/main.dart';
import 'package:portfolio/widgets/effects.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

const desktop = Size(1440, 900);
const tablet = Size(1024, 768);
const phone = Size(390, 844);

final portfolio = parsePortfolio(File(contentAsset).readAsStringSync());

/// Records URLs the app tries to open instead of launching them.
class FakeUrlLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  final launched = <String>[];

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return true;
  }

  @override
  Future<bool> canLaunch(String url) async => true;
}

/// Pumps the real app at [size] with URL launching faked out.
Future<FakeUrlLauncher> pumpApp(WidgetTester tester, Size size) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final launcher = FakeUrlLauncher();
  UrlLauncherPlatform.instance = launcher;

  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async => null,
  );

  // Any framework error (overflow, assertion, exception) fails the test on
  // its own, with full details, so nothing extra is needed to catch them.
  await tester.pumpWidget(PortfolioApp(portfolio: portfolio));
  await settle(tester);
  return launcher;
}

/// The app never "settles" (it has looping animations), so pump for a while.
Future<void> settle(
  WidgetTester tester, [
  Duration duration = const Duration(milliseconds: 1500),
]) async {
  const step = Duration(milliseconds: 50);
  for (var t = Duration.zero; t < duration; t += step) {
    await tester.pump(step);
  }
}

ScrollController pageScroll(WidgetTester tester) => tester
    .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
    .controller!;

final carouselFinder = find.byWidgetPredicate(
  (w) => w is ListView && w.physics is SnapScrollPhysics,
);

ListView carousel(WidgetTester tester) =>
    tester.widget<ListView>(carouselFinder);

/// Scrolls the page so [finder] sits mid-screen (clear of the nav bar).
Future<void> bringIntoView(WidgetTester tester, Finder finder) async {
  Scrollable.ensureVisible(tester.element(finder.first), alignment: 0.5);
  await settle(tester, const Duration(milliseconds: 900));
}

ProjectsSection get projectsSection =>
    portfolio.sections.whereType<ProjectsSection>().first;

/// Nav labels shown in the desktop bar, in order.
List<PortfolioSection> get navSections =>
    portfolio.sections.where((s) => s.navLabel != null).toList();
