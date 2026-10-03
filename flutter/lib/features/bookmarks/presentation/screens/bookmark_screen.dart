import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/discord_user.dart';
import '../../data/bookmark_repository.dart';
import '../../domain/bookmarked_post.dart';
import '../widgets/bookmark_post_card.dart';

class BookmarkScreen extends StatefulWidget {
  
  final DiscordUser? user;

  
  final VoidCallback? onBrowse;

  const BookmarkScreen({
    super.key,
    this.user,
    this.onBrowse,
  });

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  Future<void> _removeBookmark(BookmarkedPost post) async {
    final user = widget.user;
    if (user == null) return;
    try {
      await BookmarkRepository.removeBookmark(
        userId: user.id,
        postId: post.postId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not remove bookmark: $e'),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    if (user == null) {
      return const _BookmarkMessage(
        'Sign in to save study sessions',
        icon: Icons.bookmark_border_rounded,
      );
    }

    return StreamBuilder<List<BookmarkedPost>>(
      stream: BookmarkRepository.watchBookmarks(user.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _BookmarkMessage(
            "Couldn't load bookmarks",
            icon: Icons.error_outline_rounded,
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        final bookmarks = snapshot.data!;
        if (bookmarks.isEmpty) {
          return _BookmarkMessage(
            'No bookmarks yet\nPosts you save will show up here.',
            icon: Icons.bookmark_border_rounded,
            onBrowse: widget.onBrowse,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 18.0, bottom: 90.0),
          itemCount: bookmarks.length,
          itemBuilder: (context, index) {
            final post = bookmarks[index];
            return Column(
              children: [
                BookmarkPostCard(
                  authorName: post.authorName ?? '@${post.author}',
                  timeAgo: post.timeAgo,
                  description: post.title,
                  avatarAsset: 'assets/images/header_avatar.png',
                  avatarUrl: post.authorAvatar,
                  communityTag: post.serverName,
                  onRemove: () => _removeBookmark(post),
                ),
                if (index < bookmarks.length - 1)
                  const Padding(
                    // Match the card's bottom padding so the next card
                    // doesn't sit on the line.
                    padding: EdgeInsets.only(bottom: 14),
                    child: Divider(height: 1, thickness: 1, color: Colors.white),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _BookmarkMessage extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onBrowse;

  const _BookmarkMessage(this.message, {required this.icon, this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.white.withValues(alpha: 0.45)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.description.copyWith(
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            if (onBrowse != null)
              TextButton(
                onPressed: onBrowse,
                child: Text(
                  'Browse the feed',
                  style: AppTextStyles.tag.copyWith(color: AppColors.accentPill),
                ),
              ),
          ],
        ),
      ),
    );
  }
}