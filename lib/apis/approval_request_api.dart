// auth_routes.dart
import '../config/app_config.dart';

class ApprovalRequestApiRoutes {
  static const String getAllApprovalRequest = '${AppConfig.apiUrlPrivate}/approval-request';
  static const String approveApprovalRequest = '${AppConfig.apiUrlPrivate}/approval-request/approve';
}
