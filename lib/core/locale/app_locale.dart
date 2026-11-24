import 'package:material_ui/material_ui.dart';

/// Maekel app languages (Ethiopia-first + Swahili / Chinese).
enum AppLocale {
  en,
  am,
  ti,
  om,
  aa,
  so,
  sw,
  zh;

  String get languageCode => name;

  Locale get locale => Locale(languageCode);

  /// Native label for the language picker (always shown in that language).
  String get nativeLabel => switch (this) {
        AppLocale.en => 'English',
        AppLocale.am => 'አማርኛ',
        AppLocale.ti => 'ትግርኛ',
        AppLocale.om => 'Afaan Oromoo',
        AppLocale.aa => 'Qafar',
        AppLocale.so => 'Soomaali',
        AppLocale.sw => 'Kiswahili',
        AppLocale.zh => '中文',
      };

  String get englishLabel => switch (this) {
        AppLocale.en => 'English',
        AppLocale.am => 'Amharic',
        AppLocale.ti => 'Tigrinya',
        AppLocale.om => 'Oromo',
        AppLocale.aa => 'Afar',
        AppLocale.so => 'Somali',
        AppLocale.sw => 'Swahili',
        AppLocale.zh => 'Chinese',
      };

  bool get usesEthiopicScript =>
      this == AppLocale.am || this == AppLocale.ti;

  bool get usesCjkScript => this == AppLocale.zh;

  static AppLocale fromLanguageCode(String? code) {
    return AppLocale.values.firstWhere(
      (e) => e.languageCode == code,
      orElse: () => AppLocale.en,
    );
  }

  static const List<AppLocale> supported = AppLocale.values;
}
