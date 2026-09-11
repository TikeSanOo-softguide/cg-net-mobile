import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/locale/app_locale_provider.dart';
import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';
import '../../core/theme/app_theme/app_theme.dart';
import '../../core/ui/bottom_nav_visibility_provider.dart';

/// Common bottom navigation — full-width surface, primary selected state.
class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = navigationShell.currentIndex;
    final locale = ref.watch(appLocaleProvider);
    final showNav = ref.watch(bottomNavVisibleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: showNav
          ? Material(
              color: AppColors.surface,
              elevation: 0,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.borderLight,
                      width: 0.5,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    key: ValueKey('bottom-nav-$locale'),
                    height: AppStyle.bottomNavHeight,
                    child: Row(
                      children: [
                        _NavItem(
                          icon: LucideIcons.house,
                          label: context.tr('nav.home'),
                          selected: index == 0,
                          onTap: () => _go(0),
                        ),
                        _NavItem(
                          icon: LucideIcons.package,
                          label: context.tr('nav.package'),
                          selected: index == 1,
                          onTap: () => _go(1),
                        ),
                        _NavItem(
                          icon: LucideIcons.mail,
                          label: context.tr('nav.inbox'),
                          selected: index == 2,
                          onTap: () => _go(2),
                        ),
                        _NavItem(
                          icon: LucideIcons.bot,
                          label: context.tr('nav.support'),
                          selected: index == 3,
                          onTap: () => _go(3),
                        ),
                        _NavItem(
                          icon: LucideIcons.user,
                          label: context.tr('nav.profile'),
                          selected: index == 4,
                          onTap: () => _go(4),
                        ),
                      ],
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
              Icon(icon, color: color, size: AppStyle.bottomNavIconSize),
              const SizedBox(height: AppStyle.bottomNavIconGap),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.navLabel(selected: selected, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
