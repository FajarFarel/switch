// class Env {
//   // Default to 10.0.2.2 for Android Emulator connecting to host localhost:5000
//   static const String baseUrl = String.fromEnvironment(
//     'BASE_URL',
//     defaultValue: 'http://10.0.2.2:5000',
//   );

//   static const int receiveTimeout = 15000; // ms
//   static const int connectTimeout = 15000; // ms
// }
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