import 'package:flutter/material.dart';

abstract final class ExamColors {
  static const ink = Color(0xff17312e);
  static const muted = Color(0xff657572);
  static const paper = Color(0xfffbfcf9);
  static const canvas = Color(0xfff4f8f5);
  static const surface = Color(0xffffffff);
  static const line = Color(0xffdbe4df);
  static const primary = Color(0xff0d746a);
  static const primaryDark = Color(0xff07574f);
  static const success = Color(0xff17734f);
  static const danger = Color(0xffb53832);
  static const warning = Color(0xffa66313);

  static const darkInk = Color(0xffe4eeeb);
  static const darkMuted = Color(0xff9caeaa);
  static const darkPaper = Color(0xff0b1211);
  static const darkCanvas = Color(0xff101a18);
  static const darkSurface = Color(0xff14201e);
  static const darkLine = Color(0xff30413d);
  static const darkPrimary = Color(0xff55c8b7);
}

abstract final class ExamTheme {
  static const fontFamily = 'Microsoft YaHei UI';

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final primary = dark ? ExamColors.darkPrimary : ExamColors.primary;
    final surface = dark ? ExamColors.darkSurface : ExamColors.surface;
    final canvas = dark ? ExamColors.darkCanvas : ExamColors.canvas;
    final ink = dark ? ExamColors.darkInk : ExamColors.ink;
    final muted = dark ? ExamColors.darkMuted : ExamColors.muted;
    final line = dark ? ExamColors.darkLine : ExamColors.line;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: brightness,
        ).copyWith(
          primary: primary,
          onPrimary: dark ? const Color(0xff07110f) : Colors.white,
          surface: surface,
          onSurface: ink,
          outline: line,
          outlineVariant: line,
          error: dark ? const Color(0xfff0857e) : ExamColors.danger,
        );
    final base = ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: canvas,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
    );
    final text = base.textTheme.apply(
      fontFamily: fontFamily,
      bodyColor: ink,
      displayColor: ink,
    );
    return base.copyWith(
      textTheme: text.copyWith(
        headlineMedium: text.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        headlineSmall: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        bodyLarge: text.bodyLarge?.copyWith(height: 1.55),
        bodyMedium: text.bodyMedium?.copyWith(height: 1.5),
        bodySmall: text.bodySmall?.copyWith(color: muted, height: 1.45),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: ink,
          fontFamily: fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shadowColor: const Color(
          0xff1e463c,
        ).withValues(alpha: dark ? 0.2 : 0.09),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: line),
        ),
      ),
      dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xff101816) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
        labelStyle: TextStyle(color: muted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          foregroundColor: ink,
          side: BorderSide(color: line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: dark
            ? const Color(0xff1b2825)
            : const Color(0xffedf4f1),
        selectedColor: dark ? const Color(0xff24443e) : const Color(0xffdff2eb),
        side: BorderSide(color: line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: TextStyle(color: ink, fontFamily: fontFamily),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: primary,
        textColor: ink,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: dark
            ? const Color(0xff24443e)
            : const Color(0xffdff2eb),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        selectedIconTheme: IconThemeData(color: primary),
        unselectedIconTheme: IconThemeData(color: muted),
        selectedLabelTextStyle: TextStyle(
          color: primary,
          fontFamily: fontFamily,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: muted,
          fontFamily: fontFamily,
          fontWeight: FontWeight.w500,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: dark
            ? const Color(0xff24443e)
            : const Color(0xffdff2eb),
        surfaceTintColor: Colors.transparent,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: dark ? const Color(0xff263633) : ExamColors.ink,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontFamily: fontFamily,
          fontSize: 12,
        ),
      ),
    );
  }
}
