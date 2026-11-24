import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/locale/fallback_material_localizations.dart';
import '../core/locale/locale_provider.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

class MaekelApp extends ConsumerWidget {
  const MaekelApp({super.key});

  /// Phone shell width used on desktop web so QA always sees mobile layout.
  static const double _webPhoneWidth = 430;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final materialLocale = ref.watch(materialLocaleProvider);

    return MaterialApp.router(
      title: 'Maekel',
      debugShowCheckedModeBanner: false,
      theme: buildMaekelTheme(),
      themeMode: ThemeMode.dark,
      themeAnimationDuration: Duration.zero,
      routerConfig: router,
      locale: materialLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      // Claim Material/Cupertino support for om/aa/so/ti via English fallback.
      // Without this, auth fields and bottom sheets go blank after language switch.
      localizationsDelegates: const [
        AppLocalizations.delegate,
        FallbackMaterialLocalizationsDelegate(),
        GlobalWidgetsLocalizations.delegate,
        FallbackCupertinoLocalizationsDelegate(),
      ],
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        if (!kIsWeb) return content;
        return _WebPhoneShell(child: content);
      },
    );
  }
}

class _WebPhoneShell extends StatelessWidget {
  const _WebPhoneShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= MaekelApp._webPhoneWidth) {
          return child;
        }

        final height = constraints.maxHeight;
        final media = MediaQuery.of(context);

        return ColoredBox(
          color: const Color(0xFF02040A),
          child: Center(
            child: Container(
              width: MaekelApp._webPhoneWidth,
              height: height,
              decoration: BoxDecoration(
                color: MaekelColors.voidBlack,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: MaekelColors.glassBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: MediaQuery(
                data: media.copyWith(
                  size: Size(MaekelApp._webPhoneWidth, height),
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
