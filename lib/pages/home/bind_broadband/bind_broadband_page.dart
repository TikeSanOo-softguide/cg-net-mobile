import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/quick_action_icon_chip/quick_action_icon_chip.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_dialog/app_dialog.dart';
import '../../../components/app_input/app_input.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/offline_navigation.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../data/broadband/broadband_repository.dart';
import '../../../data/customer_profile/customer_profile_repository.dart';
import '../../profile/profile/profile_controller.dart';
import '../home/bound_broadband.dart';
import '../home/bound_broadband_provider.dart';

class BindBroadbandPage extends ConsumerStatefulWidget {
  const BindBroadbandPage({super.key});

  @override
  ConsumerState<BindBroadbandPage> createState() => _BindBroadbandPageState();
}

class _BindBroadbandPageState extends ConsumerState<BindBroadbandPage> {
  final _account = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _serviceType = 'FTTH';
  bool _isSubmitting = false;
  bool _isFormValid = false;
  String? _accountError;

  @override
  void dispose() {
    _account.dispose();
    super.dispose();
  }

  void _validateAccount(String value) {
    final text = value.trim();

    setState(() {
      if (text.isEmpty) {
        _accountError = 'broadband.validation.account_required'.tr();
      } else if (text.length > 32) {
        _accountError = 'broadband.validation.account_max_length'.tr();
      } else {
        _accountError = null;
      }

      _updateFormValidity();
      _formKey.currentState?.validate();
    });
  }

  void _updateServiceType(String value) {
    setState(() {
      _serviceType = value;
      _updateFormValidity();
    });
  }

  void _updateFormValidity() {
    _isFormValid = _account.text.trim().isNotEmpty &&
        _account.text.trim().length <= 32 &&
        _accountError == null;
  }

  String _broadbandMessage(ApiException error) {
    final key = error.detail?.trim();
    if (key != null && key.isNotEmpty) {
      final loc = 'broadband.validation.$key';
      final translated = loc.tr();
      if (translated != loc) return translated;
    }
    return apiErrorText(error);
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;

    final bound = BoundBroadband(
      serviceType: _serviceType,
      account: _account.text.trim(),
    );
    setState(() => _isSubmitting = true);

    try {
      while (true) {
        try {
          final response = await ref.read(broadbandRepositoryProvider).connect(
                accountNumber: bound.account,
                serviceType: bound.serviceType,
              );

          debugPrint('BROADBAND CONNECT RESPONSE: $response');
          await ref.read(profileControllerProvider.notifier).fetchProfile();

          if (!mounted) return;

          ref.read(boundBroadbandProvider.notifier).state = bound;
          await showAppSuccessModal(
            context,
            title: 'home.bind_success_title'.tr(),
            body: 'home.bind_success_body'.tr(),
          );
          return;
        } on ApiException catch (error) {
          if (!mounted) return;

          if (isOfflineError(error)) {
            final shouldRetry = await showOfflineModal(context);
            if (!mounted || !shouldRetry) return;
            continue;
          }

          final message = _broadbandMessage(error);

          await showAppFailureModal(
            context,
            title: 'broadband.validation.bind_fail_title'.tr(),
            body: message,
          );
          return;
        } catch (_) {
          if (!mounted) return;
          await showAppFailureModal(
            context,
            title: 'broadband.validation.bind_fail_title'.tr(),
            body: 'broadband.validation.bind_fail_body'.tr(),
          );
          return;
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _onRemove(BoundBroadband bound) async {
    if (_isSubmitting) return;

    final confirmed = await showAppConfirmModal(
      context,
      title: 'home.remove_broadband_confirm_title'.tr(),
      body: 'home.remove_broadband_confirm_body'.tr(),
    );

    if (!mounted || !confirmed) return;

    setState(() => _isSubmitting = true);

    try {
      while (true) {
        try {
          await ref.read(broadbandRepositoryProvider).unbindAccount(
                accountNumber: bound.account,
              );

          if (!mounted) return;

          ref.read(boundBroadbandProvider.notifier).state = null;
          ref.invalidate(customerProfileProvider);
          return;
        } on ApiException catch (error) {
          if (!mounted) return;

          if (isOfflineError(error)) {
            final shouldRetry = await showOfflineModal(context);
            if (!mounted || !shouldRetry) return;
            continue;
          }

          await showAppFailureModal(
            context,
            title: 'broadband.validation.unbind_fail_title'.tr(),
            body: _broadbandMessage(error),
          );
          return;
        } catch (_) {
          if (!mounted) return;

          await showAppFailureModal(
            context,
            title: 'broadband.validation.unbind_fail_title'.tr(),
            body: 'broadband.validation.unbind_fail_body'.tr(),
          );
          return;
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bound = ref.watch(boundBroadbandProvider);
    final profile = ref.watch(profileControllerProvider);

    return AppCurvedScaffold(
      title: Text(
        bound == null
            ? context.tr('broadband.bind_now')
            : context.tr('home.broadband_account'),
      ),
      showBack: true,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (bound == null)
            _BindForm(
              formKey: _formKey,
              account: _account,
              serviceType: _serviceType,
              isSubmitting: _isSubmitting,
              isFormValid: _isFormValid,
              onAccountChanged: _validateAccount,
              onServiceTypeChanged: _updateServiceType,
              accountError: () => _accountError,
              onSubmit: _submit,
            )
          else
            _BoundAccountCard(
              bound: bound,
              name: profile.fullName.trim(),
              isSubmitting: _isSubmitting,
              onRemove: () => _onRemove(bound),
            ),
        ],
      ),
    );
  }
}

class _BindForm extends StatelessWidget {
  const _BindForm({
    required this.formKey,
    required this.account,
    required this.serviceType,
    required this.isSubmitting,
    required this.isFormValid,
    required this.onAccountChanged,
    required this.onServiceTypeChanged,
    required this.accountError,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController account;
  final String serviceType;
  final bool isSubmitting;
  final bool isFormValid;
  final ValueChanged<String> onAccountChanged;
  final ValueChanged<String> onServiceTypeChanged;
  final String? Function() accountError;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: AppCard(
        elevated: false,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        borderRadius: AppStyle.borderRadiusLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _ConnectLead(),
            const SizedBox(height: 16),
            AppInput(
              controller: account,
              label: 'home.broadband_account'.tr(),
              hint: 'home.broadband_account_hint'.tr(),
              prefixIcon: LucideIcons.router,
              textInputAction: TextInputAction.done,
              reserveErrorSpace: false,
              onChanged: onAccountChanged,
              onSubmitted: (_) {
                if (isFormValid && !isSubmitting) onSubmit();
              },
              validator: (_) => accountError(),
            ),
            const SizedBox(height: 16),
            _ServiceTypeRadios(
              value: serviceType,
              onChanged: onServiceTypeChanged,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppButton(
                label: 'Bind Account',
                height: 42,
                fontSize: 14,
                isLoading: isSubmitting,
                onPressed: isFormValid && !isSubmitting ? onSubmit : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoundAccountCard extends StatelessWidget {
  const _BoundAccountCard({
    required this.bound,
    required this.name,
    required this.isSubmitting,
    required this.onRemove,
  });

  final BoundBroadband bound;
  final String name;
  final bool isSubmitting;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final plan = bound.serviceType.trim().isEmpty ? '-' : bound.serviceType;

    return AppCard(
      elevated: false,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      borderRadius: AppStyle.borderRadiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.center,
            child: QuickActionIconChip(
              asset: QuickActionIconChip.bindAsset,
              background: QuickActionIconChip.bindSoft,
              tint: AppColors.success,
              size: 36,
              iconSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('broadband.details_title'),
            textAlign: TextAlign.center,
            style: AppTheme.english(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              height: AppStyle.lineHeightTitle,
              letterSpacing: -0.15,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _DetailRow(
                  label: context.tr('broadband.detail_account'),
                  value: bound.account,
                ),
                _DetailRow(
                  label: context.tr('broadband.detail_name'),
                  value: name.isEmpty ? '-' : name,
                ),
                _DetailRow(
                  label: context.tr('broadband.detail_price'),
                  value: '-',
                ),
                _DetailRow(
                  label: context.tr('broadband.detail_plan'),
                  value: plan,
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 42,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: isSubmitting ? null : onRemove,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF0000),
                  backgroundColor: Colors.white,
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFFFF0000), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppStyle.radiusButton),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFF0000),
                        ),
                      )
                    : Text(
                        context.tr('broadband.remove_account'),
                        style: AppTheme.english(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFF0000),
                          height: AppTheme.lineHeightMyanmarSafe,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Text(
                '$label:',
                style: AppTheme.english(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  height: AppTheme.lineHeightMyanmarSafe,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: AppTheme.english(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: AppTheme.lineHeightMyanmarSafe,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: AppColors.borderLight),
      ],
    );
  }
}

class _ConnectLead extends StatelessWidget {
  const _ConnectLead();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const QuickActionIconChip(
          asset: QuickActionIconChip.bindAsset,
          background: QuickActionIconChip.bindSoft,
          tint: AppColors.success,
          size: 36,
          iconSize: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            context.tr('broadband.connect_here'),
            style: AppTheme.english(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              height: AppStyle.lineHeightTitle,
              letterSpacing: -0.15,
            ),
          ),
        ),
      ],
    );
  }
}

class _ServiceTypeRadios extends StatelessWidget {
  const _ServiceTypeRadios({
    required this.value,
    this.onChanged,
  });

  final String value;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('home.service_type'),
          style: AppTheme.english(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            height: AppTheme.lineHeightMyanmarSafe,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ServiceRadioTile(
                label: 'FTTH',
                icon: LucideIcons.wifi,
                selected: value == 'FTTH',
                onTap: onChanged == null ? null : () => onChanged!('FTTH'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ServiceRadioTile(
                label: 'CG',
                icon: LucideIcons.cable,
                selected: value == 'CG',
                onTap: onChanged == null ? null : () => onChanged!('CG'),
              ),
            ),
          ],
        ),
        if (value != 'FTTH' && value != 'CG') ...[
          const SizedBox(height: 8),
          _ServiceRadioTile(
            label: value,
            icon: LucideIcons.router,
            selected: true,
          ),
        ],
      ],
    );
  }
}

class _ServiceRadioTile extends StatelessWidget {
  const _ServiceRadioTile({
    required this.label,
    required this.icon,
    required this.selected,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : AppColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.surface : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  icon,
                  size: 13,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  style: AppTheme.english(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.primary : AppColors.textPrimary,
                    height: AppTheme.lineHeightMyanmarSafe,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _RadioMark(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioMark extends StatelessWidget {
  const _RadioMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.textMuted,
          width: 1.5,
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: selected ? 7 : 0,
        height: selected ? 7 : 0,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
