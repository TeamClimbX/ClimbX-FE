import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';
import '../models/history_data.dart';
import '../services/user_query_service.dart';
import '../utils/tier_colors.dart';
import 'history_period_selector.dart';
import 'history_chart.dart';
import 'history_stats_summary.dart';

enum HistoryPeriod {
  all, // 전체
  oneYear, // 1년
  sixMonths, // 6개월
  oneMonth, // 1개월
  oneWeek, // 1주
}

extension HistoryPeriodExtension on HistoryPeriod {
  String get label {
    switch (this) {
      case HistoryPeriod.all:
        return '전체';
      case HistoryPeriod.oneYear:
        return '1년';
      case HistoryPeriod.sixMonths:
        return '6개월';
      case HistoryPeriod.oneMonth:
        return '1개월';
      case HistoryPeriod.oneWeek:
        return '1주';
    }
  }

  Duration? get duration {
    switch (this) {
      case HistoryPeriod.all:
        return null;
      case HistoryPeriod.oneYear:
        return const Duration(days: 365);
      case HistoryPeriod.sixMonths:
        return const Duration(days: 180);
      case HistoryPeriod.oneMonth:
        return const Duration(days: 30);
      case HistoryPeriod.oneWeek:
        return const Duration(days: 7);
    }
  }
}

class HistoryWidget extends HookWidget {
  final String tierName;

  const HistoryWidget({
    super.key,
    required this.tierName,
  });

  @override
  Widget build(BuildContext context) {
    final selectedPeriod = useState(HistoryPeriod.oneMonth);

    // fquery로 히스토리 데이터 get
    final historyQuery = useQuery<HistoryData, Exception>(
      UserQueryKeys.userHistory(),
      UserQueryService.getUserHistory,
    );

    final TierType tierType = TierColors.getTierFromString(tierName);
    final TierColorScheme colorScheme = TierColors.getColorScheme(tierType);

    // 필터링된 데이터 계산
    HistoryData? filteredHistoryData;
    if (historyQuery.data != null) {
      final filteredPoints = _getFilteredDataPoints(historyQuery.data!, selectedPeriod.value);
      filteredHistoryData = HistoryData(
        dataPoints: filteredPoints,
        totalIncrease: filteredPoints.isNotEmpty 
            ? filteredPoints.last.experience - filteredPoints.first.experience 
            : 0.0,
        averageDaily: filteredPoints.length > 1 
            ? (filteredPoints.last.experience - filteredPoints.first.experience) / (filteredPoints.length - 1) 
            : 0.0,
        maxDaily: filteredPoints.length > 1 
            ? List.generate(
                filteredPoints.length - 1, 
                (i) => (filteredPoints[i + 1].experience - filteredPoints[i].experience).abs()
              ).reduce((a, b) => a > b ? a : b) 
            : 0.0,
      );
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          
          // 기간 선택
          HistoryPeriodSelector(
            selectedPeriod: selectedPeriod.value,
            onPeriodChanged: (period) {
              selectedPeriod.value = period;
            },
            colorScheme: colorScheme,
          ),
          
          const SizedBox(height: 8),

          // 로딩 상태
          if (historyQuery.isLoading)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(),
            )
          // 에러 상태
          else if (historyQuery.isError)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '데이터를 불러올 수 없습니다',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => historyQuery.refetch(),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            )
          // 데이터 상태
          else if (filteredHistoryData != null) ...[
            // 경험치 변화 그래프
            HistoryChart(
              historyData: filteredHistoryData,
              colorScheme: colorScheme,
            ),

            const SizedBox(height: 8),

            // 통계 요약
            HistoryStatsSummary(
              historyData: filteredHistoryData,
              colorScheme: colorScheme,
            ),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  List<HistoryDataPoint> _getFilteredDataPoints(HistoryData historyData, HistoryPeriod period) {
    final duration = period.duration;
    final now = DateTime.now();
    // 오름차순 정렬 후 필터링
    final sorted = [...historyData.dataPoints]
      ..sort((a, b) => a.date.compareTo(b.date));
    if (duration == null) return sorted;
    return sorted.where((e) => e.date.isAfter(now.subtract(duration))).toList();
  }
} 