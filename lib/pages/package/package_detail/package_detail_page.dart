import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_button/app_button.dart';
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

/// Package detail — plan card, description, features, then buy.
class PackageDetailPage extends ConsumerStatefulWidget {
  const PackageDetailPage({super.key, required this.packageId});

  final String packageId;

  @override
  ConsumerState<PackageDetailPage> createState() => _PackageDetailPageState();
}

class _PackageDetailPageState extends ConsumerState<PackageDetailPage> {
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
    var planIndex = 0;
    for (var i = 0; i < state.packages.length; i++) {
      if (state.packages[i].id == widget.packageId) {
        model = state.packages[i];
        planIndex = i;
        break;
      }
    }

    final catalog = PackageCatalog.byId(widget.packageId);
    final speed = (model?.speed ?? catalog?.speedMbps ?? '').trim();
    final price = model?.price ?? catalog?.pricePoints ?? 0;
    final cycle = [
      if (model?.termMonths != null) '${model!.termMonths}',
      model?.billingCycle.trim() ?? '',
    ].join();

    return _PackageDetailViewData(
      id: widget.packageId,
      title: model?.name ?? (catalog?.titleKey ?? 'package.title').tr(),
      pricePoints: price is num ? price.toInt() : 0,
      priceLabel: '$price',
      speedMbps: speed,
      periodLabel: cycle,
      popular: model?.recommended ?? catalog?.popular ?? false,
      features: model?.features ?? const [],
      lineLabel: model?.currency ?? '',
      planIndex: planIndex,
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
      periodLabel: info.periodLabel,
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
          autoRenew: false,
          transactionId: response.transactionNo ?? 'PKG-UNKNOWN',
          occurredAt: now,
        );
      } else {
        result = PackageBuyResult.failure(
          packageId: info.id,
          packageTitle: info.title,
          pricePoints: info.pricePoints,
          speedMbps: info.speedMbps,
          autoRenew: false,
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
          autoRenew: false,
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
          autoRenew: false,
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
            _PackageDetailCard(
              name: LuxuryPackageCard.planName(info.planIndex),
              priceLabel: info.priceLabel,
              periodLabel: info.periodLabel,
              speedLabel: info.speedMbps.toLowerCase().contains('mbps')
                  ? info.speedMbps
                  : '${info.speedMbps} Mbps',
              accent: LuxuryPackageCard.accentAt(info.planIndex),
            ),
            const SizedBox(height: 18),
            AppButton(
              label: 'home.buy_now'.tr(),
              onPressed: _submitting ? null : _buyNow,
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
    required this.priceLabel,
    required this.speedMbps,
    required this.periodLabel,
    required this.popular,
    this.features = const [],
    this.lineLabel = '',
    this.planIndex = 0,
  });

  final String id;
  final String title;
  final int pricePoints;
  final String priceLabel;
  final String speedMbps;
  final String periodLabel;
  final bool popular;
  final List<String> features;
  final String lineLabel;
  final int planIndex;
}

class _PackageDetailCard extends StatelessWidget {
  const _PackageDetailCard({
    required this.name,
    required this.priceLabel,
    required this.periodLabel,
    required this.speedLabel,
    required this.accent,
  });

  final String name;
  final String priceLabel;
  final String periodLabel;
  final String speedLabel;
  final Color accent;

  static const _featureKeys = [
    'package.feature_unlimited',
    'package.feature_speed',
    'package.feature_router',
    'package.feature_term',
    'package.feature_anywhere',
  ];

  ({String value, String unit}) get _speed {
    final text = speedLabel.trim();
    if (text.toLowerCase().endsWith('mbps')) {
      return (
        value: text.substring(0, text.length - 4).trim(),
        unit: 'Mbps',
      );
    }
    return (value: text, unit: text.isEmpty ? '' : 'Mbps');
  }

  @override
  Widget build(BuildContext context) {
    final speed = _speed;
    final period = periodLabel.trim().isEmpty
        ? ''
        : (periodLabel.trim().startsWith('/')
            ? periodLabel.trim()
            : '/${periodLabel.trim()}');

    return Material(
      color: AppColors.surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            width: 156,
            height: 92,
            child: IgnorePointer(
              child: CustomPaint(
                painter: _DetailWavePainter(color: accent),
              ),
            ),
          ),
          Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.english(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C1C1E),
                height: 1.25,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    priceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.english(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: accent,
                      height: 1,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
                if (period.isNotEmpty)
                  Text(
                    period,
                    style: AppTheme.english(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: accent,
                      height: 1,
                    ),
                  ),
                if (speed.value.isNotEmpty) ...[
                  const Spacer(),
                  const SizedBox(width: 12),
                  Text(
                    speed.value,
                    style: AppTheme.english(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1C1C1E),
                      height: 1,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (speed.unit.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      speed.unit,
                      style: AppTheme.english(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accent,
                        height: 1,
                      ),
                    ),
                  ],
                ],
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'package.detail_about'.tr(),
              style: AppTheme.english(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C1C1E),
                height: 1.25,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'package.detail_description'.tr(),
              style: AppTheme.english(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textMuted,
                height: 1.5,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'package.features'.tr(),
              style: AppTheme.english(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C1C1E),
                height: 1.25,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _featureKeys.length; i++) ...[
              if (i > 0) const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox(width: 4, height: 4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _featureKeys[i].tr(),
                      style: AppTheme.english(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textMuted,
                        height: 1.5,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
        ],
      ),
    );
  }
}

class _DetailWavePainter extends CustomPainter {
  const _DetailWavePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..arcToPoint(
        Offset(size.width, size.height * 0.08),
        radius: Radius.elliptical(size.width * 1.05, size.height * 1.2),
        clockwise: false,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _DetailWavePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
