import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/tactile_button.dart';
import '../../../auth/domain/discord_user.dart';
import 'new_post_sheet.dart';

/// Round + button that opens [NewPostSheet].
class NewPostButton extends StatelessWidget {
  final DiscordUser user;

  const NewPostButton({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return TactileButton(
      onTap: () => NewPostSheet.show(context, user),
      pressedScale: 0.9,
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: AppColors.accentPill,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.add_rounded,
          size: 30,
          color: AppColors.buttonText,
        ),
      ),
    );
  }
}
