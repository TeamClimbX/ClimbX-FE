import 'user_service.dart';
import 'auth_service.dart';

/// fquery 쿼리 키들
class UserQueryKeys {
  static List<String> userProfile() => ['userProfile'];
  static List<String> authStatus() => ['authStatus'];
}

/// fquery mutation 키들
class AuthMutationKeys {
  static List<String> signIn() => ['signIn'];
}

/// fquery용 
class UserQueryService {
  /// 기존 UserService.getCurrentUserProfile을 그대로 사용
  static Future<UserProfile> getUserProfile() async {
    final response = await UserService.getCurrentUserProfile();
    if (response.success && response.data != null) {
      return response.data!;
    } else {
      throw Exception(response.error);
    }
  }
}

/// fquery용 Auth 서비스
class AuthQueryService {
  /// Google OAuth 로그인 mutation
  static Future<String> signInWithGoogle(_) async {
    final token = await AuthService.signInWithGoogle();
    if (token != null) {
      return token;
    } else {
      throw Exception('토큰 발급에 실패했습니다. 다시 시도해주세요.');
    }
  }

  /// 인증 상태 확인 query
  static Future<bool> checkAuthStatus() {
    return AuthService.isLoggedIn().catchError((error) {
      return false;
    });
  }
} 