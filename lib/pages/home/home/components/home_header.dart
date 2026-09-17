import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../components/app_logo/app_logo.dart';
import '../../../../core/theme/app_colors/app_colors.dart';
import '../../../../core/theme/app_style/app_style.dart';
import '../../../../core/theme/app_theme/app_theme.dart';
import '../bound_broadband_provider.dart';
import 'bind_broadband_drawer.dart';

Future<void> _onBindTap(BuildContext context, WidgetRef ref) async {
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

/// Fixed home top: logo, account number, Bind now — does not scroll.
class HomePinnedBar extends ConsumerWidget {
  const HomePinnedBar({super.key, required this.accountNumber});

  final String accountNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bound = ref.watch(boundBroadbandProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.primary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: ColoredBox(
        color: AppColors.primary,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
            child: Row(
              children: [
                const AppLogo(
                  width: 52,
                  height: 42,
                  padding: 0,
                  borderRadius: 0,
                  backgroundColor: Colors.transparent,
                  showShadow: false,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'home.account_number'.tr(),
                        style: AppTheme.english(
                          color: AppColors.onPrimary,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        accountNumber,
                        style: AppTheme.english(
                          color: AppColors.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _onBindTap(context, ref),
                    borderRadius: BorderRadius.circular(8),
                    overlayColor: WidgetStateProperty.all(
                      Colors.white.withValues(alpha: 0.08),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                          width: 0.7,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            bound == null
                                ? LucideIcons.link
                                : LucideIcons.router,
                            color: AppColors.onPrimary,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 108),
                            child: Text(
                              bound == null
                                  ? 'home.bind_now'.tr()
                                  : bound.account,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.english(
                                color: AppColors.onPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Scrollable header: balance + decorative orbs (below the pinned bar).
class HomeBalanceHeader extends ConsumerStatefulWidget {
  const HomeBalanceHeader({super.key, required this.balanceAmount});

  final String balanceAmount;

  @override
  ConsumerState<HomeBalanceHeader> createState() => _HomeBalanceHeaderState();
}

class _HomeBalanceHeaderState extends ConsumerState<HomeBalanceHeader> {
  bool _balanceVisible = false;

  String get _maskedAmount => '********';

  String get _visibleAmount {
    final raw = widget.balanceAmount.replaceAll(',', '');
    final value = double.tryParse(raw);
    if (value == null) return widget.balanceAmount;
    return NumberFormat('#,##0').format(value);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final bottomOrb = (w * 0.42).clamp(150.0, 200.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
            child: const ColoredBox(color: AppColors.primary),
          ),
        ),
        Positioned(
          bottom: -(bottomOrb * 0.28),
          left: -(bottomOrb * 0.32),
          child: IgnorePointer(
            child: Container(
              width: bottomOrb,
              height: bottomOrb,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                  width: 0.5,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -(bottomOrb * 0.28),
          right: -(bottomOrb * 0.32),
          child: IgnorePointer(
            child: Container(
              width: bottomOrb,
              height: bottomOrb,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                  width: 0.5,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 17, 18, 46),
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
                    borderRadius: BorderRadius.circular(8),
                    overlayColor: WidgetStateProperty.all(
                      Colors.white.withValues(alpha: 0.08),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.wallet,
                            color: AppColors.onPrimary,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'home.balance_label'.tr(),
                            style: AppTheme.english(
                              color: AppColors.onPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _balanceVisible
                                ? LucideIcons.eye
                                : LucideIcons.eye_off,
                            color: AppColors.onPrimary,
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppStyle.spaceMd),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _balanceVisible ? _visibleAmount : _maskedAmount,
                      textAlign: TextAlign.center,
                      style: AppTheme.english(
                        color: AppColors.onPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: _balanceVisible ? 0.2 : 1.5,
                        height: 1,
                      ),
                    ),
                    if (_balanceVisible) ...[
                      const SizedBox(width: AppStyle.spaceXs),
                      Text(
                        'Pts',
                        style: AppTheme.english(
                          color: AppColors.onPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
