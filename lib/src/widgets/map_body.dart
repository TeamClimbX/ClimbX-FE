import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'dart:developer' as developer;
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/gym.dart';
import '../models/gym.dart';
import '../utils/color_schemes.dart';
import '../utils/tier_colors.dart';
import '../utils/navigation_helper.dart';
import '../utils/analytics_helper.dart';

class MapBody extends HookWidget {
  final bool isGuestMode;
  
  const MapBody({
    super.key,
    this.isGuestMode = false,
  });

  @override
  Widget build(BuildContext context) {
    // GA 이벤트 로깅
    useEffect(() {
      AnalyticsHelper.visitMap();
      return null;
    }, []);

    final controller = useState<NaverMapController?>(null);
    final searchController = useTextEditingController();
    final searchFocusNode = useFocusNode();
    final searchQuery = useState<String>('');
    final isSearching = useState<bool>(false);
    final debounceTimer = useRef<Timer?>(null);

    // useQuery 효과를 위한 커스텀 hook
    final gymsQuery = useFuture(
      useMemoized(() {
        if (searchQuery.value.trim().isEmpty) {
          return GymApi.getAllGyms();
        } else {
          return GymApi.searchGymsByKeyword(searchQuery.value.trim());
        }
      }, [searchQuery.value]),
    );

    final gyms = gymsQuery.data ?? <Gym>[];
    final isLoading = gymsQuery.connectionState == ConnectionState.waiting;

    // 커스텀 마커 아이콘 생성 함수
    final createCustomMarkerIcon = useCallback((String gymName) async {
      return await NOverlayImage.fromWidget(
        widget: SizedBox(
          width: 80,
          height: 70,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 마커 아이콘
              Icon(
                Icons.location_on,
                color: AppColorSchemes.accentOrange, // 주황색 고정
                size: 40,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              // 클라이밍장 이름
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  gymName,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColorSchemes.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        size: const Size(80, 70),
        context: context,
      );
    }, []);

    // 바텀시트 표시 함수
    final showGymDetailBottomSheet = useCallback((Gym gym) {
      final rootContext = context;
      showModalBottomSheet(
        context: rootContext,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          // 화면 높이를 기준으로 초기 바텀시트 높이를 계산하여
          // 이미지+이름(주소)+전화까지만 보이도록 조정
          return DraggableScrollableSheet(
            initialChildSize: _computeInitialSheetSize(sheetContext),
            minChildSize: (_computeInitialSheetSize(sheetContext) - 0.05).clamp(
              0.25,
              0.8,
            ),
            maxChildSize: 0.9,
            expand: false,
            builder: (draggableContext, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    // 핸들
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 상단 이미지 영역 지금은 map2dImageCdnUrl 사용
                            Container(
                              width: double.infinity,
                              height: 200,
                              margin: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: (gym.map2dImageCdnUrl.isNotEmpty)
                                  ? Image.network(
                                      gym.map2dImageCdnUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.image,
                                              size: 48,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '클라이밍장 사진',
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        );
                                      },
                                    )
                                  : Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image,
                                            size: 48,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '클라이밍장 사진',
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),

                            // 클라이밍장 정보 영역 주소/전화만 표시
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 클라이밍장 이름
                                  Text(
                                    gym.name,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColorSchemes.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // 주소
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 18,
                                        color: AppColorSchemes.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          gym.address,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color:
                                                AppColorSchemes.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // 전화번호
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone,
                                        size: 18,
                                        color: AppColorSchemes.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () async {
                                          AnalyticsHelper.clickPhoneNumber(gym.gymId);
                                          
                                          final String raw = gym.phoneNumber.trim();
                                          if (raw.isEmpty) return;
                                          final String digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
                                          final Uri telUri = Uri(scheme: 'tel', path: digits);
                                          try {
                                            final bool ok = await launchUrl(
                                              telUri,
                                              mode: LaunchMode.externalApplication,
                                            );
                                            if (!ok) {
                                              developer.log('전화 연결 실패: $telUri', name: 'MapBody');
                                            }
                                          } catch (e) {
                                            developer.log('전화 연결 중 오류: $e', name: 'MapBody');
                                          }
                                        },
                                        child: Text(
                                          gym.phoneNumber,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColorSchemes.accentBlue,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  // 표준 난이도 분포 섹션
                                  const Text(
                                    '표준 난이도 분포',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColorSchemes.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                    child: _buildDifficultyChart(),
                                  ),
                                  const SizedBox(height: 16),

                                  // 문제 보기 버튼 (표준 난이도 분포 아래)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        AnalyticsHelper.clickProblemSearch(gym.gymId);
                                        
                                        // 바텀시트 닫기
                                        Navigator.of(sheetContext).pop();
                                        
                                        // MapBody 컨텍스트로 네비게이션 실행
                                        if (!rootContext.mounted) return;
                                        NavigationHelper.navigateToSearchWithGym(
                                          rootContext,
                                          gym.gymId,
                                          isGuestMode: isGuestMode,
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.search,
                                        color: Colors.white,
                                      ),
                                      label: const Text('이 지점 문제 보기'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColorSchemes.accentBlue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }, []);

    // 마커 추가 함수
    final addMarkersToMap = useCallback((
      NaverMapController mapController,
      List<Gym> gymList,
    ) async {
      if (gymList.isEmpty) return;

      try {
        // 기존 마커 제거
        await mapController.clearOverlays();

        // 각 클라이밍장을 마커로 병렬 추가
        await Future.wait(
          gymList.map((gym) async {
            // 각 클라이밍장마다 개별 마커 아이콘 생성
            final markerIcon = await createCustomMarkerIcon(gym.name);

            final marker = NMarker(
              id: 'gym_${gym.gymId}',
              position: NLatLng(gym.latitude, gym.longitude),
              icon: markerIcon, // 클라이밍장 이름이 포함된 커스텀 마커
            );

            // 마커 클릭 이벤트
            marker.setOnTapListener((NMarker marker) {
              AnalyticsHelper.clickMarker(gym.gymId);
              showGymDetailBottomSheet(gym);
            });

            // 마커 추가
            await mapController.addOverlay(marker);
          }),
        );

        developer.log('${gymList.length}개 이름 포함 마커 추가 완료', name: 'MapBody');
      } catch (e) {
        developer.log('마커 추가 중 오류: $e', name: 'MapBody');
      }
    }, [createCustomMarkerIcon, showGymDetailBottomSheet]);

    // 위치 권한 요청 함수
    Future<void> requestLocationPermission() async {
      final currentContext = context;

      try {
        final status = await Permission.location.status;
        if (status.isDenied) {
          await Permission.location.request();
        } else if (status.isPermanentlyDenied) {
          if (!currentContext.mounted) return;

          // 사용자에게 권한이 영구적으로 거부되었음을 알리고 설정으로 이동하도록 안내
          await showDialog(
            context: currentContext,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text('위치 권한 필요'),
                content: const Text(
                  '지도 기능을 사용하려면 위치 권한이 필요합니다. 설정에서 권한을 허용해주세요.',
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('설정으로 이동'),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      openAppSettings();
                    },
                  ),
                  TextButton(
                    child: const Text('취소'),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
      } catch (e) {
        developer.log('위치 권한 요청 중 오류: $e', name: 'MapBody');
      }
    }

    // 마커 추가 useEffect
    useEffect(() {
      if (controller.value != null && gyms.isNotEmpty) {
        addMarkersToMap(controller.value!, gyms);
      }
      return null;
    }, [controller.value, gyms, addMarkersToMap]);

    // 포커스 리스너 useEffect
    useEffect(() {
      void onFocusChange() {
        isSearching.value = searchFocusNode.hasFocus;
      }

      searchFocusNode.addListener(onFocusChange);
      return () => searchFocusNode.removeListener(onFocusChange);
    }, [searchFocusNode]);

    // 디바운스 정리 useEffect
    useEffect(() {
      return () => debounceTimer.value?.cancel();
    }, []);

    // 검색 디바운스 함수
    void onSearchChanged(String value) {
      debounceTimer.value?.cancel();
      debounceTimer.value = Timer(const Duration(milliseconds: 500), () {
        searchQuery.value = value;
      });
    }

    return Stack(
      children: [
        // 네이버 지도 (배경)
        NaverMap(
          options: const NaverMapViewOptions(
            // 서울 중심으로 설정 - 서울이 한 화면에 들어오도록 줌 조정
            initialCameraPosition: NCameraPosition(
              target: NLatLng(37.5665, 126.9780),
              zoom: 10, // 서울 전체가 보이도록 줌 레벨 낮춤
            ),
            mapType: NMapType.basic,
            activeLayerGroups: [NLayerGroup.building, NLayerGroup.transit],
            // 줌 레벨 제한 설정
            minZoom: 8,
            // 최소 줌 (더 멀리)
            maxZoom: 20,
            // 최대 줌 (더 가까이)
            // 위치 권한 활성화
            locationButtonEnable: true,
            // 1.4.1+1 버전에서 추가된 contentPadding 설정
            contentPadding: EdgeInsets.zero,
          ),
          onMapReady: (NaverMapController mapController) {
            controller.value = mapController;
            // 지도가 준비되면 위치 권한 요청
            requestLocationPermission();
            // 컨트롤러로 위치 추적 모드 활성화
            mapController.setLocationTrackingMode(NLocationTrackingMode.follow);
          },
        ),

        // 로딩 인디케이터
        if (isLoading) const Center(child: CircularProgressIndicator()),

        // 상단 검색바
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              focusNode: searchFocusNode,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: '주변 클라이밍장 찾기',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 24),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          searchController.clear();
                          searchQuery.value = '';
                          searchFocusNode.unfocus();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 0,
                ),
                isDense: true,
              ),
              onSubmitted: (value) {
                searchQuery.value = value;
                searchFocusNode.unfocus();
              },
              onChanged: onSearchChanged,
            ),
          ),
        ),

        // 클라이밍장 개수 표시
        if (!isSearching.value)
          Positioned(
            top: 80,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                '클라이밍장 ${gyms.length}개',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),

        // 검색 결과 오버레이
        if (isSearching.value && gyms.isNotEmpty)
          Positioned(
            top: 76, // 검색바 아래
            left: 16,
            right: 16,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(
                  maxHeight: 180, // 약 3칸 높이
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: gyms.length,
                  itemBuilder: (context, index) {
                    final gym = gyms[index];
                    return ListTile(
                      title: Text(
                        gym.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColorSchemes.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        gym.address,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColorSchemes.textSecondary,
                        ),
                      ),
                      onTap: () {
                        AnalyticsHelper.clickMarker(gym.gymId);
                        searchController.text = gym.name;
                        searchQuery.value = gym.name;
                        searchFocusNode.unfocus();
                        showGymDetailBottomSheet(gym);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  // 바텀시트 초기 높이 계산: 이미지(200) + 여백/텍스트들을 고려한 고정 픽셀을 비율로 환산
  double _computeInitialSheetSize(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    // UI 구성 요소 높이 추정치 (레이아웃 변경 시 함께 수정 필요)
    const double handleHeight = 24;
    const double imageHeightWithMargin = 200 + 32; // 이미지 높이 + 상하 마진
    const double nameHeight = 28;
    const double addressHeight = 22;
    const double phoneHeight = 22;
    const double contentSpacing = 12 + 8 + 24; // 이름-주소, 주소-전화, 전화-하단 간격
    const double safetyPadding = 8; // 추가 여유 공간

    const double estimatedContentHeight =
        handleHeight +
        imageHeightWithMargin +
        nameHeight +
        addressHeight +
        phoneHeight +
        contentSpacing +
        safetyPadding;

    // 화면 대비 비율로 환산 (최소/최대 범위 클램프)
    return (estimatedContentHeight / screenHeight).clamp(0.3, 0.6);
  }

  /// 난이도 분포 차트 빌드
  Widget _buildDifficultyChart() {
    // 우리 표준 티어 시스템 (위에서 아래로: M -> B3)
    final tiers = [
      'M',
      'D1',
      'D2',
      'D3',
      'P1',
      'P2',
      'P3',
      'G1',
      'G2',
      'G3',
      'S1',
      'S2',
      'S3',
      'B1',
      'B2',
      'B3',
    ];

    // 클라이밍장 색깔 난이도와 우리 티어 매핑 (더미 데이터)
    final gymColorGrades = [
      {'name': '흰색', 'color': Colors.white, 'startTier': 'B3', 'endTier': 'B2'},
      {
        'name': '노란색',
        'color': Colors.yellow,
        'startTier': 'B2',
        'endTier': 'B1',
      },
      {
        'name': '주황색',
        'color': Colors.orange,
        'startTier': 'B1',
        'endTier': 'S3',
      },
      {
        'name': '초록색',
        'color': Colors.green,
        'startTier': 'S3',
        'endTier': 'G3',
      },
      {'name': '파란색', 'color': Colors.blue, 'startTier': 'G3', 'endTier': 'P3'},
      {'name': '빨간색', 'color': Colors.red, 'startTier': 'P3', 'endTier': 'P1'},
      {
        'name': '보라색',
        'color': Colors.purple,
        'startTier': 'P1',
        'endTier': 'D3',
      },
      {'name': '회색', 'color': Colors.grey, 'startTier': 'D3', 'endTier': 'D1'},
      {'name': '갈색', 'color': Colors.brown, 'startTier': 'D1', 'endTier': 'M'},
    ];

    return Container(
      height: 500,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          // 왼쪽 티어 라벨들
          SizedBox(
            width: 40,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: tiers.map((tier) {
                return SizedBox(
                  height: 26,
                  child: Text(
                    tier,
                    style: TextStyle(
                      color: _getTierColorForMap(tier),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(width: 8),

          // 차트 영역 - 가로선들과 색깔 컬럼들
          Expanded(
            child: Stack(
              children: [
                // 가로선들
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: tiers.map((tier) {
                    return SizedBox(
                      height: 26,
                      child: Container(
                        height: 1,
                        color: Colors.grey[300],
                        margin: const EdgeInsets.symmetric(vertical: 12.5),
                      ),
                    );
                  }).toList(),
                ),

                // 색깔별 개별 컬럼들
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: gymColorGrades.map((colorGrade) {
                    return SizedBox(
                      width: 24, // 고정 너비
                      child: _buildColorColumn(
                        colorGrade['color'] as Color,
                        colorGrade['startTier'] as String,
                        colorGrade['endTier'] as String,
                        tiers,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 색깔별 컬럼 빌드
  Widget _buildColorColumn(
    Color color,
    String startTier,
    String endTier,
    List<String> tiers,
  ) {
    final startIndex = tiers.indexOf(startTier);
    final endIndex = tiers.indexOf(endTier);

    if (startIndex == -1 || endIndex == -1) return Container();

    final minIndex = startIndex < endIndex ? startIndex : endIndex;
    final maxIndex = startIndex > endIndex ? startIndex : endIndex;

    // 전체 높이를 부모 컨테이너의 높이에 따라 동적으로 계산
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight - 24; // 24 padding
        final tierHeight = totalHeight / 16;

        // 각 영역 높이 계산
        final topSpaceHeight = minIndex * tierHeight;
        final rangeBoxHeight = (maxIndex - minIndex + 1) * tierHeight;
        final bottomSpaceHeight = (15 - maxIndex) * tierHeight;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          child: Column(
            children: [
              // 상단 여백
              SizedBox(height: topSpaceHeight),

              // 범위 박스
              Container(
                width: double.infinity,
                height: rangeBoxHeight,
                decoration: BoxDecoration(
                  color: color == Colors.white
                      ? Colors.grey[100]!.withValues(alpha: 0.9)
                      : color.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: color == Colors.white
                      ? Border.all(color: Colors.grey[400]!, width: 1)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),

              // 하단 여백
              SizedBox(height: bottomSpaceHeight),
            ],
          ),
        );
      },
    );
  }

  /// 지도용 티어 색상 반환 함수
  Color _getTierColorForMap(String tier) {
    if (tier.startsWith('B')) {
      return TierColors.getColorScheme(TierType.bronze).primary;
    } else if (tier.startsWith('S')) {
      return TierColors.getColorScheme(TierType.silver).primary;
    } else if (tier.startsWith('G')) {
      return TierColors.getColorScheme(TierType.gold).primary;
    } else if (tier.startsWith('P')) {
      return TierColors.getColorScheme(TierType.platinum).primary;
    } else if (tier.startsWith('D')) {
      return TierColors.getColorScheme(TierType.diamond).primary;
    } else if (tier == 'M') {
      return TierColors.getColorScheme(TierType.master).primary;
    }
    return Colors.grey; // 기본값
  }
}
