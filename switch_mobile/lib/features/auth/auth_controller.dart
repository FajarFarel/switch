import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/storage/local_storage.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService;
  final LocalStorage _localStorage;

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _currentUser != null;
  String? get errorMessage => _errorMessage;

  AuthController({AuthService? authService, LocalStorage? localStorage})
      : _authService = authService ?? AuthService(),
        _localStorage = localStorage ?? LocalStorage();

  Future<bool> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _localStorage.getToken();
      if (token != null && token.isNotEmpty) {
        final profileResponse = await _authService.getProfile();
        if (profileResponse.success && profileResponse.data != null) {
          _currentUser = profileResponse.data;
          await _localStorage.saveUserData(jsonEncode(_currentUser!.toJson()));
          _isLoading = false;
          _isInitialized = true;
          notifyListeners();
          return true;
        }
      }
    } catch (_) {}

    await logout();
    _isLoading = false;
    _isInitialized = true;
    notifyListeners();
    return false;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _authService.login(email: email, password: password);

    _isLoading = false;
    if (response.success && response.data != null) {
      final token = response.data!['token'] as String?;
      final userData = response.data!['user'] as Map<String, dynamic>?;

      if (token != null && userData != null) {
        await _localStorage.saveToken(token);
        _currentUser = UserModel.fromJson(userData);
        await _localStorage.saveUserData(jsonEncode(_currentUser!.toJson()));
        notifyListeners();
        return true;
      }
    }

    _errorMessage = response.message.isNotEmpty
        ? response.message
        : 'Login gagal, periksa email dan password';
    notifyListeners();
    return false;
  }

  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _authService.register(
      username: username,
      email: email,
      password: password,
    );

    _isLoading = false;
    if (response.success) {
      notifyListeners();
      return true;
    }

    _errorMessage = response.message.isNotEmpty
        ? response.message
        : 'Registrasi gagal';
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    await _localStorage.clearAll();
    notifyListeners();
  }
}
