/// 클라이밍 문제 정보 모델
class Problem {
  final String problemId;       // UUID 형태의 문제 ID
  final int gymId;              // 클라이밍장 ID
  final int gymAreaId;          // 클라이밍장 영역 ID
  final String gymAreaName;     // 클라이밍장 영역 이름 (예: "메인홀")
  final String localLevel;      // 난이도 색상 (빨강, 파랑, 초록 등)
  final String holdColor;       // 홀드 색상 (빨강, 파랑, 초록 등)
  final int problemRating;      // 문제 난이도 점수
  final String problemImageCdnUrl; // 문제 이미지 CDN URL
  final String activeStatus;    // 활성 상태 (ACTIVE, INACTIVE 등)
  final DateTime createdAt;     // 생성일

  Problem({
    required this.problemId,
    required this.gymId,
    required this.gymAreaId,
    required this.gymAreaName,
    required this.localLevel,
    required this.holdColor,
    required this.problemRating,
    required this.problemImageCdnUrl,
    required this.activeStatus,
    required this.createdAt,
  });

  factory Problem.fromJson(Map<String, dynamic> json) {
    // Required fields: problemId, createdAt
    final String? problemId = json['problemId'] as String?;
    final dynamic createdAtRaw = json['createdAt'];

    if (problemId == null || problemId.isEmpty) {
      throw const FormatException('problemId 필드는 필수입니다.');
    }

    if (createdAtRaw == null) {
      throw const FormatException('createdAt 필드는 필수입니다.');
    }

    final String createdAtString = createdAtRaw as String;
    final DateTime? createdAt = DateTime.tryParse(createdAtString);
    if (createdAt == null) {
      throw FormatException('createdAt 형식이 올바르지 않습니다: $createdAtString');
    }

    return Problem(
      problemId: problemId,
      gymId: (json['gymId'] as num?)?.toInt() ?? 0,
      gymAreaId: (json['gymAreaId'] as num?)?.toInt() ?? 0,
      gymAreaName: json['gymAreaName'] as String? ?? '',
      localLevel: json['localLevel'] as String? ?? '',
      holdColor: json['holdColor'] as String? ?? '',
      problemRating: (json['problemRating'] as num?)?.toInt() ?? 0,
      problemImageCdnUrl: json['problemImageCdnUrl'] as String? ?? '',
      activeStatus: json['activeStatus'] as String? ?? 'ACTIVE',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'problemId': problemId,
      'gymId': gymId,
      'gymAreaId': gymAreaId,
      'gymAreaName': gymAreaName,
      'localLevel': localLevel,
      'holdColor': holdColor,
      'problemRating': problemRating,
      'problemImageCdnUrl': problemImageCdnUrl,
      'activeStatus': activeStatus,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Problem(problemId: $problemId, gymId: $gymId, gymAreaName: $gymAreaName, localLevel: $localLevel, holdColor: $holdColor, rating: $problemRating)';
  }
} 