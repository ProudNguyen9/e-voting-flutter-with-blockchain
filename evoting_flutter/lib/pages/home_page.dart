import 'package:flutter/material.dart';

import '../model/election_summary.dart';
import '../server/election_service.dart';
import '../server/auth_server.dart';
import 'election_detail_page.dart';
import 'election_register_page.dart';
import 'login_page.dart';
import 'vote_page.dart';
import 'wallet_setup_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.baseUrl,
    required this.token,
    required this.email,
    required this.walletAddress,
  });

  final String baseUrl;
  final String token;
  final String email;
  final String walletAddress;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final ElectionService _electionService = ElectionService();

  bool _isLoading = true;
  bool _isError = false;
  String _statusMessage = 'Đang tải danh sách bầu cử...';
  List<ElectionSummary> _elections = const [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadElections();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadElections() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _statusMessage = 'Đang tải danh sách bầu cử...';
    });

    try {
      final elections = await _electionService.getElections(
        baseUrl: widget.baseUrl,
        token: widget.token,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _elections = elections;
        _isLoading = false;
        _isError = false;
        _statusMessage = elections.isEmpty
            ? 'Hiện tại chưa có cuộc bầu cử nào.'
            : 'Đã tải ${elections.length} cuộc bầu cử.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isError = true;
        _statusMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF1D4ED8)),
              title: const Text('Thông tin tài khoản'),
              subtitle: Text(widget.email),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.account_balance_wallet,
                color: Color(0xFF1D4ED8),
              ),
              title: const Text('Địa chỉ ví'),
              subtitle: Text(
                widget.walletAddress,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(); // Đóng bottom sheet
                  _handleReconnectWallet();
                },
                icon: const Icon(Icons.wallet),
                label: const Text('Kết nối lại ví'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(); // Đóng bottom sheet
                  _handleLogout();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Đăng xuất'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Đóng dialog
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReconnectWallet() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kết nối lại ví'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cảnh báo quan trọng!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.orange,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Thay đổi địa chỉ ví có thể khiến bạn không thể tham gia bầu cử nếu đã được admin phê duyệt với ví cũ. Chỉ thay đổi khi thực sự cần thiết!',
                          style: TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chọn phương thức kết nối:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.wallet, color: Color(0xFF1D4ED8)),
              title: const Text('Kết nối MetaMask'),
              subtitle: const Text('Kết nối qua WalletConnect'),
              onTap: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                navigator.pop();
                final result = await navigator.push(
                  MaterialPageRoute(
                    builder: (context) => WalletSetupPage(
                      baseUrl: widget.baseUrl,
                      token: widget.token,
                      email: widget.email,
                    ),
                  ),
                );

                if (!mounted || result != true) {
                  return;
                }

                setState(() {
                  // Reload để cập nhật wallet address
                });
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Đã cập nhật địa chỉ ví thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF1D4ED8)),
              title: const Text('Nhập địa chỉ ví thủ công'),
              subtitle: const Text('Cập nhật địa chỉ ví mới'),
              onTap: () {
                Navigator.of(context).pop();
                _showManualWalletInput();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  void _showManualWalletInput() {
    final TextEditingController walletController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhập địa chỉ ví mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: walletController,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ ví',
                hintText: '0x...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            const Text(
              'Lưu ý: Địa chỉ ví phải bắt đầu bằng 0x',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newWallet = walletController.text.trim();
              if (newWallet.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập địa chỉ ví'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (!newWallet.startsWith('0x') || newWallet.length < 42) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Địa chỉ ví không hợp lệ'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.of(context).pop();
              await _updateWalletAddress(newWallet);
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateWalletAddress(String newWallet) async {
    try {
      final authServer = AuthServer();
      final result = await authServer.updateWalletAddress(
        baseUrl: widget.baseUrl,
        token: widget.token,
        walletAddress: newWallet,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cập nhật địa chỉ ví thành công! Vui lòng đăng nhập lại.',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Đăng xuất và quay về trang login
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Cập nhật thất bại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<ElectionSummary> get _ongoingElections {
    return _elections
        .where(
          (e) =>
              e.statusLabel == 'Đang diễn ra' ||
              e.statusLabel == 'Sắp diễn ra' ||
              e.statusLabel == 'Chưa đủ điều kiện',
        )
        .toList();
  }

  List<ElectionSummary> get _endedElections {
    return _elections.where((e) => e.statusLabel == 'Đã kết thúc').toList();
  }

  List<ElectionSummary> get _insufficientElections {
    return _elections.where((e) => e.statusLabel == 'Đã hủy').toList();
  }

  void _showElectionMenu(ElectionSummary election) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ElectionMenuSheet(
        election: election,
        userEmail: widget.email,
        walletAddress: widget.walletAddress,
        baseUrl: widget.baseUrl,
        token: widget.token,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Voting'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadElections,
            tooltip: 'Tải lại',
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _showSettingsMenu,
            tooltip: 'Cài đặt',
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // User Info Card - Compact
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F1D4ED8),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.email,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.walletAddress.substring(0, 10)}...${widget.walletAddress.substring(widget.walletAddress.length - 8)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Status Message
            if (_isError || _statusMessage.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isError
                      ? Colors.red.shade50
                      : colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isError
                        ? Colors.red.shade200
                        : colorScheme.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isError ? Icons.error_outline : Icons.info_outline,
                      size: 20,
                      color: _isError
                          ? Colors.red.shade700
                          : colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _isError
                              ? Colors.red.shade800
                              : colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.all(14.0),
              child: SizedBox(
                height: 44,
                child: TabBar(
                  controller: _tabController,

                  isScrollable: false,
                  indicatorSize: TabBarIndicatorSize.tab,

                  labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  indicator: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),

                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey.shade700,

                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  tabs: [
                    Tab(text: 'Đang chạy (${_ongoingElections.length})'),
                    Tab(text: 'Đã kết thúc (${_endedElections.length})'),
                    Tab(text: 'Đã hủy (${_insufficientElections.length})'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tab View
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // Đang diễn ra
                        _ongoingElections.isEmpty
                            ? _EmptyState(
                                icon: Icons.event_available,
                                message: 'Chưa có cuộc bầu cử nào đang diễn ra',
                                onReload: _loadElections,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: _ongoingElections.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _ElectionCard(
                                      election: _ongoingElections[index],
                                      onTap: () => _showElectionMenu(
                                        _ongoingElections[index],
                                      ),
                                    ),
                                  );
                                },
                              ),
                        // Đã kết thúc
                        _endedElections.isEmpty
                            ? _EmptyState(
                                icon: Icons.event_busy,
                                message: 'Chưa có cuộc bầu cử nào đã kết thúc',
                                onReload: _loadElections,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: _endedElections.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _ElectionCard(
                                      election: _endedElections[index],
                                      onTap: () => _showElectionMenu(
                                        _endedElections[index],
                                      ),
                                    ),
                                  );
                                },
                              ),
                        // Đã hủy
                        _insufficientElections.isEmpty
                            ? _EmptyState(
                                icon: Icons.warning_amber_outlined,
                                message: 'Chưa có cuộc bầu cử nào bị hủy',
                                onReload: _loadElections,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: _insufficientElections.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _ElectionCard(
                                      election: _insufficientElections[index],
                                      onTap: () => _showElectionMenu(
                                        _insufficientElections[index],
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
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.onReload,
  });

  final IconData icon;
  final String message;
  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onReload,
            icon: const Icon(Icons.refresh),
            label: const Text('Tải lại'),
          ),
        ],
      ),
    );
  }
}

class _ElectionCard extends StatelessWidget {
  const _ElectionCard({required this.election, required this.onTap});

  final ElectionSummary election;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = _statusColor(election.statusLabel);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.how_to_vote_outlined,
                      color: accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      election.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      election.statusLabel,
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_formatDateTime(election.startTime)} - ${_formatDateTime(election.endTime)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.tag, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'ID: ${election.blockchainElectionId}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'Đang diễn ra':
        return const Color(0xFF059669);
      case 'Đã kết thúc':
        return const Color(0xFF6B7280);
      case 'Đã hủy':
        return const Color(0xFFDC2626);
      case 'Chưa đủ điều kiện':
        return const Color(0xFFD97706);
      case 'Sắp diễn ra':
      default:
        return const Color(0xFF1D4ED8);
    }
  }

  static String _formatDateTime(DateTime? value) {
    if (value == null) return '--';
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _ElectionMenuSheet extends StatelessWidget {
  const _ElectionMenuSheet({
    required this.election,
    required this.userEmail,
    required this.walletAddress,
    required this.baseUrl,
    required this.token,
  });

  final ElectionSummary election;
  final String userEmail;
  final String walletAddress;
  final String baseUrl;
  final String token;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = election.statusLabel;
    final isEnded = status == 'Đã kết thúc';
    final canVote = status == 'Đang diễn ra';
    final canRegister =
        status == 'Sắp diễn ra' || status == 'Chưa đủ điều kiện';
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.how_to_vote,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        election.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'ID: ${election.blockchainElectionId}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Đăng ký tham dự - chỉ hiện khi chưa bắt đầu
            if (canRegister) ...[
              _MenuOption(
                icon: Icons.app_registration,
                title: 'Đăng ký tham dự',
                subtitle: 'Đăng ký để có quyền bỏ phiếu',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ElectionRegisterPage(
                        election: election,
                        baseUrl: baseUrl,
                        token: token,
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 24),
            ],

            // Xem thông tin - hiện cho tất cả
            _MenuOption(
              icon: Icons.info_outline,
              title: 'Xem thông tin cuộc bầu cử',
              subtitle: 'Chi tiết về cuộc bầu cử và ứng cử viên',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ElectionDetailPage(
                      election: election,
                      baseUrl: baseUrl,
                      token: token,
                    ),
                  ),
                );
              },
            ),

            // Bỏ phiếu - chỉ hiện khi đang diễn ra thực sự
            if (canVote) ...[
              const Divider(height: 24),
              _MenuOption(
                icon: Icons.how_to_vote,
                title: 'Bỏ phiếu',
                subtitle: 'Xác thực PIN và ký giao dịch trực tiếp bằng ví',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VotePinPage(
                        baseUrl: baseUrl,
                        token: token,
                        email: userEmail,
                        walletAddress: walletAddress,
                        election: election,
                      ),
                    ),
                  );
                },
              ),
            ],

            // Xem kết quả - chỉ hiện khi đã kết thúc (đã lên blockchain)
            if (isEnded) ...[
              const Divider(height: 24),
              _MenuOption(
                icon: Icons.bar_chart,
                title: 'Xem kết quả',
                subtitle: 'Kết quả bầu cử và thống kê',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chức năng xem kết quả đang phát triển'),
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuOption extends StatelessWidget {
  const _MenuOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = onTap == null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDisabled
                    ? Colors.grey.shade200
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDisabled
                    ? Colors.grey.shade400
                    : theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDisabled ? Colors.grey.shade400 : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDisabled
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (!isDisabled)
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
