import 'dart:developer' as developer;
import 'util/core/api_client.dart';
import '../models/user_profile.dart';
import '../models/history_data.dart';
import '../models/streak_data.dart';

/// 사용자 관련 API 호출 함수들
class UserApi {
  static final _apiClient = ApiClient.instance;

  /// 현재 사용자 프로필 조회 (기존 alice 엔드포인트)
  static Future<UserProfile> getCurrentUserProfile() async {
    try {
      return await _apiClient.get<UserProfile>(
        '/api/users/alice',
        fromJson: (data) => UserProfile.fromJson(data as Map<String, dynamic>),
        logContext: 'UserApi',
      );
    } catch (e) {
      throw Exception('프로필 정보를 불러올 수 없습니다: $e');
    }
  }

  /// 편의 메서드: getUserProfile() -> getCurrentUserProfile() 호출
  static Future<UserProfile> getUserProfile() async {
    return await getCurrentUserProfile();
  }

  /// 특정 사용자 프로필 조회 (확장 가능)
  static Future<UserProfile> getUserProfileByUsername(String username) async {
    try {
      return await _apiClient.get<UserProfile>(
        '/api/users/$username',
        fromJson: (data) => UserProfile.fromJson(data as Map<String, dynamic>),
        logContext: 'UserApi',
      );
    } catch (e) {
      throw Exception('프로필 정보를 불러올 수 없습니다: $e');
    }
  }

  /// 사용자 히스토리 조회 (queryParameters 방식 사용)
  static Future<HistoryData> getUserHistory({
    String username = 'alice',
    String? from,
    String? to,
    String criteria = 'RATING',
  }) async {
    try {
      // 쿼리 파라미터 구성
      final queryParams = <String, String>{'criteria': criteria};
      if (from != null) queryParams['from'] = from;
      if (to != null) queryParams['to'] = to;

      final data = await _apiClient.get<dynamic>(
        '/api/users/$username/history',
        queryParameters: queryParams,
        logContext: 'UserApi',
      );

      // HistoryData는 List<dynamic>을 기대하므로 타입 체크
      if (data is List) {
        return HistoryData.fromJson(data);
      } else {
        developer.log('HistoryData: List가 아닌 데이터, 빈 리스트 사용', name: 'UserApi');
        return HistoryData.fromJson([]);
      }
    } catch (e) {
      throw Exception('히스토리 데이터를 불러올 수 없습니다: $e');
    }
  }

  /// 현재 사용자 히스토리 조회 (간편 메서드)
  static Future<HistoryData> getCurrentUserHistory({
    String? from,
    String? to,
    String criteria = 'RATING',
  }) async {
    return await getUserHistory(
      username: 'alice',
      from: from,
      to: to,
      criteria: criteria,
    );
  }

  /// 사용자 스트릭 조회 (queryParameters 방식 사용)
  static Future<StreakData> getUserStreak({
    String username = 'alice',
    String? from,
    String? to,
  }) async {
    try {
      // 쿼리 파라미터 구성
      final queryParams = <String, String>{};
      if (from != null) queryParams['from'] = from;
      if (to != null) queryParams['to'] = to;

      final data = await _apiClient.get<dynamic>(
        '/api/users/$username/streak',
        queryParameters: queryParams,
        logContext: 'UserApi',
      );

      // StreakData는 List<dynamic>을 기대하므로 타입 체크
      if (data is List) {
        final streakData = StreakData.fromJson(data);
        developer.log('스트릭 데이터 ${streakData.items.length}개 조회 성공', name: 'UserApi');
        return streakData;
      } else {
        developer.log('StreakData: List가 아닌 데이터, 빈 리스트 사용', name: 'UserApi');
        return StreakData.fromJson([]);
      }
    } catch (e) {
      throw Exception('스트릭 데이터를 불러올 수 없습니다: $e');
    }
  }

  /// 현재 사용자 스트릭 조회 (간편 메서드)
  static Future<StreakData> getCurrentUserStreak({
    String? from,
    String? to,
  }) async {
    return await getUserStreak(
      username: 'alice',
      from: from,
      to: to,
    );
  }
} 