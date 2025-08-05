import 'package:flutter/material.dart';
import '../widgets/map_body.dart';
import '../widgets/profile_body.dart';
import '../widgets/leaderboard_body.dart';
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
  
  // TODO: 디버깅용 - 나중에 제거할 것
  int _debugRating = 0;
  bool _isDebugMode = false;

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
    
    // TODO: 디버깅용 - 나중에 제거할 것
    final TierType tierType;
    final TierColorScheme colorScheme;
    if (_isDebugMode) {
      // 디버깅 모드일 때는 레이팅에 따라 티어 결정
      tierType = TierColors.getTierTypeFromRating(_debugRating);
      colorScheme = TierColors.getColorScheme(tierType);
    } else {
      // 일반 모드일 때는 기존 로직 사용
      tierType = TierColors.getTierFromString(userTier);
      colorScheme = TierColors.getColorScheme(tierType);
    }

    // 원본 코드 (나중에 복원할 것)
    // final TierType tierType = TierColors.getTierFromString(userTier);
    // final TierColorScheme colorScheme = TierColors.getColorScheme(tierType);

    return TierProvider(
      colorScheme: colorScheme,
      child: Scaffold(
        backgroundColor: AppColorSchemes.backgroundSecondary,

        // TODO: 디버깅용 - 나중에 제거할 것
        appBar: CustomAppBar(
          onDebugRatingChange: _handleDebugRatingChange,
        ),
        // 원본 코드 (나중에 복원할 것)
        // appBar: const CustomAppBar(),

        
      // Body - Indexed Stack으로 화면 전환
      body: IndexedStack(
        index: _currentTab.index,
        children: [
          // 0: 프로필
          const ProfileBody(),
          // 1: 리더보드
          const LeaderboardBody(),
          // 2: 검색
          _buildComingSoon('검색', Icons.search),
          // 3: 지도
          const MapBody(),
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

  // TODO: 디버깅용 - 나중에 제거할 것
  void _handleDebugRatingChange() {
    setState(() {
      if (!_isDebugMode) {
        _isDebugMode = true;
        _debugRating = 900; // Gold III로 시작
      } else {
        // 다음 레이팅으로 순환 (정확한 티어 구간)
        if (_debugRating >= 2250) {
          _debugRating = 0; // Bronze III로 돌아가기
        } else if (_debugRating >= 1800) {
          _debugRating = 2250; // Master
        } else if (_debugRating >= 1350) {
          _debugRating = 1800; // Diamond III
        } else if (_debugRating >= 900) {
          _debugRating = 1350; // Platinum III
        } else if (_debugRating >= 450) {
          _debugRating = 900; // Gold III
        } else if (_debugRating >= 0) {
          _debugRating = 450; // Silver III
        }
      }
    });
    
    developer.log('디버깅 레이팅 변경: $_debugRating', name: 'MainPage');
  }

  // 출시 예정 페이지 (임시페이지임 삭제 예정)
  Widget _buildComingSoon(
    String title,
    IconData icon,
  ) {
    final screenSize = MediaQuery.of(context).size;

    return Center(
      child: Container(
        width: screenSize.width * 0.85,
        height: screenSize.height * 0.4,
        decoration: BoxDecoration(
          color: AppColorSchemes.backgroundPrimary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColorSchemes.lightShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(screenSize.width * 0.05),
              decoration: BoxDecoration(
                gradient: AppColorSchemes.defaultGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: AppColorSchemes.backgroundPrimary,
                size: screenSize.width * 0.08,
              ),
            ),
            SizedBox(height: screenSize.height * 0.02),
            Text(
              title,
              style: TextStyle(
                fontSize: screenSize.width * 0.05,
                fontWeight: FontWeight.w700,
                color: AppColorSchemes.textPrimary,
              ),
            ),
            SizedBox(height: screenSize.height * 0.01),
            Text(
              '곧 출시 예정입니다',
              style: TextStyle(
                fontSize: screenSize.width * 0.035,
                color: AppColorSchemes.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
