class Env {
  static String get baseUrl {
    const customUrl = String.fromEnvironment('BASE_URL');
    if (customUrl.isNotEmpty) {
      return customUrl;
    }

    return 'https://8aa8-140-213-187-14.ngrok-free.app';
  }

  static const int receiveTimeout = 15000; // ms
  static const int connectTimeout = 15000; // ms
}
