import 'api_client.dart';

/// 사용자 프로필 정보를 담는 모델
class UserProfile {
  final String nickname;
  final String statusMessage;
  final String? profileImageUrl;
  final int ranking;
  final int rating;
  final Map<String, int> categoryRatings;
  final int currentStreak;
  final int longestStreak;
  final int solvedProblemsCount;
  final int rivalCount;

  UserProfile({
    required this.nickname,
    required this.statusMessage,
    this.profileImageUrl,
    required this.ranking,
    required this.rating,
    required this.categoryRatings,
    required this.currentStreak,
    required this.longestStreak,
    required this.solvedProblemsCount,
    required this.rivalCount,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      nickname: json['nickname'] ?? '',
      statusMessage: json['statusMessage'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      ranking: json['ranking'] ?? 0,
      rating: json['rating'] ?? 0,
      categoryRatings: Map<String, int>.from(json['categoryRatings'] ?? {}),
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      solvedProblemsCount: json['solvedProblemsCount'] ?? 0,
      rivalCount: json['rivalCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nickname': nickname,
      'statusMessage': statusMessage,
      'profileImageUrl': profileImageUrl,
      'ranking': ranking,
      'rating': rating,
      'categoryRatings': categoryRatings,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'solvedProblemsCount': solvedProblemsCount,
      'rivalCount': rivalCount,
    };
  }

  @override
  String toString() {
    return 'UserProfile(nickname: $nickname, ranking: $ranking, rating: $rating, streak: $currentStreak)';
  }
}

/// 사용자 관련 API 서비스
class UserService {
  static final _apiClient = ApiClient.instance;

  /// 현재 사용자 프로필 조회 (기존 alice 엔드포인트)
  static Future<ApiResponse<UserProfile>> getCurrentUserProfile() async {
    return await _apiClient.get<UserProfile>(
      '/api/users/alice',
      needsAuth: false, // 기존 인터페이스 유지
      fromJson: UserProfile.fromJson,
    );
  }

  /// 특정 사용자 프로필 조회 (확장 가능)
  static Future<ApiResponse<UserProfile>> getUserProfile(String username) async {
    return await _apiClient.get<UserProfile>(
      '/api/users/$username',
      needsAuth: false,
      fromJson: UserProfile.fromJson,
    );
  }
}
