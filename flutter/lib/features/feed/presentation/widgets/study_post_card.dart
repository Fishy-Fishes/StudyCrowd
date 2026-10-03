import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/tactile_button.dart';

class StudyPostCard extends StatelessWidget {
  final String authorName;
  final String timeAgo;
  final String? communityTag;
  final String postContent;
  final String? eventDate;
  final String avatarAsset;
  final String? avatarUrl;
  final String? mediaAsset;
  final int attendeeCount;
  final int? commentCount;
  final String? attendeeNames;
  final bool showGoingButton;
  final bool isGoing;
  final VoidCallback? onGoingPressed;
  final VoidCallback? onRemove;

  const StudyPostCard({
    super.key,
    required this.authorName,
    required this.timeAgo,
    required this.postContent,
    this.eventDate,
    required this.avatarAsset,
    this.avatarUrl,
    this.communityTag,
    this.mediaAsset,
    this.attendeeCount = 0,
    this.commentCount,
    this.attendeeNames,
    this.showGoingButton = false,
    this.isGoing = false,
    this.onGoingPressed,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 2.0),
            child: Container(
              width: 53,
              height: 53,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: avatarUrl == null
                    ? Image.asset(avatarAsset, fit: BoxFit.cover)
                    : Image.network(
                        avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            Image.asset(avatarAsset, fit: BoxFit.cover),
                      ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                authorName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.authorName,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              timeAgo,
                              style: AppTextStyles.timestamp,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (communityTag != null) ...[
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 150),
                          child: Text(
                            communityTag!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.tag,
                          ),
                        ),
                        if (onRemove != null) const SizedBox(width: 8),
                      ],
                      if (onRemove != null) ...[
                        TactileButton(
                          onTap: onRemove!,
                          pressedScale: 0.85,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.6),
                                width: 1.0,
                              ),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 15,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 3),

                  
                  Text(
                    postContent,
                    style: AppTextStyles.description,
                  ),

                  if (eventDate != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.event_outlined,
                          color: Colors.white,
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Text(eventDate!, style: AppTextStyles.caption),
                      ],
                    ),
                  ],

                  const SizedBox(height: 8),

                  
                  if (mediaAsset != null) ...[
                    Container(
                      width: double.infinity,
                      height: 331,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.black,
                          width: 1.0,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.asset(
                          mediaAsset!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],

                  
                  if (showGoingButton || (attendeeNames != null && attendeeNames!.isNotEmpty)) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.groups_outlined,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$attendeeCount',
                                style: AppTextStyles.caption,
                              ),
                              if (commentCount != null) ...[
                                const SizedBox(width: 10),
                                const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: Colors.white,
                                  size: 15,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$commentCount',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                              if (attendeeNames != null) ...[
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    attendeeNames!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        
                        if (showGoingButton)
                          TactileButton(
                            onTap: onGoingPressed ?? () {},
                            pressedScale: 0.90,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isGoing
                                    ? AppColors.accentPill
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isGoing
                                      ? AppColors.accentPill
                                      : Colors.white,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    isGoing ? 'Going' : "I’m going",
                                    style: AppTextStyles.caption.copyWith(
                                      color: isGoing
                                          ? AppColors.scaffoldBackground
                                          : Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Icon(
                                    isGoing
                                        ? Icons.check_rounded
                                        : Icons.arrow_circle_right_outlined,
                                    size: 13,
                                    color: isGoing
                                        ? AppColors.scaffoldBackground
                                        : Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
