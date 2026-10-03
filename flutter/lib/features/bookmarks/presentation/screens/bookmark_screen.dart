import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/bookmark_post_card.dart';

class _BookmarkedPost {
  final String authorName;
  final String? timeAgo;
  final String communityTag;
  final String description;
  final String avatarAsset;

  const _BookmarkedPost({
    required this.authorName,
    required this.communityTag,
    required this.description,
    required this.avatarAsset,
    this.timeAgo,
  });
}

class BookmarkScreen extends StatefulWidget {
  /// Called when the user wants to browse the feed instead (empty state CTA).
  final VoidCallback? onBrowse;

  const BookmarkScreen({
    super.key,
    this.onBrowse,
  });

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  // Posts from the Figma "Bookmark" frame (node 21:309).
  final List<_BookmarkedPost> _bookmarks = [
    const _BookmarkedPost(
      authorName: 'Ethane Nguyen 🙍🧑‍🦯',
      timeAgo: '.1d',
      communityTag: 'CSIT Discord',
      description: 'Hey I want to meet today at uni in building 80.',
      avatarAsset: 'assets/images/bookmark_avatar_1.png',
    ),
    const _BookmarkedPost(
      authorName: 'SADIQ😆',
      timeAgo: '.43min',
      communityTag: 'CSIT Discord',
      description:
          'We study Software engineering pls come and have fun with us! Building 80.04.11🥰🥰',
      avatarAsset: 'assets/images/bookmark_avatar_2.png',
    ),
    const _BookmarkedPost(
      authorName: 'IBRAHIM🍎',
      communityTag: 'BERSS Discord',
      description:
          'Finding group study computer science for the assignment pls come and have free food with us at 1pm to 7pm. Join us to have fun and make friends we welcome!!😄😁',
      avatarAsset: 'assets/images/bookmark_avatar_3.png',
    ),
  ];

  void _removeBookmark(int index) {
    setState(() {
      _bookmarks.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_bookmarks.isEmpty) {
      return _EmptyBookmarks(onBrowse: widget.onBrowse);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 18.0, bottom: 90.0),
      itemCount: _bookmarks.length,
      itemBuilder: (context, index) {
        final post = _bookmarks[index];
        return Column(
          children: [
            BookmarkPostCard(
              authorName: post.authorName,
              timeAgo: post.timeAgo,
              communityTag: post.communityTag,
              description: post.description,
              avatarAsset: post.avatarAsset,
              onRemove: () => _removeBookmark(index),
            ),
            // Full-width divider between posts (Figma: 1px white lines)
            if (index < _bookmarks.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                color: Colors.white,
              ),
          ],
        );
      },
    );
  }
}

class _EmptyBookmarks extends StatelessWidget {
  final VoidCallback? onBrowse;

  const _EmptyBookmarks({this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 56,
              color: Colors.white.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 16),
            Text(
              'No bookmarks yet',
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 8),
            Text(
              'Posts you save will show up here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.description.copyWith(
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
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
