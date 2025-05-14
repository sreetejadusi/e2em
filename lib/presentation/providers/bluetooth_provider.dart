import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothProvider with ChangeNotifier {
  bool get android => _android;
  final bool _android = Platform.isAndroid;

  bool get ios => _ios;
  final bool _ios = Platform.isIOS;

  bool get bluetoothPermission => _bluetoothPermission;
  bool _bluetoothPermission = false;

  bool get gpsPermission => _gpsPermission;
  bool _gpsPermission = false;

  bool get bluetoothOn => _bluetoothOn;
  bool _bluetoothOn = false;

  bool get gpsOn => _gpsOn;
  bool _gpsOn = false;

  bool _bluetoothAsked = false;
  bool _gpsAsked = false;

  BluetoothProvider();

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> check(BuildContext context) async {
    if (android) {
      await _checkAndroidPermissions();
    } else if (ios) {
      await _checkIosPermissions();
    }

    Future.delayed(const Duration(seconds: 2), () => check(context));
  }

  Future<void> _checkAndroidPermissions() async {
    _bluetoothPermission = await Permission.bluetooth.isGranted;

    _gpsPermission = await Permission.locationWhenInUse.isGranted;

    if (!_bluetoothPermission) {
      final result = await Permission.bluetooth.request();
      _bluetoothPermission = result.isGranted;
    }

    if (!_gpsPermission) {
      final result = await Permission.locationWhenInUse.request();
      _gpsPermission = await Permission.locationWhenInUse.isGranted;
    }

    if (_bluetoothPermission && !_bluetoothOn) {
      final result = await FlutterBluePlus.turnOn();
      _bluetoothOn = (await FlutterBluePlus.adapterState.first) ==
          BluetoothAdapterState.on;
    }

    notifyListeners();
  }

  Future<void> _checkIosPermissions() async {
    if (!_bluetoothPermission) {
      final result = await Permission.bluetooth.request();
      _bluetoothPermission = result.isGranted;
    }

    notifyListeners();
  }
}
