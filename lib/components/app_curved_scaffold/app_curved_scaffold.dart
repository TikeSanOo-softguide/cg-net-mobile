import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';
import '../../core/theme/app_theme/app_theme.dart';
import '../app_circle_icon_button/app_circle_icon_button.dart';

/// Compact primary top bar + curved content panel.
class AppCurvedScaffold extends StatelessWidget {
  const AppCurvedScaffold({
    super.key,
    required this.body,
    this.title,
    this.trailing,
    this.trailingIcon,
    this.onTrailingPressed,
    this.showBack = true,
    this.onBack,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.floatingActionButton,
  });

  final Widget body;
  final Widget? title;
  final Widget? trailing;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingPressed;
  final bool showBack;
  final VoidCallback? onBack;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final showLeading = showBack && (onBack != null || canPop);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.primary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        floatingActionButton: floatingActionButton,
        body: Column(
          children: [
            ColoredBox(
              color: AppColors.primary,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppStyle.spaceLg,
                    AppStyle.spaceXs,
                    AppStyle.spaceLg,
                    AppStyle.spaceMd,
                  ),
                  child: SizedBox(
                    height: AppStyle.topBarHeight,
                    child: Row(
                      children: [
                        if (showLeading)
                          AppCircleIconButton(
                            icon: LucideIcons.chevron_left,
                            onPressed: onBack ??
                                () => Navigator.of(context).maybePop(),
                          )
                        else
                          const SizedBox(width: AppStyle.circleButtonSize),
                        Expanded(
                          child: title == null
                              ? const SizedBox.shrink()
                              : DefaultTextStyle(
                                  style: AppTheme.topBarTitle(),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  child: title!,
                                ),
                        ),
                        if (trailing != null)
                          trailing!
                        else if (trailingIcon != null)
                          AppCircleIconButton(
                            icon: trailingIcon!,
                            onPressed: onTrailingPressed,
                          )
                        else
                          const SizedBox(width: AppStyle.circleButtonSize),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: backgroundColor ?? AppColors.background,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppStyle.radiusCurve),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
