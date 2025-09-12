import 'package:flutter/material.dart';
import '../models/problem.dart';
import '../utils/color_schemes.dart';
import '../screens/problem_detail_page.dart';
import '../utils/color_codes.dart';

/// 클라이밍 문제 그리드 아이템 위젯
class ProblemGridItem extends StatelessWidget {
  final Problem problem;
  final int? gymId; // 클라이밍장 ID 추가
  final VoidCallback? onTapOverride;

  const ProblemGridItem({
    super.key, 
    required this.problem,
    this.gymId,
    this.onTapOverride,
  });

  @override
  Widget build(BuildContext context) {
    // MediaQuery 기반 반응형 크기 계산
    final screenWidth = MediaQuery.of(context).size.width;
    final estimatedItemWidth = screenWidth / 2.3;
    final infoAreaHeight = estimatedItemWidth * 0.25;
    
    // 비율 기반 크기 계산
    final fontSize = (infoAreaHeight * 0.22).clamp(8.0, 12.0);
    final iconSize = fontSize * 0.8;
    final containerPadding = screenWidth * 0.02;           // 컨테이너 전체 패딩
    final badgeHorizontalPadding = screenWidth * 0.012;     // 배지 좌우 패딩
    final badgeVerticalPadding = screenWidth * 0.008;       // 배지 상하 패딩
    final badgeSpacing = screenWidth * 0.02;
    final iconTextSpacing = screenWidth * 0.008;
    final maxBadgeWidth = (estimatedItemWidth - containerPadding * 2 - badgeSpacing) / 2;
    
    return GestureDetector(
      onTap: () {
        if (onTapOverride != null) {
          onTapOverride!();
          return;
        }
        // 문제 상세 페이지로 이동
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProblemDetailPage(
              problem: problem,
              gymId: gymId ?? problem.gymId,
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

            // 문제 정보
            Expanded(
              flex: 1,
              child: Container(
                padding: EdgeInsets.all(containerPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 난이도 정보
                    Row(
                      children: [
                        Flexible(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxBadgeWidth),
                            child: _buildColorBadge(
                              problem.localLevel, 
                              '난이도',
                              fontSize: fontSize,
                              iconSize: iconSize,
                              horizontalPadding: badgeHorizontalPadding,
                              verticalPadding: badgeVerticalPadding,
                              iconTextSpacing: iconTextSpacing,
                            ),
                          ),
                        ),
                        SizedBox(width: badgeSpacing),
                        Flexible(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxBadgeWidth),
                            child: _buildColorBadge(
                              problem.holdColor, 
                              '홀드',
                              fontSize: fontSize,
                              iconSize: iconSize,
                              horizontalPadding: badgeHorizontalPadding,
                              verticalPadding: badgeVerticalPadding,
                              iconTextSpacing: iconTextSpacing,
                            ),
                          ),
                        ),
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
  Widget _buildColorBadge(
    String raw, 
    String label, {
    required double fontSize,
    required double iconSize,
    required double horizontalPadding,
    required double verticalPadding,
    required double iconTextSpacing,
  }) {
    final colorStyle = ColorCodes.getColorStyleInfo(raw, AppColorSchemes.accentBlue);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding, 
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: colorStyle.bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: colorStyle.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: colorStyle.displayColor,
              shape: BoxShape.circle,
              border: colorStyle.needsBorder 
                  ? Border.all(color: AppColorSchemes.whiteSelectionBorder, width: 1)
                  : null,
            ),
          ),
          SizedBox(width: iconTextSpacing),
          Flexible(
            child: Text(
              '$label: ${colorStyle.displayLabel}',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: colorStyle.textColor,
              ),
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
}
