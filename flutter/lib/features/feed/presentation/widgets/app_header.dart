import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/tactile_button.dart';
import '../../../auth/data/discord_auth_service.dart';
import '../../../auth/domain/discord_user.dart';
import '../../../auth/presentation/screens/sign_in_screen.dart';

class AppHeader extends StatelessWidget {
  final DiscordUser? currentUser;
  final VoidCallback? onProfilePressed;

  const AppHeader({
    super.key,
    this.currentUser,
    this.onProfilePressed,
  });

  void _showProfileModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomContext) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          decoration: const BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accentPill, width: 2),
                  ),
                  child: ClipOval(
                    child: currentUser?.avatarUrl != null
                        ? Image.network(
                            currentUser!.avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Image.asset(
                              'assets/images/header_avatar.png',
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            'assets/images/header_avatar.png',
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(height: 14),

                // Name & Username
                Text(
                  currentUser?.displayName ?? 'Guest User',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (currentUser != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '@${currentUser!.username}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (currentUser!.email != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      currentUser!.email!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 24),

                // Sign Out Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(bottomContext).pop();
                      await DiscordAuthService.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const SignInScreen(),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.headerBackground,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left spacer to keep the logo centered (grid icon removed)
              const SizedBox(width: 48),

              // Center Logo (Figma Node 21:290)
              Image.asset(
                'assets/images/app_logo.png',
                height: 42,
                fit: BoxFit.contain,
              ),

              // Right Profile Avatar (Figma Node 22:429 / Live Discord Avatar)
              TactileButton(
                onTap: onProfilePressed ?? () => _showProfileModal(context),
                pressedScale: 0.90,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: currentUser != null ? AppColors.accentPill : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: currentUser?.avatarUrl != null
                        ? Image.network(
                            currentUser!.avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Image.asset(
                              'assets/images/header_avatar.png',
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            'assets/images/header_avatar.png',
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
