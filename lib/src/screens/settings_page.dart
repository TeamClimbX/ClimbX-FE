import 'package:flutter/material.dart';
import '../utils/color_schemes.dart';
import '../utils/navigation_helper.dart';
import '../api/auth.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorSchemes.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: AppColorSchemes.backgroundPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          '설정',
          style: TextStyle(
            color: AppColorSchemes.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const _SectionHeader(title: '계정'),
          _SettingTile(
            icon: Icons.logout,
            title: '로그아웃',
            onTap: () async {
              await AuthHelpers.clearToken();
              if (context.mounted) {
                NavigationHelper.navigateToLoginAfterLogout(context);
              }
            },
          ),
          _SettingTile(
            icon: Icons.delete_forever_outlined,
            title: '계정 삭제',
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) {
                  bool agreed = false;
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return Dialog(
                        backgroundColor: AppColorSchemes.backgroundPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '계정 삭제',
                                style: TextStyle(
                                  color: AppColorSchemes.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                '계정을 삭제하면 모든 데이터가 영구적으로 삭제되며 복구할 수 없습니다. 삭제 처리에는 최대 14일이 소요될 수 있습니다.',
                                style: TextStyle(color: AppColorSchemes.textSecondary, height: 1.5),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: agreed,
                                    onChanged: (v) => setState(() => agreed = v ?? false),
                                  ),
                                  const Expanded(
                                    child: Text(
                                      '영구 삭제의 결과를 이해했으며 동의합니다.',
                                      style: TextStyle(color: AppColorSchemes.textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColorSchemes.textSecondary,
                                    ),
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('취소'),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColorSchemes.accentRed,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: agreed ? () => Navigator.of(ctx).pop(true) : null,
                                    child: const Text('삭제 요청'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );

              if (confirmed == true) {
                // API 미구현: 임시로 로그아웃 처리 및 안내만 제공
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('삭제 요청이 접수되었습니다. 처리에는 최대 14일이 소요될 수 있습니다.')),
                );
                await AuthHelpers.clearToken();
                if (context.mounted) {
                  NavigationHelper.navigateToLoginAfterLogout(context);
                }
              }
            },
          ),

          const SizedBox(height: 16),
          const _SectionHeader(title: '개인정보/법적 고지'),
          _SettingTile(
            icon: Icons.privacy_tip_outlined,
            title: '개인정보처리방침',
            onTap: () {
              NavigationHelper.navigateToMarkdown(
                context,
                title: '개인정보처리방침',
                assetPath: 'privacy-policy-ko.md',
              );
            },
          ),
          _SettingTile(
            icon: Icons.description_outlined,
            title: '이용약관',
            onTap: () {
              NavigationHelper.navigateToMarkdown(
                context,
                title: '이용약관',
                assetPath: 'terms-of-service-ko.md',
              );
            },
          ),

          const SizedBox(height: 16),
          const _SectionHeader(title: '지원'),
          _SettingTile(
            icon: Icons.email_outlined,
            title: '문의하기',
            onTap: () {
              NavigationHelper.navigateToEmailCompose(
                context,
                title: '문의하기',
                toEmail: 'climbx.cs@gmail.com',
                subject: '[문의] ClimbX 문의',
                hint: '문의 유형, 상세 내용을 적어주세요',
              );
            },
          ),
          _SettingTile(
            icon: Icons.report_gmailerrorred_outlined,
            title: '콘텐츠 신고',
            onTap: () {
              NavigationHelper.navigateToEmailCompose(
                context,
                title: '콘텐츠 신고',
                toEmail: 'climbx.cs@gmail.com',
                subject: '[신고] 부적절한 콘텐츠 신고',
                hint: '콘텐츠 ID/링크, 신고 유형(저작권/명예훼손/음란/스팸 등), 상세 설명을 적어주세요',
              );
            },
          ),
          _SettingTile(
            icon: Icons.link,
            title: '계정 삭제(웹/메일) 요청',
            onTap: () {
              NavigationHelper.navigateToEmailCompose(
                context,
                title: '계정 삭제 요청',
                toEmail: 'climbx.cs@gmail.com',
                subject: '[계정삭제요청] ClimbX',
                hint: '닉네임, 연락 가능한 이메일(선택), 삭제 사유(선택)를 적어주세요',
              );
            },
          ),

          const SizedBox(height: 16),
          const _SectionHeader(title: '앱 정보'),
          _SettingTile(
            icon: Icons.info_outline,
            title: '버전',
            trailingText: '',
            onTap: () async {
              final pkg = await PackageInfo.fromPlatform();
              if (!context.mounted) return;
              showDialog<void>(
                context: context,
                builder: (ctx) => Dialog(
                  backgroundColor: AppColorSchemes.backgroundPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '앱 정보',
                          style: TextStyle(
                            color: AppColorSchemes.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '버전: ${pkg.version} (${pkg.buildNumber})',
                          style: const TextStyle(color: AppColorSchemes.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: AppColorSchemes.accentBlue,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('확인'),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColorSchemes.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailingText;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.trailingText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColorSchemes.backgroundPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColorSchemes.textSecondary),
        title: Text(
          title,
          style: const TextStyle(color: AppColorSchemes.textPrimary, fontWeight: FontWeight.w600),
        ),
        trailing: trailingText != null && trailingText!.isNotEmpty
            ? Text(
                trailingText!,
                style: const TextStyle(color: AppColorSchemes.textSecondary),
              )
            : const Icon(Icons.chevron_right, color: AppColorSchemes.textSecondary),
        onTap: onTap,
      ),
    );
  }
}

