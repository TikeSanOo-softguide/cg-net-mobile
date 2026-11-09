import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/app_button/app_button.dart';
import '../../../components/app_card/app_card.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import 'onboarding_controller.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final slides = [
      (
        title: 'onboarding.slide1_title'.tr(),
        body: 'onboarding.slide1_body'.tr(),
        asset: 'assets/images/onboarding/fiber.png',
      ),
      (
        title: 'onboarding.slide2_title'.tr(),
        body: 'onboarding.slide2_body'.tr(),
        asset: 'assets/images/onboarding/plan.png',
      ),
      (
        title: 'onboarding.slide3_title'.tr(),
        body: 'onboarding.slide3_body'.tr(),
        asset: 'assets/images/onboarding/support.png',
      ),
    ];

    const illustrationSize = 236.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: controller.pageController,
                    itemCount: slides.length,
                    onPageChanged: controller.setPage,
                    itemBuilder: (context, index) {
                      final slide = slides[index];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(28, 52, 28, 0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: illustrationSize,
                              height: illustrationSize,
                              child: Image.asset(
                                slide.asset,
                                width: illustrationSize,
                                height: illustrationSize,
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                filterQuality: FilterQuality.high,
                                isAntiAlias: true,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              slide.title,
                              style: AppTheme.pageTitle(
                                color: AppColors.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 320),
                              child: Text(
                                slide.body,
                                style: AppTheme.bodySecondary().copyWith(
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 3,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(slides.length, (i) {
                    final active = i == page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : AppColors.border,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                ColoredBox(
                  color: AppColors.background,
                  child: AppCard(
                    color: const Color(0xFFFFFFFF),
                    elevated: false,
                    bordered: false,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppStyle.radiusCurve),
                      topRight: Radius.circular(AppStyle.radiusCurve),
                    ),
                    child: AppButton(
                      label: page == slides.length - 1
                          ? 'onboarding.get_started'.tr()
                          : 'common.next'.tr(),
                      onPressed: () {
                        if (page == slides.length - 1) {
                          controller.finish(context);
                        } else {
                          controller.next(slides.length);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 16,
              child: _GlassSkipButton(
                onTap: () => controller.finish(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassSkipButton extends StatelessWidget {
  const _GlassSkipButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        overlayColor: WidgetStateProperty.all(
          AppColors.primary.withValues(alpha: 0.06),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.borderLight,
                  width: 0.8,
                ),
              ),
              child: Text(
                'common.skip'.tr(),
                style: AppTheme.english(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  letterSpacing: 0.3,
                  height: AppTheme.lineHeightMyanmarSafe,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
