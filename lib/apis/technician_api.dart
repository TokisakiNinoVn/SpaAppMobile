// auth_routes.dart
import 'package:spa_app/config/app_config.dart';

class TechnicianApiRoutes {
  static const String createTechnician = '${AppConfig.apiUrlPrivate}/technician/create';
  static const String updateTechnician = '${AppConfig.apiUrlPrivate}/technician/update';
  static const String createTechnicianNoAccount = '${AppConfig.apiUrlPrivate}/technician/create-no-account';
  static const String detailTechnician = '${AppConfig.apiUrlPrivate}/technician';
  static const String filterTechnician = '${AppConfig.apiUrlPrivate}/technician/filter';

  static const String addTechnician = '${AppConfig.apiUrlPrivate}/technician/create-no-account';
  static const String listTechnicianCreateByUser = '${AppConfig.apiUrlPrivate}/technician/list-technicians-user';
  static const String deleteTechnicianCreateByUser = '${AppConfig.apiUrlPrivate}/technician/delete';

  static const String listTechnicianForCustomer = '${AppConfig.apiUrlPublic}/technician-app/all-technicians';
  static const String detailTechnicianForCustomer = '${AppConfig.apiUrlPublic}/technician-customer';

  static const String updateLocationTechnician = '${AppConfig.apiUrlPrivate}/technician-app/update-location';

}
