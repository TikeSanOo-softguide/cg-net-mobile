import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_theme/app_theme.dart';

class InstallationWizardScaffold extends StatelessWidget {
  const InstallationWizardScaffold({
    super.key,
    required this.step,
    required this.barTitle,
    required this.title,
    required this.description,
    required this.child,
    required this.actionLabel,
    required this.onAction,
    this.totalSteps = 3,
    this.actionEnabled = true,
    this.actionLoading = false,
    this.onBack,
    this.onStepSelected,
  });

  final int step;
  final int totalSteps;
  final String barTitle;
  final String title;
  final String description;
  final Widget child;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool actionEnabled;
  final bool actionLoading;
  final VoidCallback? onBack;
  final ValueChanged<int>? onStepSelected;

  @override
  Widget build(BuildContext context) {
    return AppCurvedScaffold(
      title: Text(barTitle, style: AppTheme.topBarTitle()),
      showBack: true,
      onBack: onBack,
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: AppColors.background,
              child: SingleChildScrollView(
                key: ValueKey(step),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _InstallationStepIndicator(
                      step: step,
                      totalSteps: totalSteps,
                      onStepSelected: onStepSelected,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: AppTheme.cardTitle(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTheme.caption().copyWith(height: 1.35),
                    ),
                    const SizedBox(height: 12),
                    child,
                  ],
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.paperBorder.withValues(alpha: 0.9)),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: AppButton(
                  label: actionLabel,
                  isLoading: actionLoading,
                  onPressed: actionEnabled ? onAction : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstallationStepIndicator extends StatelessWidget {
  const _InstallationStepIndicator({
    required this.step,
    required this.totalSteps,
    this.onStepSelected,
  });

  final int step;
  final int totalSteps;
  final ValueChanged<int>? onStepSelected;

  static const _labels = [
    'installationApplication.step_package',
    'installationApplication.step_customer',
    'installationApplication.step_review',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (var index = 0; index < totalSteps; index++) ...[
                if (index > 0)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        height: 1.5,
                        color: step > index
                            ? AppColors.primary
                            : AppColors.primaryLight,
                      ),
                    ),
                  ),
                _StepNode(
                  number: index + 1,
                  label: _labels[index].tr(),
                  state: step > index + 1
                      ? _StepState.done
                      : step == index + 1
                          ? _StepState.current
                          : _StepState.upcoming,
                  onTap: index + 1 < step
                      ? () => onStepSelected?.call(index + 1)
                      : null,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

enum _StepState { done, current, upcoming }

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.number,
    required this.label,
    required this.state,
    this.onTap,
  });

  final int number;
  final String label;
  final _StepState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final active = state != _StepState.upcoming;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: state == _StepState.upcoming
                ? AppColors.primaryLight
                : AppColors.primary,
          ),
          child: state == _StepState.done
              ? const Icon(
                  LucideIcons.check,
                  size: 12,
                  color: AppColors.onPrimary,
                )
              : Text(
                  '$number',
                  style: AppTheme.english(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: state == _StepState.upcoming
                        ? AppColors.textMuted
                        : AppColors.onPrimary,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.captionSm(
            color: active ? AppColors.primary : AppColors.textMuted,
          ).copyWith(
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
      ),
    );
  }
}
