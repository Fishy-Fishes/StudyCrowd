import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/tactile_button.dart';

/// A saved-post card matching the Figma "Bookmark" frame (node 21:309):
/// avatar on the left, author/time/tag + description on the right, and a
/// remove control in the top-right corner.
class BookmarkPostCard extends StatelessWidget {
  final String authorName;
  final String? timeAgo;
  final String communityTag;
  final String description;
  final String avatarAsset;
  final VoidCallback? onRemove;

  const BookmarkPostCard({
    super.key,
    required this.authorName,
    required this.communityTag,
    required this.description,
    required this.avatarAsset,
    this.timeAgo,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar (Figma: x:16, 53x53)
          ClipOval(
            child: SizedBox(
              width: 53,
              height: 53,
              child: Image.asset(
                avatarAsset,
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Right column (Figma: x:75)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author + time (left), community tag (right)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.authorName,
                      ),
                    ),
                    if (timeAgo != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        timeAgo!,
                        style: AppTextStyles.timestamp,
                      ),
                    ],
                    const Spacer(),
                    Text(
                      communityTag,
                      style: AppTextStyles.tag,
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Description
                Text(
                  description,
                  style: AppTextStyles.description,
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Remove control, top-right of the card
          Tooltip(
            message: 'Remove bookmark',
            child: TactileButton(
              onTap: onRemove ?? () {},
              pressedScale: 0.85,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                    width: 1.0,
                  ),
                ),
                child: Icon(
                  Icons.bookmark_remove_outlined,
                  size: 17,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
