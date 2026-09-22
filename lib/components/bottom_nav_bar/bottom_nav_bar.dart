import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/locale/app_locale_provider.dart';
import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';
import '../../core/theme/app_theme/app_theme.dart';
import '../../core/ui/bottom_nav_visibility_provider.dart';

/// Common bottom navigation — light surface + soft glass selected pill.
class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    (Icons.home, 'nav.home'),
    (Icons.widgets, 'nav.package'),
    (Icons.mail, 'nav.inbox'),
    (Icons.chat, 'nav.support'),
    (Icons.person, 'nav.profile'),
  ];

  static const _pillWidth = 44.0;
  static const _pillHeight = 26.0;
  static const _pillTop = 10.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = navigationShell.currentIndex;
    final locale = ref.watch(appLocaleProvider);
    final showNav = ref.watch(bottomNavVisibleProvider);

    const navTopRadius = BorderRadius.vertical(
      top: Radius.circular(AppStyle.radiusCurve),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: showNav
          ? DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: navTopRadius,
                border: Border(
                  top: BorderSide(
                    color: AppColors.paperBorder,
                    width: 0.8,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Material(
                color: AppColors.surface,
                elevation: 0,
                clipBehavior: Clip.antiAlias,
                shape: const RoundedRectangleBorder(
                  borderRadius: navTopRadius,
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    key: ValueKey('bottom-nav-$locale'),
                    height: AppStyle.bottomNavHeight,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final itemWidth =
                            constraints.maxWidth / _items.length;
                        final pillLeft =
                            (itemWidth * index) +
                            ((itemWidth - _pillWidth) / 2);

                        return Stack(
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeOutCubic,
                              left: pillLeft,
                              top: _pillTop,
                              width: _pillWidth,
                              height: _pillHeight,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 8,
                                    sigmaY: 8,
                                  ),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      // Soft primary glass — less white overlay.
                                      color: AppColors.primaryLight
                                          .withValues(alpha: 0.42),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.22),
                                        width: 0.6,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.06),
                                          blurRadius: 5,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                for (var i = 0; i < _items.length; i++)
                                  _NavItem(
                                    icon: _items[i].$1,
                                    label: context.tr(_items[i].$2),
                                    selected: index == i,
                                    onTap: () => _go(i),
                                  ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  void _go(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 26,
                child: Icon(
                  icon,
                  color: color,
                  size: AppStyle.bottomNavIconSize,
                ),
              ),
              const SizedBox(height: AppStyle.bottomNavIconGap),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                style: AppTheme.navLabel(selected: selected, color: color),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

