class ApiResult {
  const ApiResult({required this.success, required this.message});

  final bool success;
  final String message;

  factory ApiResult.fromJson(Map<String, dynamic> json) {
    return ApiResult(
      success: json['success'] == true,
      message:
          (json['message'] ?? json['error'] ?? 'Không có phản hồi từ server')
              .toString(),
    );
  }
}
