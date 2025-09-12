import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';
import '../api/submission.dart';
import '../models/submission.dart';
import '../utils/color_schemes.dart';
import '../utils/tier_colors.dart';
import '../utils/problem_tier.dart';
import '../utils/navigation_helper.dart';
import '../utils/color_codes.dart';

class SubmissionListWidget extends HookWidget {
  final String? nickname; // 특정 유저의 제출 조회용
  const SubmissionListWidget({super.key, this.nickname});

  @override
  Widget build(BuildContext context) {
    final submissionsState = useState<List<Submission>>([]);
    final isLoadingMore = useState(false);
    final nextCursor = useState<String?>(null);
    final hasNext = useState<bool>(true);

    final initialQuery = useQuery<SubmissionPageData, Exception>(
      ['submissions', 'initial', if (nickname != null) nickname!],
        () => SubmissionApi.getSubmissions(nickname: nickname),
    );

    // 초기 데이터 동기화 및 에러 알림
    useEffect(() {
      final page = initialQuery.data;
      if (page != null) {
        submissionsState.value = page.submissions;
        nextCursor.value = page.nextCursor;
        hasNext.value = page.hasNext;
      }
      if (initialQuery.isError) {
        if (!context.mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '제출 내역을 불러오지 못했습니다: ${initialQuery.error}',
            ),
          ),
        );
      }
      return null;
    }, [initialQuery.data, initialQuery.isError]);

    Future<void> loadMore() async {
      if (isLoadingMore.value || !hasNext.value) return;
      isLoadingMore.value = true;
      try {
        final page = await SubmissionApi.getSubmissions(
          cursor: nextCursor.value,
          nickname: nickname,
        );
        submissionsState.value = [
          ...submissionsState.value,
          ...page.submissions,
        ];
        nextCursor.value = page.nextCursor;
        hasNext.value = page.hasNext;
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('더 불러오기 실패: $e')));
      } finally {
        isLoadingMore.value = false;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200) {
              loadMore();
            }
            return false;
          },
          child: initialQuery.isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              : submissionsState.value.isEmpty
                  ? ListView(
                      physics: const ClampingScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        _buildEmptyState(),
                        const SizedBox(height: 120),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      physics: const ClampingScrollPhysics(),
                      itemCount: submissionsState.value.length +
                          (hasNext.value ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index >= submissionsState.value.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final item = submissionsState.value[index];
                        return _SubmissionListItem(item: item);
                      },
                    ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.outbox_outlined,
            size: 64,
            color: AppColorSchemes.textTertiary,
          ),
          SizedBox(height: 12),
          Text(
            '아직 제출 내역이 없어요',
            style: TextStyle(
              color: AppColorSchemes.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '문제를 제출하면 이곳에서 확인할 수 있어요',
            style: TextStyle(color: AppColorSchemes.textTertiary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _SubmissionListItem extends StatelessWidget {
  final Submission item;

  const _SubmissionListItem({required this.item});

  Color _statusColor(SubmissionStatus status) {
    switch (status) {
      case SubmissionStatus.pending:
      case SubmissionStatus.processing:
        return AppColorSchemes.accentOrange;
      case SubmissionStatus.accepted:
        return AppColorSchemes.accentGreen;
      case SubmissionStatus.failed:
        return AppColorSchemes.accentRed;
    }
  }

  String _statusLabel(SubmissionStatus status) {
    switch (status) {
      case SubmissionStatus.pending:
        return '대기중';
      case SubmissionStatus.processing:
        return '처리중';
      case SubmissionStatus.accepted:
        return '승인';
      case SubmissionStatus.failed:
        return '실패';
    }
  }

  @override
  Widget build(BuildContext context) {
    final (levelLabel, levelColorInt) = item.localLevelLabelAndColor;
    final (holdLabel, holdColorInt) = item.holdColorLabelAndColor;
    final levelColor = Color(levelColorInt);
    final holdColor = Color(holdColorInt);

    return InkWell(
      onTap: () => NavigationHelper.navigateToProblemVotes(context, item.problemId),
      child: Container(
      decoration: BoxDecoration(
        color: AppColorSchemes.backgroundPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColorSchemes.borderPrimary, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 썸네일 (고정 크기)
            Container(
              width: 80,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColorSchemes.borderPrimary,
                  width: 1,
                ),
                color: AppColorSchemes.backgroundSecondary,
              ),
              clipBehavior: Clip.antiAlias,
              child: item.thumbnailUrl == null || item.thumbnailUrl!.isEmpty
                  ? const Icon(
                      Icons.video_file_outlined,
                      color: AppColorSchemes.textTertiary,
                    )
                  : Image.network(
                      item.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.video_file_outlined,
                        color: AppColorSchemes.textTertiary,
                      ),
                    ),
            ),
            const SizedBox(width: 12),

            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.gymName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColorSchemes.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // 티어 배지 (지점명 아래, 난이도/홀드색 위)
                  _ProblemTierBadge(rating: item.problemRating),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildBadge('난이도: $levelLabel', levelColor),
                      const SizedBox(width: 8),
                      _buildBadge('홀드색: $holdLabel', holdColor),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.submittedAt.toString().split('T').first,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColorSchemes.textTertiary,
                    ),
                  ),
                ],
              ),
            ),

            // 상태 칩
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _statusColor(item.status).withValues(alpha: 0.1),
                border: Border.all(
                  color: _statusColor(item.status).withValues(alpha: 0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _statusLabel(item.status),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _statusColor(item.status),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    // Extract color label from text (e.g., "난이도: 흰색" -> "흰색")
    final parts = text.split(': ');
    final colorLabel = parts.length > 1 ? parts[1] : text;
    
    final colorStyle = ColorCodes.getColorStyleInfo(colorLabel, color);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorStyle.bgColor,
        border: Border.all(color: colorStyle.borderColor, width: 1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colorStyle.textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProblemTierBadge extends StatelessWidget {
  final int rating;

  const _ProblemTierBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    final tierType = ProblemTierHelper.getType(rating);
    final display = ProblemTierHelper.getDisplayName(rating);
    final scheme = TierColors.getColorScheme(tierType);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: scheme.gradient,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            TierColors.getTierIcon(tierType),
            size: 14,
            color: AppColorSchemes.backgroundPrimary,
          ),
          const SizedBox(width: 6),
          Text(
            display,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColorSchemes.backgroundPrimary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
