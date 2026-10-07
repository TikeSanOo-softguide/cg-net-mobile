import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names/route_names.dart';
import '../../../../core/theme/app_colors/app_colors.dart';
import '../../../../core/theme/app_theme/app_theme.dart';

/// Help block under login CTA — Q&A entry only.
class LoginHelpFooter extends StatelessWidget {
  const LoginHelpFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.pushNamed(RouteNames.loginQa),
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 13,
                    color: AppColors.primary.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        style: AppTheme.english(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textMuted,
                          height: 1.3,
                          letterSpacing: 0.2,
                        ),
                        children: [
                          TextSpan(text: 'login.help_prefix'.tr()),
                          TextSpan(
                            text: 'login.help_qa'.tr(),
                            style: AppTheme.english(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              height: 1.3,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
