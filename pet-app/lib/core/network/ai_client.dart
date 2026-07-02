import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';

enum AiProvider { local, cloud }

class AIClient {
  final Dio _dio;
  final AiProvider _provider;
  final bool _useLocalAI;

  AIClient({required bool useLocalAI, String? apiKey})
      : _useLocalAI = useLocalAI,
        _provider = useLocalAI ? AiProvider.local : AiProvider.cloud,
        _dio = Dio(BaseOptions(
          baseUrl: useLocalAI
              ? AppConstants.localAiBaseUrl
              : AppConstants.cloudApiBaseUrl,
          connectTimeout: AppConstants.apiTimeout,
          receiveTimeout: useLocalAI ? AppConstants.aiTimeout : AppConstants.apiTimeout,
          headers: {
            'Content-Type': 'application/json',
            'X-API-Key': apiKey ?? AppConstants.localAiServiceKey,
          },
        ));

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> uploadFile(
    String path, {
    required String filePath,
    String fieldName = 'file',
    Map<String, dynamic>? extraFields,
  }) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
      if (extraFields != null) ...extraFields,
    });
    return _dio.post(path, data: formData);
  }

  AiProvider get provider => _provider;
  bool get isLocal => _useLocalAI;
}

final aiClientProvider = Provider.family<AIClient, bool>((_, useLocalAI) {
  return AIClient(useLocalAI: useLocalAI);
});
