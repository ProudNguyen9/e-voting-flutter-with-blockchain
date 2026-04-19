import 'package:flutter/material.dart';

import '../model/voter_register_request.dart';
import '../server/auth_server.dart';

class VoterRegisterPage extends StatefulWidget {
  const VoterRegisterPage({
    super.key,
    this.baseUrl = 'http://172.20.10.4:3000',
  });

  final String baseUrl;

  @override
  State<VoterRegisterPage> createState() => _VoterRegisterPageState();
}

class _VoterRegisterPageState extends State<VoterRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _baseUrlController;
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthServer _authServer = AuthServer();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _statusMessage = 'Nhập thông tin để đăng ký tài khoản cử tri.';
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController(text: widget.baseUrl);
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
      _isError = false;
      _statusMessage = 'Đang gửi yêu cầu đăng ký...';
    });

    try {
      final result = await _authServer.registerVoter(
        baseUrl: _baseUrlController.text,
        request: VoterRegisterRequest(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _isError = !result.success;
        _statusMessage = result.message;
      });

      if (result.success) {
        final baseUrl = _baseUrlController.text.trim();
        _fullNameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();

        _showSnackBar(
          'Đăng ký thành công. Chuyển sang trang đăng nhập.',
          isError: false,
        );

        await Future<void>.delayed(const Duration(milliseconds: 300));
        if (!mounted) {
          return;
        }
        Navigator.of(context).pop(baseUrl);
        return;
      }

      _showSnackBar(result.message, isError: !result.success);
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

  String? _validateFullName(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Nhập họ và tên';
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

  String? _validateConfirmPassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Nhập lại mật khẩu';
    }
    if (value != _passwordController.text) {
      return 'Mật khẩu nhập lại không khớp';
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
                          Icons.how_to_vote_rounded,
                          size: 56,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Đăng ký cử tri',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tạo tài khoản cử tri và gửi dữ liệu đến API /api/auth/register của backend.',
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
                            hintText: 'http://localhost:3000',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.dns_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _fullNameController,
                          textInputAction: TextInputAction.next,
                          validator: _validateFullName,
                          decoration: const InputDecoration(
                            labelText: 'Họ và tên',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
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
                          textInputAction: TextInputAction.next,
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
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          validator: _validateConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Nhập lại mật khẩu',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(
                              Icons.verified_user_outlined,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                              icon: Icon(
                                _obscureConfirmPassword
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
                            onPressed: _isSubmitting ? null : _submitRegister,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.app_registration),
                            label: Text(
                              _isSubmitting
                                  ? 'Đang đăng ký...'
                                  : 'Đăng ký cử tri',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.of(
                                  context,
                                ).pop(_baseUrlController.text.trim()),
                          child: const Text('Quay lại đăng nhập'),
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
