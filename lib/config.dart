// lib/config.dart

class AppConfig {
  // Your local machine's IP address
  static const String serverIP = '192.168.1.11';

  // The base URL for your Python NLP Flask API (assuming port 5000)
  static const String baseUrl = 'http://$serverIP:5000';
}
