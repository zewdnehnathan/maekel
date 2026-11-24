import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'app/maekel_app.dart';
import 'app/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Hash routes work on any static host (GitHub Pages / Netlify / Cloudflare)
  // without server rewrite rules: https://host/#/home
  if (kIsWeb) {
    setUrlStrategy(HashUrlStrategy());
  }
  // Avoid hard-crash if font CDN is slow/blocked on first launch.
  GoogleFonts.config.allowRuntimeFetching = true;
  // Prefetch Latin + Ethiopic so language switches never load fonts mid-layout
  // (that was blowing up TextField / AppBar metrics after repeated toggles).
  try {
    await MaekelFonts.prefetch();
  } catch (_) {
    // Offline / CDN blocked — runtime fetch can still recover later.
  }
  runApp(const ProviderScope(child: MaekelApp()));
}
