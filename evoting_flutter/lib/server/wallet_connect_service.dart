import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

class WalletConnectService {
  WalletConnectService._();

  static const String projectId = '46f0649f0b8d05e56b15c3bd8acbf454';
  static const String relayUrl = 'wss://relay.walletconnect.com';
  static const String redirectScheme = 'evotingflutter://wallet';
  static const String walletNamespace = 'eip155';
  static const String walletChainId = 'eip155:31337';

  static const PairingMetadata metadata = PairingMetadata(
    name: 'E-Voting',
    description: 'Kết nối MetaMask để ký giao dịch trực tiếp trên blockchain',
    url: 'https://walletconnect.com',
    icons: ['https://walletconnect.com/walletconnect-logo.png'],
    redirect: Redirect(native: redirectScheme),
  );

  static Web3App? _app;

  static Future<Web3App> ensureInitialized() async {
    final existing = _app;
    if (existing != null) {
      return existing;
    }

    final app = await Web3App.createInstance(
      projectId: projectId,
      relayUrl: relayUrl,
      metadata: metadata,
      logLevel: LogLevel.error,
    );
    _app = app;
    return app;
  }

  static Future<Map<String, SessionData>> getActiveSessions() async {
    final app = await ensureInitialized();
    return app.getActiveSessions();
  }

  static String extractWalletAddress(SessionData session) {
    final namespace = session.namespaces[walletNamespace];
    final accounts = namespace?.accounts ?? const <String>[];
    if (accounts.isEmpty) {
      throw Exception('MetaMask chưa trả về địa chỉ ví.');
    }

    return accounts.first.split(':').last;
  }

  static String extractChainId(SessionData session) {
    final namespace = session.namespaces[walletNamespace];
    final accounts = namespace?.accounts ?? const <String>[];
    if (accounts.isEmpty) {
      throw Exception('Không xác định được chainId của ví.');
    }

    final parts = accounts.first.split(':');
    if (parts.length < 2) {
      throw Exception('Dữ liệu chainId từ ví không hợp lệ.');
    }

    return '${parts[0]}:${parts[1]}';
  }

  static bool sessionMatchesExpected(
    SessionData session, {
    String? expectedWalletAddress,
  }) {
    final normalizedExpectedWallet = expectedWalletAddress
        ?.trim()
        .toLowerCase();
    final sessionWallet = extractWalletAddress(session).toLowerCase();
    final sessionChainId = extractChainId(session);

    final isWalletMatch =
        normalizedExpectedWallet == null ||
        normalizedExpectedWallet.isEmpty ||
        sessionWallet == normalizedExpectedWallet;

    return isWalletMatch && sessionChainId == walletChainId;
  }

  static Future<void> disconnectAllSessions() async {
    final app = await ensureInitialized();
    final sessions = app.getActiveSessions();
    for (final session in sessions.values) {
      await app.disconnectSession(
        topic: session.topic,
        reason: Errors.getSdkError(Errors.USER_DISCONNECTED),
      );
    }
  }
}
