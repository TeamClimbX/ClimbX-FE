import 'package:flutter/material.dart';
import '../models/history_data.dart';
import '../services/user_service.dart';
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

class HistoryWidget extends StatefulWidget {
  final String tierName;

  const HistoryWidget({
    super.key,
    required this.tierName,
  });

  @override
  State<HistoryWidget> createState() => _HistoryWidgetState();
}

class _HistoryWidgetState extends State<HistoryWidget> {
  HistoryPeriod selectedPeriod = HistoryPeriod.oneMonth;
  HistoryData? historyData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  /// 히스토리 데이터 로드
  Future<void> _loadHistoryData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await UserService.getCurrentUserHistory(
          criteria: 'RATING');

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          historyData = response.data!;
          isLoading = false;
        });
      } else {
        setState(() {
          error = response.error ?? '데이터를 불러올 수 없습니다';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = '네트워크 오류가 발생했습니다';
        isLoading = false;
      });
    }
  }

  List<HistoryDataPoint> getFilteredDataPoints() {
    if (historyData == null) return [];
    final duration = selectedPeriod.duration;
    final now = DateTime.now();
    // 오름차순 정렬 후 필터링
    final sorted = [...historyData!.dataPoints]
      ..sort((a, b) => a.date.compareTo(b.date));
    if (duration == null) return sorted;
    return sorted.where((e) => e.date.isAfter(now.subtract(duration))).toList();
  }

  @override
  Widget build(BuildContext context) {
    final TierType tierType = TierColors.getTierFromString(widget.tierName);
    final TierColorScheme colorScheme = TierColors.getColorScheme(tierType);

    final filteredPoints = getFilteredDataPoints();
    final filteredHistoryData = HistoryData(
      dataPoints: filteredPoints,
      totalIncrease: filteredPoints.isNotEmpty ? filteredPoints.last
          .experience - filteredPoints.first.experience : 0.0,
      averageDaily: filteredPoints.length > 1 ? (filteredPoints.last
          .experience - filteredPoints.first.experience) /
          (filteredPoints.length - 1) : 0.0,
      maxDaily: filteredPoints.length > 1 ? List.generate(
          filteredPoints.length - 1, (i) =>
          (filteredPoints[i + 1].experience - filteredPoints[i].experience)
              .abs()).reduce((a, b) => a > b ? a : b) : 0.0,
    );

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),

          // 기간 선택
          HistoryPeriodSelector(
            selectedPeriod: selectedPeriod,
            onPeriodChanged: (period) {
              setState(() {
                selectedPeriod = period;
              });
            },
            colorScheme: colorScheme,
          ),

          const SizedBox(height: 8),

          // 로딩, 에러, 데이터 상태 처리
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(),
            )
          else
            if (error != null)
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
                      error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadHistoryData,
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              )
            else
              if (historyData != null) ...[
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
} 