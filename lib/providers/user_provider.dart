import 'dart:io';

import 'package:clean_water/data/models/api_response.dart';
import 'package:clean_water/data/services/list_service.dart';
import 'package:clean_water/presentation/utils/index_utils.dart';
import 'package:flutter/material.dart';

class ListProvider extends ChangeNotifier {
  final ListService _listService = ListService();

  bool isLoading = false;

  String? errorMessage;
  ApiResponse? apiResponse;

  List<dynamic> pricingObjects = [];
  List<dynamic> waterPrices = [];
  List<dynamic> clientTypes = [];
  List<dynamic> areas = [];
  List<dynamic> regions = [];

  Future<bool> loadPricingObjects() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await _listService.getPricingObjects();
      apiResponse = res;

      if (res.success == true) {
        pricingObjects = res.data ?? [];
        return true;
      } else {
        errorMessage = res.message;
        return false;
      }
    } catch (e) {
      errorMessage = 'Đã xảy ra lỗi: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loadWaterPrices() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await _listService.getWaterPrices();
      apiResponse = res;

      if (res.success == true) {
        waterPrices = res.data ?? [];
        return true;
      } else {
        errorMessage = res.message;
        return false;
      }
    } catch (e) {
      errorMessage = 'Đã xảy ra lỗi: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loadClientTypes() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await _listService.getClientTypes();
      apiResponse = res;

      if (res.success == true) {
        clientTypes = res.data ?? [];
        // appLog("clientTypes: ${clientTypes}");

        return true;
      } else {
        // appLog("clientTypes: ${res.success}");

        errorMessage = res.message;
        return false;
      }
    } catch (e) {
      errorMessage = 'Đã xảy ra lỗi: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loadAreas() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await _listService.getAreas();
      apiResponse = res;

      if (res.success == true) {
        areas = res.data ?? [];
        // appLog("areas: ${areas}");

        return true;
      } else {
        errorMessage = res.message;
        return false;
      }
    } catch (e) {
      errorMessage = 'Đã xảy ra lỗi: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loadRegions() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await _listService.getRegions();
      apiResponse = res;

      if (res.success == true) {
        regions = res.data ?? [];
        // appLog("regions: ${regions}");
        return true;
      } else {
        errorMessage = res.message;
        return false;
      }
    } catch (e) {
      errorMessage = 'Đã xảy ra lỗi: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}