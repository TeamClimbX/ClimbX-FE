import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:fquery/fquery.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'src/widgets/auth_wrapper.dart';
import 'src/api/util/core/api_client.dart';
import 'src/api/util/auth/auth_interceptor.dart';
import 'dart:developer' as developer;

// 전역 네비게이터 키 (팝업용)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 네이버 맵 클라이언트 ID 검증
  const naverMapClientId = String.fromEnvironment('NAVER_MAP_CLIENT_ID');
  if (naverMapClientId.isEmpty) {
    throw Exception('NAVER_MAP_CLIENT_ID가 설정되지 않았습니다.');
  }
  
  await FlutterNaverMap().init(
    clientId: naverMapClientId,
    onAuthFailed: (ex) {
      switch (ex) {
        case NQuotaExceededException(:final message):
          developer.log('사용량 초과 (message: $message)', name: 'FlutterNaverMap');
          break;
        case NUnauthorizedClientException() ||
            NClientUnspecifiedException() ||
            NAnotherAuthFailedException():
          developer.log('인증 실패: $ex', name: 'FlutterNaverMap');
          break;
      }
    },
  );

  // 카카오 SDK 초기화
  const kakaoNativeAppKey = String.fromEnvironment('KAKAO_NATIVE_APP_KEY');
  if (kakaoNativeAppKey.isEmpty) {
    throw Exception('KAKAO_NATIVE_APP_KEY가 설정되지 않았습니다.');
  }
  KakaoSdk.init(nativeAppKey: kakaoNativeAppKey);

  // API 클라이언트 초기화
  ApiClient.instance;

  // AuthInterceptor 콜백 설정 - 토큰 만료 시 처리
  AuthInterceptor.setOnUnauthorized(() async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    // 토큰 만료 팝업 표시
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('로그인 만료'),
        content: const Text('로그인이 만료되었습니다. 다시 로그인해주세요.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // AuthWrapper가 자동으로 로그인 상태를 확인하고 LoginPage로 이동
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return QueryClientProvider(
      queryClient: QueryClient(),
      child: MaterialApp(
        title: 'ClimbX',
        theme: ThemeData(primarySwatch: Colors.blue),
        navigatorKey: navigatorKey, // 전역 네비게이터 키 설정
        home: const AuthWrapper(),
      ),
    );
  }
}
