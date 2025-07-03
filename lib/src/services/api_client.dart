import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;
import 'token_storage.dart';

/// API 응답 결과를 담는 클래스
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int statusCode;

  ApiResponse({
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

/// Dio 기반 API 클라이언트
class ApiClient {
  static final String _baseUrl = dotenv.env['BASE_URL'] ?? '';
  
  late final Dio _dio;
  static ApiClient? _instance;
  
  // 401 에러 발생 시 호출할 콜백 함수
  Function()? onUnauthorized;

  // 싱글톤 패턴
  static ApiClient get instance {
    _instance ??= ApiClient._internal();
    return _instance!;
  }

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // JWT 토큰 자동 추가 (TokenStorage 사용)
          final token = await TokenStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          // 요청 로깅 (개발 모드에서만)
          if (kDebugMode) {
            developer.log(
              '[${options.method}] ${options.uri}',
              name: 'ApiClient',
            );
            if (options.data != null) {
              developer.log('Body: ${options.data}', name: 'ApiClient');
            }
          }
          
          handler.next(options);
        },
        onResponse: (response, handler) {
          // 응답 로깅 (개발 모드에서만)
          if (kDebugMode) {
            developer.log(
              '[${response.statusCode}] ${response.requestOptions.uri} (${response.requestOptions.method})',
              name: 'ApiClient',
            );
          }
          handler.next(response);
        },
        onError: (error, handler) {
          _handleApiError(error);
          handler.next(error);
        },
      ),
    );
  }

  void _handleApiError(DioException error) {
    final statusCode = error.response?.statusCode ?? 0;
    
    developer.log(
      'API Error: $statusCode - ${error.message}',
      name: 'ApiClient',
    );

    switch (statusCode) {
      case 401:
        // 인증 만료 시 콜백 호출 (AuthService에서 처리하도록)
        developer.log('인증 만료 감지 - 토큰 정리 콜백 호출', name: 'ApiClient');
        onUnauthorized?.call();
        break;
      case 500:
        developer.log('서버 오류 발생', name: 'ApiClient');
        break;
    }
  }

  /// Dio Response를 ApiResponse로 변환
  ApiResponse<T> _convertResponse<T>(
    Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    try {
      final statusCode = response.statusCode ?? 0;
      
      // 응답 실패 시 바로 리턴
      if (statusCode < 200 || statusCode >= 300) {
        return ApiResponse.failure('요청 처리 중 오류가 발생했습니다.', statusCode);
      }

      // 데이터가 null일 때 바로 리턴
      if (response.data == null) {
        return ApiResponse.success(null as T, statusCode);
      }

      // 데이터가 Map이 아닐 때 바로 리턴 (wrapper 없는 경우)
      if (response.data is! Map<String, dynamic>) {
        return ApiResponse.success(response.data as T, statusCode);
      }

      final responseData = response.data as Map<String, dynamic>;
      final httpStatus = responseData['httpStatus'] as int;
      
      // httpStatus가 실패일 때 바로 리턴
      if (httpStatus < 200 || httpStatus >= 300) {
        final statusMessage = responseData['statusMessage'] ?? '요청 처리 실패';
        return ApiResponse.failure(statusMessage, httpStatus);
      }

      // 성공 케이스 - data 필드 추출
      final actualData = responseData['data'];
      
      // fromJson이 있으면 변환, 없으면 data를 그대로 반환
      if (fromJson != null) {
        return ApiResponse.success(fromJson(actualData), statusCode);
      } else {
        return ApiResponse.success(actualData as T, statusCode);
      }
    } catch (e) {
      developer.log('응답 변환 오류: $e', name: 'ApiClient');
      return ApiResponse.failure('응답 데이터 파싱 오류', response.statusCode ?? 0);
    }
  }

  /// DioException을 ApiResponse로 변환
  ApiResponse<T> _convertError<T>(DioException error) {
    final statusCode = error.response?.statusCode ?? 0;
    String errorMessage;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = '네트워크 연결을 확인해주세요.';
        break;
      case DioExceptionType.badResponse:
        errorMessage = _getErrorMessage(statusCode, error.response?.data);
        break;
      case DioExceptionType.cancel:
        errorMessage = '요청이 취소되었습니다.';
        break;
      default:
        errorMessage = '네트워크 연결을 확인해주세요.';
    }

    return ApiResponse.failure(errorMessage, statusCode);
  }

  /// 에러 메시지 추출
  String _getErrorMessage(int statusCode, dynamic responseData) {
    // 응답 데이터에서 에러 메시지 추출 시도
    try {
      // responseData가 Map이 아니면 바로 기본 메시지로
      if (responseData is! Map<String, dynamic>) {
        return _getDefaultErrorMessage(statusCode);
      }
      
      // statusMessage 키가 있으면 바로 리턴
      if (responseData.containsKey('statusMessage')) {
        return responseData['statusMessage'];
      }
      
      // message 키가 있으면 바로 리턴
      if (responseData.containsKey('message')) {
        return responseData['message'];
      }
      
      // error 키가 있으면 바로 리턴
      if (responseData.containsKey('error')) {
        return responseData['error'];
      }
    } catch (e) {
      developer.log('에러 메시지 파싱 실패: $e', name: 'ApiClient');
    }

    // 기본 에러 메시지 반환
    return _getDefaultErrorMessage(statusCode);
  }

  /// 상태 코드에 따른 기본 에러 메시지 반환
  String _getDefaultErrorMessage(int statusCode) {
    switch (statusCode) {
      case 401:
        return '인증이 만료되었습니다. 다시 로그인해주세요.';
      case 403:
        return '접근 권한이 없습니다.';
      case 404:
        return '요청한 리소스를 찾을 수 없습니다.';
      case 422:
        return '입력 데이터가 올바르지 않습니다.';
      case 500:
        return '서버에 일시적인 문제가 발생했습니다. 잠시 후 다시 시도해주세요.';
      default:
        return '요청 처리 중 오류가 발생했습니다. (코드: $statusCode)';
    }
  }

  /// GET 요청
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    T Function(Map<String, dynamic>)? fromJson,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
      );
      return _convertResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _convertError<T>(e);
    }
  }

  /// POST 요청
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.post(endpoint, data: body);
      return _convertResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _convertError<T>(e);
    }
  }

  /// PUT 요청
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.put(endpoint, data: body);
      return _convertResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _convertError<T>(e);
    }
  }

  /// DELETE 요청
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(endpoint);
      return _convertResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _convertError<T>(e);
    }
  }

  /// 기본 URL 반환
  static String? get baseUrl => _baseUrl;
}
