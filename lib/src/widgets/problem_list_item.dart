import 'package:flutter/material.dart';
import '../models/problem.dart';
import '../utils/color_schemes.dart';

/// 클라이밍 문제 리스트 아이템 위젯
class ProblemListItem extends StatelessWidget {
  final Problem problem;

  const ProblemListItem({super.key, required this.problem});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColorSchemes.backgroundPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColorSchemes.lightShadow,
      ),
      child: Row(
        children: [
          // 문제 정보 (왼쪽)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 문제 ID
                Text(
                  '문제 #${problem.problemId.substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColorSchemes.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),

                // 난이도 정보
                Row(
                  children: [
                    _buildColorBadge(problem.localLevel, '난이도'),
                    const SizedBox(width: 8),
                    _buildColorBadge(problem.holdColor, '홀드'),
                  ],
                ),
                const SizedBox(height: 8),

                // 점수 정보
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 16,
                      color: AppColorSchemes.accentOrange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${problem.problemRating}점',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColorSchemes.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // 영역 정보
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: AppColorSchemes.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      problem.gymAreaName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColorSchemes.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // 문제 이미지 (오른쪽)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColorSchemes.borderPrimary,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: _buildProblemImage(),
            ),
          ),
        ],
      ),
    );
  }

  /// 색상 배지 위젯
  Widget _buildColorBadge(String color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getColorForOption(color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getColorForOption(color).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getColorForOption(color),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$label: $color',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _getColorForOption(color),
            ),
          ),
        ],
      ),
    );
  }

  /// 문제 이미지 위젯
  Widget _buildProblemImage() {
    // 기본 이미지 위젯
    final Widget defaultImage = Container(
      color: AppColorSchemes.backgroundTertiary,
      child: const Icon(
        Icons.image,
        color: AppColorSchemes.textTertiary,
        size: 24,
      ),
    );

    if (problem.problemImageCdnUrl.isEmpty) {
      return defaultImage;
    }

    // 네트워크 이미지
    return Image.network(
      problem.problemImageCdnUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => defaultImage,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: AppColorSchemes.backgroundTertiary,
          child: const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }

  /// 옵션에 따른 색상 반환
  Color _getColorForOption(String option) {
    switch (option) {
      case '빨강':
        return const Color(0xFFEF4444);
      case '파랑':
        return const Color(0xFF3B82F6);
      case '초록':
        return const Color(0xFF10B981);
      case '노랑':
        return const Color(0xFFF59E0B);
      case '보라':
        return const Color(0xFF8B5CF6);
      default:
        return AppColorSchemes.accentBlue;
    }
  }
}
