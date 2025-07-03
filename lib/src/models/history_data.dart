
// 하루 경험치 데이터 1개 -> 점 1개
class HistoryDataPoint {
  final DateTime date;
  final double experience;

  HistoryDataPoint({
    required this.date,
    required this.experience,
  });
}

// 히스토리 정보
class HistoryData {
  final List<HistoryDataPoint> dataPoints;

  // 밋밋해서 최종 증가량, 하루 평균, 하루 최대량 같은거 넣어봄 (제거 가능)
  final double totalIncrease;
  final double averageDaily;
  final double maxDaily;

  HistoryData({
    required this.dataPoints,
    required this.totalIncrease,
    required this.averageDaily,
    required this.maxDaily,
  });

  // 임시 데이터 생성 함수
  static HistoryData generateMockData() {
    final now = DateTime.now();
    
    // 역동적인 30일간의 경험치 데이터 (왔다갔다하면서 우상향)
    final dataPoints = <HistoryDataPoint>[
      HistoryDataPoint(date: now.subtract(const Duration(days: 29)), experience: 1280.0), // 시작
      HistoryDataPoint(date: now.subtract(const Duration(days: 28)), experience: 1320.0), // +40 좋은 시작
      HistoryDataPoint(date: now.subtract(const Duration(days: 27)), experience: 1285.0), // -35 실수로 감소
      HistoryDataPoint(date: now.subtract(const Duration(days: 26)), experience: 1365.0), // +80 큰 성과
      HistoryDataPoint(date: now.subtract(const Duration(days: 25)), experience: 1340.0), // -25 하락
      HistoryDataPoint(date: now.subtract(const Duration(days: 24)), experience: 1410.0), // +70 회복
      HistoryDataPoint(date: now.subtract(const Duration(days: 23)), experience: 1390.0), // -20 소폭 하락
      HistoryDataPoint(date: now.subtract(const Duration(days: 22)), experience: 1480.0), // +90 큰 점프
      HistoryDataPoint(date: now.subtract(const Duration(days: 21)), experience: 1455.0), // -25 조정
      HistoryDataPoint(date: now.subtract(const Duration(days: 20)), experience: 1520.0), // +65 상승
      HistoryDataPoint(date: now.subtract(const Duration(days: 19)), experience: 1610.0), // +90 큰 성장
      HistoryDataPoint(date: now.subtract(const Duration(days: 18)), experience: 1580.0), // -30 소폭 하락
      HistoryDataPoint(date: now.subtract(const Duration(days: 17)), experience: 1665.0), // +85 반등
      HistoryDataPoint(date: now.subtract(const Duration(days: 16)), experience: 1640.0), // -25 조정
      HistoryDataPoint(date: now.subtract(const Duration(days: 15)), experience: 1720.0), // +80 상승
      HistoryDataPoint(date: now.subtract(const Duration(days: 14)), experience: 1795.0), // +75 지속 상승
      HistoryDataPoint(date: now.subtract(const Duration(days: 13)), experience: 1765.0), // -30 하락
      HistoryDataPoint(date: now.subtract(const Duration(days: 12)), experience: 1850.0), // +85 큰 회복
      HistoryDataPoint(date: now.subtract(const Duration(days: 11)), experience: 1825.0), // -25 소폭 조정
      HistoryDataPoint(date: now.subtract(const Duration(days: 10)), experience: 1915.0), // +90 큰 성장
      HistoryDataPoint(date: now.subtract(const Duration(days: 9)), experience: 1890.0),  // -25 하락
      HistoryDataPoint(date: now.subtract(const Duration(days: 8)), experience: 1970.0),  // +80 상승
      HistoryDataPoint(date: now.subtract(const Duration(days: 7)), experience: 2055.0),  // +85 지속 상승
      HistoryDataPoint(date: now.subtract(const Duration(days: 6)), experience: 2025.0),  // -30 조정
      HistoryDataPoint(date: now.subtract(const Duration(days: 5)), experience: 2110.0),  // +85 회복
      HistoryDataPoint(date: now.subtract(const Duration(days: 4)), experience: 2180.0),  // +70 상승
      HistoryDataPoint(date: now.subtract(const Duration(days: 3)), experience: 2155.0),  // -25 소폭 하락
      HistoryDataPoint(date: now.subtract(const Duration(days: 2)), experience: 2240.0),  // +85 큰 성장
      HistoryDataPoint(date: now.subtract(const Duration(days: 1)), experience: 2320.0),  // +80 지속 상승
      HistoryDataPoint(date: now.subtract(const Duration(days: 0)), experience: 2365.0),  // +45 마무리
    ];
    
    return HistoryData(
      dataPoints: dataPoints,
      totalIncrease: 1085.0, // 2365.0 - 1280.0
      averageDaily: 36.2,    // 1085.0 / 30
      maxDaily: 90.0,        // 최대 일일 증가량
    );
  }
} 