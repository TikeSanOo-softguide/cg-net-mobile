import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors/app_colors.dart';
import '../../../../core/theme/app_style/app_style.dart';
import '../../../../core/theme/app_theme/app_theme.dart';

/// Shared home section title + See all. Same height / gap on every section.
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    required this.onSeeAll,
  });

  final String title;
  final VoidCallback onSeeAll;

  static const double sectionGap = 10;
  static const double titleToContent = 5;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.body(
                  color: AppColors.textPrimary,
                  weight: FontWeight.w500,
                ).copyWith(
                  fontSize: AppStyle.fontBody - 1,
                  height: AppStyle.lineHeightBody,
                ),
              ),
            ),
            InkWell(
              onTap: onSeeAll,
              borderRadius: BorderRadius.circular(8),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'home.see_all'.tr(),
                  style: AppTheme.caption(
                    color: AppColors.primary,
                    weight: FontWeight.w500,
                  ).copyWith(fontSize: 10, height: 1),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: titleToContent),
      ],
    );
  }
}
