import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/theme/app_style/app_style.dart';
import '../app_circle_icon_button/app_circle_icon_button.dart';
import '../app_curved_scaffold/app_curved_scaffold.dart';

/// Legacy alias — prefer [AppCurvedScaffold] for the screenshot-style layout.
@Deprecated('Use AppCurvedScaffold instead')
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.centerTitle = true,
  });

  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      actions: actions,
      leading: leading ??
          (automaticallyImplyLeading && Navigator.of(context).canPop()
              ? Padding(
                  padding: const EdgeInsets.only(left: AppStyle.spaceSm),
                  child: Center(
                    child: AppCircleIconButton(
                      icon: LucideIcons.chevron_left,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                )
              : null),
      centerTitle: centerTitle,
      leadingWidth: AppStyle.circleButtonSize + AppStyle.spaceLg,
    );
  }
}
