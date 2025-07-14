// auth_routes.dart
import '../config/app_config.dart';

class TechnicianApiRoutes {
  static const String createTechnician = '${AppConfig.apiUrlPrivate}/technician/create';
  static const String createTechnicianNoAccount = '${AppConfig.apiUrlPrivate}/technician/create-no-account';
  static const String detailTechnician = '${AppConfig.apiUrlPrivate}/technician';
}
