import 'package:flutter/material.dart';
import '../models/problem.dart';
import '../utils/color_schemes.dart';
import '../screens/problem_detail_page.dart';

/// 클라이밍 문제 그리드 아이템 위젯
class ProblemGridItem extends StatelessWidget {
  final Problem problem;
  final int? gymId; // 클라이밍장 ID 추가

  const ProblemGridItem({
    super.key, 
    required this.problem,
    this.gymId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 문제 상세 페이지로 이동
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProblemDetailPage(
              problem: problem,
              gymId: gymId,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColorSchemes.backgroundPrimary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColorSchemes.lightShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 문제 이미지 (상단)
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  border: Border.all(
                    color: AppColorSchemes.borderPrimary,
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                  child: _buildProblemImage(),
                ),
              ),
            ),

            // 문제 정보 (하단)
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 난이도 정보
                    Row(
                      children: [
                        _buildColorBadge(problem.localLevel, '난이도'),
                        const SizedBox(width: 6),
                        _buildColorBadge(problem.holdColor, '홀드'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 색상 배지 위젯
  Widget _buildColorBadge(String color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), // 패딩 축소
      decoration: BoxDecoration(
        color: _getColorForOption(color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8), // 둥근 모서리 축소
        border: Border.all(
          color: _getColorForOption(color).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: _getColorForOption(color),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '$label: $color',
            style: TextStyle(
              fontSize: 9,
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
        size: 32,
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
              width: 20,
              height: 20,
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
