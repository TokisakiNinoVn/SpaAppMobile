// lib/config/app_config.dart
class AppConfig {

  static const List<int> time = [60, 90, 120];
  static final bool isProduction = true;
  static final String urlPrivacy = "https://serene-spa-green.vercel.app/privacy";
  static final String urlSupport = "https://serene-spa-green.vercel.app/support";
  static final String urlTerm = "https://serene-spa-green.vercel.app/terms";

  // dev
  static const String ip = "10.16.23.104";
  // static const String apiWebsocket = "ws://apispa.tokisakinino.xyz/api/private/ws/account-status";
  // static const String domain = "http://${ip}:5001";
  // static const String apiUrl = "http://${ip}:5001";
  // static const String apiWebsocketUrl = "ws://${ip}:5001";
  // static const String apiUrlTinhThanh = "https://api-tinh-thanh-git-main-toiyours-projects.vercel.app";
  // static const String apiUrlPrivate = "$apiUrl/api/private";
  // static const String apiUrlPublic = "$apiUrl/api/public";
  // static const String apiUrlImage = "$apiUrl/public";
  // static const String apiKey = "";

  // production
  // static const String ip = "192.168.1.70";

  static const String apiWebsocket = "wss://apispa.tokisakinino.xyz/api/private/ws/account-status";
  static const String domain = "https://apispa.tokisakinino.xyz";
  static const String apiUrl = "https://apispa.tokisakinino.xyz";
  static const String apiWebsocketUrl = "ws://apispa.tokisakinino.xyz";
  static const String apiUrlTinhThanh = "https://api-tinh-thanh-git-main-toiyours-projects.vercel.app";
  static const String apiUrlPrivate = "$apiUrl/api/private";
  static const String apiUrlPublic = "$apiUrl/api/public";
  static const String apiUrlImage = "$apiUrl/public";
  static const String apiKey = "";

  static const String apiAdminUrlPrivate = "$apiUrl/api/admin/private";
}
