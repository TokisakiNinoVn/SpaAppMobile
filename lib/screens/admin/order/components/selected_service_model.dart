import 'package:spa_app/helper/logger_utils.dart';

class SelectedService {
  final String serviceId;
  final String serviceName;
  final String timePriceId;
  final int duration;
  final int price;

  const SelectedService({
    required this.serviceId,
    required this.serviceName,
    required this.timePriceId,
    required this.duration,
    required this.price,
  });

  void logInfo() {
    appLog('''
    ======= Selected Service =======
    serviceId   : $serviceId
    serviceName : $serviceName
    timePriceId : $timePriceId
    duration    : $duration phút
    price       : $price
    ================================
    ''');
  }
  @override
  String toString() {
    return '''
    _SelectedService(
      serviceId: $serviceId,
      serviceName: $serviceName,
      timePriceId: $timePriceId,
      duration: $duration,
      price: $price,
    )
    ''';
  }
}
