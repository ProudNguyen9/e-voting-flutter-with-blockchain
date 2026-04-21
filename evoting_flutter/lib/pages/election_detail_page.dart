import 'package:flutter/material.dart';

import '../model/candidate.dart';
import '../model/election_summary.dart';
import '../server/election_service.dart';

class ElectionDetailPage extends StatefulWidget {
  final ElectionSummary election;
  final String baseUrl;
  final String token;

  const ElectionDetailPage({
    super.key,
    required this.election,
    required this.baseUrl,
    required this.token,
  });

  @override
  State<ElectionDetailPage> createState() => _ElectionDetailPageState();
}

class _ElectionDetailPageState extends State<ElectionDetailPage> {
  final ElectionService _electionService = ElectionService();
  bool _isLoading = true;
  String? _errorMessage;
  ElectionSummary? _electionDetail;
  List<Candidate> _candidates = [];

  @override
  void initState() {
    super.initState();
    _loadElectionDetail();
  }

  Future<void> _loadElectionDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _electionService.getCandidates(
        baseUrl: widget.baseUrl,
        token: widget.token,
        electionId: widget.election.id,
      );

      setState(() {
        _electionDetail = result['election'] as ElectionSummary?;
        _candidates = result['candidates'] as List<Candidate>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final localDateTime = dateTime.toLocal();
    return '${localDateTime.day.toString().padLeft(2, '0')}/${localDateTime.month.toString().padLeft(2, '0')}/${localDateTime.year} ${localDateTime.hour.toString().padLeft(2, '0')}:${localDateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final election = _electionDetail ?? widget.election;
    final statusText = election.statusLabel;
    final now = DateTime.now();
    final startTime = election.startTime ?? now;
    final endTime = election.endTime ?? now;

    // Xác định màu sắc và icon dựa trên trạng thái
    final Color statusColor;
    final IconData statusIcon;

    switch (statusText) {
      case 'Đã kết thúc':
        statusColor = Colors.grey.shade700;
        statusIcon = Icons.check_circle;
        break;
      case 'Đang diễn ra':
        statusColor = Colors.green.shade700;
        statusIcon = Icons.play_circle_filled;
        break;
      case 'Đã hủy':
        statusColor = Colors.red.shade700;
        statusIcon = Icons.cancel;
        break;
      case 'Sắp diễn ra':
      default:
        statusColor = Colors.blue.shade700;
        statusIcon = Icons.schedule;
        break;
    }

    final Color bgColor = statusText == 'Đã kết thúc'
        ? Colors.grey.shade100
        : statusText == 'Đang diễn ra'
        ? Colors.green.shade50
        : statusText == 'Đã hủy'
        ? Colors.red.shade50
        : Colors.blue.shade50;

    final Color borderColor = statusText == 'Đã kết thúc'
        ? Colors.grey.shade300
        : statusText == 'Đang diễn ra'
        ? Colors.green.shade200
        : statusText == 'Đã hủy'
        ? Colors.red.shade200
        : Colors.blue.shade200;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết cuộc bầu cử'),
        foregroundColor: Colors.black,
      ),
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
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadElectionDetail,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadElectionDetail,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thông tin cuộc bầu cử
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.how_to_vote,
                                  color: statusColor,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      election.title,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: bgColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: borderColor),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            statusIcon,
                                            color: statusColor,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            statusText,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (election.description.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Text(
                                election.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          _buildInfoItem(
                            icon: Icons.calendar_today,
                            label: 'Bắt đầu',
                            value: _formatDateTime(startTime),
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoItem(
                            icon: Icons.event_busy,
                            label: 'Kết thúc',
                            value: _formatDateTime(endTime),
                            color: Colors.orange,
                          ),
                          if (election.isOnchain) ...[
                            const SizedBox(height: 12),
                            _buildInfoItem(
                              icon: Icons.link,
                              label: 'Blockchain',
                              value: 'Đã kích hoạt',
                              color: Colors.green,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),

                    // Danh sách ứng cử viên
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.people,
                                    size: 24,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Danh sách ứng cử viên',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${_candidates.length} ứng cử viên',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_candidates.isEmpty)
                            Center(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 32,
                                ),
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.person_off_outlined,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Chưa có ứng cử viên nào',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Danh sách ứng cử viên sẽ được cập nhật sau',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _candidates.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final candidate = _candidates[index];
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Số thứ tự hoặc avatar
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade600,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: candidate.imageUrl.isNotEmpty
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child: Image.network(
                                                    candidate.imageUrl,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) {
                                                          return Center(
                                                            child: Text(
                                                              '${index + 1}',
                                                              style: const TextStyle(
                                                                fontSize: 24,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                  ),
                                                )
                                              : Center(
                                                  child: Text(
                                                    '${index + 1}',
                                                    style: const TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                        const SizedBox(width: 14),
                                        // Thông tin ứng cử viên
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                candidate.candidateName,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  height: 1.3,
                                                ),
                                              ),
                                              if (candidate
                                                  .candidateDescription
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  candidate
                                                      .candidateDescription,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey.shade600,
                                                    height: 1.4,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                              if (candidate
                                                      .blockchainCandidateId !=
                                                  null) ...[
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.tag,
                                                      size: 14,
                                                      color:
                                                          Colors.grey.shade500,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'ID: ${candidate.blockchainCandidateId}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
