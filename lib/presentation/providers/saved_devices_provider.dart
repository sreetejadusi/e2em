import 'dart:async';
import 'dart:convert';
import 'package:ezing/data/models/saved_device.dart';
import 'package:flutter/cupertino.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class SavedDevicesProvider extends ChangeNotifier {
  List<SavedDeviceModel> get devices => _devices;
  List<SavedDeviceModel> _devices = [];

  Future<void> save() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> devicesData = [
      for (final item in _devices) item.toMap()
    ];
    prefs.setString('devicesData', jsonEncode(devicesData));
    notifyListeners();
    init();
  }

  Future<void> addDevice(BuildContext context, SavedDeviceModel d) async {
    _devices.add(d);
    notifyListeners();
    await save();
  }

  Future<void> removeDevice(BuildContext context, String id) async {
    for (var y = 0; y < _devices.length; y++) {
      if (_devices[y].id == id) {
        _devices.removeAt(y);
      }
    }
    notifyListeners();
    await save();
  }

  Future<void> editDeviceName(
      BuildContext context, String id, String name) async {
    for (var y = 0; y < _devices.length; y++) {
      if (_devices[y].id == id) {
        _devices[y].name = name;
      }
    }
    notifyListeners();
    await save();
  }

  Future<void> init() async {
    _devices = [];
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String devicesData = (prefs.getString('devicesData') ?? jsonEncode([]));
    List<dynamic> ld = jsonDecode(devicesData);
    List<Map<String, dynamic>> parsedDevicesData = [];
    for (var y = 0; y < ld.length; y++) {
      Map<String, dynamic> m = ld[y];
      parsedDevicesData.add(m);
    }
    _devices = [
      for (final item in parsedDevicesData) SavedDeviceModel.fromDocument(item)
    ];
    notifyListeners();
  }
}
