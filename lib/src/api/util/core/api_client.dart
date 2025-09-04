import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import '../auth/auth_interceptor.dart';
import '../error/error_interceptor.dart';
import 'response_interceptor.dart';
import 'http_method.dart';

/// API 응답 결과를 담는 클래스
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int statusCode;

  const ApiResponse({
    required this.success,
    this.data,
    this.error,
    required this.statusCode,
  });

  factory ApiResponse.success(T data, int statusCode) {
    return ApiResponse(success: true, data: data, statusCode: statusCode);
  }

  factory ApiResponse.failure(String error, int statusCode) {
    return ApiResponse(success: false, error: error, statusCode: statusCode);
  }
}

/// 강화된 Dio 기반 API 클라이언트
class ApiClient {
  static const String _baseUrl = String.fromEnvironment('BASE_URL');

  late final Dio _dio;
  static ApiClient? _instance;

  // 싱글톤 패턴
  static ApiClient get instance {
    _instance ??= ApiClient._internal();
    return _instance!;
  }

  /// Dio 인스턴스에 직접 접근
  Dio get dio => _dio;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    // 인증 토큰 인터셉터 추가
    _dio.interceptors.add(AuthInterceptor.createInterceptor());
    
    // Response 변환 인터셉터 추가
    _dio.interceptors.add(ResponseInterceptor.createInterceptor());
    
    // 에러 처리 인터셉터 추가
    _dio.interceptors.add(ErrorInterceptor.createInterceptor());

    // 로깅 인터셉터 (개발 모드에서만)
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
        logPrint: (obj) => developer.log(obj.toString(), name: 'ApiClient'),
      ));
    }
  }

  /// 인터셉터 콜백 설정
  void setInterceptorCallbacks({
    Function()? onUnauthorized,
  }) {
    // 인증 관련 콜백 설정
    AuthInterceptor.setOnUnauthorized(onUnauthorized);
  }

  /// 기본 URL 반환
  static String? get baseUrl => _baseUrl;

  /// 클라이언트 재설정 (테스트용)
  static void reset() {
    _instance = null;
  }

  /// 제네릭 API 요청 메서드
  Future<T> request<T>(
    HttpMethod method,
    String path, {
    Map<String, dynamic>? queryParameters,
    dynamic data,
    T Function(dynamic)? fromJson,
    String? logContext,
  }) async {
    final contextName = logContext ?? 'ApiClient';
    
    try {
      developer.log('API 요청 시작: ${method.value} $path', name: contextName);
      
      final response = await _dio.request(
        path,
        options: Options(method: method.value),
        queryParameters: queryParameters,
        data: data,
      );
      
      final apiResponse = response.data as ApiResponse<dynamic>;
      
      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.error ?? 'API 요청 실패');
      }
      
      // fromJson 함수가 있으면 데이터 변환
      if (fromJson != null) {
        final result = fromJson(apiResponse.data);
        developer.log('API 요청 성공: ${method.value} $path', name: contextName);
        return result;
      }
      
      // fromJson이 없으면 원시 데이터 반환
      developer.log('API 요청 성공: ${method.value} $path', name: contextName);
      return apiResponse.data as T;
      
    } catch (e) {
      developer.log('API 요청 실패: ${method.value} $path - $e', name: contextName);
      
      // 사용자 친화적 에러 메시지 생성
      String errorMessage;
      if (e is DioException) {
        errorMessage = 'API 요청 중 오류가 발생했습니다: ${e.message}';
      } else {
        errorMessage = 'API 요청 중 예상치 못한 오류가 발생했습니다: $e';
      }
      
      throw Exception(errorMessage);
    }
  }

  /// GET 요청 편의 메서드
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    String? logContext,
  }) =>
      request<T>(
        HttpMethod.get,
        path,
        queryParameters: queryParameters,
        fromJson: fromJson,
        logContext: logContext,
      );

  /// POST 요청 편의 메서드
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    String? logContext,
  }) =>
      request<T>(
        HttpMethod.post,
        path,
        data: data,
        queryParameters: queryParameters,
        fromJson: fromJson,
        logContext: logContext,
      );

  /// PUT 요청 편의 메서드
  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    String? logContext,
  }) =>
      request<T>(
        HttpMethod.put,
        path,
        data: data,
        queryParameters: queryParameters,
        fromJson: fromJson,
        logContext: logContext,
      );

  /// PATCH 요청 편의 메서드
  Future<T> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    String? logContext,
  }) =>
      request<T>(
        HttpMethod.patch,
        path,
        data: data,
        queryParameters: queryParameters,
        fromJson: fromJson,
        logContext: logContext,
      );

  /// DELETE 요청 편의 메서드
  Future<T> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    String? logContext,
  }) =>
      request<T>(
        HttpMethod.delete,
        path,
        queryParameters: queryParameters,
        fromJson: fromJson,
        logContext: logContext,
      );
} 