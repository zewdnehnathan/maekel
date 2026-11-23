import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

/// Futuristic Addis night — void black, signal cyan, meskel amber.
abstract final class MaekelColors {
  static const Color voidBlack = Color(0xFF05070B);
  static const Color deep = Color(0xFF0A1018);
  static const Color panel = Color(0xFF101821);
  static const Color panelLift = Color(0xFF16202C);
  static const Color ink = Color(0xFFE8F1F5);
  static const Color muted = Color(0xFF8A9AAB);
  static const Color signal = Color(0xFF2EF3C5);
  static const Color signalDim = Color(0xFF1AAF8C);
  static const Color amber = Color(0xFFFFB347);
  static const Color coral = Color(0xFFFF5C7A);
  static const Color violetFog = Color(0xFF3D5A80);
  static const Color grid = Color(0x14FFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color danger = Color(0xFFFF6B6B);

  // Module accents
  static const Color ride = Color(0xFF2EF3C5);
  static const Color market = Color(0xFFFFB347);
  static const Color food = Color(0xFFFF5C7A);
  static const Color games = Color(0xFF6EC8FF);
  static const Color events = Color(0xFFC4A1FF);

  // Legacy aliases used by older stubs (map into new system)
  static const Color forest = signalDim;
  static const Color gold = amber;
  static const Color sun = amber;
  static const Color stone = panelLift;
  static const Color mist = deep;
  static const Color chalk = panel;
  static const Color copper = coral;
  static const Color slate = muted;
  static const Color leaf = signal;
}

ThemeData buildMaekelTheme() {
  final display = GoogleFonts.spaceGroteskTextTheme();
  final body = GoogleFonts.soraTextTheme();

  final colorScheme = ColorScheme.dark(
    primary: MaekelColors.signal,
    onPrimary: MaekelColors.voidBlack,
    secondary: MaekelColors.amber,
    onSecondary: MaekelColors.voidBlack,
    tertiary: MaekelColors.coral,
    surface: MaekelColors.panel,
    onSurface: MaekelColors.ink,
    error: MaekelColors.danger,
    onError: MaekelColors.ink,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: MaekelColors.voidBlack,
    visualDensity: VisualDensity.standard,
  );

  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: MaekelColors.ink,
      iconTheme: const IconThemeData(color: MaekelColors.signal),
      titleTextStyle: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: MaekelColors.ink,
        letterSpacing: 0.4,
      ),
    ),
    textTheme: body.copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 52,
        fontWeight: FontWeight.w700,
        height: 0.95,
        letterSpacing: -1.6,
        color: MaekelColors.ink,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.05,
        letterSpacing: -1.0,
        color: MaekelColors.ink,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: MaekelColors.ink,
        letterSpacing: -0.2,
      ),
      titleLarge: display.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: MaekelColors.ink,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: MaekelColors.ink,
      ),
      bodyLarge: GoogleFonts.sora(
        fontSize: 16,
        height: 1.5,
        color: MaekelColors.ink,
      ),
      bodyMedium: GoogleFonts.sora(
        fontSize: 14,
        height: 1.45,
        color: MaekelColors.muted,
      ),
      labelLarge: GoogleFonts.sora(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
        color: MaekelColors.signal,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: MaekelColors.signal,
        foregroundColor: MaekelColors.voidBlack,
        minimumSize: const Size.fromHeight(54),
        elevation: 0,
        shadowColor: MaekelColors.signal.withValues(alpha: 0.45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: MaekelColors.signal,
        minimumSize: const Size.fromHeight(50),
        side: BorderSide(color: MaekelColors.signal.withValues(alpha: 0.45)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.spaceGrotesk(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: MaekelColors.panel.withValues(alpha: 0.85),
      labelStyle: GoogleFonts.sora(color: MaekelColors.muted),
      hintStyle: GoogleFonts.sora(color: MaekelColors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: MaekelColors.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: MaekelColors.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: MaekelColors.signal, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: MaekelColors.danger),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: MaekelColors.voidBlack,
    ),
  );
}
