import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import 'app_locale.dart';
import 'locale_provider.dart';

Future<void> showLanguagePicker(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return;

  final current = ref.read(localeControllerProvider);

  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: MaekelColors.panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.languageTitle,
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.languageSubtitle,
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                        color: MaekelColors.muted,
                      ),
                ),
                const SizedBox(height: 16),
                ...AppLocale.supported.map((locale) {
                  final selected = locale == current;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color:
                          selected ? MaekelColors.signal : MaekelColors.muted,
                    ),
                    title: Text(
                      locale.nativeLabel,
                      style: Theme.of(sheetContext)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            color: MaekelColors.ink,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            height: 1.3,
                          ),
                    ),
                    subtitle: Text(
                      locale.englishLabel,
                      style: Theme.of(sheetContext)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: MaekelColors.muted),
                    ),
                    onTap: () async {
                      await ref
                          .read(localeControllerProvider.notifier)
                          .setLocale(locale);
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      );
    },
  );
}
