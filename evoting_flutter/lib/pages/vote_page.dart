import 'package:flutter/material.dart';

import '../model/candidate.dart';
import '../model/election_summary.dart';
import '../server/election_service.dart';
import 'home_page.dart';

class VotePinPage extends StatefulWidget {
  const VotePinPage({
    super.key,
    required this.baseUrl,
    required this.token,
    required this.email,
    required this.walletAddress,
    required this.election,
  });

  final String baseUrl;
  final String token;
  final String email;
  final String walletAddress;
  final ElectionSummary election;

  @override
  State<VotePinPage> createState() => _VotePinPageState();
}

class _VotePinPageState extends State<VotePinPage> {
  final ElectionService _electionService = ElectionService();
  final TextEditingController _pinController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verifyPin() async {
    final pinCode = _pinController.text.trim();
    if (pinCode.isEmpty) {
      _showSnackBar('Vui lòng nhập mã PIN.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await _electionService.verifyPin(
        baseUrl: widget.baseUrl,
        token: widget.token,
        electionId: widget.election.id,
        pinCode: pinCode,
      );

      if (!mounted) {
        return;
      }

      _showSnackBar(result.message, isError: false);

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VotePage(
            baseUrl: widget.baseUrl,
            token: widget.token,
            email: widget.email,
            walletAddress: widget.walletAddress,
            election: widget.election,
            verifiedPin: pinCode,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? Colors.red.shade700
              : Colors.green.shade700,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xác thực mã PIN')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 56,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nhập mã PIN để bỏ phiếu',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Mã PIN đã được gửi qua email sau khi admin phê duyệt đăng ký tham dự cuộc bầu cử.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning_amber, color: Colors.orange),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Giữ bí mật mã PIN của bạn',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Text(
                              '• Không chia sẻ mã PIN cho người khác.',
                              style: TextStyle(height: 1.5),
                            ),
                            Text(
                              '• Chỉ nhập PIN trên thiết bị cá nhân của bạn.',
                              style: TextStyle(height: 1.5),
                            ),
                            Text(
                              '• Sau khi xác thực đúng, bạn sẽ chọn ứng cử viên và gửi phiếu bầu đã mã hóa về server để ký hộ.',
                              style: TextStyle(height: 1.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: 'Mã PIN',
                          hintText: 'Nhập 6 số',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.password_outlined),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _verifyPin,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.arrow_forward),
                        label: Text(
                          _isSubmitting
                              ? 'Đang xác thực...'
                              : 'Xác thực và tiếp tục',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VotePage extends StatefulWidget {
  const VotePage({
    super.key,
    required this.baseUrl,
    required this.token,
    required this.email,
    required this.walletAddress,
    required this.election,
    required this.verifiedPin,
  });

  final String baseUrl;
  final String token;
  final String email;
  final String walletAddress;
  final ElectionSummary election;
  final String verifiedPin;

  @override
  State<VotePage> createState() => _VotePageState();
}

class _VotePageState extends State<VotePage> {
  final ElectionService _electionService = ElectionService();

  bool _isLoadingCandidates = true;
  bool _isSubmittingVote = false;
  bool _isPreparingWallet = false;
  String? _errorMessage;
  Candidate? _selectedCandidate;
  List<Candidate> _candidates = const [];
  String? _txHash;

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
    setState(() {
      _isLoadingCandidates = true;
      _errorMessage = null;
    });

    try {
      final result = await _electionService.getCandidates(
        baseUrl: widget.baseUrl,
        token: widget.token,
        electionId: widget.election.id,
      );

      final candidates = (result['candidates'] as List<Candidate>)
          .where((candidate) => candidate.blockchainCandidateId != null)
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _candidates = candidates;
        _selectedCandidate = candidates.isNotEmpty ? candidates.first : null;
        _isLoadingCandidates = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoadingCandidates = false;
      });
    }
  }

  Future<void> _submitVote() async {
    final selectedCandidate = _selectedCandidate;
    if (selectedCandidate == null) {
      _showSnackBar('Vui lòng chọn ứng cử viên.', isError: true);
      return;
    }

    if (selectedCandidate.blockchainCandidateId == null) {
      _showSnackBar(
        'Ứng cử viên này chưa có blockchainCandidateId để bỏ phiếu.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isPreparingWallet = true;
      _isSubmittingVote = true;
    });

    try {
      debugPrint(
        '[VotePage] submitVote server-sign electionId=${widget.election.id} blockchainElectionId=${widget.election.blockchainElectionId} wallet=${widget.walletAddress}',
      );

      final walletAddress = widget.walletAddress.trim();
      if (walletAddress.isEmpty) {
        throw Exception(
          'Tài khoản của bạn chưa có địa chỉ ví để định danh cử tri.',
        );
      }

      final result = await _electionService.submitServerSignedVote(
        baseUrl: widget.baseUrl,
        token: widget.token,
        electionId: widget.election.id,
        blockchainElectionId: widget.election.blockchainElectionId,
        candidateBlockchainId: selectedCandidate.blockchainCandidateId!,
        verifiedPin: widget.verifiedPin,
        voterAddress: walletAddress,
      );

      if (!mounted) return;

      setState(() {
        _isPreparingWallet = false;
        _isSubmittingVote = false;
        _txHash = result.message;
      });

      _showSnackBar(
        'Đã gửi phiếu bầu mã hóa lên server để ký thành công.',
        isError: false,
      );

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VoteSuccessPage(
            baseUrl: widget.baseUrl,
            token: widget.token,
            email: widget.email,
            walletAddress: walletAddress,
            election: widget.election,
            txHash: result.message,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isPreparingWallet = false;
        _isSubmittingVote = false;
      });

      _showSnackBar(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? Colors.red.shade700
              : Colors.green.shade700,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isBusy =
        _isLoadingCandidates || _isSubmittingVote || _isPreparingWallet;

    return Scaffold(
      appBar: AppBar(title: const Text('Bỏ phiếu')),
      body: _isLoadingCandidates
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
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _loadCandidates,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tải lại'),
                    ),
                  ],
                ),
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.orange.shade200,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.privacy_tip_outlined,
                                        color: Colors.orange.shade800,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Bỏ phiếu bảo mật',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Không để người khác nhìn thấy màn hình này. Sau khi chọn ứng cử viên, ứng dụng sẽ mã hóa lựa chọn và gửi về server để ký giao dịch thay bạn. Mỗi cử tri chỉ được bỏ phiếu một lần.',
                                  style: TextStyle(height: 1.6),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Cuộc bầu cử: ${widget.election.title}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Blockchain Election ID: ${widget.election.blockchainElectionId}',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_candidates.isEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: const [
                                  Icon(Icons.person_off_outlined, size: 48),
                                  SizedBox(height: 12),
                                  Text(
                                    'Không có ứng cử viên hợp lệ để bỏ phiếu.',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ..._candidates.map(
                            (candidate) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _CandidateVoteCard(
                                candidate: candidate,
                                isSelected:
                                    candidate.id == _selectedCandidate?.id,
                                onTap: isBusy
                                    ? null
                                    : () {
                                        setState(() {
                                          _selectedCandidate = candidate;
                                        });
                                      },
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _candidates.isEmpty || isBusy
                              ? null
                              : _submitVote,
                          icon: isBusy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.how_to_vote),
                          label: Text(
                            _isPreparingWallet
                                ? 'Đang mã hóa phiếu...'
                                : _isSubmittingVote
                                ? 'Đang gửi server ký...'
                                : 'Bỏ phiếu ngay',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        if (_txHash != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'TxHash: $_txHash',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class VoteSuccessPage extends StatelessWidget {
  const VoteSuccessPage({
    super.key,
    required this.baseUrl,
    required this.token,
    required this.email,
    required this.walletAddress,
    required this.election,
    required this.txHash,
  });

  final String baseUrl;
  final String token;
  final String email;
  final String walletAddress;
  final ElectionSummary election;
  final String txHash;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bỏ phiếu thành công')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 80,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chúc mừng, bạn đã bỏ phiếu thành công!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Phiếu bầu của bạn đã được mã hóa trên ứng dụng, gửi về server để ký và ghi nhận lên blockchain thành công.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              election.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'TxHash: $txHash',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => HomePage(
                                  baseUrl: baseUrl,
                                  token: token,
                                  email: email,
                                  walletAddress: walletAddress,
                                ),
                              ),
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.home_outlined),
                          label: const Text('Quay về trang chủ'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CandidateVoteCard extends StatelessWidget {
  const _CandidateVoteCard({
    required this.candidate,
    required this.isSelected,
    required this.onTap,
  });

  final Candidate candidate;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Colors.blue.shade700 : Colors.grey.shade400;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                    color: isSelected ? color : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate.candidateName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        candidate.candidateDescription.isEmpty
                            ? 'Không có mô tả.'
                            : candidate.candidateDescription,
                        style: TextStyle(
                          height: 1.5,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Blockchain Candidate ID: ${candidate.blockchainCandidateId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
