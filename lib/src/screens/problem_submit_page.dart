import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;
import '../models/problem.dart';
import '../models/video.dart';
import '../api/video.dart';
import '../utils/color_schemes.dart';
import '../utils/color_codes.dart';
import '../widgets/video_overlay_player.dart';
import '../api/submission.dart';
import '../utils/navigation_helper.dart';
import '../utils/bottom_nav_tab.dart';
import '../utils/profile_refresh_manager.dart';

/// 문제 제출 페이지
class ProblemSubmitPage extends HookWidget {
  final Problem problem;
  final int? gymId;
  final String? initialSelectedVideoId;

  const ProblemSubmitPage({
    super.key,
    required this.problem,
    this.gymId,
    this.initialSelectedVideoId,
  });

  @override
  Widget build(BuildContext context) {
    // 선택된 영상 ID들 관리 (초기 선택 지원)
    final selectedVideoIds = useState<Set<String>>(
      initialSelectedVideoId != null && initialSelectedVideoId!.isNotEmpty
          ? {initialSelectedVideoId!}
          : {},
    );
    
    // 제출 중 상태 관리
    final isSubmitting = useState(false);
    
    // 업로드 중 상태 관리
    final isUploading = useState(false);
    
    // ImagePicker 인스턴스
    final picker = useMemoized(() => ImagePicker(), []);

    // 영상 목록 조회
    final videosQuery = useQuery<List<Video>, Exception>(
      ['user_videos'],
      VideoApi.getCurrentUserVideos,
    );

    // 로컬 업로드 중 영상들 (서버에 아직 반영되지 않은 항목)
    final localVideos = useState<List<Video>>([]);

    // 새로고침: 로컬 업로드 항목 초기화 후 서버 목록 요청
    void refreshVideos() {
      localVideos.value = [];
      videosQuery.refetch();
    }
    
    // 제출 버튼 활성화 여부
    final canSubmit = selectedVideoIds.value.isNotEmpty && !isSubmitting.value;

    // 영상 업로드 처리
    Future<void> handleVideoUpload(XFile pickedFile, String successMsg) async {
      final contextMounted = context.mounted;
      if (!contextMounted) return;

      try {
        isUploading.value = true;

        // 로컬 Video 항목 생성 및 목록에 추가 (업로드 전)
        final localVideo = Video.fromLocalFile(pickedFile.path);
        localVideos.value = [localVideo, ...localVideos.value];
        
        // 성공 메시지 표시
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(successMsg)),
          );
        }

        developer.log(
          '영상 업로드 시작: ${pickedFile.path}',
          name: 'ProblemSubmitPage',
        );

        // 실제 업로드 수행
        final videoId = await VideoApi.uploadVideo(
          filePath: pickedFile.path,
          onProgress: (progress) {
            // 로컬 항목의 진행률 업데이트
            final index = localVideos.value.indexWhere(
              (v) => v.localPath == pickedFile.path,
            );
            if (index != -1) {
              final uploadingVideo = localVideos.value[index].copyWith(
                isUploading: true,
                uploadProgress: progress,
              );
              final newList = List.of(localVideos.value);
              newList[index] = uploadingVideo;
              localVideos.value = newList;
            }
          },
        );

        developer.log('영상 업로드 완료: $videoId', name: 'ProblemSubmitPage');

        // 영상 업로드 성공 시 프로필 새로고침 플래그 설정
        await ProfileRefreshManager().setNeedsRefresh(true);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('영상 업로드가 완료되었습니다!'),
              backgroundColor: AppColorSchemes.accentGreen,
            ),
          );
        }

        // 영상 목록 새로고침 (서버 처리중 항목 반영) - 로컬 항목 정리 포함
        refreshVideos();
      } catch (e) {
        developer.log('영상 업로드 실패: $e', name: 'ProblemSubmitPage', error: e);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('영상 업로드 실패: $e'),
              backgroundColor: AppColorSchemes.accentRed,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        // 실패한 로컬 항목 제거
        localVideos.value = localVideos.value
            .where((v) => v.localPath != pickedFile.path)
            .toList();
      } finally {
        isUploading.value = false;
      }
    }

    // 비디오 촬영
    Future<void> recordVideo() async {
      try {
        // 카메라 권한 요청
        final cameraStatus = await Permission.camera.request();
        developer.log('카메라 권한 상태: $cameraStatus', name: 'ProblemSubmitPage');

        if (!cameraStatus.isGranted) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('카메라 접근 권한이 필요합니다.'),
                action: SnackBarAction(
                  label: '설정',
                  onPressed: () async {
                    final result = await openAppSettings();
                    developer.log(
                      '설정 페이지 열기: $result',
                      name: 'ProblemSubmitPage',
                    );
                  },
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }

        final XFile? video = await picker.pickVideo(
          source: ImageSource.camera,
          maxDuration: const Duration(minutes: 1),
        );

        if (video != null) {
          await handleVideoUpload(video, '촬영된 영상을 업로드 중입니다...');
        }
      } catch (e) {
        developer.log('비디오 촬영 실패: $e', name: 'ProblemSubmitPage', error: e);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('비디오 촬영 실패: $e'),
              backgroundColor: AppColorSchemes.accentRed,
            ),
          );
        }
      }
    }

    // 갤러리에서 영상 선택
    Future<void> selectFromGallery() async {
      try {
        final XFile? picked = await picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(minutes: 5),
        );

        if (picked != null) {
          await handleVideoUpload(picked, '선택된 영상을 업로드 중입니다...');
        }
      } catch (e) {
        developer.log(
          '갤러리 영상 선택 실패: $e',
          name: 'ProblemSubmitPage',
          error: e,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('갤러리 영상 선택 실패: $e'),
              backgroundColor: AppColorSchemes.accentRed,
            ),
          );
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColorSchemes.backgroundSecondary,
      appBar: AppBar(
        title: const Text('문제 제출'),
        backgroundColor: AppColorSchemes.backgroundPrimary,
        foregroundColor: AppColorSchemes.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 스크롤 영역 (문제 정보 + 영상 업로드 + 영상 리스트)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 상단: 문제 정보
                  _buildProblemInfo(),
                  
                  // 중간: 영상 업로드 버튼 + 영상 목록
          _buildVideoSection(
                    context,
                    videosQuery.data ?? [],
                    localVideos.value,
                    selectedVideoIds,
                    videosQuery.isLoading,
                    videosQuery.isError,
                    isUploading,
                    recordVideo,
                    selectFromGallery,
                    () => refreshVideos(), // 콜백 함수로 전달
                  ),
                ],
              ),
            ),
          ),
          
          // 하단: 제출 버튼 (고정)
          _buildSubmitButton(
            context,
            canSubmit,
            isSubmitting,
            selectedVideoIds,
          ),
        ],
      ),
    );
  }

  /// 문제 정보 위젯
  Widget _buildProblemInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorSchemes.backgroundPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColorSchemes.lightShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 문제 이미지
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColorSchemes.borderPrimary,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: _buildProblemImage(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 문제 정보
          Row(
            children: [
              _buildInfoCard('난이도', problem.localLevel),
              const SizedBox(width: 12),
              _buildInfoCard('홀드색', problem.holdColor),
            ],
          ),
        ],
      ),
    );
  }

  /// 문제 이미지 위젯
  Widget _buildProblemImage() {
    final Widget defaultImage = Container(
      color: AppColorSchemes.backgroundSecondary,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: AppColorSchemes.textTertiary,
        ),
      ),
    );

    if (problem.problemImageCdnUrl.isEmpty) {
      return defaultImage;
    }

    return Image.network(
      problem.problemImageCdnUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => defaultImage,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: AppColorSchemes.backgroundSecondary,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  /// 정보 카드 위젯
  Widget _buildInfoCard(String label, String value) {
    final normalized = ColorCodes.labelAndColorFromAny(value);
    final displayLabel = normalized?.$1 ?? value;
    final displayColor = normalized?.$2 ?? AppColorSchemes.accentBlue;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: displayColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: displayColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColorSchemes.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: displayColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  displayLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: displayColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 영상 섹션 위젯 (업로드 버튼 + 영상 목록)
  Widget _buildVideoSection(
    BuildContext context,
    List<Video> serverVideos,
    List<Video> localVideos,
    ValueNotifier<Set<String>> selectedVideoIds,
    bool isLoading,
    bool isError,
    ValueNotifier<bool> isUploading,
    VoidCallback onRecordVideo,
    VoidCallback onSelectFromGallery,
    VoidCallback onRefresh, // 콜백 함수로 변경
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 영상 업로드 버튼들
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColorSchemes.backgroundPrimary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColorSchemes.lightShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '영상 업로드',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColorSchemes.textPrimary,
                      ),
                    ),
                    // 새로고침 버튼
                    IconButton(
                      onPressed:
                          (isLoading || isUploading.value) ? null : onRefresh,
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: '목록 새로고침',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // 촬영하기 버튼
                    Expanded(
                      child: _buildUploadButton(
                        icon: Icons.videocam_outlined,
                        label: '촬영하기',
                        onTap: isUploading.value ? null : onRecordVideo,
                        isLoading: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 갤러리에서 선택 버튼
                    Expanded(
                      child: _buildUploadButton(
                        icon: Icons.photo_library_outlined,
                        label: '갤러리에서 선택',
                        onTap: isUploading.value ? null : onSelectFromGallery,
                        isLoading: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 영상 목록
          _buildVideoList(
            context,
            serverVideos,
            localVideos,
            selectedVideoIds,
            isLoading,
            isError,
          ),
        ],
      ),
    );
  }

  /// 업로드 버튼 위젯
  Widget _buildUploadButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required bool isLoading,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColorSchemes.accentBlue
              : AppColorSchemes.textTertiary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: onTap != null
                ? AppColorSchemes.accentBlue
                : AppColorSchemes.borderPrimary,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 영상 목록 위젯
  Widget _buildVideoList(
    BuildContext context,
    List<Video> serverVideos,
    List<Video> localVideos,
    ValueNotifier<Set<String>> selectedVideoIds,
    bool isLoading,
    bool isError,
  ) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (isError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('영상 목록을 불러올 수 없습니다'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // 새로고침 로직
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    // 서버+로컬 목록을 병합(로컬이 먼저)
    final allVideos = [
      ...localVideos,
      ...serverVideos,
    ];

    if (allVideos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: AppColorSchemes.textTertiary,
            ),
            SizedBox(height: 16),
            Text(
              '완료된 영상이 없습니다',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColorSchemes.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '영상을 업로드하고 처리가 완료되면\n여기서 선택할 수 있습니다',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColorSchemes.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: allVideos.asMap().entries.map((entry) {
        final video = entry.value;
        final isSelected = selectedVideoIds.value.contains(video.videoId);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildVideoItem(
            context,
            video,
            isSelected,
            (selected) {
              if (selected) {
                // 단일 선택: 라디오 동작으로 현재 선택만 유지
                selectedVideoIds.value = {video.videoId!};
              } else {
                // 선택 해제 시 비우기 (0개 선택 상태 허용)
                selectedVideoIds.value = {};
              }
            },
          ),
        );
      }).toList(),
    );
  }

  /// 영상 아이템 위젯
  Widget _buildVideoItem(
    BuildContext context,
    Video video,
    bool isSelected,
    Function(bool) onSelectionChanged,
  ) {
    final bool isSelectable = video.isCompleted && video.hasValidUrl && !video.isUploading;

    return GestureDetector(
      onTap: isSelectable ? () => onSelectionChanged(!isSelected) : null,
      child: Container(
        decoration: BoxDecoration(
          color: AppColorSchemes.backgroundPrimary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
              ? AppColorSchemes.accentBlue 
              : AppColorSchemes.borderPrimary,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: AppColorSchemes.lightShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 체크박스
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelectable
                        ? (isSelected
                            ? AppColorSchemes.accentBlue
                            : AppColorSchemes.borderPrimary)
                        : AppColorSchemes.borderPrimary,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColorSchemes.accentBlue,
                          ),
                        ),
                      )
                    : null,
              ),
              
              const SizedBox(width: 12),
              
              // 썸네일/상태 (업로드중/서버 처리중/썸네일)
              Container(
                width: 80,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColorSchemes.borderPrimary,
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: video.isUploading
                      ? _buildStatusCell(context, '업로드중')
                      : (video.isPending || video.isProcessing)
                          ? _buildStatusCell(context, '서버 처리중')
                          : video.getThumbnailWidget(
                              width: 80,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 영상 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColorSchemes.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${video.formattedDuration} • ${video.createdAt.toString().split(' ')[0]}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColorSchemes.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 재생 버튼 (업로드중/처리중일 때는 disabled)
              IconButton(
                onPressed: (video.isUploading || video.isPending || video.isProcessing)
                    ? null
                    : () => _onVideoTap(context, video),
                icon: const Icon(
                  Icons.play_circle_outline,
                  color: AppColorSchemes.accentBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCell(BuildContext context, String label) {
    return Container(
      color: AppColorSchemes.backgroundSecondary,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColorSchemes.accentBlue,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColorSchemes.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 영상 재생
  void _onVideoTap(BuildContext context, Video video) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (BuildContext context) {
        return VideoOverlayPlayer(
          video: video,
          showSubmitButton: false, // 제출 페이지에서는 제출 버튼 숨기기
          tierColors: null, // 기본 색상 사용
        );
      },
    );
  }

  /// 제출 버튼 위젯
  Widget _buildSubmitButton(
    BuildContext context,
    bool canSubmit,
    ValueNotifier<bool> isSubmitting,
    ValueNotifier<Set<String>> selectedVideoIds,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorSchemes.backgroundPrimary,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canSubmit ? () => _handleSubmit(
              context,
              isSubmitting,
              selectedVideoIds,
            ) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canSubmit 
                ? AppColorSchemes.accentBlue 
                : AppColorSchemes.textTertiary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isSubmitting.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    '제출하기 (${selectedVideoIds.value.length}개 선택)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  /// 제출 처리
  Future<void> _handleSubmit(
    BuildContext context,
    ValueNotifier<bool> isSubmitting,
    ValueNotifier<Set<String>> selectedVideoIds,
  ) async {
    if (selectedVideoIds.value.isEmpty) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColorSchemes.backgroundPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: const Row(
          children: [
            Icon(Icons.outbox_rounded, color: AppColorSchemes.accentBlue),
            SizedBox(width: 8),
            Text(
              '제출하시겠습니까?',
              style: TextStyle(
                color: AppColorSchemes.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            '선택한 영상으로 문제를 제출합니다.',
            style: TextStyle(
              color: AppColorSchemes.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColorSchemes.textSecondary,
              side: const BorderSide(color: AppColorSchemes.borderPrimary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            child: const Text('아니요'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorSchemes.accentBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            child: const Text('네'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    isSubmitting.value = true;

    try {
      final String videoId = selectedVideoIds.value.first;
      await SubmissionApi.submit(
        videoId: videoId,
        // 서버 스펙에 따라 problemId가 정수형일 경우 변환 필요
        problemId: problem.problemId,
      );

      // 풀이 제출 성공 시 프로필 새로고침 플래그 설정
      await ProfileRefreshManager().setNeedsRefresh(true);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('제출이 완료되었습니다!'),
            backgroundColor: AppColorSchemes.accentGreen,
          ),
        );

        // 검색 탭으로 이동
        NavigationHelper.navigateToMainWithTab(context, BottomNavTab.search);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('제출 실패: $e'),
            backgroundColor: AppColorSchemes.accentRed,
          ),
        );
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  // 색상 계산은 ColorCodes에서 처리함
} 