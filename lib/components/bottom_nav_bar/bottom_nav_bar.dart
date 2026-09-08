import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final index = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Material(
        color: AppColors.primary,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'nav.home'.tr(),
                  selected: index == 0,
                  onTap: () => _go(0),
                ),
                _NavItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'nav.package'.tr(),
                  selected: index == 1,
                  onTap: () => _go(1),
                ),
                _NavItem(
                  icon: Icons.mail_outline_rounded,
                  label: 'nav.inbox'.tr(),
                  selected: index == 2,
                  onTap: () => _go(2),
                ),
                _NavItem(
                  icon: Icons.smart_toy_outlined,
                  label: 'nav.support'.tr(),
                  selected: index == 3,
                  onTap: () => _go(3),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  label: 'nav.profile'.tr(),
                  selected: index == 4,
                  onTap: () => _go(4),
                ),
              ],
            ),
          ),
        ),
      ),
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
    final color = selected ? AppColors.accent : AppColors.onPrimary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
