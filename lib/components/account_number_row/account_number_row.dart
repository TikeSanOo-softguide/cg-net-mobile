import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_theme/app_theme.dart';

/// Compact locked account line used on request forms.
class AccountNumberRow extends StatelessWidget {
  const AccountNumberRow({
    super.key,
    required this.label,
    required this.value,
    this.error,
  });

  final String label;
  final String value;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.id_card,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.caption().copyWith(fontSize: 11, height: 1.2),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: AppTheme.body(
                    weight: FontWeight.w600,
                    color: AppColors.primary,
                  ).copyWith(fontSize: 13, height: 1.3),
                ),
                if (error != null && error!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(error!, style: AppTheme.fieldError()),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
