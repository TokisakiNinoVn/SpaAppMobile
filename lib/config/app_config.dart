// lib/config/app_config.dart

class AppConfig {
  // dev
  // static const String ip = "192.168.1.5";
  // static const String apiWebsocket = "ws://spa-be-api.onrender.com/api/private/ws/account-status";
  // static const String domain = "http://192.168.1.5:5001";
  // static const String apiUrl = "http://192.168.1.5:5001";
  // static const String apiWebsocketUrl = "ws://192.168.1.5:5001";
  // static const String apiUrlTinhThanh = "https://api-tinh-thanh-git-main-toiyours-projects.vercel.app";
  // static const String apiUrlPrivate = "$apiUrl/api/private";
  // static const String apiUrlPublic = "$apiUrl/api/public";
  // static const String apiUrlImage = "$apiUrl/public";
  // static const String apiKey = "";
  // static const bool isProduction = false;

  // production
  // static const String ip = "192.168.1.70";

  static const String apiWebsocket = "wss://spa-be-api.onrender.com/api/private/ws/account-status";
  static const String domain = "https://spa-be-api.onrender.com";
  static const String apiUrl = "https://spa-be-api.onrender.com";
  static const String apiWebsocketUrl = "ws://spa-be-api.onrender.com";
  static const String apiUrlTinhThanh = "https://api-tinh-thanh-git-main-toiyours-projects.vercel.app";
  static const String apiUrlPrivate = "$apiUrl/api/private";
  static const String apiUrlPublic = "$apiUrl/api/public";
  static const String apiUrlImage = "$apiUrl/public";
  static const String apiKey = "";
  static const bool isProduction = false;
}
