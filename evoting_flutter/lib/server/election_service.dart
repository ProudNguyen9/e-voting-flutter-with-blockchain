import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/api_result.dart';
import '../model/candidate.dart';
import '../model/election_summary.dart';

class ElectionService {
  ElectionService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<ElectionSummary>> getElections({
    required String baseUrl,
    required String token,
  }) async {
    final response = await _client.get(
      Uri.parse('${_normalizedBaseUrl(baseUrl)}/api/elections'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = _decodeResponse(
      response,
      actionName: 'Lấy danh sách bầu cử thất bại',
    );

    final elections = (data['elections'] as List?) ?? const [];
    return elections
        .whereType<Map>()
        .map((item) => ElectionSummary.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<Map<String, dynamic>> getCandidates({
    required String baseUrl,
    required String token,
    required int electionId,
  }) async {
    final response = await _client.get(
      Uri.parse(
        '${_normalizedBaseUrl(baseUrl)}/api/elections/$electionId/candidates',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = _decodeResponse(
      response,
      actionName: 'Lấy danh sách ứng cử viên thất bại',
    );

    final election = data['election'] as Map<String, dynamic>?;
    final candidatesList = (data['candidates'] as List?) ?? const [];
    final candidates = candidatesList
        .whereType<Map>()
        .map((item) => Candidate.fromJson(item.cast<String, dynamic>()))
        .toList();

    return {
      'election': election != null ? ElectionSummary.fromJson(election) : null,
      'candidates': candidates,
    };
  }

  Future<ApiResult> registerElection({
    required String baseUrl,
    required String token,
    required int electionId,
  }) async {
    final response = await _client.post(
      Uri.parse(
        '${_normalizedBaseUrl(baseUrl)}/api/elections/$electionId/join',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = _decodeResponse(
      response,
      actionName: 'Đăng ký tham dự thất bại',
    );

    return ApiResult.fromJson(data);
  }

  Future<ApiResult> verifyPin({
    required String baseUrl,
    required String token,
    required int electionId,
    required String pinCode,
  }) async {
    final response = await _client.post(
      Uri.parse(
        '${_normalizedBaseUrl(baseUrl)}/api/elections/$electionId/verify-pin',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'pinCode': pinCode}),
    );

    final data = _decodeResponse(response, actionName: 'Xác thực PIN thất bại');

    return ApiResult.fromJson(data);
  }

  Future<ApiResult> submitServerSignedVote({
    required String baseUrl,
    required String token,
    required int electionId,
    required int blockchainElectionId,
    required int candidateBlockchainId,
    required String verifiedPin,
    required String voterAddress,
  }) async {
    final response = await _client.post(
      Uri.parse(
        '${_normalizedBaseUrl(baseUrl)}/api/elections/$electionId/vote',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'blockchainElectionId': blockchainElectionId,
        'candidateBlockchainId': candidateBlockchainId,
        'pinCode': verifiedPin,
        'voterAddress': voterAddress,
      }),
    );

    final data = _decodeResponse(
      response,
      actionName: 'Gửi phiếu bầu thất bại',
    );

    return ApiResult.fromJson(data);
  }

  Future<Map<String, dynamic>> getContractInfo({
    required String baseUrl,
  }) async {
    final response = await _client.get(
      Uri.parse('${_normalizedBaseUrl(baseUrl)}/api/contract-info'),
      headers: const {'Content-Type': 'application/json'},
    );

    return _decodeResponse(
      response,
      actionName: 'Lấy thông tin contract thất bại',
    );
  }

  Future<ApiResult> trackGas({
    required String baseUrl,
    required String token,
    required int electionId,
    required String txHash,
  }) async {
    final response = await _client.post(
      Uri.parse('${_normalizedBaseUrl(baseUrl)}/api/gas-tracking'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'electionId': electionId, 'txHash': txHash}),
    );

    final data = _decodeResponse(
      response,
      actionName: 'Lưu gas tracking thất bại',
    );

    return ApiResult.fromJson(data);
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
