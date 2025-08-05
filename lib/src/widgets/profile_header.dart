import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';
import 'package:image_picker/image_picker.dart';
import '../api/user.dart';
import '../models/user_profile.dart';
import '../utils/color_schemes.dart';
import '../utils/image_compressor.dart';
import '../utils/tier_colors.dart';

/// 프로필 헤더 위젯 - 사용자 정보 표시 및 편집 기능
/// 인라인 편집 모드 지원

class ProfileHeader extends HookWidget {
  const ProfileHeader({
    super.key,
    required this.userProfile,
    required this.tierName,
  });

  final UserProfile userProfile;
  final String tierName;

  @override
  Widget build(BuildContext context) {
    // 현재 사용자 정보 참조
    final u = userProfile;

    // 편집 상태 관리
    final isEditing = useState(false);
    final submitting = useState(false);
    final picker = useMemoized(() => ImagePicker());
    final newImage = useState<File?>(null);

    // 텍스트 입력 컨트롤러
    final nickCtrl = useTextEditingController();
    final statusCtrl = useTextEditingController();

    // 캐시 무효화용 클라이언트
    final queryClient = useQueryClient();

    /* ----------------- 편집 기능 ----------------- */

    /// 변경사항 저장 처리
    Future<void> saveChanges() async {
      // 변경사항 감지
      final newNick = nickCtrl.text.trim();
      final newStatus = statusCtrl.text.trim();
      final nickChanged = newNick != u.nickname;
      final statusChanged = newStatus != u.statusMessage;
      final imageChanged = newImage.value != null;

      if (!nickChanged && !statusChanged && !imageChanged) {
        isEditing.value = false;
        return;
      }

      submitting.value = true;
      try {
        // 텍스트 정보 업데이트
        if (nickChanged || statusChanged) {
          await UserApi.updateProfile(
            currentNickname: u.nickname,
            newNickname: newNick.isNotEmpty ? newNick : u.nickname,
            newStatusMessage: newStatus,
          );
        }

        // 프로필 이미지 업데이트
        if (imageChanged) {
          try {
            final compressed = await compressUnder5MB(
              File(newImage.value!.path),
            );

            // 닉네임이 변경된 경우 새 nickname, 아니면 현재 nickname 사용
            final imageNickname = nickChanged && newNick.isNotEmpty
                ? newNick
                : u.nickname;
            await UserApi.updateProfileImage(
              nickname: imageNickname,
              file: XFile(compressed.path),
            );
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
            }
            return; // 에러 발생 시 저장 중단
          }
        }
        // 캐시 무효화로 화면 갱신
        queryClient.invalidateQueries(['user_profile'], exact: true);
        isEditing.value = false;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('프로필이 업데이트되었습니다.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('업데이트 실패: $e')),
          );
        }
      } finally {
        submitting.value = false;
      }
    }

    final screenW = MediaQuery.of(context).size.width;
    final tier = TierColors.getTierFromString(tierName);
    final colorScheme = TierColors.getColorScheme(tier);

    /* ----------------- UI 구성 ----------------- */
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: AppColorSchemes.defaultGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 2),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(screenW * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 프로필 이미지 영역
                GestureDetector(
                  onTap: isEditing.value
                      ? () async {
                          final picked = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (picked != null) {
                            newImage.value = File(picked.path);
                          }
                        }
                      : null,
                  child: Container(
                    width: screenW * 0.18,
                    height: screenW * 0.18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: colorScheme.gradient,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow,
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: screenW * 0.09 - 3,
                            backgroundImage: newImage.value != null
                                ? FileImage(newImage.value!)
                                : (u.profileImageUrl?.isNotEmpty ?? false)
                                ? NetworkImage(u.profileImageUrl!)
                                : const AssetImage('assets/images/avatar.png')
                                      as ImageProvider,
                          ),
                          // 편집 모드 시 카메라 아이콘 오버레이
                          if (isEditing.value)
                            Container(
                              width: (screenW * 0.18 - 6),
                              height: (screenW * 0.18 - 6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.4),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenW * 0.04),
                // 닉네임 및 상태메시지 영역
                Expanded(
                  child: isEditing.value
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 닉네임 입력 박스
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColorSchemes.backgroundSecondary,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColorSchemes.borderPrimary,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: nickCtrl,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppColorSchemes.textPrimary,
                                ),
                                decoration: const InputDecoration(
                                  hintText: '닉네임',
                                  hintStyle: TextStyle(
                                    color: AppColorSchemes.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  isDense: true,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // 상태메시지 입력 박스
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColorSchemes.backgroundSecondary,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColorSchemes.borderPrimary,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: statusCtrl,
                                maxLength: 50,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColorSchemes.textSecondary,
                                ),
                                decoration: const InputDecoration(
                                  hintText: '상태메세지',
                                  hintStyle: TextStyle(
                                    color: AppColorSchemes.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  counterText: '',
                                  isDense: true,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u.nickname,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColorSchemes.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              u.statusMessage,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColorSchemes.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                ),

                SizedBox(width: screenW * 0.04),

                // 설정/완료 버튼
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColorSchemes.backgroundSecondary,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColorSchemes.borderPrimary,
                      width: 1,
                    ),
                  ),
                  child: submitting.value
                      ? const SizedBox(
                          width: 36,
                          height: 36,
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            isEditing.value
                                ? Icons.check
                                : Icons.settings_outlined,
                            color: AppColorSchemes.textSecondary,
                            size: 20,
                          ),
                          onPressed: isEditing.value
                               ? saveChanges
                              : () {
                                  // 편집 모드 진입 시 초기값 설정
                                  nickCtrl.text = u.nickname;
                                  statusCtrl.text = u.statusMessage;
                                  isEditing.value = true;
                                },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _TierCard(
              colorScheme: colorScheme,
              tierName: tierName,
              rating: u.rating,
            ),
            const SizedBox(height: 12),
            _StatsRow(colorScheme: colorScheme),
          ],
        ),
      ),
    );
  }
}

// 헬퍼 위젯들
/// 티어 정보 카드
class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.colorScheme,
    required this.tierName,
    required this.rating,
  });

  final TierColorScheme colorScheme;
  final String tierName;
  final int rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: colorScheme.gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _UserRatingLabel(),
          const SizedBox(height: 12),
          Text(
            tierName,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColorSchemes.backgroundPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$rating',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColorSchemes.backgroundPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          const _ProgressBar(),
        ],
      ),
    );
  }
}

/// 사용자 등급 라벨
class _UserRatingLabel extends StatelessWidget {
  const _UserRatingLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'USER RATING',
        style: TextStyle(
          fontSize: 10,
          color: AppColorSchemes.backgroundPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// 진행률 바
class _ProgressBar extends StatelessWidget {
  const _ProgressBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 6,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          FractionallySizedBox(
            widthFactor: 0.14,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.5),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 통계 정보 행
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.colorScheme});

  final TierColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    // 통계 카드 생성
    Widget card(String num, String label, IconData icon) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColorSchemes.backgroundSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColorSchemes.borderPrimary),
          ),
          child: Column(
            children: [
              Icon(icon, color: colorScheme.primary, size: 18),
              const SizedBox(height: 4),
              Text(
                num,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColorSchemes.textPrimary,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColorSchemes.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        card('1520', '문제 해결', Icons.check_circle_outline),
        const SizedBox(width: 12),
        card('274', '문제 기여', Icons.add_circle_outline),
        const SizedBox(width: 12),
        card('331', '명의 라이벌', Icons.people_outline),
      ],
    );
  }
}
