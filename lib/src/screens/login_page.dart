import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../api/auth.dart';
import '../api/util/error/auth_cancelled_exception.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:io';
import '../utils/navigation_helper.dart';


class LoginPage extends HookWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // fquery mutation 사용
    final signInMutation = useMutation(
      (_) => AuthApi.signInWithKakao(),
      onSuccess: (token, _, __) {
        // 토큰 발급 성공 - MainPage로 이동
        NavigationHelper.navigateToMainAfterLogin(context);
      },
      onError: (error, _, __) {
        if (error is AuthCancelledException) return; // 사용자가 취소한 경우 무시
      },
    );

    // Apple 로그인 mutation
    final signInAppleMutation = useMutation(
      (_) => AuthApi.signInWithApple(),
      onSuccess: (token, _, __) {
        NavigationHelper.navigateToMainAfterLogin(context);
      },
      onError: (error, _, __) {
        if (error is AuthCancelledException) return;
      },
    );

    // Google 로그인 mutation
    final signInGoogleMutation = useMutation(
      (_) => AuthApi.signInWithGoogle(),
      onSuccess: (token, _, __) {
        NavigationHelper.navigateToMainAfterLogin(context);
      },
      onError: (error, _, __) {
        if (error is AuthCancelledException) return;
      },
    );

    // Apple 로그인 사용 가능 여부 확인 (iOS 13+, Android 웹)
    final appleAvailableSnapshot = useFuture(
      useMemoized(() => SignInWithApple.isAvailable()),
    );
    final showAppleButton =
        Platform.isIOS && appleAvailableSnapshot.data == true;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고
            const Text(
              'ClimbX',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 48,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.0,
              ),
            ),

            const SizedBox(height: 16),

            // 서브 타이틀
            const Text(
              '소셜 계정으로 로그인',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 64),

            // Kakao 로그인 버튼 (공식 가이드라인 준수)
            Container(
              width: 280,
              height: 60, // 가이드라인 준수: 최소 30pt (60px @2x)
              decoration: BoxDecoration(
                color: const Color(0xFFFEE500), // 카카오 공식 브랜드 컬러
                borderRadius: BorderRadius.circular(8), // 카카오 권장: 8px
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1), // 자연스러운 그림자
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: signInMutation.isPending
                      ? null
                      : () => signInMutation.mutate(null),
                  child: Center(
                    child: signInMutation.isPending
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF3C1E1E),
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center, // 수직 중앙 정렬 명시
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: SvgPicture.asset(
                                  'assets/images/social/kakao_symbol.svg',
                                  width: 22,
                                  height: 22,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(width: 8), // 카카오 권장 간격
                              const Text(
                                '카카오 로그인', // 카카오 공식 가이드라인 텍스트
                                style: TextStyle(
                                  color: Color(0xFF3C1E1E), // 카카오 공식 텍스트 색상
                                  fontSize: 16, // 일관된 폰트 크기
                                  fontWeight: FontWeight.w600, // 카카오 권장 폰트 굵기
                                  height: 1.0, // 라인 높이 조정으로 수직 정렬 개선
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Google 로그인 버튼 (Google 공식 가이드라인 준수)
            Container(
              width: 280,
              height: 60, // 가이드라인 준수: 최소 30pt (60px @2x)
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8), // 다른 버튼들과 일관성 유지
                border: Border.all(color: const Color(0xFFDADCE0), width: 1), // Google 공식 테두리 색상
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000), // Google 권장 그림자 투명도
                    blurRadius: 6,
                    offset: Offset(0, 1),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: signInGoogleMutation.isPending
                      ? null
                      : () => signInGoogleMutation.mutate(null),
                  child: Center(
                    child: signInGoogleMutation.isPending
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF1E293B),
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center, // 수직 중앙 정렬 명시
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: SvgPicture.asset(
                                  'assets/images/social/google_g_logo.svg',
                                  width: 18,
                                  height: 18,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(width: 8), // Google 권장: 8px 간격
                              const Text(
                                'Sign in with Google',
                                style: TextStyle(
                                  color: Color(0xFF3c4043), // Google 공식 색상
                                  fontSize: 16, // 카카오와 통일된 크기
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Roboto', // Google 권장 폰트
                                  height: 1.0, // 라인 높이 조정으로 수직 정렬 개선
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),

            if (showAppleButton) ...[
              const SizedBox(height: 16),
              // Apple 공식 SignInWithAppleButton 사용
              SizedBox(
                width: 280,
                height: 60, // 다른 버튼들과 높이 통일
                child: SignInWithAppleButton(
                  style: SignInWithAppleButtonStyle.black,
                  borderRadius: BorderRadius.circular(8), // 모던한 디자인으로 통일
                  onPressed: signInAppleMutation.isPending
                      ? null
                      : () => signInAppleMutation.mutate(null),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // 설명 텍스트
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                '소셜 계정으로 로그인하여 시작하세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
