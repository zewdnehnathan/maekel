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

/// Font helpers shared by theme + form controls.
///
/// Important: [TextFormField] inherits [DefaultTextStyle] / theme fallbacks.
/// After Noto Sans Ethiopic loads (Amharic/Tigrinya), those fallbacks blow up
/// input metrics on Flutter web. Use [latinUi] for every editable field so
/// `fontFamilyFallback` is an empty list (clears inheritance).
abstract final class MaekelFonts {
  static final String spaceGrotesk = GoogleFonts.spaceGrotesk().fontFamily!;
  static final String sora = GoogleFonts.sora().fontFamily!;
  static final String notoSansEthiopic =
      GoogleFonts.notoSansEthiopic().fontFamily!;
  static final String notoSansSc = GoogleFonts.notoSansSc().fontFamily!;

  static final List<String> scriptFallback = <String>[
    notoSansEthiopic,
    notoSansSc,
  ];

  static Future<void> prefetch() async {
    GoogleFonts.spaceGrotesk();
    GoogleFonts.sora();
    GoogleFonts.notoSansEthiopic();
    GoogleFonts.notoSansSc();
    GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600);
    GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700);
    GoogleFonts.sora(fontWeight: FontWeight.w600);
    GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.w600);
    GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.w700);
    GoogleFonts.notoSansSc(fontWeight: FontWeight.w600);
    GoogleFonts.notoSansSc(fontWeight: FontWeight.w700);
    await GoogleFonts.pendingFonts();
  }

  static TextStyle withScriptFallback(TextStyle style) {
    return style.copyWith(fontFamilyFallback: scriptFallback);
  }

  /// Latin-only UI style — empty fallback list prevents Ethiopic metric leaks.
  static TextStyle latinUi({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
    double height = 1.25,
    double? letterSpacing,
    Color color = MaekelColors.ink,
  }) {
    return GoogleFonts.sora(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    ).copyWith(fontFamilyFallback: const <String>[]);
  }

  static const StrutStyle latinStrut = StrutStyle(
    fontSize: 16,
    height: 1.25,
    forceStrutHeight: true,
  );
}

ThemeData buildMaekelTheme() {
  final display = GoogleFonts.spaceGroteskTextTheme();
  final body = GoogleFonts.soraTextTheme();

  TextStyle displayFont({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w600,
    double height = 1.2,
    double? letterSpacing,
    Color color = MaekelColors.ink,
  }) {
    return MaekelFonts.withScriptFallback(
      GoogleFonts.spaceGrotesk(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      ),
    );
  }

  TextStyle bodyFont({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    double height = 1.4,
    double? letterSpacing,
    Color color = MaekelColors.ink,
  }) {
    return MaekelFonts.withScriptFallback(
      GoogleFonts.sora(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      ),
    );
  }

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
    fontFamily: MaekelFonts.sora,
  );

  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: MaekelColors.voidBlack.withValues(alpha: 0.92),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: MaekelColors.ink,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: MaekelColors.signal),
      titleTextStyle: displayFont(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    ),
    textTheme: body.copyWith(
      displayLarge: displayFont(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -1.2,
      ),
      displayMedium: displayFont(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.8,
      ),
      headlineMedium: displayFont(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: -0.2,
      ),
      titleLarge: MaekelFonts.withScriptFallback(
        display.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: MaekelColors.ink,
              height: 1.25,
            ) ??
            displayFont(fontSize: 18),
      ),
      titleMedium: displayFont(fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall: displayFont(fontSize: 14, fontWeight: FontWeight.w600),
      bodyLarge: bodyFont(fontSize: 16, height: 1.45),
      bodyMedium: bodyFont(fontSize: 14, height: 1.4, color: MaekelColors.muted),
      labelLarge: bodyFont(
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
        textStyle: displayFont(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: 0.6,
          color: MaekelColors.voidBlack,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: MaekelColors.signal,
        minimumSize: const Size.fromHeight(50),
        side: BorderSide(color: MaekelColors.signal.withValues(alpha: 0.45)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: displayFont(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: MaekelColors.panel.withValues(alpha: 0.85),
      // Empty fallback list — do not inherit Ethiopic metrics into fields.
      labelStyle: MaekelFonts.latinUi(color: MaekelColors.muted, fontSize: 14),
      hintStyle: MaekelFonts.latinUi(color: MaekelColors.muted, fontSize: 14),
      prefixStyle: MaekelFonts.latinUi(
        color: MaekelColors.signal,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      floatingLabelStyle: MaekelFonts.latinUi(
        color: MaekelColors.signal,
        fontSize: 14,
      ),
      errorStyle: MaekelFonts.latinUi(color: MaekelColors.danger, fontSize: 12),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: MaekelColors.voidBlack,
    ),
  );
}
