import 'package:flutter_test/flutter_test.dart';
import 'package:climbx_fe/src/models/history_data.dart';

void main() {
  group('History Data Model Tests', () {
    test('Mock 데이터가 생성된다', () {
      final historyData = HistoryData.generateMockData();
      
      // 기본적으로 데이터가 생성되는지만 확인
      expect(historyData, isNotNull);
      expect(historyData.dataPoints, isNotEmpty);
    });
  });
} 