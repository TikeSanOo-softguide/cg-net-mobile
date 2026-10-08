import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors/app_colors.dart';
import '../../../../core/theme/app_style/app_style.dart';
import '../../../../data/home_banner/home_banner_repository.dart';

class HomePromoBanner extends ConsumerStatefulWidget {
  const HomePromoBanner({super.key});

  @override
  ConsumerState<HomePromoBanner> createState() => _HomePromoBannerState();
}

class _HomePromoBannerState extends ConsumerState<HomePromoBanner> {
  static const _bannerAspect = 1024 / 340;
  static const _autoSlide = Duration(seconds: 4);

  final _controller = PageController();
  int _index = 0;
  Timer? _timer;
  int _bannerCount = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoSlide(int bannerCount) {
    _timer?.cancel();
    _bannerCount = bannerCount;
    if (bannerCount <= 1) return;
    _timer = Timer.periodic(_autoSlide, (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % _bannerCount;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final language = context.locale.languageCode;

    final bannersAsync = ref.watch(
      homeBannerProvider(language),
    );

    return bannersAsync.when(
      loading: () {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
      error: (error, stackTrace) {
        return const SizedBox.shrink();
      },
      data: (banners) {
        if (banners.isEmpty) {
          return const SizedBox.shrink();
        }

        if (_bannerCount != banners.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _startAutoSlide(banners.length);
          });
        }

        return Padding(
          padding: AppStyle.pagePaddingH,
          child: AspectRatio(
            aspectRatio: _bannerAspect,
            child: ClipRRect(
              borderRadius: AppStyle.borderRadiusMd,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: AppColors.primary),
                  PageView.builder(
                    controller: _controller,
                    itemCount: banners.length,
                    onPageChanged: (value) {
                      setState(() {
                        _index = value;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Image.network(
                        banners[index].image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        alignment: Alignment.center,
                        filterQuality: FilterQuality.high,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const ColoredBox(
                            color: AppColors.primary,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const ColoredBox(
                            color: AppColors.primary,
                            child: Center(
                              child: Icon(
                                LucideIcons.image_off,
                                color: Colors.white70,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(banners.length, (i) {
                        final active = i == _index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 14 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: active
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.45),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
