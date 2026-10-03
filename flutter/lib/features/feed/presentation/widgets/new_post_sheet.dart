import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/tactile_button.dart';
import '../../../auth/domain/discord_user.dart';
import '../../data/post_repository.dart';

/// Bottom sheet for posting a new study session from the app.
class NewPostSheet extends StatefulWidget {
  final DiscordUser user;

  const NewPostSheet({super.key, required this.user});

  static Future<void> show(BuildContext context, DiscordUser user) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.headerBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => NewPostSheet(user: user),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('New study session', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 2,
            maxLines: 5,
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
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TactileButton(
              onTap: _post,
              pressedScale: 0.9,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentPill,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _posting ? 'Posting…' : 'Post',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.buttonText,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
