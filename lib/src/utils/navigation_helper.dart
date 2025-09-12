import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../screens/main_page.dart';
import '../screens/login_page.dart';
import '../screens/settings_page.dart';
import '../screens/markdown_viewer_page.dart';
import '../screens/email_compose_page.dart';
import '../utils/bottom_nav_tab.dart';
import '../screens/video_submission_flow_page.dart';
import '../screens/public_profile_page.dart';
import '../screens/problem_votes_page.dart';
import '../api/util/auth/user_identity.dart';

/// 공통 네비게이션 처리 헬퍼
class NavigationHelper {
  /// 영상 제출 플로우 시작: 검색 탭을 제출 모드로 열어 videoId를 싣고 들어감
  static Future<void> startVideoSubmissionFlow(
    BuildContext context, {
    required String? videoId,
    int? gymId,
  }) async {
    Navigator.push(
      context,
      _createPageRoute(
        VideoSubmissionFlowPage(
          videoId: videoId,
          initialGymId: gymId,
        ),
      ),
    );
  }
  /// 로그인 성공 후 MainPage로 이동
  static void navigateToMainAfterLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      _createPageRoute(const MainPage()),
    );
  }

  /// 난이도 기여 페이지로 이동
  static void navigateToProblemVotes(BuildContext context, String problemId) {
    Navigator.push(
      context,
      _createPageRoute(
        ProblemVotesPage(problemId: problemId),
      ),
    );
  }

  /// 로그아웃 후 LoginPage로 이동 (모든 페이지 스택 제거)
  static void navigateToLoginAfterLogout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      _createPageRoute(const LoginPage()),
      (route) => false, // 모든 이전 페이지 제거
    );
  }

  /// 메인에서 특정 탭으로 이동 (검색 탭 등)
  static void navigateToMainWithTab(BuildContext context, BottomNavTab tab) {
    Navigator.pushAndRemoveUntil(
      context,
      _createPageRoute(MainPage(initialTab: tab)),
      (route) => false,

    );
  }

  /// 자기 자신인지 확인하여 적절한 화면으로 이동 (자기 자신이면 메인 프로필 탭으로)
  static Future<void> navigateToPublicProfileSmart(
    BuildContext context, {
    required String targetNickname,
  }) async {
    // await 이전에 NavigatorState를 확보하여 context 경고 회피
    final navigator = Navigator.of(context);
    try {
      final current = await UserIdentity.getOrFetchNickname(logContext: 'NavigationHelper');
      if (current == targetNickname) {
        navigator.pushAndRemoveUntil(
          _createPageRoute(const MainPage(initialTab: BottomNavTab.profile)),
          (route) => false,
        );
        return;
      }
    } catch (e, s) {
      developer.log(
        '현재 사용자 닉네임 확인 실패, 퍼블릭 프로필로 이동',
        name: 'NavigationHelper',
        error: e,
        stackTrace: s,
      );
    }
    navigator.push(
      _createPageRoute(
        PublicProfilePage(nickname: targetNickname),
      ),
    );
  }

  /// 지도에서 검색 탭으로 이동하며 특정 지점을 프리필 (완전히 새로운 페이지로)
  static void navigateToSearchWithGym(BuildContext context, int gymId) {
    Navigator.pushReplacement(
      context,
      _createPageRoute(
        MainPage(
          initialTab: BottomNavTab.search,
          initialGymIdForSearch: gymId,
        ),
      ),
    );
  }

  /// 설정 페이지로 이동
  static void navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      _createPageRoute(const SettingsPage()),
    );
  }

  /// 마크다운 문서 뷰어로 이동
  static void navigateToMarkdown(
    BuildContext context, {
    required String title,
    required String assetPath,
  }) {
    Navigator.push(
      context,
      _createPageRoute(
        MarkdownViewerPage(title: title, assetPath: assetPath),
      ),
    );
  }

  /// 이메일 작성 화면으로 이동
  static void navigateToEmailCompose(
    BuildContext context, {
    required String title,
    required String toEmail,
    required String subject,
    String? hint,
    String? contentId,
  }) {
    Navigator.push(
      context,
      _createPageRoute(
        EmailComposePage(
          title: title,
          toEmail: toEmail,
          defaultSubject: subject,
          hint: hint,
          contentId: contentId,
        ),
      ),
    );
  }

  /// 퍼블릭 프로필 페이지로 이동 (하단바 없이 오버레이)
  static void navigateToPublicProfile(BuildContext context, String nickname) {
    Navigator.push(
      context,
      _createPageRoute(
        PublicProfilePage(nickname: nickname),
      ),
    );
  }

  /// 공통 페이지 라우트 생성 (애니메이션 없음)
  static PageRouteBuilder<T> _createPageRoute<T extends Widget>(T page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
} 