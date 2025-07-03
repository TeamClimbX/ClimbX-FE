import 'dart:developer' as developer;
import 'api_client.dart';
import '../models/history_data.dart';
import '../models/user_profile.dart';

/// 사용자 관련 API 서비스
class UserService {
  static final _apiClient = ApiClient.instance;

  /// 현재 사용자 프로필 조회 (기존 alice 엔드포인트)
  static Future<ApiResponse<UserProfile>> getCurrentUserProfile() async {
    return await _apiClient.get<UserProfile>(
      '/api/users/alice',
      fromJson: UserProfile.fromJson,
    );
  }

  /// 특정 사용자 프로필 조회 (확장 가능)
  static Future<ApiResponse<UserProfile>> getUserProfile(String username) async {
    return await _apiClient.get<UserProfile>(
      '/api/users/$username',
      fromJson: UserProfile.fromJson,
    );
  }

  /// 사용자 히스토리 조회
  /// 
  /// [username]: 사용자명 (기본값: 'alice')
  /// [from]: 시작 날짜 (YYYY-MM-DD, 선택적)
  /// [to]: 종료 날짜 (YYYY-MM-DD, 선택적)  
  /// [criteria]: 조회 기준 ('RATING', 'EXPERIENCE' 등, 기본값: 'RATING')
  static Future<ApiResponse<HistoryData>> getUserHistory({
    String username = 'alice',
    String? from,
    String? to,
    String criteria = 'RATING',
  }) async {
    // 쿼리 파라미터 구성
    final queryParams = <String, String>{
      'criteria': criteria,
    };
    
    if (from != null) queryParams['from'] = from;
    if (to != null) queryParams['to'] = to;

    // URL 쿼리 문자열 생성
    final queryString = queryParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    
    final url = '/api/users/$username/history${queryString.isNotEmpty ? '?$queryString' : ''}';

    final response = await _apiClient.get<dynamic>(url);
    
    if (response.success && response.data != null) {
      // HistoryData는 List<dynamic>을 기대하므로 타입 체크
      if (response.data is List) {
        return ApiResponse.success(HistoryData.fromJson(response.data), response.statusCode);
      } else {
        developer.log('HistoryData: List가 아닌 데이터, 빈 리스트 사용', name: 'UserService');
        return ApiResponse.success(HistoryData.fromJson([]), response.statusCode);
      }
    } else {
      return ApiResponse.failure(response.error ?? '데이터를 불러올 수 없습니다', response.statusCode);
    }
  }

  /// 현재 사용자 히스토리 조회 (간편 메소드)
  static Future<ApiResponse<HistoryData>> getCurrentUserHistory({
    String? from,
    String? to,
    String criteria = 'RATING',
  }) async {
    return getUserHistory(
      username: 'alice',
      from: from,
      to: to,
      criteria: criteria,
    );
  }
}
