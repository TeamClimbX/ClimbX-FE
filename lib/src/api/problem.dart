import '../models/problem.dart';
import 'util/core/api_client.dart';

/// 클라이밍 문제 관련 API 호출 함수들
class ProblemApi {
  static final ApiClient _client = ApiClient.instance;

  /// 문제 목록 조회
  static Future<List<Problem>> getProblems({
    int? gymId,
    int? gymAreaId,
    String? localLevel,
    String? holdColor,
    String? problemTier,
    String? activeStatus,
  }) async {
    final queryParams = <String, dynamic>{
      if (gymId != null) 'gymId': gymId,
      if (gymAreaId != null) 'gymAreaId': gymAreaId,
      if (localLevel != null) 'localLevel': localLevel,
      if (holdColor != null) 'holdColor': holdColor,
      if (problemTier != null) 'problemTier': problemTier,
      if (activeStatus != null) 'activeStatus': activeStatus,
    };

    return _client.get<List<Problem>>(
      '/api/problems',
      queryParameters: queryParams,
      fromJson: (data) => (data as List)
          .map((item) => Problem.fromJson(item as Map<String, dynamic>))
          .toList(),
      logContext: 'ProblemApi',
    );
  }

  /// 특정 클라이밍장의 문제 목록 조회
  static Future<List<Problem>> getProblemsByGymId(int gymId) async {
    return getProblems(gymId: gymId);
  }

  /// 특정 문제 상세 정보 조회
  static Future<Problem> getProblemById(String problemId) async {
    return _client.get<Problem>(
      '/api/problems/$problemId',
      fromJson: (data) => Problem.fromJson(data as Map<String, dynamic>),
      logContext: 'ProblemApi',
    );
  }
} 