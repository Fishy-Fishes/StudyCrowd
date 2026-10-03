import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/tactile_button.dart';
import '../../../auth/domain/discord_user.dart';
import '../../data/post_repository.dart';

/// Compose sheet for posting a study session from the app. The card is anchored
/// to the top of the screen with the Post button floating below it; both slide
/// down together and slide back up when dismissed.
class NewPostSheet extends StatefulWidget {
  final DiscordUser user;

  const NewPostSheet({super.key, required this.user});

  static Future<void> show(BuildContext context, DiscordUser user) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) => NewPostSheet(user: user),
      transitionBuilder: (_, animation, _, child) => SlideTransition(
        position: animation.drive(
          Tween(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)),
        ),
        child: child,
      ),
    );
  }

  @override
  State<NewPostSheet> createState() => _NewPostSheetState();
}

class _NewPostSheetState extends State<NewPostSheet> {
  final _controller = TextEditingController();
  bool _posting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _posting) return;
    setState(() => _posting = true);
    try {
      await PostRepository.createPost(author: widget.user, text: text);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _posting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not post: $e'),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Transparent Material so the floating Post button gets text styling too.
    return Material(
      type: MaterialType.transparency,
      child: Align(
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _ComposeCard(controller: _controller),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 20, 0),
              child: _PostButton(posting: _posting, onTap: _post),
            ),
          ],
        ),
      ),
    );
  }
}

/// The dark card holding the text box, flush with the top of the screen.
class _ComposeCard extends StatelessWidget {
  final TextEditingController controller;

  const _ComposeCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.headerBackground,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 116,
            child: TextField(
              controller: controller,
              autofocus: true,
              expands: true,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              cursorColor: AppColors.accentPill,
              style: AppTextStyles.description,
              decoration: InputDecoration(
                hintText: 'Study at the library at 3?',
                hintStyle: AppTextStyles.description.copyWith(
                  color: AppColors.textMuted,
                ),
                filled: true,
                fillColor: AppColors.cardSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PostButton extends StatelessWidget {
  final bool posting;
  final VoidCallback onTap;

  const _PostButton({required this.posting, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TactileButton(
      onTap: onTap,
      pressedScale: 0.92,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.accentPill,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          posting ? 'Posting…' : 'Post',
          style: AppTextStyles.authorName.copyWith(color: AppColors.buttonText),
        ),
      ),
    );
  }
}
