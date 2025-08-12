import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class TinhThanhService {
  List<dynamic> _tinhThanhList = [];

  Future<void> loadData() async {
    final String jsonString = await rootBundle.loadString(
      'lib/assets/data/tinhthanh.json',
    );
    _tinhThanhList = jsonDecode(jsonString);
  }

  /// Lấy danh sách tỉnh/thành
  Future<List<Map<String, dynamic>>> getTinhThanh() async {
    if (_tinhThanhList.isEmpty) {
      await loadData();
    }
    return _tinhThanhList.map((e) => {
      'id': e['id'],
      'name': e['name'],
    }).toList();
  }

  List<Map<String, dynamic>> getHuyenByTinh(int idProvince) {
    final province = _tinhThanhList.firstWhere((e) => e['id'] == idProvince, orElse: () => null);
    if (province != null && province['children'] != null) {
      return List<Map<String, dynamic>>.from(province['children']);
    }
    return [];
  }
}
