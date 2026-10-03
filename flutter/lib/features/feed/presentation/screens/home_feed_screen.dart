import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../bookmarks/presentation/screens/bookmark_screen.dart';
import '../widgets/app_header.dart';
import '../widgets/study_post_card.dart';
import '../widgets/bottom_nav_bar.dart';

import '../../../auth/domain/discord_user.dart';

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
            maxWidth: 402, // Exact Figma frame width
          ),
          child: Stack(
            children: [
              // Main Content (shared header + active tab body)
              Column(
                children: [
                  // Flush Header with status bar coverage (Figma Node 21:288)
                  AppHeader(
                    currentUser: widget.currentUser,
                  ),

                  // Active tab body
                  Expanded(
                    child: IndexedStack(
                      index: _currentTabIndex,
                      children: [
                        _buildFeedList(),
                        BookmarkScreen(
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

              // Floating Dual-Pill Bottom Navigation Bar (Figma Node 21:291)
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
    return ListView(
      padding: const EdgeInsets.only(top: 18.0, bottom: 90.0),
      children: [
        // Post 1: Ethane Nguyen (Figma Node 21:263)
        StudyPostCard(
          authorName: 'Ethane Nguyen 🙍🧑‍🦯',
          timeAgo: '.1d',
          communityTag: 'CSIT Discord',
          postContent: 'Hey I want to meet today at uni in building 80.',
          avatarAsset: 'assets/images/avatar_dragon.png',
          mediaAsset: 'assets/images/post1_meeting.png',
          attendeeCount: 11,
          attendeeNames: 'Remy, Sadiq, Liam...',
          showGoingButton: true,
          onGoingPressed: () {},
        ),

        // Post 2: Sethcha Sara (Figma Node 21:276)
        const StudyPostCard(
          authorName: 'Sethcha Sara🐶',
          timeAgo: '.23min',
          communityTag: 'BERSS Discord',
          postContent:
              'We make meeting at RMIT library study biomedical Engineering pls come and join us!!',
          avatarAsset: 'assets/images/avatar_anime.png',
          mediaAsset: 'assets/images/post2_library.png',
        ),
      ],
    );
  }
}
