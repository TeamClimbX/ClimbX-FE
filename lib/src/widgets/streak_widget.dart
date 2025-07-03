import 'package:flutter/material.dart';
import '../utils/tier_colors.dart';
import '../models/user_profile.dart';

class StreakWidget extends StatelessWidget {
  final String tierName;
  final UserProfile? userProfile;

  const StreakWidget({
    super.key,
    this.tierName = 'Diamond I',
    this.userProfile,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final TierType currentTier = TierColors.getTierFromString(tierName);
    final TierColorScheme colorScheme = TierColors.getColorScheme(currentTier);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: screenWidth - 32, // 좌우 여백 고려
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 20,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 2),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: colorScheme.gradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'SUBMISSION STREAK',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFFFFFFFF),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            SizedBox(height: screenWidth * 0.05),

            // 최대 출석 정보
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                    children: [
                      const TextSpan(text: '최대 '),
                      TextSpan(
                        text: userProfile != null
                            ? '${userProfile!.longestStreak}'
                            : '0',
                        style: TextStyle(color: colorScheme.primary),
                      ),
                      const TextSpan(text: '주 출석'),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: screenWidth * 0.04),

            // 깃허브 잔디 스타일 그리드
            _buildStreakGrid(colorScheme),

            SizedBox(height: screenWidth * 0.04),

            // 통계 정보
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '스트릭 통계',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          '현재 스트릭',
                          userProfile != null
                              ? '${userProfile!.currentStreak}일'
                              : '0일',
                          colorScheme,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          '최장 스트릭',
                          userProfile != null
                              ? '${userProfile!.longestStreak}일'
                              : '0일',
                          colorScheme,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem('이번 주', '4/7일', colorScheme),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          '총 제출일',
                          userProfile != null
                              ? '${userProfile!.solvedProblemsCount}일'
                              : '0일',
                          colorScheme,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakGrid(TierColorScheme colorScheme) {
    // 24주간의 데이터를 표시 (나중에는 실제 데이터 값으로 변경)
    const int weeks = 24;
    const int daysPerWeek = 7;

    // 임시 데이터 - 실제로는 API에서 받아올 것
    final List<List<int>> streakData = _generateMockStreakData(weeks);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 그리드
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 요일 라벨 (세로, 고정)
            Column(
              children: ['월', '화', '수', '목', '금', '토', '일']
                  .map(
                    (day) => Container(
                      height: 14,
                      width: 20,
                      margin: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(width: 8),

            // 실제 그리드 (가로 스크롤)
            // 현재 스트릭 데이터가 2차원 데이터
            // streakData[weekIndex][dayIndex]로 있는데
            // 백에서 전처리하거나 프론트에서 바꿔야함
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  children: List.generate(
                    daysPerWeek,
                    (dayIndex) => Row(
                      children: List.generate(
                        weeks,
                        (weekIndex) => Container(
                          width: 14,
                          height: 14,
                          margin: const EdgeInsets.only(right: 2, bottom: 2),
                          decoration: BoxDecoration(
                            color: _getStreakColor(
                              streakData[weekIndex][dayIndex],
                              colorScheme,
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 적고 많음 지표 보여줌
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              '적음',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            ...List.generate(
              5,
              (index) => Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  color: _getStreakColor(index, colorScheme),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '많음',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    TierColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        _buildValueWithColoredNumbers(value, colorScheme),
      ],
    );
  }

  Widget _buildValueWithColoredNumbers(
    String value,
    TierColorScheme colorScheme,
  ) {
    // "일"만 검은색으로, 나머지는 티어 색상으로 표시
    if (value.endsWith('일')) {
      final numberPart = value.substring(0, value.length - 1);
      return RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: numberPart,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
            const TextSpan(
              text: '일',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      );
    }

    // "일"로 끝나지 않는 경우 전체를 티어 색상으로
    return Text(
      value,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: colorScheme.primary,
      ),
    );
  }

  // 임시 데이터 생성 (나중에 안쓸 예정)
  List<List<int>> _generateMockStreakData(int weeks) {
    return List.generate(
      weeks,
      (weekIndex) => List.generate(7, (dayIndex) {
        // 랜덤하게 0-4 사이의 값 생성
        final random = (weekIndex * 7 + dayIndex) % 17;
        if (random < 5) return 0;
        if (random < 10) return 1;
        if (random < 14) return 2;
        if (random < 16) return 3;
        return 4;
      }),
    );
  }

  // 현재는 0 1 2 3 으로 구분 이후에는 최댓값 기준으로 수정 예정
  Color _getStreakColor(int submissions, TierColorScheme colorScheme) {
    if (submissions == 0) return const Color(0xFFF1F5F9); // 더 연한 회색 (제출 안함)
    if (submissions == 1) return colorScheme.streakColor.withValues(alpha: 0.3);
    if (submissions == 2) return colorScheme.streakColor.withValues(alpha: 0.5);
    if (submissions == 3) return colorScheme.streakColor.withValues(alpha: 0.7);
    return colorScheme.streakColor; // 스트릭 전용 색상 사용
  }
}
