import 'package:flutter/material.dart';
import '../utils/navigation_helper.dart';
import '../utils/color_schemes.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

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
      titleSpacing: 24.0,
      centerTitle: false, // 왼쪽 정렬

      // 액션들
      actions: [
        // 레이팅 디버깅 버튼 삭제

        // 알림 버튼 (비활성화/주석 처리)
        // Container(
        //   margin: const EdgeInsets.only(right: 8),
        //   decoration: BoxDecoration(
        //     color: AppColorSchemes.backgroundSecondary,
        //     borderRadius: BorderRadius.circular(12),
        //   ),
        //   child: IconButton(
        //     icon: const Icon(
        //       Icons.notifications_outlined,
        //       color: AppColorSchemes.textSecondary,
        //       size: 22,
        //     ),
        //     onPressed: () {},
        //   ),
        // ),
        // 설정
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: AppColorSchemes.backgroundSecondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.settings,
              color: AppColorSchemes.textSecondary,
              size: 22,
            ),
            onPressed: () {
              NavigationHelper.navigateToSettings(context);
            },
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
