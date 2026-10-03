import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/tactile_button.dart';

class StudyPostCard extends StatelessWidget {
  final String authorName;
  final String timeAgo;
  final String communityTag;
  final String postContent;
  final String avatarAsset;
  final String mediaAsset;
  final int attendeeCount;
  final String? attendeeNames;
  final bool showGoingButton;
  final VoidCallback? onGoingPressed;
  final VoidCallback? onRemove;

  const StudyPostCard({
    super.key,
    required this.authorName,
    required this.timeAgo,
    required this.communityTag,
    required this.postContent,
    required this.avatarAsset,
    required this.mediaAsset,
    this.attendeeCount = 0,
    this.attendeeNames,
    this.showGoingButton = false,
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
          // Left Column: Circular Avatar (Figma: x:16, width:53, height:53)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 2.0),
            child: Container(
              width: 53,
              height: 53,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  avatarAsset,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Right Column: Author, Post Text, Indented Photo, and Action Row
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Line 1: Author Name, Time, and Community Tag
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
                      Text(
                        communityTag,
                        style: AppTextStyles.tag,
                      ),
                      if (onRemove != null) ...[
                        const SizedBox(width: 8),
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

                  // Line 2: Post Description
                  Text(
                    postContent,
                    style: AppTextStyles.description,
                  ),

                  const SizedBox(height: 8),

                  // Line 3: Media Photo (corner radius 10, black border, height 331)
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
                        mediaAsset,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Line 4: Attendees & "I'm going" Action Row
                  if (showGoingButton || (attendeeNames != null && attendeeNames!.isNotEmpty)) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Attendees count & participant names wrapped in Expanded to prevent overflow
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

                        // "I'm going ->" Action Pill Button (Figma Node 21:380)
                        if (showGoingButton)
                          TactileButton(
                            onTap: onGoingPressed ?? () {},
                            pressedScale: 0.90,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white, width: 1.0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "I’m going",
                                    style: AppTextStyles.caption,
                                  ),
                                  const SizedBox(width: 3),
                                  const Icon(
                                    Icons.arrow_circle_right_outlined,
                                    size: 13,
                                    color: Colors.white,
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
