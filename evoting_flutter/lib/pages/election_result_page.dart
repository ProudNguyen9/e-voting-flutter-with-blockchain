import 'package:flutter/material.dart';

import '../model/election_result.dart';
import '../model/election_summary.dart';
import '../server/election_service.dart';

class ElectionResultPage extends StatefulWidget {
  const ElectionResultPage({
    super.key,
    required this.election,
    required this.baseUrl,
    required this.token,
  });

  final ElectionSummary election;
  final String baseUrl;
  final String token;

  @override
  State<ElectionResultPage> createState() => _ElectionResultPageState();
}

class _ElectionResultPageState extends State<ElectionResultPage> {
  final ElectionService _electionService = ElectionService();

  bool _isLoading = true;
  String? _errorMessage;
  ElectionResult? _result;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _electionService.getElectionResults(
        baseUrl: widget.baseUrl,
        token: widget.token,
        electionId: widget.election.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  double _progressOf(ElectionResultCandidate candidate, int totalVotes) {
    if (totalVotes <= 0) {
      return 0;
    }
    return candidate.voteCount / totalVotes;
  }

  String _percentOf(ElectionResultCandidate candidate, int totalVotes) {
    if (totalVotes <= 0) {
      return '0.0%';
    }
    final percent = (candidate.voteCount * 100) / totalVotes;
    return '${percent.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _result;
    final topVoteCount = result != null && result.candidates.isNotEmpty
        ? result.candidates
              .map((candidate) => candidate.voteCount)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    final leadersCount = result != null
        ? result.candidates
              .where((candidate) => candidate.voteCount == topVoteCount)
              .length
        : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả bầu cử')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _loadResults,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tải lại'),
                    ),
                  ],
                ),
              ),
            )
          : result == null
          ? const Center(child: Text('Không có dữ liệu kết quả.'))
          : RefreshIndicator(
              onRefresh: _loadResults,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _SummaryChip(
                                icon: Icons.how_to_vote,
                                label: 'Tổng phiếu',
                                value: '${result.totalVotes}',
                              ),
                              _SummaryChip(
                                icon: Icons.groups_2_outlined,
                                label: 'Tổng cử tri',
                                value: '${result.totalVoters}',
                              ),
                              _SummaryChip(
                                icon: Icons.settings_ethernet,
                                label: 'Phase',
                                value: result.phase,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: result.isFinalized
                                  ? Colors.green.shade50
                                  : Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: result.isFinalized
                                    ? Colors.green.shade200
                                    : Colors.amber.shade200,
                              ),
                            ),
                            child: Text(
                              result.message,
                              style: TextStyle(
                                color: result.isFinalized
                                    ? Colors.green.shade900
                                    : Colors.orange.shade900,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (result.candidates.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Chưa có dữ liệu ứng cử viên để hiển thị kết quả.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ...result.candidates.asMap().entries.map((entry) {
                      final index = entry.key;
                      final candidate = entry.value;
                      final progress = _progressOf(
                        candidate,
                        result.totalVotes,
                      );
                      final percent = _percentOf(candidate, result.totalVotes);
                      final isWinner =
                          result.isFinalized &&
                          candidate.voteCount > 0 &&
                          candidate.voteCount == topVoteCount &&
                          leadersCount == 1;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: isWinner
                                          ? Colors.amber.shade100
                                          : Colors.blue.shade50,
                                      foregroundColor: isWinner
                                          ? Colors.amber.shade900
                                          : Colors.blue.shade900,
                                      child: Text('${index + 1}'),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  candidate.name,
                                                  style: theme
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ),
                                              if (isWinner)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Colors.amber.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          999,
                                                        ),
                                                  ),
                                                  child: const Text(
                                                    'Dẫn đầu',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          if (candidate
                                              .description
                                              .isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              candidate.description,
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Text(
                                      result.isFinalized
                                          ? '${candidate.voteCount} phiếu'
                                          : 'Chưa có kết quả giải mã',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      result.isFinalized ? percent : 'Đang chờ',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: result.isFinalized ? progress : null,
                                  minHeight: 10,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}
