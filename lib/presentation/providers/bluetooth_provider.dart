import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_blue_elves/flutter_blue_elves.dart';
import 'package:provider/provider.dart';

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
  bool _decision = false;

  Future<void> check(BuildContext context) async {
    if (android) {
      FlutterBlueElves.instance.androidCheckBlueLackWhat().then((event) {
        print(event);
        if (event.contains(AndroidBluetoothLack.bluetoothPermission)) {
          _bluetoothPermission = false;
          _bluetoothOn = false;
          notifyListeners();
          FlutterBlueElves.instance.androidApplyBluetoothPermission((isOk) {
            debugPrint(isOk
                ? "User agrees to grant Bluetooth permission"
                : "User does not agree to grant Bluetooth permission");
          });
        } else {
          _bluetoothPermission = true;
          if (event.contains(AndroidBluetoothLack.bluetoothFunction)) {
            _bluetoothOn = false;
            notifyListeners();
            if (!_decision && !_bluetoothAsked) {
              FlutterBlueElves.instance.androidOpenBluetoothService((isOk) {
                _decision = false;
                _bluetoothAsked = true;
                notifyListeners();
                debugPrint(isOk
                    ? "The user agrees to turn on the Bluetooth function"
                    : "The user does not agrees to turn on the Bluetooth function");
              });
            } else {}
            _decision = true;
            notifyListeners();
          } else {
            _bluetoothOn = true;
            notifyListeners();
          }
        }
        if (event.contains(AndroidBluetoothLack.locationPermission)) {
          _gpsPermission = false;
          _gpsOn = false;
          notifyListeners();
          FlutterBlueElves.instance.androidApplyLocationPermission((isOk) {
            debugPrint(isOk
                ? "User agrees to grant location permission"
                : "User does not agree to grant location permission");
          });
        } else {
          _gpsPermission = true;
          if (event.contains(AndroidBluetoothLack.locationFunction)) {
            _gpsOn = false;
            notifyListeners();
            if (_bluetoothOn && !_decision && !_gpsAsked) {
              FlutterBlueElves.instance.androidOpenLocationService((isOk) {
                _decision = false;
                _gpsAsked = true;
                notifyListeners();
                debugPrint(isOk
                    ? "The user agrees to turn on the positioning function"
                    : "The user does not agree to enable the positioning function");
              });
            } else {}
            _decision = true;
            notifyListeners();
          } else {
            _gpsOn = true;
            notifyListeners();
          }
        }
      });
    } else {}
    notifyListeners();
    Future.delayed(const Duration(seconds: 2), () async {
      check(context);
    });
  }
}
