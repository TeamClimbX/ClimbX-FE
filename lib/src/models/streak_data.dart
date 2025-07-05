/// 개별 스트릭 항목 (API 응답 구조)
class StreakItem {
  final DateTime date;
  final int value;

  StreakItem({
    required this.date,
    required this.value,
  });

  /// 서버 응답에서 생성
  factory StreakItem.fromJson(Map<String, dynamic> json) {
    return StreakItem(
      date: DateTime.parse(json['date']),
      value: (json['value'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD 형태로
      'value': value,
    };
  }

  @override
  String toString() {
    return 'StreakItem(date: $date, value: $value)';
  }
}

/// 스트릭 데이터 (2차원 배열 형태로 변환)
class StreakData {
  final List<StreakItem> items;
  final List<List<int>> weeklyData; // 24주 x 7일 형태 (위젯에서 바로 사용)
  final int currentStreak;
  final int longestStreak;
  final int totalDays;

  StreakData({
    required this.items,
    required this.weeklyData,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalDays,
  });

  /// 서버 응답 데이터에서 생성 (2차원 배열 변환 포함)
  factory StreakData.fromJson(List<dynamic> jsonList) {
    final items = jsonList
        .map((json) => StreakItem.fromJson(json as Map<String, dynamic>))
        .toList();

    // 2차원 배열 변환 (24주 x 7일)
    final weeklyData = _convertToWeeklyGrid(items);

    // 통계 계산
    final stats = _calculateStats(items);

    return StreakData(
      items: items,
      weeklyData: weeklyData,
      currentStreak: stats['currentStreak'] ?? 0,
      longestStreak: stats['longestStreak'] ?? 0,
      totalDays: stats['totalDays'] ?? 0,
    );
  }

  /// 1차원 스트릭 데이터를 24주 x 7일 2차원 배열로 변환
  static List<List<int>> _convertToWeeklyGrid(List<StreakItem> items) {
    const int weeks = 24;
    const int daysPerWeek = 7;
    
    // 24주 x 7일 배열 초기화 (기본값 0)
    final grid = List.generate(
      weeks,
      (week) => List.generate(daysPerWeek, (day) => 0),
    );

    // 현재 날짜 기준으로 24주 전, 월요일부터 시작
    final now = DateTime.now();
    final currentWeekday = now.weekday; // 1 = 월요일, 7 = 일요일
    final startDate = now.subtract(Duration(days: weeks * daysPerWeek - 1 + currentWeekday - 1));

    // 각 스트릭 항목을 그리드에 매핑
    for (final item in items) {
      final daysDiff = item.date.difference(startDate).inDays;
      if (daysDiff >= 0 && daysDiff < weeks * daysPerWeek) {
        final weekIndex = daysDiff ~/ daysPerWeek;
        final dayIndex = daysDiff % daysPerWeek;
        
        if (weekIndex < weeks && dayIndex < daysPerWeek) {
          grid[weekIndex][dayIndex] = item.value;
        }
      }
    }

    return grid;
  }

  /// 스트릭 통계 계산
  static Map<String, int> _calculateStats(List<StreakItem> items) {
    if (items.isEmpty) {
      return {
        'currentStreak': 0,
        'longestStreak': 0,
        'totalDays': 0,
      };
    }

    // 날짜순 정렬
    final sortedItems = [...items]
      ..sort((a, b) => a.date.compareTo(b.date));

    // 현재 스트릭 계산
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;
    DateTime? lastDate;

    for (final item in sortedItems) {
      if (item.value > 0) {
        if (lastDate != null) {
          final daysDiff = item.date.difference(lastDate).inDays;
          if (daysDiff == 1) {
            // 연속된 날짜
            tempStreak++;
          } else {
            // 연속이 끊김
            longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;
            tempStreak = 1;
          }
        } else {
          // 첫 번째 항목
          tempStreak = 1;
        }
        lastDate = item.date;
      }
    }

    // 마지막 스트릭 체크
    longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;

    // 현재 스트릭 계산 (오늘까지 연속인지 확인)
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    
    if (lastDate != null) {
      final lastDateOnly = DateTime(lastDate.year, lastDate.month, lastDate.day);
      final daysDiff = todayDateOnly.difference(lastDateOnly).inDays;
      
      if (daysDiff <= 1) {
        // 어제 또는 오늘까지 연속
        currentStreak = tempStreak;
      } else {
        currentStreak = 0;
      }
    }

    // 총 제출일수 계산
    final totalDays = sortedItems.where((item) => item.value > 0).length;

    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalDays': totalDays,
    };
  }

  @override
  String toString() {
    return 'StreakData(items: ${items.length}, currentStreak: $currentStreak, longestStreak: $longestStreak, totalDays: $totalDays)';
  }
} 