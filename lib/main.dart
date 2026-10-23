import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'content/markdown_parser.dart';
import 'content/models.dart';
import 'home_page.dart';
import 'theme.dart';

/// All site content lives in this Markdown file.
const contentAsset = 'assets/content.md';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final markdown = await rootBundle.loadString(contentAsset);
  runApp(PortfolioApp(portfolio: parsePortfolio(markdown)));
}

class PortfolioApp extends StatefulWidget {
  const PortfolioApp({super.key, required this.portfolio});
  final Portfolio portfolio;

  @override
  State<PortfolioApp> createState() => _PortfolioAppState();
}

class _PortfolioAppState extends State<PortfolioApp> {
  final _themeMode = ValueNotifier(ThemeMode.dark);

  @override
  void dispose() {
    _themeMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _themeMode,
      builder: (context, mode, _) => MaterialApp(
        title: widget.portfolio.name.isEmpty
            ? 'Portfolio'
            : '${widget.portfolio.name} · Portfolio',
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        themeAnimationDuration: const Duration(milliseconds: 500),
        themeAnimationCurve: Curves.easeInOut,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: HomePage(portfolio: widget.portfolio, themeMode: _themeMode),
      ),
    );
  }
}
