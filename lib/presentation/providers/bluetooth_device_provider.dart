// ignore_for_file: empty_catches

import 'package:ezing/presentation/providers/location_provider.dart';
import 'package:ezing/presentation/providers/saved_devices_provider.dart';
import 'package:ezing/presentation/providers/user_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'data_provider.dart';

class BluetoothDevicesProvider with ChangeNotifier {
  bool get scanning => _scanning;
  bool _scanning = false;

  List<ScanResult> get scanResultList => _scanResultList;
  List<ScanResult> _scanResultList = [];

  String get lastDevice => _lastDevice;
  String _lastDevice = "ROVE";

  BluetoothDevice? get connectedDevice => _connectedDevice;
  BluetoothDevice? _connectedDevice;
  String? get connectedDeviceName => _connectedDeviceName;
  String? _connectedDeviceName;

  int get tabIndex => _tabIndex;
  int _tabIndex = 1;

  Future<void> changeTabIndex(int i) async {
    _tabIndex = i;
    notifyListeners();
  }

  Future<void> changeConnectedDevice(BluetoothDevice? d, String name) async {
    _connectedDevice = d;
    _connectedDeviceName = name;

    // Save last connected device for auto-reconnect
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('vehicle', name);
    _lastDevice = name;
    notifyListeners();
  }

  Future<void> lastDeviceInit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _lastDevice = (prefs.getString('vehicle') ?? "--------");
    notifyListeners();
  }

  Future<void> stopScan() async {
    try {
      FlutterBluePlus.stopScan();
      notifyListeners();
    } catch (e) {}
  }

  Future<void> scan(BuildContext context) async {
    SharedPreferences? prefs = await SharedPreferences.getInstance();
    try {
      if (_scanning) return;
      _scanning = true;
      notifyListeners();
      _scanResultList = [];

      FlutterBluePlus.onScanResults.listen((results) {
        if (results.isNotEmpty) {
          for (var result in results) {
            if (!_scanResultList
                .any((e) => e.device.remoteId == result.device.remoteId)) {
              _scanResultList.insert(0, result);
              print(_scanResultList
                  .map((e) => e.advertisementData.advName)
                  .toList());
              notifyListeners();
            }

            if (result.advertisementData.advName.trim() == _lastDevice.trim()) {
              result.device.connect().then((value) {
                changeConnectedDevice(
                    result.device, result.advertisementData.advName);
                _scanning = false;
                notifyListeners();
                FlutterBluePlus.stopScan();
              });
            } else {
              _connectedDevice = null;
              _connectedDeviceName = null;
            }
          }
        }
      });

      await FlutterBluePlus.startScan(
        withNames: [],
        timeout: Duration(seconds: 7),
      ).then((value) {
        _scanning = false;
        notifyListeners();
      });
    } catch (e) {
      _scanning = false;
      scan(context);
      notifyListeners();
      print('Scan failed: $e');
    }
  }
}
