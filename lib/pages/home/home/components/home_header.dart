import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../components/app_logo/app_logo.dart';
import '../../../../core/router/route_names/route_names.dart';
import '../../../../core/theme/app_colors/app_colors.dart';
import '../../../../core/theme/app_style/app_style.dart';
import '../../../../core/theme/app_theme/app_theme.dart';
import '../bound_broadband_provider.dart';
import 'bind_broadband_drawer.dart';

Future<void> onHomeBindTap(BuildContext context, WidgetRef ref) async {
  final bound = ref.read(boundBroadbandProvider);
  if (bound == null) {
    final result = await showBindBroadbandDrawer(context);
    if (!context.mounted || result == null) return;
    ref.read(boundBroadbandProvider.notifier).state = result;
    await showBindSuccessModal(context);
    return;
  }

  final removed = await showBoundAccountDrawer(context, bound: bound);
  if (!context.mounted || !removed) return;
  ref.read(boundBroadbandProvider.notifier).state = null;
}

/// Fixed home top: glass logo, account number, notification — does not scroll.
class HomePinnedBar extends StatelessWidget {
  const HomePinnedBar({super.key, required this.accountNumber});

  final String accountNumber;

  static const double _padTop = 14;
  static const double _padBottom = 8;
  /// Glass chips stay this size (logo + notify).
  static const double _chipSize = 40;
  /// Row tall enough for larger account / phone text.
  static const double _rowH = 44;

  /// Status inset + vertical padding + content row.
  static double heightOf(BuildContext context) {
    return MediaQuery.paddingOf(context).top +
        _padTop +
        _rowH +
        _padBottom;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlayPrimary,
      child: ColoredBox(
        color: AppColors.primary,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppStyle.pageMarginH,
              HomePinnedBar._padTop,
              AppStyle.pageMarginH,
              HomePinnedBar._padBottom,
            ),
            child: SizedBox(
              height: HomePinnedBar._rowH,
              child: Row(
                children: [
                  const _LiquidGlassChip(
                    child: AppLogo(
                      width: 32,
                      height: 26,
                      padding: 0,
                      borderRadius: 0,
                      backgroundColor: Colors.transparent,
                      showShadow: false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'home.account_number'.tr(),
                          style: AppTheme.english(
                            color: AppColors.onPrimary.withValues(alpha: 0.82),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          accountNumber,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.english(
                            color: AppColors.onPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'nav.inbox'.tr(),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.goNamed(RouteNames.inboxList),
                        borderRadius: BorderRadius.circular(8),
                        overlayColor: WidgetStateProperty.all(
                          Colors.white.withValues(alpha: 0.10),
                        ),
                        child: const _LiquidGlassChip(
                          child: Icon(
                            LucideIcons.bell,
                            color: AppColors.onPrimary,
                            size: 24,
                          ),
                        ),
                      ),
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

/// Soft chip — same wash as Balance label chip (clear glass fill + light rim).
class _LiquidGlassChip extends StatelessWidget {
  const _LiquidGlassChip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: HomePinnedBar._chipSize,
      height: HomePinnedBar._chipSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 0.7,
        ),
      ),
      child: child,
    );
  }
}

/// Scrollable header: balance (below the pinned bar).
class HomeBalanceHeader extends ConsumerStatefulWidget {
  const HomeBalanceHeader({super.key, required this.balanceAmount});

  final String balanceAmount;

  /// Blue block height (content is centered inside).
  static const double sectionHeight = 148;

  /// Matches HomeQuickActions.hangBelow — room above the overlapping card.
  static const double cardClearance = 30;

  @override
  ConsumerState<HomeBalanceHeader> createState() => _HomeBalanceHeaderState();
}

class _HomeBalanceHeaderState extends ConsumerState<HomeBalanceHeader> {
  bool _balanceVisible = false;

  String get _maskedAmount => '******';

  String get _visibleAmount {
    final raw = widget.balanceAmount.replaceAll(',', '');
    final value = double.tryParse(raw);
    if (value == null) return widget.balanceAmount;
    return NumberFormat('#,##0').format(value);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: HomeBalanceHeader.sectionHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(10),
              ),
              clipBehavior: Clip.hardEdge,
              child: const ColoredBox(color: AppColors.primary),
            ),
          ),
          // Balance + amount — nudged slightly below vertical center.
          Positioned(
            left: AppStyle.pageMarginH,
            right: AppStyle.pageMarginH,
            top: 14,
            bottom: HomeBalanceHeader.cardClearance,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() => _balanceVisible = !_balanceVisible);
                      },
                      borderRadius: BorderRadius.circular(20),
                      overlayColor: WidgetStateProperty.all(
                        Colors.white.withValues(alpha: 0.08),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                            width: 0.7,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.wallet,
                              color: AppColors.onPrimary,
                              size: 11,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'home.balance_label'.tr(),
                              style: AppTheme.english(
                                color: AppColors.onPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _balanceVisible
                                  ? LucideIcons.eye
                                  : LucideIcons.eye_off,
                              color: AppColors.onPrimary,
                              size: 11,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 32,
                    child: Center(
                      child: _balanceVisible
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  _visibleAmount,
                                  textAlign: TextAlign.center,
                                  style: AppTheme.english(
                                    color: AppColors.onPrimary,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Pts',
                                  style: AppTheme.english(
                                    color: AppColors.onPrimary.withValues(
                                      alpha: 0.92,
                                    ),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    height: 1,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              _maskedAmount,
                              textAlign: TextAlign.center,
                              style: AppTheme.english(
                                color: AppColors.onPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 5,
                                height: 1,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
