import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_dialog/app_dialog.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/idempotency_key.dart';
import '../../../core/network/offline_navigation.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../data/package/package_buy_repository.dart';
import '../../../models/package_model/package_model.dart';
import '../components/luxury_package_card.dart';
import '../package_catalog.dart';
import '../package_list/package_list_controller.dart';
import 'package_buy_confirm_drawer.dart';
import 'package_buy_result.dart';

/// Package detail — luxury plan card, renew, then buy.
class PackageDetailPage extends ConsumerStatefulWidget {
  const PackageDetailPage({super.key, required this.packageId});

  final String packageId;

  @override
  ConsumerState<PackageDetailPage> createState() => _PackageDetailPageState();
}

class _PackageDetailPageState extends ConsumerState<PackageDetailPage> {
  bool _autoRenew = true;
  bool _submitting = false;

  Future<void> _showProcessing() {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: const Color(0x6B000000),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'package.processing'.tr(),
                    style: AppTheme.english(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  _PackageDetailViewData _resolveViewData(
    String localeCode,
    PackageListState state,
  ) {
    PackageModel? model;
    for (final item in state.packages) {
      if (item.id == widget.packageId) {
        model = item;
        break;
      }
    }

    final catalog = PackageCatalog.byId(widget.packageId);
    final speedDigits = model?.speed.replaceAll(RegExp(r'[^0-9]'), '');
    final speedFromModel =
        speedDigits == null || speedDigits.isEmpty ? null : speedDigits;

    final cycle = model?.termMonths == null
        ? (model?.billingCycle ?? '')
        : '${model!.termMonths} ${model.billingCycle}'.trim();

    return _PackageDetailViewData(
      id: widget.packageId,
      title: model?.localizedName?[localeCode] ??
          model?.localizedName?['en'] ??
          model?.name ??
          (catalog?.titleKey ?? 'package.title').tr(),
      pricePoints: model?.price.toInt() ?? catalog?.pricePoints ?? 15000,
      speedMbps: speedFromModel ?? catalog?.speedMbps ?? '20',
      periodLabel: cycle.isEmpty ? 'home.offer_month'.tr() : '/ $cycle',
      popular: model?.recommended ?? catalog?.popular ?? false,
      features: model?.features ?? const [],
    );
  }

  void _closeProcessingDialog() {
    if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _buyNow() async {
    if (_submitting) return;

    final locale = context.locale.languageCode;
    final info = _resolveViewData(
      locale,
      ref.read(packageListControllerProvider),
    );
    final packageId = int.tryParse(widget.packageId);
    if (packageId == null) {
      await showAppFailureModal(
        context,
        title: 'package.result_failure_title'.tr(),
        body: 'package.result_failure_body'.tr(),
      );
      return;
    }

    final confirmed = await showPackageBuyConfirmDrawer(
      context,
      packageTitle: info.title,
      pricePoints: info.pricePoints,
      speedMbps: info.speedMbps,
      autoRenew: _autoRenew,
    );
    if (!mounted || !confirmed) return;

    final password = await showAppPasswordModal(
      context,
      title: 'package.password_title'.tr(),
      body: 'package.password_body'.tr(),
      amountPoints: info.pricePoints,
    );
    if (!mounted || password == null) return;

    setState(() => _submitting = true);
    _showProcessing();

    try {
      final now = DateTime.now();
      final response = await ref.read(packageBuyRepositoryProvider).buyPackage(
            packageId: packageId,
            idempotencyKey: IdempotencyKey.generate(),
          );

      late final PackageBuyResult result;
      if (response.isSuccess) {
        result = PackageBuyResult.success(
          packageId: info.id,
          packageTitle: info.title,
          pricePoints: info.pricePoints,
          speedMbps: info.speedMbps,
          autoRenew: _autoRenew,
          transactionId: response.transactionNo ?? 'PKG-UNKNOWN',
          occurredAt: now,
        );
      } else {
        result = PackageBuyResult.failure(
          packageId: info.id,
          packageTitle: info.title,
          pricePoints: info.pricePoints,
          speedMbps: info.speedMbps,
          autoRenew: _autoRenew,
          transactionId: response.transactionNo ?? 'PKG-UNKNOWN',
          occurredAt: now,
          errorTitleKey: 'package.result_failure_title',
          errorBody: response.message,
        );
      }

      _closeProcessingDialog();
      if (!mounted) return;

      switch (result.status) {
        case PackageBuyTxnStatus.success:
          context.pushReplacementNamed(
            RouteNames.packageBuySuccess,
            extra: result,
          );
          return;
        case PackageBuyTxnStatus.failure:
          context.pushReplacementNamed(
            RouteNames.packageBuyFailure,
            extra: result,
          );
          return;
      }
    } on ApiException catch (error) {
      _closeProcessingDialog();
      if (!mounted) return;
      if (isOfflineError(error)) {
        await openNoInternetPage(context);
        return;
      }
      context.pushNamed(
        RouteNames.packageBuyFailure,
        extra: PackageBuyResult.failure(
          packageId: info.id,
          packageTitle: info.title,
          pricePoints: info.pricePoints,
          speedMbps: info.speedMbps,
          autoRenew: _autoRenew,
          transactionId: 'PKG-UNKNOWN',
          errorTitleKey: 'package.result_failure_title',
          errorBody: apiErrorText(error),
        ),
      );
    } catch (_) {
      _closeProcessingDialog();
      if (!mounted) return;
      context.pushNamed(
        RouteNames.packageBuyFailure,
        extra: PackageBuyResult.failure(
          packageId: info.id,
          packageTitle: info.title,
          pricePoints: info.pricePoints,
          speedMbps: info.speedMbps,
          autoRenew: _autoRenew,
          transactionId: 'PKG-UNKNOWN',
          errorTitleKey: 'package.result_failure_title',
          errorBodyKey: 'package.result_failure_body',
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final packageState = ref.watch(packageListControllerProvider);
    final info = _resolveViewData(locale, packageState);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlayPrimary,
      child: AppCurvedScaffold(
        key: ValueKey('package-detail-${widget.packageId}-$locale'),
        title: Text('package.title'.tr()),
        showBack: true,
        onBack: () => context.pop(),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            LuxuryPackageCard(
              title: info.title,
              priceLabel: '${info.pricePoints} ${'topup.pts'.tr()}',
              periodLabel: info.periodLabel,
              speedLabel: '${info.speedMbps} Mbps',
              popular: info.popular,
              features: info.features,
              onBuy: _buyNow,
              footer: _RenewRow(
                value: _autoRenew,
                onChanged: (v) => setState(() => _autoRenew = v),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageDetailViewData {
  const _PackageDetailViewData({
    required this.id,
    required this.title,
    required this.pricePoints,
    required this.speedMbps,
    required this.periodLabel,
    required this.popular,
    this.features = const [],
  });

  final String id;
  final String title;
  final int pricePoints;
  final String speedMbps;
  final String periodLabel;
  final bool popular;
  final List<String> features;
}

class _RenewRow extends StatelessWidget {
  const _RenewRow({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          LucideIcons.refresh_cw,
          size: 14,
          color: AppColors.accent,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'package.renew'.tr(),
                style: AppTheme.english(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'package.renew_hint'.tr(),
                style: AppTheme.english(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        Transform.scale(
          scale: 0.62,
          alignment: Alignment.centerRight,
          child: Switch.adaptive(
            value: value,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.accent,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
