import 'package:flutter/material.dart';
import '../utils/tier_colors.dart';
import '../services/user_service.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfile? userProfile;
  final String tierName;

  const ProfileHeader({
    super.key,
    this.userProfile,
    this.tierName = 'Bronze 3',
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final TierType currentTier = TierColors.getTierFromString(tierName);
    final TierColorScheme colorScheme = TierColors.getColorScheme(currentTier);

    return Container(
      width: double.infinity,
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
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 프로필 섹션
            Row(
              children: [
                // 프로필 이미지
                Container(
                  width: screenWidth * 0.18,
                  height: screenWidth * 0.18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: colorScheme.gradient,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: CircleAvatar(
                      radius: screenWidth * 0.09 - 3,
                      backgroundImage: const AssetImage(
                        'assets/images/avatar.png',
                      ),
                    ),
                  ),
                ),

                // 프로필 사진이랑 이름 소개글 사이의 패딩
                SizedBox(width: screenWidth * 0.04),

                // 프로필 이름과 설명
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userProfile!.nickname,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        userProfile!.statusMessage,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // 설정 버튼
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                ),
              ],
            ),

            // 상단 프로필이랑 티어 카드 사이의 패딩
            SizedBox(height: screenWidth * 0.06),

            // 티어 정보 카드
            Container(
              // 컨테이너 속성
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: colorScheme.gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),

              // 내부에 들어가는 요소들
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // 1. 왼쪽 위의 USER RATING
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x33FFFFFF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'USER RATING',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFFFFFFFF),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      // 좌우에 위치하도록 사이에 Spacer
                      const Spacer(),

                      // 2. 오른쪽에 ~까지 ~점
                      const Text(
                        'Master까지 86점',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFFFFFFF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tierName,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFFFFF),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userProfile != null ? '${userProfile!.rating}' : '---',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFFFFFF),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 진행바
                  SizedBox(
                    height: 6,
                    child: Stack(
                      children: [
                        // 뒤의 배경 진행바
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        // 진행도 (현재 티어 색상)
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.14, // 0.14 = 14% 진행
                          child: Container(
                            height: 6, // 높이도 명시적으로 지정
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: screenWidth * 0.04),

            // 지역 정보
            const Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF94A3B8),
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  '서울 은평구',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            SizedBox(height: screenWidth * 0.04),

            // 통계 정보
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '1520',
                    '문제 해결',
                    Icons.check_circle_outline,
                    colorScheme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '274',
                    '문제 기여',
                    Icons.add_circle_outline,
                    colorScheme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '331',
                    '명의 라이벌',
                    Icons.people_outline,
                    colorScheme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 스탯 카드 만드는 위젯
  Widget _buildStatCard(
    String number,
    String label,
    IconData icon,
    TierColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 18),
          const SizedBox(height: 4),
          Text(
            number,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
