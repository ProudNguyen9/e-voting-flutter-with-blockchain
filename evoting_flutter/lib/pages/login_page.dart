import 'package:flutter/material.dart';

import '../model/login_request.dart';
import '../server/auth_server.dart';
import 'voter_register_page.dart';
import 'wallet_setup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _baseUrlController = TextEditingController(
    text: 'http://172.20.10.4:3000',
  );
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthServer _authServer = AuthServer();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _isError = false;
  String _statusMessage = 'Vui lòng đăng nhập để sử dụng ứng dụng bầu cử.';

  @override
  void dispose() {
    _baseUrlController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
      _isError = false;
      _statusMessage = 'Đang đăng nhập...';
    });

    try {
      final result = await _authServer.login(
        baseUrl: _baseUrlController.text,
        request: LoginRequest(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _isError = false;
        _statusMessage = result.message;
      });

      _showSnackBar(result.message, isError: false);

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WalletSetupPage(
            baseUrl: _baseUrlController.text.trim(),
            email: _emailController.text.trim(),
            token: result.token,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = error.toString().replaceFirst('Exception: ', '');

      setState(() {
        _isSubmitting = false;
        _isError = true;
        _statusMessage = message;
      });

      _showSnackBar(message, isError: true);
    }
  }

  Future<void> _openRegisterPage() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            VoterRegisterPage(baseUrl: _baseUrlController.text.trim()),
      ),
    );

    if (!mounted || result == null || result.isEmpty) {
      return;
    }

    _baseUrlController.text = result;
    setState(() {
      _statusMessage =
          'Đăng ký xong. Vui lòng đăng nhập bằng tài khoản vừa tạo.';
      _isError = false;
    });
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

  String? _validateBaseUrl(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Nhập địa chỉ server';
    }
    final uri = Uri.tryParse(text);
    if (uri == null || (!uri.hasScheme || uri.host.isEmpty)) {
      return 'Server không hợp lệ';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Nhập email';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(text)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) {
      return 'Nhập mật khẩu';
    }
    if (text.length < 6) {
      return 'Mật khẩu tối thiểu 6 ký tự';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
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
                          Icons.login_rounded,
                          size: 56,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Đăng nhập cử tri',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mỗi lần mở ứng dụng, người dùng cần đăng nhập lại để vào hệ thống bầu cử.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _baseUrlController,
                          keyboardType: TextInputType.url,
                          validator: _validateBaseUrl,
                          decoration: const InputDecoration(
                            labelText: 'Server URL',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.dns_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: _validateEmail,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          validator: _validatePassword,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
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
                                  : colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: _isSubmitting ? null : _submitLogin,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.login),
                            label: Text(
                              _isSubmitting ? 'Đang đăng nhập...' : 'Đăng nhập',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          children: [
                            const Text('Chưa có tài khoản?'),
                            TextButton(
                              onPressed: _openRegisterPage,
                              child: const Text('Qua trang đăng ký'),
                            ),
                          ],
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
