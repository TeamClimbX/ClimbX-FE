import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'profile_header.dart';
import 'tier_widget.dart';
import 'history_widget.dart';
import 'streak_widget.dart';
import '../utils/color_schemes.dart';
import '../models/user_profile.dart';
import '../api/user.dart';
import 'video_gallery_widget.dart';
import '../utils/tier_provider.dart';
import 'submission_list_widget.dart';
import '../utils/profile_refresh_manager.dart';

/// 프로필 화면의 메인 바디 위젯
/// 로딩/에러 상태 처리 및 탭 구조 관리

class ProfileBody extends HookWidget {
  const ProfileBody({super.key});

  @override
  Widget build(BuildContext context) {
    // 사용자 프로필 데이터 조회
    final userQuery = useQuery<UserProfile, Exception>([
      'user_profile',
    ], UserApi.getUserProfile);

    // 프로필 새로고침 매니저 인스턴스
    final refreshManager = useMemoized(() => ProfileRefreshManager(), []);

    // 공통 프로필 새로고침 로직
    Future<void> performProfileRefresh(String logMessage) async {
      if (context.mounted) {
        developer.log(logMessage, name: 'ProfileBody');
        userQuery.refetch();
        // markRefreshed도 비동기이므로 context.mounted 재확인
        if (context.mounted) {
          await refreshManager.markRefreshed();
        }
      }
    }

    // 페이지 진입 시 새로고침 필요성 체크
    useEffect(() {
      // 진입 시 즉시 새로고침 필요성 체크 (플래그 + 5분 경과 종합 판단)
      refreshManager.shouldRefresh().then((shouldRefresh) async {
        if (shouldRefresh) {
          await performProfileRefresh('프로필 진입 시 새로고침 트리거');
        }
      });

      return null;
    }, const []);

    // 로딩 중 표시
    if (userQuery.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 에러 발생 시 재시도 화면
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

    // 데이터 로드 성공 - 프로필 정보 사용
    final userProfile = userQuery.data!;
    final currentTier = userProfile.displayTier;
    final colorScheme = TierProvider.of(context);
    return DefaultTabController(
      length: 5,
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverToBoxAdapter(child: ProfileHeader(userProfile: userProfile)),
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
                  tabs: [
                    _buildTab('개요'),
                    _buildTab('히스토리'),
                    _buildTab('스트릭'),
                    _buildTab('내 영상'),
                    _buildTab('제출 내역'),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          children: [
            _buildTabContent(child: TierWidget(userProfile: userProfile)),
            _buildTabContent(child: HistoryWidget(tierName: currentTier)),
            _buildTabContent(
              child: StreakWidget(
                userProfile: userProfile,
              ),
            ),
            _buildTabContent(child: const VideoGalleryWidget()),
            // _buildTabContent(
            //   child: _buildComingSoon('분야별 티어', Icons.category, colorScheme),
            // ),
            // 제출 내역은 내부에서 자체 스크롤(ListView)을 사용하므로
            // 외부 SingleChildScrollView로 감싸지 않도록 직접 배치
            Container(
              color: AppColorSchemes.backgroundSecondary,
              child: const SubmissionListWidget(),
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
      color: AppColorSchemes.backgroundSecondary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: child,
      ),
    );
  }
}

/// 스크롤 시 고정되는 탭바 델리게이트
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
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
