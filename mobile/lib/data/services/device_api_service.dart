import 'package:dio/dio.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_call.dart';

class DeviceApiService {
  DeviceApiService(this._dio);

  final Dio _dio;

  /// Stores the FCM token so the backend can push order updates here.
  Future<void> registerToken(String token) {
    return guardApiCall(() async {
      await _dio.put<void>(ApiEndpoints.deviceToken, data: {'token': token});
    });
  }
}
