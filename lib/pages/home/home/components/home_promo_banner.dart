import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/theme/app_colors/app_colors.dart';
import '../../../../core/theme/app_style/app_style.dart';

class HomePromoBanner extends StatefulWidget {
  const HomePromoBanner({super.key});

  @override
  State<HomePromoBanner> createState() => _HomePromoBannerState();
}

class _HomePromoBannerState extends State<HomePromoBanner> {
  static const _banners = [
    'assets/images/banners/banner_1.png',
    'assets/images/banners/banner_2.png',
    'assets/images/banners/banner_3.png',
    'assets/images/banners/banner_4.png',
    'assets/images/banners/banner_5.png',
    'assets/images/banners/banner_6.jpg',
  ];

  // Native 1024 x 293; display slot a bit taller, image still fills the card.
  static const _bannerAspect = 1024 / 340;
  static const _autoSlide = Duration(seconds: 4);

  final _controller = PageController();
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _timer?.cancel();
    _timer = Timer.periodic(_autoSlide, (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % _banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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
                itemCount: _banners.length,
                onPageChanged: (value) {
                  setState(() => _index = value);
                  _startAutoSlide();
                },
                itemBuilder: (context, index) {
                  return Image.asset(
                    _banners[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: AppColors.primary,
                      child: Center(
                        child: Icon(
                          LucideIcons.image_off,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_banners.length, (i) {
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
  }
}
