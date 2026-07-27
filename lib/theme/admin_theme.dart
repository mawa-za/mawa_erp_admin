import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDesign {
  AdminDesign._();
  static const red = Color(0xFFF20D1A);
  static const redDark = Color(0xFFC9000B);
  static const redSoft = Color(0xFFFFECEE);
  static const navy = Color(0xFF0B1F33);
  static const page = Color(0xFFF4F7FB);
  static const surface = Colors.white;
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const borderStrong = Color(0xFFCBD5E1);
  static const success = Color(0xFF3FAE5A);
  static const info = Color(0xFF2F80ED);
  static const warning = Color(0xFFF59E0B);
}

class AdminTheme {
  AdminTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AdminDesign.red,
      primary: AdminDesign.red,
      secondary: AdminDesign.navy,
      surface: AdminDesign.surface,
    ).copyWith(
      primaryContainer: AdminDesign.redSoft,
      onPrimaryContainer: AdminDesign.redDark,
      onSurface: AdminDesign.navy,
      onSurfaceVariant: AdminDesign.muted,
      outline: AdminDesign.borderStrong,
      outlineVariant: AdminDesign.border,
    );
    OutlineInputBorder border(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: width),
        );
    final textTheme = GoogleFonts.interTextTheme().apply(
      bodyColor: AdminDesign.navy,
      displayColor: AdminDesign.navy,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AdminDesign.page,
      textTheme: textTheme.copyWith(
        headlineMedium: GoogleFonts.inter(fontSize: 25, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        headlineSmall: GoogleFonts.inter(fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.3),
        titleLarge: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w800),
        titleMedium: GoogleFonts.inter(fontSize: 15.5, fontWeight: FontWeight.w700),
        titleSmall: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700),
        bodyMedium: GoogleFonts.inter(fontSize: 14, height: 1.48),
        bodySmall: GoogleFonts.inter(fontSize: 12.5, height: 1.45),
        labelLarge: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        toolbarHeight: 68,
        backgroundColor: AdminDesign.surface,
        foregroundColor: AdminDesign.navy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: const Color(0x160F172A),
        titleTextStyle: GoogleFonts.inter(
          color: AdminDesign.navy,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: const Color(0x160F172A),
        margin: const EdgeInsets.symmetric(vertical: 6),
        color: AdminDesign.surface,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AdminDesign.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AdminDesign.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 18,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.inter(
          color: AdminDesign.navy,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: GoogleFonts.inter(
          color: AdminDesign.muted,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AdminDesign.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: GoogleFonts.inter(color: AdminDesign.muted, fontWeight: FontWeight.w600),
        hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
        border: border(AdminDesign.borderStrong),
        enabledBorder: border(AdminDesign.borderStrong),
        focusedBorder: border(AdminDesign.red, width: 1.6),
        errorBorder: border(const Color(0xFFDC2626)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AdminDesign.red,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AdminDesign.red,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AdminDesign.navy,
          backgroundColor: AdminDesign.surface,
          side: const BorderSide(color: AdminDesign.borderStrong),
          minimumSize: const Size(0, 46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF1F5F9),
        selectedColor: AdminDesign.redSoft,
        side: const BorderSide(color: AdminDesign.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: const WidgetStatePropertyAll(Color(0xFFF8FAFC)),
        headingTextStyle: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AdminDesign.navy),
        dataTextStyle: GoogleFonts.inter(fontSize: 13.5, color: AdminDesign.navy),
        dividerThickness: 1,
        headingRowHeight: 48,
        dataRowMinHeight: 52,
        dataRowMaxHeight: 64,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AdminDesign.navy,
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(color: AdminDesign.border, thickness: 1),
    );
  }
}
