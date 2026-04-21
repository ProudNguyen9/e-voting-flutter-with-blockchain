import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/api_result.dart';
import '../model/login_request.dart';
import '../model/login_result.dart';
import '../model/voter_register_request.dart';

class AuthServer {
  AuthServer({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<ApiResult> registerVoter({
    required String baseUrl,
    required VoterRegisterRequest request,
  }) async {
    final response = await _client.post(
      Uri.parse('${_normalizedBaseUrl(baseUrl)}/api/auth/register'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    final data = _decodeResponse(response, actionName: 'Đăng ký thất bại');
    return ApiResult.fromJson(data);
  }

  Future<LoginResult> login({
    required String baseUrl,
    required LoginRequest request,
  }) async {
    final response = await _client.post(
      Uri.parse('${_normalizedBaseUrl(baseUrl)}/api/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    final data = _decodeResponse(response, actionName: 'Đăng nhập thất bại');
    return LoginResult.fromJson(data);
  }

  Future<ApiResult> connectWallet({
    required String baseUrl,
    required String token,
    required String walletAddress,
  }) async {
    final response = await _client.post(
      Uri.parse('${_normalizedBaseUrl(baseUrl)}/api/auth/connect-wallet'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'walletAddress': walletAddress}),
    );

    final data = _decodeResponse(response, actionName: 'Kết nối ví thất bại');
    return ApiResult.fromJson(data);
  }

  Future<Map<String, dynamic>> updateWalletAddress({
    required String baseUrl,
    required String token,
    required String walletAddress,
  }) async {
    try {
      final response = await _client.put(
        Uri.parse('${_normalizedBaseUrl(baseUrl)}/api/auth/update-wallet'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'walletAddress': walletAddress}),
      );

      final data = _decodeResponse(
        response,
        actionName: 'Cập nhật ví thất bại',
      );
      return {
        'success': true,
        'message': data['message'] ?? 'Cập nhật thành công',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  String _normalizedBaseUrl(String baseUrl) {
    return baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
  }

  Map<String, dynamic> _decodeResponse(
    http.Response response, {
    required String actionName,
  }) {
    final Map<String, dynamic> data = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 400) {
      throw Exception(
        (data['error'] ?? '$actionName (${response.statusCode})').toString(),
      );
    }

    return data;
  }
}
