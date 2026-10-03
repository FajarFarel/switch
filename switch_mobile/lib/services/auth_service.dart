import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    return await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.login,
      body: {
        'email': email,
        'password': password,
      },
      requiresAuth: false,
      create: (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    return await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.register,
      body: {
        'username': username,
        'email': email,
        'password': password,
      },
      requiresAuth: false,
      create: (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<UserModel>> getProfile() async {
    return await _apiClient.get<UserModel>(
      ApiConstants.me,
      requiresAuth: true,
      create: (json) => UserModel.fromJson(json as Map<String, dynamic>),
    );
  }
}
