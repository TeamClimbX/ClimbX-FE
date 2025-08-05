import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../utils/navigation_helper.dart';
import '../utils/color_schemes.dart';
import '../api/auth.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  // TODO: 디버깅용 - 나중에 제거할 것
  final VoidCallback? onDebugRatingChange;
  const CustomAppBar({
    super.key,
    this.onDebugRatingChange,
  });

  // 원본 생성자 (나중에 복원할 것)
  // const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColorSchemes.backgroundPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,

      // 로고
      title: const Text(
        'ClimbX',
        style: TextStyle(
          color: AppColorSchemes.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),

      // 액션들
      actions: [
        // TODO: 디버깅용 레이팅 변경 버튼 - 나중에 제거할 것
        if (onDebugRatingChange != null)
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColorSchemes.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.tune, color: AppColorSchemes.textSecondary, size: 22),
              onPressed: onDebugRatingChange,
            ),
          ),

        // 로그아웃 버튼 (임시, 나중에 제거 예정)
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: AppColorSchemes.backgroundSecondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.logout, color: AppColorSchemes.textSecondary, size: 22),
            onPressed: () {
              _handleLogout(context);
            },
          ),
        ),

        // 알림
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: AppColorSchemes.backgroundSecondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColorSchemes.textSecondary,
              size: 22,
            ),
            onPressed: () {},
          ),
        ),
        // 메뉴
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: AppColorSchemes.backgroundSecondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.menu_rounded,
              color: AppColorSchemes.textSecondary,
              size: 22,
            ),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  // 로그아웃 처리
  static void _handleLogout(BuildContext context) {
    developer.log('로그아웃 요청', name: 'CustomAppBar');

    AuthHelpers.clearToken()
        .then((_) {
          developer.log('토큰 삭제 완료', name: 'CustomAppBar');
          
          // LoginPage로 이동
          if (context.mounted) {
            NavigationHelper.navigateToLoginAfterLogout(context);
            developer.log('LoginPage로 이동 완료', name: 'CustomAppBar');
          }
        })
        .catchError((error) {
          developer.log('로그아웃 실패: $error', name: 'CustomAppBar');
        });
  }
}
