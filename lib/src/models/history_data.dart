
// 하루 경험치 데이터 1개 -> 점 1개
class HistoryDataPoint {
  final DateTime date;
  final double experience;

  HistoryDataPoint({
    required this.date,
    required this.experience,
  });

  /// 서버 응답에서 생성 (날짜 문자열 -> DateTime 변환, value -> experience)
  factory HistoryDataPoint.fromJson(Map<String, dynamic> json) {
    return HistoryDataPoint(
      date: DateTime.parse(json['date']),
      experience: (json['value'] ?? 0).toDouble(), // 서버의 'value' -> 'experience'
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD 형태로
      'value': experience, // experience -> 'value'로 변환
    };
  }
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

  /// 서버 응답 데이터에서 생성 (통계는 자동 계산)
  factory HistoryData.fromJson(List<dynamic> jsonList) {
    final dataPoints = jsonList
        .map((json) => HistoryDataPoint.fromJson(json as Map<String, dynamic>))
        .toList();

    // 통계 자동 계산
    if (dataPoints.isEmpty) {
      return HistoryData(
        dataPoints: dataPoints,
        totalIncrease: 0.0,
        averageDaily: 0.0,
        maxDaily: 0.0,
      );
    }

    final firstValue = dataPoints.first.experience;
    final lastValue = dataPoints.last.experience;
    final totalIncrease = lastValue - firstValue;

    double maxDaily = 0.0;
    for (int i = 1; i < dataPoints.length; i++) {
      final dailyChange = (dataPoints[i].experience - dataPoints[i - 1].experience).abs();
      if (dailyChange > maxDaily) {
        maxDaily = dailyChange;
      }
    }

    final averageDaily = dataPoints.length > 1 
        ? totalIncrease / (dataPoints.length - 1)
        : 0.0;

    return HistoryData(
      dataPoints: dataPoints,
      totalIncrease: totalIncrease,
      averageDaily: averageDaily,
      maxDaily: maxDaily,
    );
  }

} 