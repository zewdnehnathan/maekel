import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'app/maekel_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Hash routes work on any static host (GitHub Pages / Netlify / Cloudflare)
  // without server rewrite rules: https://host/#/home
  if (kIsWeb) {
    setUrlStrategy(HashUrlStrategy());
  }
  // Avoid hard-crash if font CDN is slow/blocked on first launch.
  GoogleFonts.config.allowRuntimeFetching = true;
  runApp(const ProviderScope(child: MaekelApp()));
}
