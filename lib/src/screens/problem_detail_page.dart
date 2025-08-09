import 'package:flutter/material.dart';
import '../models/problem.dart';
import '../api/gym.dart';
import '../utils/color_schemes.dart';
import '../screens/problem_submit_page.dart';

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
  final TextEditingController _commentController = TextEditingController();
  String? _gymName; // 클라이밍장 이름 저장

  @override
  void initState() {
    super.initState();
    _loadGymName();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// 클라이밍장 이름 로드
  Future<void> _loadGymName() async {
    if (widget.gymId != null) {
      try {
        final gym = await GymApi.getGymById(widget.gymId!);
        setState(() {
          _gymName = gym.name;
        });
      } catch (e) {
        // 에러 처리 - 기본값 사용
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
                  const SizedBox(height: 24),

                  // 코멘트 섹션
                  _buildCommentSection(),
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _getColorForOption(value).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getColorForOption(value).withValues(alpha: 0.3),
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
                    color: _getColorForOption(value),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _getColorForOption(value),
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

  /// 코멘트 섹션 위젯
  Widget _buildCommentSection() {
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
          // 코멘트 제목
          const Text(
            '코멘트',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColorSchemes.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // 코멘트 입력 필드
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '코멘트를 입력하세요...',
              hintStyle: const TextStyle(
                color: AppColorSchemes.textTertiary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColorSchemes.borderPrimary,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColorSchemes.accentBlue,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 코멘트 작성 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  // 코멘트 작성 로직
                  _submitComment();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorSchemes.accentBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '작성',
                  style: TextStyle(
                    color: AppColorSchemes.backgroundPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 코멘트 제출
  void _submitComment() {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('코멘트를 입력해주세요.')),
      );
      return;
    }

    // 코멘트 제출 로직 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('코멘트가 작성되었습니다!')),
    );
    _commentController.clear();
  }

  /// 옵션에 따른 색상 반환
  Color _getColorForOption(String option) {
    switch (option) {
      case '빨강':
        return const Color(0xFFEF4444);
      case '파랑':
        return const Color(0xFF3B82F6);
      case '초록':
        return const Color(0xFF10B981);
      case '노랑':
        return const Color(0xFFF59E0B);
      case '보라':
        return const Color(0xFF8B5CF6);
      default:
        return AppColorSchemes.accentBlue;
    }
  }
} 