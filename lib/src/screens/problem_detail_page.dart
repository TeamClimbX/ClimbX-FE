import 'package:flutter/material.dart';
import '../models/problem.dart';
import '../api/gym.dart';
import '../utils/color_schemes.dart';
import '../screens/problem_submit_page.dart';
import '../utils/color_codes.dart';
import '../utils/navigation_helper.dart';

/// 문제 상세 정보 페이지
class ProblemDetailPage extends StatefulWidget {
  final Problem problem;
  final int? gymId; // 클라이밍장 ID 추가

  const ProblemDetailPage({
    super.key,
    required this.problem,
    this.gymId,
  });

  @override
  State<ProblemDetailPage> createState() => _ProblemDetailPageState();
}

class _ProblemDetailPageState extends State<ProblemDetailPage> {
  String? _gymName; // 클라이밍장 이름 저장

  @override
  void initState() {
    super.initState();
    _loadGymName();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// 클라이밍장 이름 로드
  Future<void> _loadGymName() async {
    if (widget.gymId != null) {
      try {
        final gym = await GymApi.getGymById(widget.gymId!);
        if (!mounted) return;
        setState(() {
          _gymName = gym.name;
        });
      } catch (e) {
        // 에러 처리 - 기본값 사용
        if (!mounted) return;
        setState(() {
          _gymName = '클라이밍장';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorSchemes.backgroundSecondary,
      body: CustomScrollView(
        slivers: [
          // 상단 앱바
          SliverAppBar(
            expandedHeight: 300, // 이미지 높이
            floating: false,
            pinned: true,
            backgroundColor: AppColorSchemes.backgroundPrimary,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: AppColorSchemes.textPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProblemImage(),
            ),
          ),

          // 문제 정보 섹션
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 문제 기본 정보
                  _buildBasicInfo(),
                  const SizedBox(height: 24),

                  // 문제 제출 버튼
                  _buildSubmitButton(),
                  const SizedBox(height: 12),
                  // 난이도 기여 페이지로 이동 버튼
                  _buildVotesButton(),
                  const SizedBox(height: 24),

                  // 코멘트 섹션 제거됨
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 문제 이미지 위젯
  Widget _buildProblemImage() {
    // 기본 이미지 위젯
    final Widget defaultImage = Container(
      color: AppColorSchemes.backgroundTertiary,
      child: const Icon(
        Icons.image,
        color: AppColorSchemes.textTertiary,
        size: 64,
      ),
    );

    if (widget.problem.problemImageCdnUrl.isEmpty) {
      return defaultImage;
    }

    // 네트워크 이미지
    return Image.network(
      widget.problem.problemImageCdnUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => defaultImage,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: AppColorSchemes.backgroundTertiary,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  /// 기본 정보 위젯
  Widget _buildBasicInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorSchemes.backgroundPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColorSchemes.lightShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 문제 제목 (클라이밍장 이름 포함)
          Text(
            _gymName != null ? '$_gymName - ${widget.problem.gymAreaName}' : widget.problem.gymAreaName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColorSchemes.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // 난이도 정보
          Row(
            children: [
              _buildInfoCard('난이도', widget.problem.localLevel),
              const SizedBox(width: 12),
              _buildInfoCard('홀드색', widget.problem.holdColor),
            ],
          ),
          const SizedBox(height: 16),


        ],
      ),
    );
  }

  /// 정보 카드 위젯
  Widget _buildInfoCard(String label, String value) {
    final colorStyle = ColorCodes.getColorStyleInfo(value, AppColorSchemes.accentBlue);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorStyle.bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorStyle.borderColor,
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
                    color: colorStyle.displayColor,
                    shape: BoxShape.circle,
                    border: colorStyle.needsBorder 
                        ? Border.all(color: AppColorSchemes.whiteSelectionBorder, width: 1)
                        : null,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  colorStyle.displayLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorStyle.textColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  /// 제출 버튼 위젯
  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: () {
          // 제출 페이지로 이동
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProblemSubmitPage(
                problem: widget.problem,
                gymId: widget.gymId,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorSchemes.accentBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          '문제 제출하기',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// 난이도 기여 페이지 이동 버튼
  Widget _buildVotesButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton(
        onPressed: () => NavigationHelper.navigateToProblemVotes(context, widget.problem.problemId),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColorSchemes.accentBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text(
          '난이도 기여 보기',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColorSchemes.accentBlue,
          ),
        ),
      ),
    );
  }
}
