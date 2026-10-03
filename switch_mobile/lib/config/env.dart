class Env {
  // Default to 10.0.2.2 for Android Emulator connecting to host localhost:5000
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );

  static const int receiveTimeout = 15000; // ms
  static const int connectTimeout = 15000; // ms
}
