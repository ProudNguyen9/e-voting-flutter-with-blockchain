import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

import '../server/auth_server.dart';
import '../server/wallet_connect_service.dart';
import 'home_page.dart';

class WalletSetupPage extends StatefulWidget {
  const WalletSetupPage({
    super.key,
    required this.baseUrl,
    required this.email,
    required this.token,
  });

  final String baseUrl;
  final String email;
  final String token;

  @override
  State<WalletSetupPage> createState() => _WalletSetupPageState();
}

class _WalletSetupPageState extends State<WalletSetupPage>
    with WidgetsBindingObserver {
  final AuthServer _authServer = AuthServer();
  final _formKey = GlobalKey<FormState>();
  final _walletAddressController = TextEditingController();
  String? _walletConnectUri;
  String? _sessionTopic;
  bool _isInitializingWalletKit = false;
  bool _isDisconnectingWallet = false;
  bool _isOpeningMetaMask = false;
  bool _isSavingWallet = false;
  bool _isError = false;
  String _statusMessage =
      'Bấm kết nối MetaMask, xác nhận trong ví, sau đó quay lại app. Địa chỉ ví sẽ tự động điền vào ô bên dưới.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _walletAddressController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isOpeningMetaMask) {
      unawaited(_syncActiveSessionFromWallet());
    }
  }

  Future<Web3App> _ensureWeb3AppInitialized() async {
    if (mounted) {
      setState(() {
        _isInitializingWalletKit = true;
        _isError = false;
        _statusMessage =
            'Đang khởi tạo WalletConnect v2 để chuẩn bị kết nối MetaMask...';
      });
    }

    try {
      return await WalletConnectService.ensureInitialized();
    } catch (error) {
      throw Exception(_normalizeWalletConnectError(error));
    } finally {
      if (mounted) {
        setState(() {
          _isInitializingWalletKit = false;
        });
      }
    }
  }

  Future<void> _launchWalletConnectUri(String uri) async {
    final deepLink = 'metamask://wc?uri=${Uri.encodeComponent(uri)}';
    _walletConnectUri = deepLink;

    final openedMetaMask = await launchUrlString(
      deepLink,
      mode: LaunchMode.externalApplication,
    );

    if (openedMetaMask) {
      return;
    }

    final fallbackLink =
        'https://metamask.app.link/wc?uri=${Uri.encodeComponent(uri)}';
    _walletConnectUri = fallbackLink;

    final openedFallback = await launchUrlString(
      fallbackLink,
      mode: LaunchMode.externalApplication,
    );

    if (!openedFallback) {
      throw Exception('Không mở được MetaMask bằng WalletConnect v2');
    }
  }

  String _extractWalletAddress(SessionData session) {
    return WalletConnectService.extractWalletAddress(session);
  }

  String _extractChainId(SessionData session) {
    return WalletConnectService.extractChainId(session);
  }

  bool _sessionMatchesExpected(SessionData session) {
    return WalletConnectService.sessionMatchesExpected(session);
  }

  Future<void> _fillWalletAddressFromSession(SessionData session) async {
    final walletAddress = _extractWalletAddress(session);
    final chainId = _extractChainId(session);
    _walletAddressController.text = walletAddress;
    _sessionTopic = session.topic;

    if (!mounted) {
      return;
    }

    setState(() {
      _isOpeningMetaMask = false;
      _isError = false;
      _statusMessage =
          'Đã kết nối MetaMask thành công qua WalletConnect v2 trên mạng $chainId. Địa chỉ ví đã được tự động điền, bạn chỉ cần bấm lưu.';
    });
  }

  Future<void> _syncActiveSessionFromWallet() async {
    try {
      final sessions = await WalletConnectService.getActiveSessions();
      if (sessions.isEmpty) {
        return;
      }

      for (final session in sessions.values) {
        if (_sessionMatchesExpected(session)) {
          await _fillWalletAddressFromSession(session);
          return;
        }
      }

      await _fillWalletAddressFromSession(sessions.values.first);
    } catch (_) {
      // chờ flow timeout hiện tại xử lý nếu session vẫn chưa sẵn sàng
    }
  }

  String _normalizeWalletConnectError(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    final lower = raw.toLowerCase();

    if (lower.contains('projectid') || lower.contains('project id')) {
      return 'Project ID WalletConnect không hợp lệ hoặc chưa được cấu hình đúng.';
    }

    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('relay')) {
      return 'Không thể kết nối tới relay của WalletConnect v2. Hãy kiểm tra mạng Internet hoặc cấu hình projectId.';
    }

    if (lower.contains('user rejected')) {
      return 'Người dùng đã từ chối kết nối trong MetaMask.';
    }

    if (lower.contains('metamask')) {
      return raw;
    }

    if (lower.contains('walletconnect')) {
      return 'Kết nối WalletConnect v2 thất bại. $raw';
    }

    return raw;
  }

  Future<void> _disconnectCurrentWallet({bool showMessage = true}) async {
    await _ensureWeb3AppInitialized();
    final sessions = await WalletConnectService.getActiveSessions();

    if (sessions.isEmpty) {
      _walletAddressController.clear();
      _sessionTopic = null;
      if (!mounted) {
        return;
      }

      setState(() {
        _isDisconnectingWallet = false;
        _isError = false;
        _statusMessage =
            'Hiện chưa có session MetaMask nào đang kết nối. Bạn có thể bấm Kết nối MetaMask để chọn ví.';
      });
      return;
    }

    await WalletConnectService.disconnectAllSessions();

    _walletAddressController.clear();
    _sessionTopic = null;
    _walletConnectUri = null;

    if (!mounted) {
      return;
    }

    setState(() {
      _isDisconnectingWallet = false;
      _isError = false;
      _statusMessage =
          'Đã ngắt kết nối MetaMask hiện tại. Bây giờ bạn có thể kết nối lại để chọn account khác.';
    });

    if (showMessage) {
      _showSnackBar(
        'Đã ngắt session MetaMask cũ. Hãy kết nối lại để chọn địa chỉ ví khác.',
        isError: false,
      );
    }
  }

  Future<void> _switchWalletAccount() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isDisconnectingWallet = true;
      _isError = false;
      _statusMessage =
          'Đang ngắt session MetaMask hiện tại để bạn chọn account khác...';
    });

    try {
      await _disconnectCurrentWallet();
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = _normalizeWalletConnectError(error);
      setState(() {
        _isDisconnectingWallet = false;
        _isError = true;
        _statusMessage = message;
      });
      _showSnackBar(message, isError: true);
    }
  }

  Future<void> _openMetaMask() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isOpeningMetaMask = true;
      _isError = false;
      _statusMessage =
          'Đang tạo yêu cầu WalletConnect v2. Khi MetaMask mở ra, hãy bấm Connect/Approve rồi quay lại app để thấy địa chỉ ví tự điền.';
    });

    try {
      final app = await _ensureWeb3AppInitialized();
      final sessions = await WalletConnectService.getActiveSessions();
      if (sessions.isNotEmpty) {
        for (final session in sessions.values) {
          if (_sessionMatchesExpected(session)) {
            await _fillWalletAddressFromSession(session);
            return;
          }
        }

        await _disconnectCurrentWallet(showMessage: false);
      }

      final response = await app.connect(
        optionalNamespaces: {
          WalletConnectService.walletNamespace: const RequiredNamespace(
            chains: [WalletConnectService.walletChainId],
            methods: [
              'eth_sendTransaction',
              'personal_sign',
              'eth_sign',
              'eth_signTypedData',
            ],
            events: ['accountsChanged', 'chainChanged'],
          ),
        },
      );

      final uri = response.uri;
      if (uri == null) {
        throw Exception('WalletConnect v2 không trả về URI để mở MetaMask');
      }

      await _launchWalletConnectUri(uri.toString());
      unawaited(_syncActiveSessionFromWallet());

      final session = await response.session.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () async {
          final sessionsAfterTimeout =
              await WalletConnectService.getActiveSessions();
          for (final session in sessionsAfterTimeout.values) {
            if (_sessionMatchesExpected(session)) {
              return session;
            }
          }

          if (sessionsAfterTimeout.isNotEmpty) {
            return sessionsAfterTimeout.values.first;
          }

          throw Exception(
            'Hết thời gian chờ xác nhận từ MetaMask. Hãy mở lại MetaMask và bấm Connect/Approve.',
          );
        },
      );

      await _fillWalletAddressFromSession(session);
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = _normalizeWalletConnectError(error);
      setState(() {
        _isOpeningMetaMask = false;
        _isError = true;
        _statusMessage = message;
      });
      _showSnackBar(message, isError: true);
    }
  }

  Future<void> _submitManualWallet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.token.trim().isEmpty) {
      setState(() {
        _isError = true;
        _statusMessage = 'Thiếu token đăng nhập để gửi địa chỉ ví lên backend.';
      });
      _showSnackBar(_statusMessage, isError: true);
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSavingWallet = true;
      _isError = false;
      _statusMessage = 'Đang gửi địa chỉ ví lên backend...';
    });

    try {
      final result = await _authServer.connectWallet(
        baseUrl: widget.baseUrl,
        token: widget.token,
        walletAddress: _walletAddressController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSavingWallet = false;
        _isError = false;
        _statusMessage = result.message;
      });

      _showSnackBar(result.message, isError: false);

      final walletAddress = _walletAddressController.text.trim();

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomePage(
            baseUrl: widget.baseUrl,
            token: widget.token,
            email: widget.email,
            walletAddress: walletAddress,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = error.toString().replaceFirst('Exception: ', '');
      setState(() {
        _isSavingWallet = false;
        _isError = true;
        _statusMessage = message;
      });
      _showSnackBar(message, isError: true);
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

  String? _validateWalletAddress(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Nhập địa chỉ ví';
    }

    final walletRegex = RegExp(r'^0x[a-fA-F0-9]{40}$');
    if (!walletRegex.hasMatch(text)) {
      return 'Địa chỉ ví không hợp lệ';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isBusy =
        _isInitializingWalletKit ||
        _isDisconnectingWallet ||
        _isOpeningMetaMask ||
        _isSavingWallet;

    return Scaffold(
      appBar: AppBar(title: const Text('Thiết lập MetaMask')),
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 56,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Liên kết ví MetaMask',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'App dùng WalletConnect v2 để mở MetaMask. Sau khi bạn xác nhận kết nối trong ví, địa chỉ ví sẽ được tự động điền khi quay lại ứng dụng.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 24),
                        _InfoTile(label: 'Server URL', value: widget.baseUrl),
                        const SizedBox(height: 12),
                        _InfoTile(label: 'Email', value: widget.email),
                        const SizedBox(height: 12),
                        _InfoTile(
                          label: 'Token đăng nhập',
                          value: widget.token.isEmpty
                              ? 'Chưa có token'
                              : 'Đã nhận token từ backend',
                        ),
                        const SizedBox(height: 12),
                        _InfoTile(
                          label: 'WalletConnect Project ID',
                          value: WalletConnectService.projectId,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _isError
                                ? Colors.red.shade50
                                : colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isError
                                  ? Colors.red.shade200
                                  : colorScheme.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            _statusMessage,
                            style: TextStyle(
                              color: _isError
                                  ? Colors.red.shade800
                                  : Colors.grey.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: isBusy ? null : _openMetaMask,
                          icon: _isInitializingWalletKit || _isOpeningMetaMask
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.open_in_new_outlined),
                          label: Text(
                            _isInitializingWalletKit
                                ? 'Đang khởi tạo WalletConnect v2...'
                                : _isOpeningMetaMask
                                ? 'Đang mở MetaMask...'
                                : 'Kết nối MetaMask',
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: isBusy ? null : _switchWalletAccount,
                          icon: _isDisconnectingWallet
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.swap_horiz_outlined),
                          label: Text(
                            _isDisconnectingWallet
                                ? 'Đang đổi tài khoản...'
                                : 'Đổi tài khoản MetaMask',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _walletAddressController,
                          validator: _validateWalletAddress,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Địa chỉ ví MetaMask',
                            hintText: '0x...',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.wallet_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: isBusy ? null : _submitManualWallet,
                          icon: _isSavingWallet
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.cloud_upload_outlined),
                          label: Text(
                            _isSavingWallet
                                ? 'Đang lưu địa chỉ ví...'
                                : 'Lưu địa chỉ ví lên backend',
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Text(
                            _walletConnectUri == null
                                ? 'Các bước: 1) bấm Kết nối MetaMask, 2) app khởi tạo WalletConnect v2 bằng projectId Reown, 3) MetaMask mở vào màn hình Connect/Approve, 4) quay lại app để thấy địa chỉ ví được điền sẵn, 5) nếu muốn ví khác thì bấm Đổi tài khoản MetaMask để ngắt session cũ, 6) bấm kết nối lại và chọn account mới, 7) bấm lưu để app gọi API /api/auth/connect-wallet với Bearer token.'
                                : 'Nếu MetaMask chưa hiện đúng màn hình kết nối, app đang dùng deeplink này: $_walletConnectUri\nSession topic hiện tại: ${_sessionTopic ?? 'chưa có'}',
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
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(value),
        ],
      ),
    );
  }
}
