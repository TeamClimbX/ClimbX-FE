import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';
import 'dart:developer' as developer;
import '../api/auth.dart';
import '../screens/login_page.dart';
import '../screens/main_page.dart';
import '../utils/color_schemes.dart';

class AuthWrapper extends HookWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // fquery로 인증 상태 확인
    final authQuery = useQuery<bool, Exception>([
      'auth_status',
    ], AuthHelpers.isLoggedIn);

    // 로딩 중일 때 스플래시 화면
    if (authQuery.isLoading) {
      developer.log('토큰 상태 확인 중...', name: 'AuthWrapper');

      return const Scaffold(
        backgroundColor: AppColorSchemes.backgroundSecondary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로고
              Text(
                'ClimbX',
                style: TextStyle(
                  color: AppColorSchemes.textPrimary,
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                ),
              ),

              SizedBox(height: 32),

              // 로딩 인디케이터
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColorSchemes.accentBlue,
                ),
                strokeWidth: 3,
              ),

              SizedBox(height: 16),

              // 로딩 텍스트
              Text(
                '로그인 상태 확인 중...',
                style: TextStyle(
                  color: AppColorSchemes.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 에러 발생 시 로그인 페이지로
    if (authQuery.isError) {
      developer.log('토큰 확인 실패: ${authQuery.error}', name: 'AuthWrapper');
      return const LoginPage();
    }

    final isLoggedIn = authQuery.data ?? false;

    if (isLoggedIn) {
      developer.log('자동 로그인 성공 - MainPage로 이동', name: 'AuthWrapper');
      return const MainPage();
    } else {
      developer.log('로그인 필요 - LoginPage 표시', name: 'AuthWrapper');
      return const LoginPage();
    }
  }
}
