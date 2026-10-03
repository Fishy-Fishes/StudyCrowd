import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/tactile_button.dart';
import '../../../auth/domain/discord_user.dart';
import '../../../feed/domain/study_post.dart';
import '../../../feed/presentation/widgets/study_post_card.dart';
import '../../data/comment_repository.dart';
import '../../domain/comment.dart';

const _defaultAvatar = 'assets/images/header_avatar.png';

/// A post and its comments. Comments made in Discord (replies to the event
/// embed or messages in its thread) show up here, and comments posted here are
/// mirrored into the embed's Discord thread by the bot.
class CommentsScreen extends StatelessWidget {
  final StudyPost post;
  final DiscordUser? user;

  /// Comments to show; defaults to the post's comments in Firestore.
  final Stream<List<Comment>>? comments;

  const CommentsScreen({
    super.key,
    required this.post,
    this.user,
    this.comments,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Column(
        children: [
          const _TopBar(),
          Expanded(
            child: StreamBuilder<List<Comment>>(
              stream: comments ?? CommentRepository.watchComments(post.id),
              builder: (context, snapshot) {
                final comments = snapshot.data ?? const <Comment>[];
                return ListView(
                  padding: const EdgeInsets.only(top: 18, bottom: 12),
                  children: [
                    StudyPostCard(
                      authorName: post.authorName ?? '@${post.author}',
                      timeAgo: post.timeAgo,
                      postContent: post.title,
                      avatarAsset: _defaultAvatar,
                      avatarUrl: post.authorAvatar,
                      communityTag: post.serverName,
                      attendeeCount: post.attendeeCount,
                      attendeeNames: post.attendeeNames,
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    if (snapshot.hasData && comments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No comments yet',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    for (final comment in comments) _CommentTile(comment),
                  ],
                );
              },
            ),
          ),
          if (user != null) _CommentInput(postId: post.id, user: user!),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.headerBackground,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.iconColor,
                ),
              ),
              Text('Comments', style: AppTextStyles.sectionTitle),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;

  const _CommentTile(this.comment);

  @override
  Widget build(BuildContext context) {
    final avatar = comment.authorAvatar;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: SizedBox(
              width: 36,
              height: 36,
              child: avatar == null
                  ? Image.asset(_defaultAvatar, fit: BoxFit.cover)
                  : Image.network(
                      avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Image.asset(_defaultAvatar, fit: BoxFit.cover),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(comment.timeAgo, style: AppTextStyles.timestamp),
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.text, style: AppTextStyles.description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentInput extends StatefulWidget {
  final String postId;
  final DiscordUser user;

  const _CommentInput({required this.postId, required this.user});

  @override
  State<_CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<_CommentInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    try {
      await CommentRepository.addComment(
        postId: widget.postId,
        author: widget.user,
        text: text,
      );
    } catch (e) {
      _controller.text = text;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not comment: $e'),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.headerBackground,
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                cursorColor: AppColors.accentPill,
                style: AppTextStyles.description,
                decoration: InputDecoration(
                  hintText: 'Add a comment',
                  hintStyle: AppTextStyles.description.copyWith(
                    color: AppColors.textMuted,
                  ),
                  filled: true,
                  fillColor: AppColors.cardSurface,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            TactileButton(
              onTap: _send,
              pressedScale: 0.9,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.accentPill,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: AppColors.buttonText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
