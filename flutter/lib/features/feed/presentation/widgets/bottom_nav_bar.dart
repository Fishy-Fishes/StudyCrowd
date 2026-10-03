import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/tactile_button.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              
              Expanded(
                flex: 181,
                child: _NavPill(
                  icon: Icons.home_outlined,
                  iconSize: 34,
                  isActive: selectedIndex == 0,
                  onTap: () => onTabSelected(0),
                ),
              ),

              const SizedBox(width: 12),

              
              Expanded(
                flex: 190,
                child: _NavPill(
                  icon: Icons.bookmark_outline_rounded,
                  iconSize: 32,
                  isActive: selectedIndex == 1,
                  onTap: () => onTabSelected(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final bool isActive;
  final VoidCallback onTap;

  const _NavPill({
    required this.icon,
    required this.iconSize,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TactileButton(
      onTap: onTap,
      pressedScale: 0.94,
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: AppColors.accentPill,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            size: iconSize,
            color: isActive
                ? Colors.white
                : Colors.white.withValues(alpha: 0.55),
            shadows: isActive
                ? [
                    Shadow(
                      color: Colors.white.withValues(alpha: 0.95),
                      blurRadius: 14,
                    ),
                    Shadow(
                      color: AppColors.accentPill,
                      blurRadius: 20,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
