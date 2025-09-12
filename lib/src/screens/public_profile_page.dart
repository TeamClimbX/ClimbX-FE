import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';
import '../api/user.dart';
import '../models/user_profile.dart';
import '../utils/color_schemes.dart';
import '../utils/tier_colors.dart';
import '../utils/tier_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/tier_widget.dart';
import '../widgets/history_widget.dart';
import '../widgets/streak_widget.dart';
import '../widgets/video_gallery_widget.dart';
import '../widgets/submission_list_widget.dart';

class PublicProfilePage extends HookWidget {
  final String nickname;

  const PublicProfilePage({super.key, required this.nickname});

  @override
  Widget build(BuildContext context) {
    final profileQuery = useQuery<UserProfile, Exception>(
      ['user_profile', nickname],
      () => UserApi.getUserProfileByNickname(nickname),
    );

    if (profileQuery.isLoading) {
      return Scaffold(
        backgroundColor: AppColorSchemes.backgroundSecondary,
        appBar: _buildAppBar(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (profileQuery.isError) {
      return Scaffold(
        backgroundColor: AppColorSchemes.backgroundSecondary,
        appBar: _buildAppBar(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('프로필을 불러올 수 없습니다'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => profileQuery.refetch(),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    final UserProfile userProfile = profileQuery.data!;
    final TierType tierType = TierColors.getTierTypeFromRating(userProfile.rating.totalRating);
    final TierColorScheme colorScheme = TierColors.getColorScheme(tierType);

    return TierProvider(
      colorScheme: colorScheme,
      child: Scaffold(
        backgroundColor: AppColorSchemes.backgroundSecondary,
        appBar: _buildAppBar(context),
        body: DefaultTabController(
          length: 5,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: ProfileHeader(userProfile: userProfile, readOnly: true),
                ),
                SliverPersistentHeader(
                  delegate: _StickyTabBarDelegate(
                    TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: AppColorSchemes.backgroundPrimary,
                      unselectedLabelColor: AppColorSchemes.textSecondary,
                      indicator: BoxDecoration(
                        gradient: colorScheme.gradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                      tabs: const [
                        _TabLabel('개요'),
                        _TabLabel('히스토리'),
                        _TabLabel('스트릭'),
                        _TabLabel('영상'),
                        _TabLabel('제출 내역'),
                      ],
                    ),
                  ),
                  pinned: true,
                ),
              ];
            },
            body: TabBarView(
              children: [
                _buildScrollContent(TierWidget(userProfile: userProfile)),
                _buildScrollContent(HistoryWidget(tierName: userProfile.displayTier, nickname: nickname)),
                _buildScrollContent(StreakWidget(userProfile: userProfile, nickname: nickname)),
                _buildScrollContent(VideoGalleryWidget(readOnly: true, nickname: nickname)),
                Container(
                  color: AppColorSchemes.backgroundSecondary,
                  child: SubmissionListWidget(nickname: nickname),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColorSchemes.backgroundPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: true,
      title: const Text(
        '프로필',
        style: TextStyle(
          color: AppColorSchemes.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildScrollContent(Widget child) {
    return Container(
      color: AppColorSchemes.backgroundSecondary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: child,
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  final String text;
  const _TabLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(text),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _StickyTabBarDelegate(this.tabBar);
  final TabBar tabBar;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColorSchemes.backgroundPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: tabBar,
    );
  }
  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) => tabBar != oldDelegate.tabBar;
}


