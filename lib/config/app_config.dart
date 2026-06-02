// lib/config/app_config.dart
import 'package:flutter/cupertino.dart';
import 'package:spa_app/screens/customer/tabs/home_customer_tab.dart';

class AppConfig {
  static const String appName = "Zen Home";
  static const String appNameUpperCase = "ZEN HOME";
  static const String emailAppSupport = "zenhome.spa.support@gmail.com";
  static const String logoAppUrl = "lib/assets/images/zen-hone-circle-logo.png";
  static const String adminZalo = "0777378727";

  static const List<int> time = [60, 90, 120];
  static final bool isProduction = true;
  static final String urlPrivacy = "https://serene-spa-green.vercel.app/privacy";
  static final String urlSupport = "https://serene-spa-green.vercel.app/support";
  static final String urlTerm = "https://serene-spa-green.vercel.app/terms";

  // dev
  static const String ip = "10.16.23.104";
  // static const String apiWebsocket = "ws://apispa.tokisakinino.xyz/api/private/ws/realtime";
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

  static const String apiWebsocket = "wss://apispa.tokisakinino.xyz/api/private/ws/realtime";
  static const String domain = "https://apispa.tokisakinino.xyz";
  static const String apiUrl = "https://apispa.tokisakinino.xyz";
  static const String apiWebsocketUrl = "ws://apispa.tokisakinino.xyz";
  static const String apiUrlTinhThanh = "https://api-tinh-thanh-git-main-toiyours-projects.vercel.app";
  static const String apiUrlPrivate = "$apiUrl/api/private";
  static const String apiUrlPublic = "$apiUrl/api/public";
  static const String apiUrlImage = "$apiUrl/public";
  static const String apiKey = "";

  static const String apiAdminUrlPrivate = "$apiUrl/api/admin/private";

  static const List<String> adminPhone = [
    '0123456789',
    '0777378727',
  ];

  static var supportChannels = [
    // SupportChannel(
    //   iconAsset: 'lib/assets/images/zalo.png',
    //   name: 'Zalo',
    //   description: 'Nhắn tin qua Zalo',
    //   color: Color(0xFF0068FF),
    //   type: SupportType.zalo,
    //   url: 'https://zalo.me/0777378727', // Thay bằng số Zalo thật
    //   packageName: 'com.zing.zalo', // Package name cho Zalo
    // ),
    //  SupportChannel(
    //   iconAsset: 'lib/assets/images/messenger.png',
    //   name: 'Messenger',
    //   description: 'Chat qua Facebook Messenger',
    //   color: Color(0xFF0084FF),
    //   type: SupportType.messenger,
    //   url: 'https://m.me/your_page_id', // Thay bằng link Messenger thật
    //   packageName: 'com.facebook.orca',
    // ),
    //  SupportChannel(
    //   iconAsset: 'lib/assets/images/hotline.png',
    //   name: 'Hotline',
    //   description: 'Gọi tổng đài hỗ trợ',
    //   color: Color(0xFF34B7F1),
    //   type: SupportType.phone,
    //   url: 'tel:1900xxxx', // Thay bằng số hotline thật
    // ),
     SupportChannel(
      iconAsset: 'lib/assets/images/email.png',
      name: 'Email',
      description: 'Gửi email hỗ trợ',
      color: Color(0xFFEA4335),
      type: SupportType.email,
      url: 'mailto:app.zenhome.spa@gmail.com',
    ),
    //  SupportChannel(
    //   iconAsset: 'lib/assets/images/telegram.png',
    //   name: 'Telegram',
    //   description: 'Nhắn tin qua Telegram',
    //   color: Color(0xFF26A5E4),
    //   type: SupportType.telegram,
    //   url: 'https://t.me/your_username', // Thay bằng link Telegram thật
    //   packageName: 'org.telegram.messenger',
    // ),
  ];
}
