class Candidate {
  final int id;
  final int electionDbId;
  final int electionId;
  final String candidateName;
  final String candidateDescription;
  final String imageUrl;
  final int? blockchainCandidateId;
  final DateTime? createdAt;

  Candidate({
    required this.id,
    required this.electionDbId,
    required this.electionId,
    required this.candidateName,
    required this.candidateDescription,
    required this.imageUrl,
    this.blockchainCandidateId,
    this.createdAt,
  });

  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      id: json['id'] as int,
      electionDbId: json['election_db_id'] as int,
      electionId: json['election_id'] as int,
      candidateName: (json['candidate_name'] as String?) ?? '',
      candidateDescription: (json['candidate_description'] as String?) ?? '',
      imageUrl: (json['image_url'] as String?) ?? '',
      blockchainCandidateId: json['blockchain_candidate_id'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'election_db_id': electionDbId,
      'election_id': electionId,
      'candidate_name': candidateName,
      'candidate_description': candidateDescription,
      'image_url': imageUrl,
      'blockchain_candidate_id': blockchainCandidateId,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
