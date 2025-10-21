import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:diacritic/diacritic.dart';

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
    // print("${idProvince} - Kiểu dữ liệu idProvince: ${idProvince.runtimeType}");

    final province = _tinhThanhList.firstWhere((e) => e['id'] == idProvince, orElse: () => null);
    // print("_tinhThanhList: ${_tinhThanhList}");

    if (province != null && province['children'] != null) {
      // print("✅ Danh sách huyện/thành phố trực thuộc ${province['name']}:");
      final listQuanHuyen = List<Map<String, dynamic>>.from(province['children']);
      // print("listQuanHuyen: ${listQuanHuyen}");
      return listQuanHuyen;
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getHuyenByTinhV2(int idProvince) async {
    // Nếu chưa load dữ liệu thì tự load
    if (_tinhThanhList.isEmpty) {
      // print("⚠️ Dữ liệu chưa load — tiến hành load...");
      await loadData();
    }

    // print("🔍 Tìm tỉnh có id = $idProvince");
    final province = _tinhThanhList.firstWhere(
          (e) => e['id'] == idProvince,
      orElse: () => null,
    );

    if (province == null) {
      return [];
    }

    final children = province['children'];
    if (children == null || children.isEmpty) {
      return [];
    }

    final List<Map<String, dynamic>> listHuyen =
    List<Map<String, dynamic>>.from(children);
    return listHuyen;
  }

}
