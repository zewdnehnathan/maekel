import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';

class MaekelAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MaekelAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = true,
  });

  final String title;
  final List<Widget>? actions;
  final bool showBack;

  /// Ethiopic scripts have no case; uppercasing can confuse web layout metrics.
  static bool _hasEthiopic(String value) {
    return value.runes.any((r) => r >= 0x1200 && r <= 0x137F);
  }

  static String displayTitle(String title) {
    if (_hasEthiopic(title)) return title;
    return title.toUpperCase();
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // Keep an explicit IconData reference so --tree-shake-icons cannot
      // drop the back glyph (blank grey box on Flutter web).
      automaticallyImplyLeading: false,
      leadingWidth: showBack ? 56 : 0,
      leading: showBack
          ? IconButton(
              tooltip: AppLocalizations.of(context)!.back,
              onPressed: () => _handleBack(context),
              icon: const Icon(Icons.arrow_back_rounded),
              color: MaekelColors.signal,
            )
          : null,
      title: Text(
        displayTitle(title),
        style: Theme.of(context).appBarTheme.titleTextStyle,
      ),
      actions: actions,
      backgroundColor: MaekelColors.voidBlack.withValues(alpha: 0.92),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                MaekelColors.signal.withValues(alpha: 0.45),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
