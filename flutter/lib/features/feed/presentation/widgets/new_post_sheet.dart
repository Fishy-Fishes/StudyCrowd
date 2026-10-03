import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/event_date.dart';
import '../../../../core/widgets/tactile_button.dart';
import '../../../auth/domain/discord_user.dart';
import '../../data/post_repository.dart';

/// Space around the card and between the card and the Post button.
const double _gutter = 14;

/// Compose sheet for posting a study session from the app. The card sits at
/// the top of the screen with the Post button floating below it; both slide
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
  DateTime? _date;
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
      await PostRepository.createPost(
        author: widget.user,
        text: text,
        date: _date,
      );
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

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accentPill,
            onPrimary: AppColors.buttonText,
            surface: AppColors.headerBackground,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
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
            _ComposeCard(
              controller: _controller,
              date: _date,
              onPickDate: _pickDate,
              onClearDate: () => setState(() => _date = null),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, _gutter, _gutter, 0),
              child: _PostButton(posting: _posting, onTap: _post),
            ),
          ],
        ),
      ),
    );
  }
}

/// The dark card holding the text box, floating a gutter below the top of the screen.
class _ComposeCard extends StatelessWidget {
  final TextEditingController controller;
  final DateTime? date;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;

  const _ComposeCard({
    required this.controller,
    required this.date,
    required this.onPickDate,
    required this.onClearDate,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(_gutter, _gutter, _gutter, 0),
        child: Material(
          color: AppColors.headerBackground,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('New study session', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 12),
                SizedBox(
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
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _DateChip(
                    date: date,
                    onTap: onPickDate,
                    onClear: onClearDate,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Add date" until a day is picked, then the day with an x to clear it.
class _DateChip extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DateChip({
    required this.date,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final picked = date;
    return TactileButton(
      onTap: onTap,
      pressedScale: 0.94,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_outlined, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              picked == null ? 'Add date' : formatEventDate(picked),
              style: AppTextStyles.caption,
            ),
            if (picked != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
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
