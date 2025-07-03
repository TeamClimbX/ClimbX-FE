import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';
import 'profile_header.dart';
import 'tier_widget.dart';
import 'history_widget.dart';
import 'streak_widget.dart';
import '../utils/tier_colors.dart';
import '../services/user_service.dart';
import '../services/user_query_service.dart';

class ProfileBody extends HookWidget {
  final String currentTier;
  final TierColorScheme colorScheme;

  const ProfileBody({
    super.key,
    required this.currentTier,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    // fquery로 데이터 get
    final userQuery = useQuery<UserProfile, Exception>(
      UserQueryKeys.userProfile(),
      UserQueryService.getUserProfile,
    );

    // 로딩 상태
    if (userQuery.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 에러 상태
    if (userQuery.isError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('프로필을 불러올 수 없습니다'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => userQuery.refetch(),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    final userProfile = userQuery.data;
    return DefaultTabController(
      length: 5,
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverToBoxAdapter(
              child: ProfileHeader(
                userProfile: userProfile,
                tierName: currentTier,
              ),
            ),
            SliverPersistentHeader(
              delegate: _StickyTabBarDelegate(
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: const Color(0xFFFFFFFF),
                  unselectedLabelColor: const Color(0xFF64748B),
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
                  tabs: [
                    _buildTab('개요'),
                    _buildTab('히스토리'),
                    _buildTab('스트릭'),
                    _buildTab('분야별 티어'),
                    _buildTab('내 영상'),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          children: [
            _buildTabContent(
              child: TierWidget(
                tierName: currentTier,
                userProfile: userProfile,
              ),
            ),
            _buildTabContent(child: HistoryWidget(tierName: currentTier)),
            _buildTabContent(
              child: StreakWidget(
                tierName: currentTier,
                userProfile: userProfile,
              ),
            ),
            _buildTabContent(
              child: _buildComingSoon('분야별 티어', Icons.category, colorScheme),
            ),
            _buildTabContent(
              child: _buildComingSoon('내 영상', Icons.video_library, colorScheme),
            ),
          ],
        ),
      ),
    );
  }

  // 탭바에서 선택할 수 있는 텍스트
  Widget _buildTab(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(text),
    );
  }

  // 내용이 들어있는 탭바 위젯
  Widget _buildTabContent({required Widget child}) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: child,
      ),
    );
  }

  // 출시 예정 탭바
  Widget _buildComingSoon(
    String title,
    IconData icon,
    TierColorScheme colorScheme,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 20,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: colorScheme.gradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: const Color(0xFFFFFFFF), size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '곧 출시 예정입니다',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
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
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
