import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/storage_keys.dart';

class LocalStorage {
  final FlutterSecureStorage _storage;

  LocalStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: StorageKeys.token, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: StorageKeys.token);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: StorageKeys.token);
  }

  Future<void> saveUserData(String jsonUserData) async {
    await _storage.write(key: StorageKeys.user, value: jsonUserData);
  }

  Future<String?> getUserData() async {
    return await _storage.read(key: StorageKeys.user);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
