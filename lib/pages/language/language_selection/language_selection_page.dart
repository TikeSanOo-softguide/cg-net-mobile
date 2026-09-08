import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_button/app_button.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import 'language_selection_controller.dart';

class LanguageSelectionPage extends ConsumerWidget {
  const LanguageSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(languageSelectionControllerProvider);
    final controller = ref.read(languageSelectionControllerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                'language.title'.tr(),
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'language.subtitle'.tr(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _LanguageTile(
                label: 'language.english'.tr(),
                code: 'en',
                selected: state.selectedCode == 'en',
                onTap: () => controller.select('en'),
              ),
              const SizedBox(height: 12),
              _LanguageTile(
                label: 'language.myanmar'.tr(),
                code: 'my',
                selected: state.selectedCode == 'my',
                onTap: () => controller.select('my'),
              ),
              const SizedBox(height: 12),
              _LanguageTile(
                label: 'language.chinese'.tr(),
                code: 'zh',
                selected: state.selectedCode == 'zh',
                onTap: () => controller.select('zh'),
              ),
              const Spacer(),
              AppButton(
                label: 'common.continue'.tr(),
                isLoading: state.isSaving,
                onPressed: state.selectedCode == null
                    ? null
                    : () async {
                        await controller.confirm(context);
                        if (context.mounted) {
                          context.goNamed(RouteNames.splash);
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.label,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.secondary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.secondary),
            ],
          ),
        ),
      ),
    );
  }
}
