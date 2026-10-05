import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_dialog/app_dialog.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/idempotency_key.dart';
import '../../../core/network/offline_navigation.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../data/package/package_buy_repository.dart';
import '../../../models/package_model/package_model.dart';
import '../package_catalog.dart';
import '../package_list/package_list_controller.dart';
import 'package_buy_confirm_drawer.dart';
import 'package_buy_result.dart';

/// Package detail — left image / right features, then description → renew → buy.
class PackageDetailPage extends ConsumerStatefulWidget {
  const PackageDetailPage({super.key, required this.packageId});

  final String packageId;

  @override
  ConsumerState<PackageDetailPage> createState() => _PackageDetailPageState();
}

class _PackageDetailPageState extends ConsumerState<PackageDetailPage> {
  bool _autoRenew = true;
  bool _submitting = false;

  static const _features = <String>[
    'package.feature_speed',
    'package.feature_unlimited',
    'package.feature_router',
    'package.feature_term',
    'package.feature_anywhere',
  ];

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

    return _PackageDetailViewData(
      id: widget.packageId,
      title: model?.localizedName?[localeCode] ??
          model?.localizedName?['en'] ??
          model?.name ??
          (catalog?.titleKey ?? 'package.title').tr(),
      body: (catalog?.descriptionKey ?? 'package.empty_body').tr(),
      pricePoints: model?.price.toInt() ?? catalog?.pricePoints ?? 15000,
      speedMbps: speedFromModel ?? catalog?.speedMbps ?? '20',
      imagePath: model?.imageUrl?.trim().isNotEmpty == true
          ? model!.imageUrl!.trim()
          : _fallbackImageByTermMonths(model?.termMonths) ?? catalog?.imagePath,
      popular: model?.recommended ?? catalog?.popular ?? false,
    );
  }

  static String? _fallbackImageByTermMonths(int? months) {
    return switch (months) {
      3 => 'assets/images/packages/package_3m.png',
      6 => 'assets/images/packages/package_6m.png',
      12 => 'assets/images/packages/package_1y.png',
      1 => 'assets/images/packages/package_1m.png',
      _ => null,
    };
  }

  void _closeProcessingDialog() {
    if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Widget _buildCardImage(String imagePath) {
    const fallback = ColoredBox(
      color: AppColors.primaryLight,
      child: Center(
        child: Icon(
          LucideIcons.image_off,
          color: AppColors.primary,
          size: 18,
        ),
      ),
    );

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => fallback,
    );
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
            idempotencyKey:
                IdempotencyKey.forPackageBuy(packageId: widget.packageId),
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
    final imagePath = info.imagePath ?? 'assets/images/packages/package_1m.png';
    final title = info.title;
    final body = info.body;
    final popular = info.popular;
    final speedMbps = info.speedMbps;

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
            AppCard(
              elevated: false,
              bordered: false,
              borderRadius: AppStyle.borderRadiusLg,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Smaller image; title + features fill top→bottom to match height.
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 104,
                          child: AspectRatio(
                            aspectRatio: 3 / 4,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  _buildCardImage(imagePath),
                                  if (popular)
                                    Positioned(
                                      top: 5,
                                      left: 5,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'home.popular'.tr(),
                                          style: AppTheme.english(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFFE11D48),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SpeedTitle(
                                value: speedMbps,
                                unit: 'Mbps',
                              ),
                              for (final key in _features)
                                _FeatureRow(label: key.tr()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Description.
                  Text(
                    title,
                    style: AppTheme.english(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.2,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: AppTheme.english(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textMuted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Renew.
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primaryLight,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(
                            LucideIcons.refresh_cw,
                            size: 12,
                            color: AppColors.primary,
                          ),
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
                            value: _autoRenew,
                            activeThumbColor: AppColors.onPrimary,
                            activeTrackColor: AppColors.primary,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onChanged: (v) => setState(() => _autoRenew = v),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Button.
                  AppButton(
                    label: 'home.buy_now'.tr(),
                    onPressed: _buyNow,
                    height: 42,
                  ),
                ],
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
    required this.body,
    required this.pricePoints,
    required this.speedMbps,
    required this.imagePath,
    required this.popular,
  });

  final String id;
  final String title;
  final String body;
  final int pricePoints;
  final String speedMbps;
  final String? imagePath;
  final bool popular;
}

class _SpeedTitle extends StatelessWidget {
  const _SpeedTitle({
    required this.value,
    required this.unit,
  });

  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primarySoft,
            AppColors.primaryLight,
          ],
        ),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.primaryLight, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            value,
            style: AppTheme.english(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              height: 1,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            unit,
            style: AppTheme.english(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              height: 1,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.label});

  static const _iconAsset = 'assets/images/packages/feature_check.png';

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          _iconAsset,
          width: 13,
          height: 13,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => const Icon(
            LucideIcons.circle_check,
            size: 13,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.english(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}
