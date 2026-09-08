import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors/app_colors.dart';

class HomeServicesSection extends StatelessWidget {
  const HomeServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.receipt_long_rounded, AppColors.softBlue, 'home.service_pay'.tr()),
      (
        Icons.request_quote_outlined,
        const Color(0xFFFFDAD6),
        'home.service_check'.tr(),
      ),
      (
        Icons.history_toggle_off_rounded,
        const Color(0xFFEDE9FE),
        'home.service_history'.tr(),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'home.services'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                'home.see_all'.tr(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items
                .map(
                  (item) => SizedBox(
                    width: 96,
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: item.$2,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item.$1, color: AppColors.primary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.$3,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSlate,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
