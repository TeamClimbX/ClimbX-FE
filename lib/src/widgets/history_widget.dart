import 'package:flutter/material.dart';
import '../models/history_data.dart';
import '../utils/tier_colors.dart';
import 'history_period_selector.dart';
import 'history_chart.dart';
import 'history_stats_summary.dart';

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
  String selectedPeriod = '1개월';
  late HistoryData historyData;

  @override
  void initState() {
    super.initState();
    // 임시 데이터 로드
    historyData = HistoryData.generateMockData();
  }

  @override
  Widget build(BuildContext context) {
    final TierType tierType = TierColors.getTierFromString(widget.tierName);
    final TierColorScheme colorScheme = TierColors.getColorScheme(tierType);

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
              // TODO: 실제 데이터 연동 시 여기서 데이터 재로드
            },
            colorScheme: colorScheme,
          ),
          
          const SizedBox(height: 8),
          
          // 경험치 변화 그래프
          HistoryChart(
            historyData: historyData,
            colorScheme: colorScheme,
          ),
          
          const SizedBox(height: 8),
          
          // 통계 요약
          HistoryStatsSummary(
            historyData: historyData,
            colorScheme: colorScheme,
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
} 