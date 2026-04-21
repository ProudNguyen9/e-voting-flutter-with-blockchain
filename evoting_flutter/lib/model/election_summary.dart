class ElectionSummary {
  const ElectionSummary({
    required this.id,
    required this.blockchainElectionId,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.candidateCount,
    required this.approvedVoterCount,
    this.isOnchain = false,
  });

  final int id;
  final int blockchainElectionId;
  final String title;
  final String description;
  final DateTime? startTime;
  final DateTime? endTime;
  final int candidateCount;
  final int approvedVoterCount;
  final bool isOnchain;

  factory ElectionSummary.fromJson(Map<String, dynamic> json) {
    return ElectionSummary(
      id: _toInt(json['id']),
      blockchainElectionId: _toInt(json['election_id']),
      title: (json['title'] ?? 'Chưa có tiêu đề').toString(),
      description: (json['description'] ?? '').toString(),
      startTime: _toDateTime(json['start_time']),
      endTime: _toDateTime(json['end_time']),
      candidateCount: _toInt(json['candidate_count']),
      approvedVoterCount: _toInt(json['approved_voter_count']),
      isOnchain: json['is_onchain'] == 1 || json['is_onchain'] == true,
    );
  }

  bool get hasMinimumRequirements =>
      candidateCount >= 2 && approvedVoterCount >= 3;

  String get statusLabel {
    final now = DateTime.now();
    final start = startTime;
    final end = endTime;

    if (start == null || end == null) {
      return 'Chưa rõ thời gian';
    }
    if (now.isBefore(start)) {
      return hasMinimumRequirements ? 'Sắp diễn ra' : 'Chưa đủ điều kiện';
    }
    if (!hasMinimumRequirements) {
      return 'Đã hủy';
    }
    if (!isOnchain) {
      return 'Sắp diễn ra';
    }
    if (now.isAfter(end)) {
      return 'Đã kết thúc';
    }
    return 'Đang diễn ra';
  }

  static int _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _toDateTime(Object? value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }
}
