import 'package:flutter/material.dart';
import '../api/problem.dart';
import '../api/gym.dart';
import '../models/problem.dart';
import '../models/gym.dart';
import '../utils/color_schemes.dart';
import 'problem_grid_item.dart';
import 'search_filter_dropdown.dart';
import '../screens/problem_create_page.dart';
import '../screens/problem_submit_page.dart';
import '../utils/color_codes.dart';
import 'gym_area_map_overlay.dart';

/// 검색 탭 메인 위젯
class SearchBody extends StatefulWidget {
  const SearchBody({super.key, this.initialGymId, this.submissionVideoId});

  final int? initialGymId;
  final String? submissionVideoId; // 제출 모드: 영상 id 전달받으면 활성화

  @override
  State<SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends State<SearchBody> {
  // 검색 관련 상태
  final TextEditingController _searchController = TextEditingController();
  List<Gym> _gyms = [];
  List<Gym> _filteredGyms = [];
  Gym? _selectedGym;
  bool _isSearching = false;

  // 필터 관련 상태
  String? _selectedLocalLevel;
  String? _selectedHoldColor;
  List<GymArea> _gymAreas = [];
  int? _selectedAreaId;

  // 문제 리스트 상태
  List<Problem> _problems = [];
  bool _isLoading = false;

  // 사용 가능한 필터 옵션 (서버의 HoldColorType과 동일)
  static List<String> get localLevelOptions => ColorCodes.localLevelOptions;
  static List<String> get holdColorOptions => ColorCodes.holdColorOptions;

  @override
  void initState() {
    super.initState();
    _loadGyms();
  }

  @override
  void didUpdateWidget(covariant SearchBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // MainPage에서 initialGymId가 변경되어 전달되면 프리필 반영
    if (widget.initialGymId != null && widget.initialGymId != oldWidget.initialGymId) {
      final targetGymId = widget.initialGymId!;
      final maybeGym = _gyms.where((g) => g.gymId == targetGymId).toList();
      if (maybeGym.isNotEmpty) {
        setState(() {
          _selectedGym = maybeGym.first;
          _searchController.text = maybeGym.first.name;
          _isSearching = false;
        });
        _loadProblems();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 클라이밍장 목록 로드
  Future<void> _loadGyms() async {
    try {
      final gyms = await GymApi.getAllGyms();
      if (!mounted) return;
      setState(() {
        _gyms = gyms;
        _filteredGyms = gyms;
      });
      
      // 초기 지점 프리필 처리
      final int? initialId = widget.initialGymId;
      if (initialId != null) {
        Gym? preselected;
        try {
          preselected = gyms.firstWhere((g) => g.gymId == initialId);
        } catch (_) {
          // 해당 gym이 없으면 null 유지
        }
        if (preselected != null) {
          setState(() {
            _selectedGym = preselected;
            _searchController.text = preselected!.name;
            _isSearching = false;
          });
          await _loadGymAreas(preselected.gymId);
        }
      }

      // 초기 문제 목록 로드
      await _loadProblems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('클라이밍장 목록을 불러오는 데 실패했습니다: $e')),
        );
        if (!mounted) return;
        setState(() {
          _gyms = [];
          _filteredGyms = [];
        });
      }
    }
  }

  /// 문제 목록 로드
  Future<void> _loadProblems() async {
    if (_isLoading) return; // 중복 요청 방지
    setState(() {
      _isLoading = true;
    });

    try {
      final problems = await ProblemApi.getProblems(
        gymId: _selectedGym?.gymId,
        gymAreaId: _selectedAreaId,
        localLevel: _selectedLocalLevel,
        holdColor: _selectedHoldColor,
      );

      if (!mounted) return;
      setState(() {
        _problems = problems;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('문제 목록을 불러오는 데 실패했습니다: $e')),
        );
        if (!mounted) return;
        setState(() {
          _problems = [];
          _isLoading = false;
        });
      }
    }
  }

  /// 검색어 변경 처리
  void _onSearchChanged(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredGyms = _gyms;
      } else {
        _filteredGyms = _gyms
            .where(
              (gym) => gym.name.toLowerCase().contains(query.toLowerCase()),
            )
            .take(3) // 상위 3개만 표시
            .toList();
      }
    });
  }

  /// 검색어 초기화
  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _isSearching = false;
      _filteredGyms = _gyms;
      _selectedGym = null; // 선택된 클라이밍장도 초기화
      _gymAreas = [];
      _selectedAreaId = null;
    });
    _loadProblems(); // X 버튼 클릭 시에도 문제 목록 다시 로드
  }

  /// 클라이밍장 선택 처리
  void _onGymSelected(Gym gym) {
    setState(() {
      _selectedGym = gym;
      _searchController.text = gym.name;
      _isSearching = false;
      _gymAreas = [];
      _selectedAreaId = null;
    });
    _loadGymAreas(gym.gymId);
    _loadProblems();
  }

  /// 선택된 클라이밍장의 gymId 반환
  int? get selectedGymId => _selectedGym?.gymId;

  /// 난이도 필터 변경 처리
  void _onLocalLevelChanged(String? localLevel) {
    setState(() {
      _selectedLocalLevel = localLevel;
    });
    _loadProblems();
  }

  /// 홀드색 필터 변경 처리
  void _onHoldColorChanged(String? holdColor) {
    setState(() {
      _selectedHoldColor = holdColor;
    });
    _loadProblems();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 메인 컨텐츠
        CustomScrollView(
          slivers: [
            // 검색바
            SliverToBoxAdapter(child: _buildSearchBar()),

            // 지도 오버레이 (지점 선택 시 표시 - areas 데이터가 있을 때만)
            if (_selectedGym != null && _selectedGym!.map2dImageCdnUrl.isNotEmpty && _gymAreas.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: GymAreaMapOverlay(
                        mapImageUrl: _selectedGym!.map2dImageCdnUrl,
                        areas: _gymAreas,
                        selectedAreaId: _selectedAreaId,
                        onSelected: (id) {
                          setState(() => _selectedAreaId = id);
                          _loadProblems();
                        },
                        selectedOpacity: 0.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              )
            else if (_selectedGym != null && _selectedGym!.map2dImageCdnUrl.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // areas 로딩 중일 때는 PNG만 표시
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        _selectedGym!.map2dImageCdnUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

            // 필터 토글
            SliverToBoxAdapter(child: _buildFilterSection()),

            // 필터와 리스트 사이 간격
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // 문제 리스트
            _buildProblemListSliver(),
          ],
        ),

        // 검색 결과 오버레이
        if (_isSearching && _filteredGyms.isNotEmpty)
          _buildSearchOverlay(),

        // 우하단 FAB - 문제 등록
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () async {
              // 문제 등록 페이지로 이동 (제출 모드면 videoId도 전달)
              final created = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProblemCreatePage(
                    initialGymId: selectedGymId,
                    pendingVideoId: widget.submissionVideoId,
                  ),
                ),
              );
              if (created == true) {
                _loadProblems();
              }
            },
            backgroundColor: AppColorSchemes.accentBlue,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  /// 검색바 위젯
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColorSchemes.backgroundPrimary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColorSchemes.lightShadow,
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: '클라이밍장을 검색하세요',
            hintStyle: const TextStyle(
              color: AppColorSchemes.textTertiary,
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: AppColorSchemes.textSecondary,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: AppColorSchemes.textSecondary,
                    ),
                    onPressed: _clearSearch,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }

  /// 검색 결과 오버레이 위젯
  Widget _buildSearchOverlay() {
    return Positioned(
      top: 80, // 검색바 아래에 위치
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColorSchemes.backgroundPrimary,
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
            itemCount: _filteredGyms.length,
            itemBuilder: (context, index) {
              final gym = _filteredGyms[index];
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
                onTap: () => _onGymSelected(gym),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 필터 섹션 위젯
  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedGym != null) ...[
            _buildAreaButtons(),
            const SizedBox(height: 8),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // 난이도색 필터
              SearchFilterDropdown(
                title: '난이도색',
                options: localLevelOptions,
                selectedOption: _selectedLocalLevel,
                onOptionSelected: _onLocalLevelChanged,
              ),

              const SizedBox(width: 8), // 간격 축소
              // 홀드색 필터
              SearchFilterDropdown(
                title: '홀드색',
                options: holdColorOptions,
                selectedOption: _selectedHoldColor,
                onOptionSelected: _onHoldColorChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 영역 버튼 위젯 (간단한 버튼 리스트)
  Widget _buildAreaButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildAreaChip(null, '전체'),
          const SizedBox(width: 6),
          ..._gymAreas.map((a) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _buildAreaChip(a.areaId, a.areaName),
              )),
        ],
      ),
    );
  }

  Widget _buildAreaChip(int? areaId, String label) {
    final bool selected = _selectedAreaId == areaId || (_selectedAreaId == null && areaId == null);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) {
        setState(() {
          _selectedAreaId = areaId;
        });
        _loadProblems();
      },
      backgroundColor: Colors.white,
      selectedColor: AppColorSchemes.accentBlue.withValues(alpha: 0.12),
      side: BorderSide(
        color: selected ? AppColorSchemes.accentBlue : AppColorSchemes.borderPrimary,
      ),
      labelStyle: TextStyle(
        color: selected ? AppColorSchemes.accentBlue : AppColorSchemes.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  /// 영역 목록 로드
  Future<void> _loadGymAreas(int gymId) async {
    try {
      final detail = await GymApi.getGymById(gymId);
      if (!mounted) return;
      setState(() {
        _gymAreas = detail.gymAreas;
        if (_gymAreas.where((a) => a.areaId == _selectedAreaId).isEmpty) {
          _selectedAreaId = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _gymAreas = [];
        _selectedAreaId = null;
      });
    }
  }

  /// 문제 리스트 Sliver 위젯
  Widget _buildProblemListSliver() {
    if (_isLoading) {
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_problems.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6, // 화면 높이의 60%
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              const Icon(
                Icons.search_off,
                size: 48,
                color: AppColorSchemes.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                (_selectedGym == null && _selectedLocalLevel == null && _selectedHoldColor == null) 
                    ? '클라이밍장을 선택하거나 조건을 설정해주세요' 
                    : '조건에 맞는 문제가 없습니다',
                style: const TextStyle(
                  color: AppColorSchemes.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  final created = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProblemCreatePage(
                        initialGymId: selectedGymId,
                      ),
                    ),
                  );
                  if (created == true) {
                    _loadProblems();
                  }
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('문제 등록하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorSchemes.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2열
          crossAxisSpacing: 12, // 가로 간격
          mainAxisSpacing: 16, // 세로 간격
          childAspectRatio: 0.8, // 아이템 비율 (세로가 더 길게)
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final p = _problems[index];
            return ProblemGridItem(
              problem: p,
              gymId: selectedGymId,
              onTapOverride: widget.submissionVideoId != null
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ProblemSubmitPage(
                            problem: p,
                            gymId: selectedGymId,
                            initialSelectedVideoId: widget.submissionVideoId,
                          ),
                        ),
                      );
                    }
                  : null,
            );
          },
          childCount: _problems.length,
        ),
      ),
    );
  }

}
