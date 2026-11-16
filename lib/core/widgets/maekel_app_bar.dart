import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';

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

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title.toUpperCase()),
      automaticallyImplyLeading: showBack,
      actions: actions,
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
