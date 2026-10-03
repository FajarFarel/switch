import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/env.dart';
import '../storage/local_storage.dart';
import 'api_response.dart';

class ApiClient {
  final LocalStorage _localStorage;
  final http.Client _client;

  ApiClient({LocalStorage? localStorage, http.Client? client})
      : _localStorage = localStorage ?? LocalStorage(),
        _client = client ?? http.Client();

  Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _localStorage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Uri _buildUri(String endpoint) {
    return Uri.parse('${Env.baseUrl}$endpoint');
  }

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    bool requiresAuth = true,
    T Function(dynamic json)? create,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await _client.get(_buildUri(endpoint), headers: headers);
      return _processResponse<T>(response, create);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        message: 'Koneksi gagal atau terjadi kesalahan',
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    T Function(dynamic json)? create,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await _client.post(
        _buildUri(endpoint),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse<T>(response, create);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        message: 'Koneksi gagal atau terjadi kesalahan',
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    T Function(dynamic json)? create,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await _client.put(
        _buildUri(endpoint),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse<T>(response, create);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        message: 'Koneksi gagal atau terjadi kesalahan',
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    bool requiresAuth = true,
    T Function(dynamic json)? create,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await _client.delete(_buildUri(endpoint), headers: headers);
      return _processResponse<T>(response, create);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        message: 'Koneksi gagal atau terjadi kesalahan',
        error: e.toString(),
      );
    }
  }

  ApiResponse<T> _processResponse<T>(
    http.Response response,
    T Function(dynamic json)? create,
  ) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return ApiResponse.fromJson(decoded, create);
      }
      return ApiResponse<T>(
        success: response.statusCode >= 200 && response.statusCode < 300,
        message: 'Response format tidak valid',
      );
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        message: 'Gagal memproses respon server',
        error: e.toString(),
      );
    }
  }
}
