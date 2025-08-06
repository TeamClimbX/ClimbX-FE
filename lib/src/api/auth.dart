import 'dart:developer' as developer;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:dio/dio.dart';
import 'util/core/api_client.dart';
import 'util/auth/token_storage.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 인증 관련 API 호출 함수들
class AuthApi {
  static final _apiClient = ApiClient.instance;

  // 헤더 접근용 순수 Dio 인스턴스 (인터셉터 없음)
  static final _pureDio = Dio(
    BaseOptions(
      baseUrl: ApiClient.baseUrl ?? '',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  /// nonce 생성 함수
  static String _generateNonce() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
        32,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  /// 공통 로그인/토큰 응답 처리
  static Future<String> _processAuthResponse(Response dioResponse) async {
    // 1. 응답 데이터 파싱 (bodyData 추출)
    final responseData = dioResponse.data;
    if (responseData is! Map<String, dynamic>) {
      throw Exception('응답 형식이 올바르지 않습니다: \\${responseData.runtimeType}');
    }

    // 2. 백엔드 응답 구조에 맞게 데이터 추출
    Map<String, dynamic> bodyData;
    if (responseData.containsKey('body') &&
        responseData['body'] is Map<String, dynamic>) {
      final body = responseData['body'] as Map<String, dynamic>;
      if (body.containsKey('data') && body['data'] is Map<String, dynamic>) {
        bodyData = body['data'] as Map<String, dynamic>;
      } else {
        bodyData = body;
      }
    } else if (responseData.containsKey('data') &&
        responseData['data'] is Map<String, dynamic>) {
      bodyData = responseData['data'] as Map<String, dynamic>;
    } else {
      bodyData = responseData;
    }

    final accessToken = bodyData['accessToken'];
    if (accessToken == null || (accessToken is String && accessToken.isEmpty)) {
      throw Exception('응답에서 accessToken을 찾을 수 없음: $bodyData');
    }

    // 3. 응답 헤더에서 Refresh-Token 추출 및 저장
    final refreshToken = dioResponse.headers.value('Refresh-Token');
    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('응답 헤더에서 Refresh-Token을 찾을 수 없음');
    }

    await TokenStorage.saveTokens(
      accessToken: accessToken as String,
      refreshToken: refreshToken,
    );

    // 4. 사용자 닉네임 가져오기 및 저장 (실패해도 무시)
    try {
      final authMeResponse = await _pureDio.get('/api/auth/me');
      final authData = authMeResponse.data;
      if (authData is Map<String, dynamic>) {
        final nickname = authData['nickname'] as String?;
        if (nickname != null && nickname.isNotEmpty) {
          await TokenStorage.saveUserNickname(nickname);
          if (kDebugMode) {
            developer.log('사용자 닉네임 저장 완료: $nickname', name: 'AuthApi');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('사용자 닉네임 저장 실패: $e', name: 'AuthApi');
      }
    }

    return accessToken;
  }

  /// 카카오 로그인
  static Future<String> signInWithKakao() async {
    try {
      // nonce 생성
      final nonce = _generateNonce();
      if (kDebugMode) {
        developer.log('생성된 nonce: $nonce', name: 'AuthApi');
      }

      // 카카오톡 설치 확인
      if (await isKakaoTalkInstalled()) {
        developer.log('카카오톡 설치되어 있음', name: 'AuthApi');
        try {
          // 카카오톡으로 로그인 시도 (nonce 포함)
          await UserApi.instance.loginWithKakaoTalk(nonce: nonce);
          developer.log('카카오톡으로 로그인 성공', name: 'AuthApi');
        } catch (error) {
          developer.log('카카오톡으로 로그인 실패: $error', name: 'AuthApi');

          // 사용자가 카카오톡 설치 후 디바이스 권한 요청 화면에서 로그인을 취소한 경우,
          // 의도적인 로그인 취소로 보고 카카오계정으로 로그인 시도 없이 로그인 취소로 처리
          if (error is PlatformException && error.code == 'CANCELED') {
            throw Exception('카카오 로그인이 취소되었습니다.');
          }

          // 카카오톡에 연결된 카카오계정이 없는 경우, 카카오계정으로 로그인
          try {
            await UserApi.instance.loginWithKakaoAccount(nonce: nonce);
            developer.log('카카오계정으로 로그인 성공', name: 'AuthApi');
          } catch (error) {
            developer.log('카카오계정으로 로그인 실패: $error', name: 'AuthApi');
            throw Exception('카카오계정으로 로그인에 실패했습니다: $error');
          }
        }
      } else {
        // 카카오톡이 설치되지 않은 경우 카카오계정으로 로그인
        developer.log('카카오톡 설치되어 있지 않음', name: 'AuthApi');
        try {
          await UserApi.instance.loginWithKakaoAccount(nonce: nonce);
          developer.log('카카오계정으로 로그인 성공', name: 'AuthApi');
        } catch (error) {
          developer.log('카카오계정으로 로그인 실패: $error', name: 'AuthApi');
          throw Exception('카카오계정으로 로그인에 실패했습니다: $error');
        }
      }

      // 카카오에서 받은 토큰 정보 가져오기
      final tokenManager = TokenManagerProvider.instance.manager;
      final token = await tokenManager.getToken();

      if (token?.accessToken == null) {
        throw Exception('카카오 토큰을 가져올 수 없습니다.');
      }

      // id_token 추출 및 null 체크
      final idToken = token!.idToken;

      // idToken null 체크 - Kakao OAuth에서 선택적 필드이므로 필수 검증
      if (idToken == null || idToken.isEmpty) {
        developer.log('idToken이 null이거나 비어있음', name: 'AuthApi');
        throw Exception('카카오 ID 토큰을 받을 수 없습니다. 다시 시도해주세요.');
      }

      // 백엔드로 id_token과 nonce 전송하여 JWT 토큰 받기 (idToken 검증 후)
      // 헤더에서 Refresh-Token을 받기 위해 순수 Dio 사용 (인터셉터 없음)
      final dioResponse = await _pureDio.post(
        '/api/auth/oauth2/kakao/callback',
        data: {'idToken': idToken, 'nonce': nonce},
      );

      final accessToken = await _processAuthResponse(dioResponse);
      developer.log('로그인 성공 - 토큰 저장 완료', name: 'AuthApi');
      return accessToken;
    } catch (e) {
      throw Exception('카카오 로그인에 실패했습니다: $e');
    }
  }

  /// Apple 로그인
  static Future<String> signInWithApple() async {
    try {
      // raw nonce 생성 (replay 공격 방지)
      final nonce = _generateNonce();

      if (kDebugMode) {
        developer.log('생성된 Nonce: $nonce', name: 'AuthApi');
      }

      // Apple 로그인 요청
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // identityToken 확인
      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw Exception('Apple 로그인 실패: identityToken이 없습니다');
      }

      // 백엔드로 토큰 전송
      final dioResponse = await _pureDio.post(
        '/api/auth/oauth2/apple/callback',
        data: {'idToken': identityToken, 'nonce': nonce},
      );

      final accessToken = await _processAuthResponse(dioResponse);
      return accessToken;
    } catch (e) {
      throw Exception('Apple 로그인에 실패했습니다: \\${e.toString()}');
    }
  }

  /// Google 로그인
  static Future<String> signInWithGoogle() async {
    try {
      // Google 로그인 인스턴스 생성
      final googleSignIn = GoogleSignIn.instance;

      // 환경 변수에서 클라이언트 ID 로드 (.env)
      final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID'];
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];

      await GoogleSignIn.instance.initialize(
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? iosClientId
            : null,
        serverClientId: webClientId,
      );

      // 로그인 플로우 시작
      final GoogleSignInAccount account = await googleSignIn.authenticate();

      // 인증 정보 가져오기
      final authentication = account.authentication;
      final idToken = authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Google 로그인 실패: idToken이 없습니다');
      }

      // 백엔드로 토큰 전송
      final dioResponse = await _pureDio.post(
        '/api/auth/oauth2/google/callback',
        data: {'idToken': idToken}, // 구글은 nonce를 직접 내부에 생성하므로 nonce를 전달X
      );

      final accessToken = await _processAuthResponse(dioResponse);
      return accessToken;
    } catch (e) {
      throw Exception('Google 로그인에 실패했습니다: ${e.toString()}');
    }
  }

  /// 토큰 유효성 검증 API 호출
  static Future<bool> validateToken() async {
    try {
      await _apiClient.get<Map<String, dynamic>>(
        '/api/auth/validate',
        logContext: 'AuthApi',
      );
      return true;
    } catch (e) {
      developer.log('토큰 유효성 검증 실패: $e', name: 'AuthApi');
      return false;
    }
  }

  /// 토큰 갱신 API 호출
  static Future<String> refreshToken() async {
    try {
      final refreshToken = await TokenStorage.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        throw Exception('Refresh Token이 없습니다');
      }

      // 헤더에서 새로운 Refresh-Token을 받기 위해 순수 Dio 사용 (인터셉터 없음)
      final dioResponse = await _pureDio.post(
        '/api/auth/oauth2/refresh',
        options: Options(headers: {'Refresh-Token': refreshToken}),
      );

      final newAccessToken = await _processAuthResponse(dioResponse);
      developer.log('토큰 갱신 성공', name: 'AuthApi');
      return newAccessToken;
    } catch (e) {
      throw Exception('토큰 갱신에 실패했습니다: $e');
    }
  }
}

/// 인증 상태 관리 헬퍼 함수들 (로컬 저장소 기반)
class AuthHelpers {
  /// 로그인 상태 확인 및 토큰 유효성 검증 + 닉네임 최신화
  static Future<bool> isLoggedIn() async {
    // 1. 토큰 존재 확인
    if (!await TokenStorage.hasToken()) return false;

    // 2. 토큰 유효성 검증 + 닉네임 최신화
    try {
      final authData = await ApiClient.instance.get<Map<String, dynamic>>(
        '/api/auth/me',
      );
      final nickname = authData['nickname'] as String?;
      if (nickname != null && nickname.isNotEmpty) {
        await TokenStorage.saveUserNickname(nickname);
        if (kDebugMode) {
          developer.log('자동 로그인 시 닉네임 최신화: $nickname', name: 'AuthHelpers');
        }
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        developer.log('토큰 유효성 검증 실패: $e', name: 'AuthHelpers');
      }
      await TokenStorage.clearTokens();
      return false;
    }
  }

  /// 로그아웃 (카카오 로그아웃 + 로컬 토큰 삭제)
  static Future<void> signOut() async {
    try {
      // 카카오 로그아웃
      await UserApi.instance.logout();
      developer.log('카카오 로그아웃 성공', name: 'AuthHelpers');
    } catch (e) {
      developer.log('카카오 로그아웃 실패: $e', name: 'AuthHelpers');
    }

    // 로컬 토큰 삭제
    await TokenStorage.clearTokens();
  }

  /// 토큰 삭제 (하위 호환성을 위해 유지)
  static Future<void> clearToken() async {
    await signOut();
  }
}
