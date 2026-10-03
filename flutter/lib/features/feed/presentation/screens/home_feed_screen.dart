import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/discord_user.dart';
import '../../../bookmarks/presentation/screens/bookmark_screen.dart';
import '../../data/post_repository.dart';
import '../../domain/study_post.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/study_post_card.dart';

class HomeFeedScreen extends StatefulWidget {
  final DiscordUser? currentUser;

  const HomeFeedScreen({
    super.key,
    this.currentUser,
  });

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 402, 
          ),
          child: Stack(
            children: [
              
              Column(
                children: [
                  
                  AppHeader(
                    currentUser: widget.currentUser,
                  ),

                  
                  Expanded(
                    child: IndexedStack(
                      index: _currentTabIndex,
                      children: [
                        _buildFeedList(),
                        BookmarkScreen(
                          user: widget.currentUser,
                          onBrowse: () {
                            setState(() {
                              _currentTabIndex = 0;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: BottomNavBar(
                  selectedIndex: _currentTabIndex,
                  onTabSelected: (index) {
                    setState(() {
                      _currentTabIndex = index;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedList() {
    return StreamBuilder<List<StudyPost>>(
      stream: PostRepository.watchPosts(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _FeedMessage(
            "Couldn't load posts\n${snapshot.error}".trim(),
            icon: Icons.error_outline_rounded,
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        final posts = snapshot.data!;
        if (posts.isEmpty) {
          return const _FeedMessage(
            'No study sessions yet',
            icon: Icons.groups_outlined,
          );
        }
        return ListView(
          padding: const EdgeInsets.only(top: 18.0, bottom: 90.0),
          children: [
            for (final post in posts)
              StudyPostCard(
                authorName: _authorName(post),
                timeAgo: post.timeAgo,
                postContent: post.title,
                avatarAsset: 'assets/images/header_avatar.png',
                avatarUrl: post.authorAvatar,
                communityTag: post.serverName,
                attendeeCount: post.attendeeCount,
                attendeeNames: post.attendeeNames,
                showGoingButton: true,
                isGoing: _currentUser != null &&
                    post.attending.contains(_currentUser!.id),
                onGoingPressed: () => _toggleRsvp(post),
              ),
          ],
        );
      },
    );
  }

  DiscordUser? get _currentUser => widget.currentUser;

  void _toggleRsvp(StudyPost post) {
    final user = widget.currentUser;
    if (user == null) return;
    PostRepository.toggleRsvp(
      postId: post.id,
      userId: user.id,
      userName: user.displayName,
    ).catchError(
      (Object e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not update: $e'),
              backgroundColor: const Color(0xFFD32F2F),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  String _authorName(StudyPost post) {
    final user = widget.currentUser;
    if (post.authorName != null) return post.authorName!;
    if (user != null && post.author == user.id) return user.displayName;
    return '@${post.author}';
  }
}

class _FeedMessage extends StatelessWidget {
  final String message;
  final IconData icon;

  const _FeedMessage(this.message, {required this.icon});

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
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}