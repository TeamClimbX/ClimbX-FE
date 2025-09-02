import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api/gym.dart';
import '../api/problem.dart';
import '../utils/color_codes.dart';
import '../models/gym.dart';
import '../utils/color_schemes.dart';
import '../utils/image_compressor.dart';
import '../widgets/gym_area_map_overlay.dart';
import '../utils/profile_refresh_manager.dart';

/// 문제 등록 페이지
class ProblemCreatePage extends StatefulWidget {
  const ProblemCreatePage({
    super.key,
    this.initialGymId,
    this.pendingVideoId,
  });

  /// 진입 시 선택되어 있던 지점이 있다면 초기값으로 사용
  final int? initialGymId;
  /// 영상에서 넘어온 videoId (등록 성공 시 제출 페이지로 이어붙이기 위함)
  final String? pendingVideoId;

  @override
  State<ProblemCreatePage> createState() => _ProblemCreatePageState();
}

class _ProblemCreatePageState extends State<ProblemCreatePage> {
  // 상태
  List<Gym> _gyms = [];
  Gym? _selectedGym;
  int? _areaId; // 1~4
  List<GymArea> _gymAreas = [];
  String? _holdColor;
  String? _localLevel;
  File? _imageFile;

  bool _isLoadingGyms = false;
  bool _isSubmitting = false;
  bool _isLoadingGymDetail = false;

  // 색상 옵션
  static const List<String> _colorOptions = [
    '흰색', '노랑', '주황', '초록', '파랑', 
    '빨강', '보라', '회색', '갈색', '검정'
  ];

  @override
  void initState() {
    super.initState();
    _loadGyms();
  }

  Widget _buildAreaChipsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final a in _gymAreas)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(a.areaName),
                selected: _areaId == a.areaId,
                showCheckmark: false,
                onSelected: (_) => setState(() => _areaId = a.areaId),
                backgroundColor: Colors.white,
                selectedColor: AppColorSchemes.accentBlue.withValues(alpha: 0.12),
                side: BorderSide(
                  color: _areaId == a.areaId ? AppColorSchemes.accentBlue : AppColorSchemes.borderPrimary,
                ),
                labelStyle: TextStyle(
                  color: _areaId == a.areaId ? AppColorSchemes.accentBlue : AppColorSchemes.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _loadGyms() async {
    setState(() {
      _isLoadingGyms = true;
    });
    try {
      final gyms = await GymApi.getAllGyms();
      if (!mounted) return;
      setState(() {
        _gyms = gyms;
        if (widget.initialGymId != null && gyms.isNotEmpty) {
          final matched = gyms.where((g) => g.gymId == widget.initialGymId);
          if (matched.isNotEmpty) {
            _selectedGym = matched.first;
          }
        }
      });
      if (_selectedGym != null) {
        if (!mounted) return;
        setState(() {
          _isLoadingGymDetail = true;
        });
        await _loadGymDetail(_selectedGym!.gymId);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('클라이밍장 목록을 불러오지 못했습니다: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingGyms = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 100);
      if (picked == null) return;

      // 5MB 이하로 압축
      final compressed = await compressUnder5MB(File(picked.path));
      if (!mounted) return;
      setState(() {
        _imageFile = compressed;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택/압축에 실패했습니다: $e')),
      );
    }
  }

  bool get _canSubmit {
    return _selectedGym != null &&
        _areaId != null &&
        _holdColor != null &&
        _localLevel != null &&
        _imageFile != null &&
        !_isSubmitting;
  }

  Future<void> _handleSubmit() async {
    if (!_canSubmit) return;
    setState(() {
      _isSubmitting = true;
    });
    try {
      await ProblemApi.createProblem(
        gymAreaId: _areaId!,
        localLevelColor: ColorCodes.koreanLabelToServerCode(_localLevel),
        holdColor: ColorCodes.koreanLabelToServerCode(_holdColor),
        imageFile: _imageFile!,
      );

      // 문제 등록 성공 시 프로필 새로고침 플래그 설정
      await ProfileRefreshManager().setNeedsRefresh(true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('문제가 등록되었습니다.'),
          backgroundColor: AppColorSchemes.accentGreen,
        ),
      );

      // 생성된 문제 정보를 반환하도록 백엔드가 지원하면 해당 Problem을 pop으로 반환
      // 현재는 true만 반환. 호출자(SearchBody)에서 후속 라우팅 처리
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('문제 등록 실패: $e'),
          backgroundColor: AppColorSchemes.accentRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorSchemes.backgroundPrimary,
      appBar: AppBar(
        title: const Text('문제 등록'),
        backgroundColor: AppColorSchemes.backgroundPrimary,
        foregroundColor: AppColorSchemes.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1) 사진 선택 (최상단)
              _buildSectionTitle('문제 사진'),
              const SizedBox(height: 8),
              _buildImagePickerTopCard(),
              const SizedBox(height: 20),

              // 2) 지점 선택 (화이트 바텀시트 피커)
              _buildSectionTitle('지점'),
              const SizedBox(height: 8),
              _buildGymSelectorCard(),
              const SizedBox(height: 20),

              _buildSectionTitle('영역 선택'),
              const SizedBox(height: 8),
              if (_isLoadingGymDetail)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: _cardDecoration(),
                  child: const Center(child: CircularProgressIndicator()),
                )
              else if (_selectedGym != null && (_selectedGym!.map2dImageCdnUrl.isNotEmpty))
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: _cardDecoration(),
                  child: GymAreaMapOverlay(
                    mapImageUrl: _selectedGym!.map2dImageCdnUrl,
                    areas: _gymAreas,
                    selectedAreaId: _areaId,
                    onSelected: (id) {
                      setState(() => _areaId = id);
                    },
                    showAllWhenUnselected: false,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: _cardDecoration(),
                  child: const Text(
                    '지점을 먼저 선택하세요',
                    style: TextStyle(color: AppColorSchemes.textSecondary),
                  ),
                ),
              if (_gymAreas.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildAreaChipsRow(),
              ],
              const SizedBox(height: 20),

              _buildSectionTitle('홀드색'),
              const SizedBox(height: 8),
              _buildColorToggles(
                options: _colorOptions,
                selected: _holdColor,
                onSelected: (v) => setState(() => _holdColor = v),
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('난이도색'),
              const SizedBox(height: 8),
              _buildColorToggles(
                options: _colorOptions,
                selected: _localLevel,
                onSelected: (v) => setState(() => _localLevel = v),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _handleSubmit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSubmit
                        ? AppColorSchemes.accentBlue
                        : AppColorSchemes.textTertiary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          '문제 등록하기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColorSchemes.textPrimary,
      ),
    );
  }

  Widget _buildGymSelectorCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedGym?.name ?? '지점을 선택하세요',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColorSchemes.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  _selectedGym?.address ?? '클라이밍장 목록에서 선택합니다',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColorSchemes.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _isLoadingGyms ? null : _openGymPicker,
            icon: const Icon(Icons.store_mall_directory_outlined, size: 18),
            label: Text(_selectedGym == null ? '지점 선택' : '변경'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColorSchemes.accentBlue,
              side: const BorderSide(color: AppColorSchemes.accentBlue),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorToggles({
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: options.map((opt) {
          final bool isSel = selected == opt;
          final color = ColorCodes.toDisplayColorFromAny(opt);
          final bool needsBorder = ColorCodes.needsBorderForLabel(opt);
          final bool isWhite = needsBorder && opt == '흰색';
          final Color selectedBg = isWhite
              ? const Color(0xFFF1F5F9) // very light gray for white selection
              : color.withValues(alpha: 0.12);
          final Color sideColor = isSel
              ? (isWhite ? Colors.grey : color)
              : AppColorSchemes.borderPrimary;
          final Color textColor = isSel
              ? (isWhite ? Colors.black87 : color)
              : AppColorSchemes.textPrimary;
          return ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color, 
                    shape: BoxShape.circle,
                    border: needsBorder 
                        ? Border.all(color: Colors.grey, width: 1)
                        : null,
                  ),
                ),
                const SizedBox(width: 6),
                Text(opt),
              ],
            ),
            selected: isSel,
            onSelected: (_) => onSelected(opt),
            backgroundColor: Colors.white,
            selectedColor: selectedBg,
            side: BorderSide(color: sideColor),
            labelStyle: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildImagePickerTopCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 15,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColorSchemes.borderPrimary),
              ),
              child: _imageFile == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 46, color: AppColorSchemes.textSecondary),
                        SizedBox(height: 8),
                        Text('문제 사진을 선택하세요', style: TextStyle(color: AppColorSchemes.textSecondary)),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.file(
                        _imageFile!,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera, size: 18),
                  label: const Text('사진 촬영'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColorSchemes.accentBlue,
                    side: const BorderSide(color: AppColorSchemes.accentBlue),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, color: Colors.white, size: 18),
                  label: const Text('갤러리에서 선택'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorSchemes.accentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '팁: 문제 전체가 잘 보이도록 촬영해주세요.',
            style: TextStyle(fontSize: 12, color: AppColorSchemes.textSecondary),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColorSchemes.borderPrimary, width: 1),
    );
  }

  Future<void> _openGymPicker() async {
    if (_gyms.isEmpty) return;

    Gym? result;
    result = await showModalBottomSheet<Gym>(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          List<Gym> filtered = List.of(_gyms);
          return StatefulBuilder(
            builder: (context, setModalState) {
              void onSearch(String q) {
                setModalState(() {
                  filtered = _gyms
                      .where((g) => g.name.toLowerCase().contains(q.toLowerCase()))
                      .toList();
                });
              }

              return Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  top: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    TextField(
                      onChanged: onSearch,
                      decoration: const InputDecoration(
                        hintText: '지점 검색',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final gym = filtered[index];
                          final isSelected = gym.gymId == _selectedGym?.gymId;
                          return ListTile(
                            title: Text(
                              gym.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              gym.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check, color: AppColorSchemes.accentBlue)
                                : null,
                            onTap: () => Navigator.of(context).pop(gym),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );

    if (!mounted) return;
    if (result != null) {
      setState(() {
        _selectedGym = result;
        _areaId = null;
        _gymAreas = [];
        _isLoadingGymDetail = true;
      });
      await _loadGymDetail(result.gymId);
    }
  }

  Future<void> _loadGymDetail(int gymId) async {
    try {
      final detail = await GymApi.getGymById(gymId);
      if (!mounted) return;
      setState(() {
        _selectedGym = detail;
        _gymAreas = detail.gymAreas;
        if (_gymAreas.where((a) => a.areaId == _areaId).isEmpty) {
          _areaId = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('클라이밍장 구역 정보를 불러오지 못했습니다: $e')),
      );
      setState(() {
        _gymAreas = [];
        _areaId = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingGymDetail = false;
        });
      }
    }
  }
}
