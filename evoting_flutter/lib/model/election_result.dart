class ElectionResultCandidate {
  const ElectionResultCandidate({
    required this.candidateId,
    required this.blockchainCandidateId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.voteCount,
  });

  final int candidateId;
  final int blockchainCandidateId;
  final String name;
  final String description;
  final String imageUrl;
  final int voteCount;

  factory ElectionResultCandidate.fromJson(Map<String, dynamic> json) {
    return ElectionResultCandidate(
      candidateId: _toInt(json['candidateId'] ?? json['id']),
      blockchainCandidateId: _toInt(
        json['blockchainCandidateId'] ?? json['blockchain_candidate_id'],
      ),
      name: (json['name'] ?? json['candidate_name'] ?? '').toString(),
      description: (json['description'] ?? json['candidate_description'] ?? '')
          .toString(),
      imageUrl: (json['imageUrl'] ?? json['image_url'] ?? '').toString(),
      voteCount: _toInt(json['voteCount'] ?? json['vote_count']),
    );
  }

  static int _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class ElectionResult {
  const ElectionResult({
    required this.electionId,
    required this.blockchainElectionId,
    required this.title,
    required this.totalVotes,
    required this.totalVoters,
    required this.phase,
    required this.isFinalized,
    required this.message,
    required this.candidates,
  });

  final int electionId;
  final int blockchainElectionId;
  final String title;
  final int totalVotes;
  final int totalVoters;
  final String phase;
  final bool isFinalized;
  final String message;
  final List<ElectionResultCandidate> candidates;

  factory ElectionResult.fromJson(Map<String, dynamic> json) {
    final candidatesJson = (json['candidates'] as List?) ?? const [];
    return ElectionResult(
      electionId: _toInt(json['electionId'] ?? json['id']),
      blockchainElectionId: _toInt(
        json['blockchainElectionId'] ?? json['election_id'],
      ),
      title: (json['title'] ?? '').toString(),
      totalVotes: _toInt(json['totalVotes'] ?? json['total_votes']),
      totalVoters: _toInt(json['totalVoters'] ?? json['total_voters']),
      phase: (json['phase'] ?? '').toString(),
      isFinalized: json['isFinalized'] == true,
      message: (json['message'] ?? '').toString(),
      candidates: candidatesJson
          .whereType<Map>()
          .map(
            (item) =>
                ElectionResultCandidate.fromJson(item.cast<String, dynamic>()),
          )
          .toList(),
    );
  }

  static int _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
