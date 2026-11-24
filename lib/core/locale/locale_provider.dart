import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_locale.dart';

const _prefsKey = 'maekel_locale';

final localeControllerProvider =
    NotifierProvider<LocaleController, AppLocale>(LocaleController.new);

class LocaleController extends Notifier<AppLocale> {
  @override
  AppLocale build() {
    // Load async without blocking first frame; defaults to English.
    Future.microtask(_hydrate);
    return AppLocale.en;
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == null || saved.isEmpty) return;
    final next = AppLocale.fromLanguageCode(saved);
    if (next != state) state = next;
  }

  Future<void> setLocale(AppLocale locale) async {
    if (state == locale) return;
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }
}

final materialLocaleProvider = Provider<Locale>((ref) {
  return ref.watch(localeControllerProvider).locale;
});
