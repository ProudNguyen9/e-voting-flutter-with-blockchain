import 'package:flutter/material.dart';

import '../model/election_summary.dart';
import '../server/election_service.dart';

class ElectionRegisterPage extends StatefulWidget {
  final ElectionSummary election;
  final String baseUrl;
  final String token;

  const ElectionRegisterPage({
    super.key,
    required this.election,
    required this.baseUrl,
    required this.token,
  });

  @override
  State<ElectionRegisterPage> createState() => _ElectionRegisterPageState();
}

class _ElectionRegisterPageState extends State<ElectionRegisterPage> {
  final ElectionService _electionService = ElectionService();
  bool _isRegistering = false;

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '--';

    final localDateTime = dateTime.toLocal();
    return '${localDateTime.day.toString().padLeft(2, '0')}/${localDateTime.month.toString().padLeft(2, '0')}/${localDateTime.year} ${localDateTime.hour.toString().padLeft(2, '0')}:${localDateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleRegister() async {
    // Hiển thị dialog xác nhận
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 12),
            Text('Xác nhận đăng ký'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc muốn đăng ký tham dự cuộc bầu cử "${widget.election.title}"?',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, size: 20, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Lưu ý quan trọng:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Sau khi admin phê duyệt, bạn sẽ nhận mã PIN qua email',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  Text(
                    '• Mã PIN chỉ cấp 1 lần duy nhất cho cuộc bầu cử này',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  Text(
                    '• Vui lòng giữ bí mật mã PIN để đảm bảo an toàn',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  Text(
                    '• Mã PIN dùng để xác thực khi bỏ phiếu',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận đăng ký'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRegistering = true);

    try {
      final result = await _electionService.registerElection(
        baseUrl: widget.baseUrl,
        token: widget.token,
        electionId: widget.election.id,
      );

      if (!mounted) return;

      // Hiển thị dialog thành công
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 12),
              Text('Thành công!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.message, style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.mail_outline, size: 20, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Bước tiếp theo:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Kiểm tra email để xem trạng thái đăng ký',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                    Text(
                      '2. Đợi admin phê duyệt yêu cầu của bạn',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                    Text(
                      '3. Nhận mã PIN qua email sau khi được duyệt',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                    Text(
                      '4. Giữ bí mật mã PIN để bỏ phiếu',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Đóng dialog
                Navigator.pop(context); // Quay về trang trước
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isRegistering = false);

      // Hiển thị dialog lỗi
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 12),
              Text('Đăng ký thất bại'),
            ],
          ),
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: const TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.election.statusLabel;
    final isEnded = status == 'Đã kết thúc' || status == 'Đã hủy';
    final isOngoing = status == 'Đang diễn ra';
    final isInsufficient = status == 'Chưa đủ điều kiện';
    final now = DateTime.now();
    final startTime = widget.election.startTime ?? now;
    final endTime = widget.election.endTime ?? now;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký tham dự'),

        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.how_to_vote,
                          color: Colors.blue.shade700,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.election.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isEnded
                                    ? (status == 'Đã hủy'
                                          ? Colors.red.shade100
                                          : Colors.grey.shade200)
                                    : isOngoing
                                    ? Colors.green.shade100
                                    : isInsufficient
                                    ? Colors.orange.shade100
                                    : Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: isEnded
                                      ? (status == 'Đã hủy'
                                            ? Colors.red.shade700
                                            : Colors.grey.shade700)
                                      : isOngoing
                                      ? Colors.green.shade700
                                      : isInsufficient
                                      ? Colors.orange.shade700
                                      : Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (widget.election.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      widget.election.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Bắt đầu: ${_formatDateTime(startTime)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 18,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Kết thúc: ${_formatDateTime(endTime)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Hướng dẫn đăng ký
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quy trình đăng ký',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildStep(
                    number: '1',
                    title: 'Gửi yêu cầu đăng ký',
                    description:
                        'Nhấn nút "Đăng ký tham dự" bên dưới để gửi yêu cầu',
                    icon: Icons.send,
                    color: Colors.blue,
                  ),
                  _buildStep(
                    number: '2',
                    title: 'Chờ admin phê duyệt',
                    description:
                        'Admin sẽ xem xét và phê duyệt yêu cầu của bạn',
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                  ),
                  _buildStep(
                    number: '3',
                    title: 'Nhận mã PIN qua email',
                    description:
                        'Sau khi được duyệt, mã PIN sẽ được gửi đến email của bạn',
                    icon: Icons.mail,
                    color: Colors.green,
                  ),
                  _buildStep(
                    number: '4',
                    title: 'Giữ bí mật mã PIN',
                    description:
                        'Mã PIN chỉ cấp 1 lần, dùng để xác thực khi bỏ phiếu',
                    icon: Icons.lock,
                    color: Colors.red,
                    isLast: true,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber.shade200,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: Colors.orange.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lưu ý quan trọng',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Mã PIN là thông tin bí mật và chỉ được cấp một lần duy nhất cho mỗi cuộc bầu cử. Vui lòng không chia sẻ mã PIN với bất kỳ ai để đảm bảo tính bảo mật và công bằng của cuộc bầu cử.',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: Colors.orange.shade900,
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
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isRegistering ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isRegistering
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Đăng ký tham dự',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep({
    required String number,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Center(
                child: Text(
                  number,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 40, color: Colors.grey.shade300),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: color),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
