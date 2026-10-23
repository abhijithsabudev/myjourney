import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Change these to re-colour the whole site. Gradients run accent → accent2.
const accent = Color(0xFF2DD4BF);
const accent2 = Color(0xFF818CF8);

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: accent, brightness: brightness)
      .copyWith(
        primary: dark ? accent : const Color(0xFF0F766E),
        secondary: dark ? accent2 : const Color(0xFF4F46E5),
        surface: dark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
        surfaceContainer: dark ? const Color(0xFF111A2E) : Colors.white,
        onSurface: dark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A),
        onSurfaceVariant: dark
            ? const Color(0xFF94A3B8)
            : const Color(0xFF475569),
        outlineVariant: dark
            ? const Color(0xFF1E293B)
            : const Color(0xFFE2E8F0),
      );

  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final body = GoogleFonts.interTextTheme(base.textTheme);
  final display = GoogleFonts.spaceGroteskTextTheme(base.textTheme);

  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: body
        .copyWith(
          displayLarge: display.displayLarge,
          displayMedium: display.displayMedium,
          displaySmall: display.displaySmall,
          headlineLarge: display.headlineLarge,
          headlineMedium: display.headlineMedium,
          headlineSmall: display.headlineSmall,
          titleLarge: display.titleLarge,
        )
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.6)),
      ),
    ),
  );
}
