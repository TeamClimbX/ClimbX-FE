import 'package:flutter/material.dart';

// 가능한 티어의 종류들
enum TierType { bronze, silver, gold, platinum, diamond, master }

// 각 티어에 해당하는 색깔들
class TierColors {
  static const Map<TierType, TierColorScheme> _tierColors = {
    TierType.bronze: TierColorScheme(
      gradientStart: Color(0xFFD2691E),
      gradientEnd: Color(0xFFCD853F),
      primary: Color(0xFFD2691E),
      light: Color(0xFFFFF8DC),
      shadow: Color(0x33D2691E),
      streakColor: Color(0xFFB8860B),
    ),
    TierType.silver: TierColorScheme(
      gradientStart: Color(0xFF708090),
      gradientEnd: Color(0xFFC0C0C0),
      primary: Color(0xFF708090),
      light: Color(0xFFF8F8FF),
      shadow: Color(0x33708090),
      streakColor: Color(0xFF708090),
    ),
    TierType.gold: TierColorScheme(
      gradientStart: Color(0xFFFFA500),
      gradientEnd: Color(0xFFFFD700),
      primary: Color(0xFFFFA500),
      light: Color(0xFFFFFAF0),
      shadow: Color(0x33FFA500),
      streakColor: Color(0xFFFF8C00),
    ),
    TierType.platinum: TierColorScheme(
      gradientStart: Color(0xFF27CCCA),
      gradientEnd: Color(0xFF6EEAC0),
      primary: Color(0xFF3ED8C9),
      light: Color(0xFFF0FDFA),
      shadow: Color(0x3340E0D0),
      streakColor: Color(0xFF2DD4CF),
    ),
    TierType.diamond: TierColorScheme(
      gradientStart: Color(0xFF1E90FF),
      gradientEnd: Color(0xFF00BFFF),
      primary: Color(0xFF00BFFF),
      light: Color(0xFFF0F8FF),
      shadow: Color(0x3300BFFF),
      streakColor: Color(0xFF1E90FF),
    ),
    TierType.master: TierColorScheme(
      gradientStart: Color(0xFF805AD5),
      gradientEnd: Color(0xFFD53F8C),
      primary: Color(0xFF805AD5),
      light: Color(0xFFFDF2F8),
      shadow: Color(0x33805AD5),
      streakColor: Color(0xFF6B46C1),
    ),
  };

  // 색상 반환해주는 메서드
  static TierColorScheme getColorScheme(TierType tier) {
    return _tierColors[tier]!;
  }

  // 티어 타입 알려주는 함수
  static TierType getTierFromString(String tierName) {
    switch (tierName.toLowerCase()) {
      case 'bronze':
      case 'bronze i':
      case 'bronze ii':
      case 'bronze iii':
        return TierType.bronze;
      case 'silver':
      case 'silver i':
      case 'silver ii':
      case 'silver iii':
        return TierType.silver;
      case 'gold':
      case 'gold i':
      case 'gold ii':
      case 'gold iii':
        return TierType.gold;
      case 'platinum':
      case 'platinum i':
      case 'platinum ii':
      case 'platinum iii':
        return TierType.platinum;
      case 'diamond':
      case 'diamond i':
      case 'diamond ii':
      case 'diamond iii':
        return TierType.diamond;
      case 'master':
        return TierType.master;
      default:
        return TierType.bronze; // 기본값
    }
  }

  // 티어의 이름
  static String getTierDisplayName(TierType tier) {
    switch (tier) {
      case TierType.bronze:
        return 'Bronze';
      case TierType.silver:
        return 'Silver';
      case TierType.gold:
        return 'Gold';
      case TierType.platinum:
        return 'Platinum';
      case TierType.diamond:
        return 'Diamond';
      case TierType.master:
        return 'Master';
    }
  }

  /// Rating 점수를 TierType으로 변환
  static TierType getTierTypeFromRating(int rating) {
    if (rating >= 2250) return TierType.master;
    if (rating >= 1800) return TierType.diamond; // Diamond I, II, III
    if (rating >= 1350) return TierType.platinum; // Platinum I, II, III
    if (rating >= 900) return TierType.gold; // Gold I, II, III
    if (rating >= 450) return TierType.silver; // Silver I, II, III
    return TierType.bronze; // Bronze I, II, III
  }

  /// Rating 점수를 상세 티어 문자열로 변환
  static String getTierStringFromRating(int rating) {
    if (rating >= 2250) return 'Master';
    if (rating >= 2100) return 'Diamond I';
    if (rating >= 1950) return 'Diamond II';
    if (rating >= 1800) return 'Diamond III';
    if (rating >= 1650) return 'Platinum I';
    if (rating >= 1500) return 'Platinum II';
    if (rating >= 1350) return 'Platinum III';
    if (rating >= 1200) return 'Gold I';
    if (rating >= 1050) return 'Gold II';
    if (rating >= 900) return 'Gold III';
    if (rating >= 750) return 'Silver I';
    if (rating >= 600) return 'Silver II';
    if (rating >= 450) return 'Silver III';
    if (rating >= 300) return 'Bronze I';
    if (rating >= 150) return 'Bronze II';
    return 'Bronze III';
  }

  // 아이콘 (추후 티어 모양으로 변환예정)
  static IconData getTierIcon(TierType tier) {
    switch (tier) {
      case TierType.bronze:
        return Icons.workspace_premium;
      case TierType.silver:
        return Icons.military_tech;
      case TierType.gold:
        return Icons.emoji_events;
      case TierType.platinum:
        return Icons.star;
      case TierType.diamond:
        return Icons.diamond;
      case TierType.master:
        return Icons.stars;
    }
  }
}

class TierColorScheme {
  final Color gradientStart;
  final Color gradientEnd;
  final Color primary;
  final Color light;
  final Color shadow;
  final Color streakColor; // 스트릭 전용 색상 추가

  const TierColorScheme({
    required this.gradientStart,
    required this.gradientEnd,
    required this.primary,
    required this.light,
    required this.shadow,
    required this.streakColor,
  });

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );
}
