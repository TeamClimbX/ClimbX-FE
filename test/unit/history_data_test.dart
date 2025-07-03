import 'package:flutter_test/flutter_test.dart';
import 'package:climbx_fe/src/models/history_data.dart';

void main() {
  group('History Data Model Tests', () {
    test('서버 응답 데이터를 올바르게 파싱한다', () {
      // 서버 응답 형태의 더미 데이터
      final jsonData = [
        {'date': '2025-01-01', 'value': 1000},
        {'date': '2025-01-02', 'value': 1050},
        {'date': '2025-01-03', 'value': 1030},
      ];
      
      final historyData = HistoryData.fromJson(jsonData);
      
      // 파싱 검증
      expect(historyData, isNotNull);
      expect(historyData.dataPoints.length, equals(3));
      expect(historyData.dataPoints.first.experience, equals(1000.0));
      expect(historyData.dataPoints.last.experience, equals(1030.0));
      expect(historyData.totalIncrease, equals(30.0)); // 1030 - 1000
    });

    test('HistoryDataPoint가 서버 응답을 올바르게 변환한다', () {
      final json = {'date': '2025-01-01', 'value': 1500};
      final dataPoint = HistoryDataPoint.fromJson(json);
      
      expect(dataPoint.date, equals(DateTime.parse('2025-01-01')));
      expect(dataPoint.experience, equals(1500.0));
    });

    test('빈 데이터 목록을 올바르게 처리한다', () {
      final historyData = HistoryData.fromJson([]);
      
      expect(historyData.dataPoints, isEmpty);
      expect(historyData.totalIncrease, equals(0.0));
      expect(historyData.averageDaily, equals(0.0));
      expect(historyData.maxDaily, equals(0.0));
    });
  });
} 