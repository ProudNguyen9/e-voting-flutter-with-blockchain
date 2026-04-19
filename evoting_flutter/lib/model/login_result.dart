class LoginResult {
  const LoginResult({
    required this.message,
    required this.token,
    required this.user,
  });

  final String message;
  final String token;
  final Map<String, dynamic> user;

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      message: (json['message'] ?? 'Đăng nhập thành công').toString(),
      token: (json['token'] ?? '').toString(),
      user:
          (json['user'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{},
    );
  }
}
