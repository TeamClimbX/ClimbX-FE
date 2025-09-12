import 'package:flutter/material.dart';
import '../api/leaderboard.dart';
import '../models/leaderboard_item.dart';
import '../utils/color_schemes.dart';
import '../utils/navigation_helper.dart';
import '../utils/leaderboard_type.dart';
import '../utils/tier_colors.dart';

/// 리더보드 메인 위젯
class LeaderboardBody extends StatefulWidget {
  const LeaderboardBody({super.key});

  @override
  State<LeaderboardBody> createState() => _LeaderboardBodyState();
}

class _LeaderboardBodyState extends State<LeaderboardBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LeaderboardType _selectedType = LeaderboardType.rating;

  // 무한스크롤 상태 관리
  static const int _pageSize = 50;
  static const double _scrollThreshold = 200.0; // 바닥 근처에서 다음 페이지 로드
  final Map<LeaderboardType, List<LeaderboardItem>> _itemsByType = {};
  final Map<LeaderboardType, int> _pageByType = {};
  final Map<LeaderboardType, bool> _isLoadingByType = {};
  final Map<LeaderboardType, bool> _hasMoreByType = {};
  final Map<LeaderboardType, String?> _errorByType = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: LeaderboardType.values.length,
      vsync: this,
    );
    
    // 탭 변경 리스너 추가
    _tabController.addListener(_onTabChanged);
    
    // 초기 데이터 로드
    _loadInitial(_selectedType);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 초기 페이지 로드
  Future<void> _loadInitial(LeaderboardType type) async {
    _errorByType[type] = null;
    _pageByType[type] = 0;
    _hasMoreByType[type] = true;
    _isLoadingByType[type] = true;
    setState(() {});
    try {
      final result = await LeaderboardApi.getRanking(
        type: type,
        page: 0,
        size: _pageSize,
      );
      _itemsByType[type] = result;
      _hasMoreByType[type] = result.length >= _pageSize;
    } catch (e) {
      _errorByType[type] = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        _isLoadingByType[type] = false;
        setState(() {});
      }
    }
  }

  /// 다음 페이지 로드
  Future<void> _loadMore(LeaderboardType type) async {
    if (_isLoadingByType[type] == true) return;
    if (_hasMoreByType[type] == false) return;
    _isLoadingByType[type] = true;
    setState(() {});
    try {
      final nextPage = (_pageByType[type] ?? 0) + 1;
      final result = await LeaderboardApi.getRanking(
        type: type,
        page: nextPage,
        size: _pageSize,
      );
      final current = _itemsByType[type] ?? <LeaderboardItem>[];
      _itemsByType[type] = [...current, ...result];
      _pageByType[type] = nextPage;
      _hasMoreByType[type] = result.length >= _pageSize;
    } catch (e) {
      _errorByType[type] = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        _isLoadingByType[type] = false;
        setState(() {});
      }
    }
  }

  /// 탭 변경 처리
  void _onTabChanged() {
    // 실제 인덱스 변화만 감지하여 처리
    final newType = LeaderboardType.values[_tabController.index];
    if (_selectedType != newType) {
      _selectedType = newType;
      if ((_itemsByType[_selectedType] ?? const <LeaderboardItem>[]).isEmpty &&
          _isLoadingByType[_selectedType] != true) {
        _loadInitial(_selectedType);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 상단 탭바
        Container(
          margin: const EdgeInsets.all(16),
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
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColorSchemes.backgroundPrimary,
            unselectedLabelColor: AppColorSchemes.textSecondary,
            indicator: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColorSchemes.textSecondary,
                  AppColorSchemes.textSpecial,
                ],
              ),
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
            tabs: LeaderboardType.values
                .map((type) => _buildTab(type.label))
                .toList(),
          ),
        ),

        // 슬라이드 가능한 리더보드 페이지들
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: LeaderboardType.values.map((type) {
              return _buildLeaderboardPage(type);
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// 각 탭별 리더보드 페이지 빌드
  Widget _buildLeaderboardPage(LeaderboardType type) {
    final isLoading = _isLoadingByType[type] == true && (_itemsByType[type]?.isEmpty ?? true);
    final items = _itemsByType[type] ?? const <LeaderboardItem>[];
    final error = _errorByType[type];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Builder(
        builder: (context) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColorSchemes.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColorSchemes.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadInitial(type),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }
          if (items.isEmpty) {
            return const Center(
              child: Text(
                '리더보드 데이터가 없습니다',
                style: TextStyle(
                  color: AppColorSchemes.textSecondary,
                  fontSize: 14,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _loadInitial(type);
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification ||
                    notification is UserScrollNotification) {
                  final metrics = notification.metrics;
                  if (metrics.pixels + _scrollThreshold >= metrics.maxScrollExtent) {
                    _loadMore(type);
                  }
                }
                return false;
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: items.length + ((_hasMoreByType[type] == true) ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= items.length) {
                    // 로딩 인디케이터 셀
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return _buildLeaderboardItem(items[index]);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTab(String text) {
    return Container(
      height: 32,
      alignment: Alignment.center,
      child: Transform.translate(
        offset: const Offset(0, 2),
        child: Text(text, style: const TextStyle(height: 1.0)),
      ),
    );
  }

  Widget _buildLeaderboardItem(LeaderboardItem user) {
    final TierType tierType = TierColors.getTierFromString(user.tier);
    final TierColorScheme tierColorScheme = TierColors.getColorScheme(tierType);

    return InkWell(
      onTap: () {
        NavigationHelper.navigateToPublicProfileSmart(
          context,
          targetNickname: user.nickname,
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          // 등수
          Text(
            '${user.ranking}',
            style: const TextStyle(
              color: AppColorSchemes.textSpecial,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),

          const SizedBox(width: 32),

          // 프로필 사진
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: tierColorScheme.primary, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22.5),
              child: _buildProfileImage(user.profileImageCdnUrl),
            ),
          ),

          const SizedBox(width: 12),

          // 닉네임과 티어
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nickname,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColorSchemes.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    gradient: tierColorScheme.gradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user.tier,
                    style: const TextStyle(
                      color: AppColorSchemes.backgroundPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 값 (티어 그라디언트 적용)
          ShaderMask(
            shaderCallback: (bounds) => tierColorScheme.gradient.createShader(
              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
            ),
            child: Text(
              user.value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.white, // ShaderMask를 위해 흰색으로 설정
              ),
            ),
          ),

          const SizedBox(width: 4),
        ],
      ),
    ),
    );
  }

  /// 프로필 이미지 빌드 (네트워크 이미지 또는 기본 아바타)
  Widget _buildProfileImage(String? profileImageCdnUrl) {
    // 기본 아바타 위젯 
    final Widget defaultAvatar = Container(
      color: AppColorSchemes.backgroundTertiary,
      child: const Icon(
        Icons.person,
        color: AppColorSchemes.textTertiary,
        size: 20,
      ),
    );

    if (profileImageCdnUrl == null || profileImageCdnUrl.isEmpty) {
      return defaultAvatar;
    }

    // 절대 URL만 허용. 아니면 기본 아바타 사용
    if (!profileImageCdnUrl.startsWith('http://') &&
        !profileImageCdnUrl.startsWith('https://')) {
      return defaultAvatar;
    }
    return Image.network(
      profileImageCdnUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => defaultAvatar,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: AppColorSchemes.backgroundTertiary,
          child: const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          ),
        );
      },
    );
  }
}
