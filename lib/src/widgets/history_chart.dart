import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/history_data.dart';
import '../utils/tier_colors.dart';

class HistoryChart extends StatelessWidget {
  final HistoryData historyData;
  final TierColorScheme colorScheme;

  const HistoryChart({
    super.key,
    required this.historyData,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '경험치 변화',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 400,
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(
                      color: Color(0xFFF1F5F9),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 7,
                      getTitlesWidget: _getBottomTitles,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: 400,
                      getTitlesWidget: _getLeftTitles,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (historyData.dataPoints.length - 1).toDouble(),
                minY: _getMinY(),
                maxY: _getMaxY(),
                lineBarsData: [
                  LineChartBarData(
                    spots: _getSpots(),
                    isCurved: true,
                    gradient: colorScheme.gradient,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => const Color(0xFF1E293B),
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final dataPoint =
                            historyData.dataPoints[barSpot.x.toInt()];
                        return LineTooltipItem(
                          '${dataPoint.date.month}/${dataPoint.date.day}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(
                              text: '${dataPoint.experience.toInt()} EXP',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 점 데이터 가져오기
  List<FlSpot> _getSpots() {
    return historyData.dataPoints.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.experience);
    }).toList();
  }

  double _getMinY() {
    final minExp = historyData.dataPoints
        .map((e) => e.experience)
        .reduce((a, b) => a < b ? a : b);
    return (minExp - 50).floorToDouble();
  }

  double _getMaxY() {
    final maxExp = historyData.dataPoints
        .map((e) => e.experience)
        .reduce((a, b) => a > b ? a : b);
    return (maxExp + 50).ceilToDouble();
  }

  // 하단 타이틀 가져오기
  Widget _getBottomTitles(double value, TitleMeta meta) {
    final index = value.toInt();

    // 범위 체크
    if (index >= historyData.dataPoints.length) return Container();

    // 마지막 인덱스 체크 (글자 겹침 방지)
    if (index == historyData.dataPoints.length - 1) return Container();

    final dataPoint = historyData.dataPoints[index];
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        '${dataPoint.date.month}/${dataPoint.date.day}',
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _getLeftTitles(double value, TitleMeta meta) {
    final minY = _getMinY();
    final maxY = _getMaxY();

    // 최상단과 최하단 값은 겹칠 수 있으므로 숨김
    if (value >= maxY || value <= minY) {
      return Container();
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        '${value.toInt()}',
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
