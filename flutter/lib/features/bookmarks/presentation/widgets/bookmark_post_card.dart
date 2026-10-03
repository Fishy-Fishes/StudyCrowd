import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/tactile_button.dart';




class BookmarkPostCard extends StatelessWidget {
  final String authorName;
  final String? timeAgo;
  final String? communityTag;
  final String description;
  final String avatarAsset;
  final VoidCallback? onRemove;

  const BookmarkPostCard({
    super.key,
    required this.authorName,
    required this.description,
    required this.avatarAsset,
    this.timeAgo,
    this.communityTag,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
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

          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
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
                    if (communityTag != null)
                      Text(
                        communityTag!,
                        style: AppTextStyles.tag,
                      ),
                  ],
                ),

                const SizedBox(height: 4),

                
                Text(
                  description,
                  style: AppTextStyles.description,
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          
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
