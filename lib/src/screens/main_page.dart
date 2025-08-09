import 'package:flutter/material.dart';
import '../widgets/map_body.dart';
import '../widgets/profile_body.dart';
import '../widgets/leaderboard_body.dart';
import '../widgets/search_body.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_navigation_bar.dart';
import '../utils/tier_colors.dart';
import '../utils/bottom_nav_tab.dart';
import '../utils/color_schemes.dart';
import '../utils/tier_provider.dart';
import '../api/user.dart';
import '../models/user_profile.dart';
import 'dart:developer' as developer;

class MainPage extends StatefulWidget {
  final BottomNavTab? initialTab;

  const MainPage({super.key, this.initialTab});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late BottomNavTab _currentTab;
  UserProfile? _userProfile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 초기 탭 설정 - 프로필이 첫 번째 탭이므로 기본값으로 설정
    _currentTab = widget.initialTab ?? BottomNavTab.profile;

    // 유저 프로필 로드
    _loadUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중이거나 에러가 있으면 로딩 화면 표시
    if (_isLoading || _error != null) {
      return Scaffold(
        backgroundColor: AppColorSchemes.backgroundSecondary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('프로필 정보를 불러오는 중...'),
              ] else ...[
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(_error ?? '프로필을 불러올 수 없습니다.'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadUserProfile,
                  child: const Text('다시 시도'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // 유저 프로필이 로드된 경우
    final userTier = _userProfile?.tier ?? 'Bronze III';
    final TierType tierType = TierColors.getTierFromString(userTier);
    final TierColorScheme colorScheme = TierColors.getColorScheme(tierType);

    return TierProvider(
      colorScheme: colorScheme,
      child: Scaffold(
        backgroundColor: AppColorSchemes.backgroundSecondary,

        // 상단 앱바
        appBar: const CustomAppBar(),
      // Body - Indexed Stack으로 화면 전환
      body: IndexedStack(
        index: _currentTab.index,
        children: const [
          // 0: 프로필
          ProfileBody(),
          // 1: 리더보드
          LeaderboardBody(),
          // 2: 검색
          SearchBody(),
          // 3: 지도
          MapBody(),
        ],
      ),

              // 하단 네비게이션 바
        bottomNavigationBar: CustomBottomNavigationBar(
          currentTab: _currentTab,
          onTap: (tab) {
            // 현재 페이지 내에서 탭 변경
            setState(() {
              _currentTab = tab;
            });
          },
        ),
      ),
    );
  }
  
  /// 유저 프로필 로드
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      developer.log('유저 프로필 로드 시작', name: 'MainPage');
      final userProfile = await UserApi.getCurrentUserProfile();

      if (mounted) {
        setState(() {
          _userProfile = userProfile;
          _isLoading = false;
        });
        developer.log('유저 프로필 로드 완료: ${userProfile.tier}', name: 'MainPage');
      }
    } catch (e) {
      developer.log('유저 프로필 로드 실패: $e', name: 'MainPage', error: e);
      if (mounted) {
        setState(() {
          _error = '프로필 정보를 불러오는 데 실패했습니다.';
          _isLoading = false;
        });
      }
    }
  }
}
