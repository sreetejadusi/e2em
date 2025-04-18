
// ignore_for_file: empty_catches

import 'package:ezing/presentation/providers/location_provider.dart';
import 'package:ezing/presentation/providers/saved_devices_provider.dart';
import 'package:ezing/presentation/providers/user_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_elves/flutter_blue_elves.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'data_provider.dart';

class BluetoothDevicesProvider with ChangeNotifier {
  bool get scanning => _scanning;
  bool _scanning = false;

  bool get openedControl => _openedControl;
  bool _openedControl = false;

  List<ScanResult> get scanResultList => _scanResultList;
  List<ScanResult> _scanResultList = [];

  List<HideConnectedDevice> get hideConnectedList => _hideConnectedList;
  List<HideConnectedDevice> _hideConnectedList = [];

  String get lastDevice => _lastDevice;
  String _lastDevice = "--------";

  Device? get connectedDevice => _connectedDevice;
  Device? _connectedDevice;
  String? get connectedDeviceName => _connectedDeviceName;
  String? _connectedDeviceName;

  int get tabIndex => _tabIndex;
  int _tabIndex = 1;

  Future<void> resetName() async {
    _connectedDeviceName = "--------";
    notifyListeners();
  }

  ScanResult? checksr(String name) {
    List<ScanResult> temp = [];
    for (int i = 0; i < scanResultList.length; i++) {
      if (scanResultList[i].name == name) {
        temp.add(scanResultList[i]);
      }
    }
    if (temp.isNotEmpty) {
      return temp[0];
    } else {
      return null;
    }
  }

  Future<void> changeTabIndex(int i) async {
    _tabIndex = i;
    notifyListeners();
  }

  // Future<void> changeLastDevice(String name) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   prefs.setString('lastDevice', name);
  //   lastDeviceInit();
  //   notifyListeners();
  // }

  Future<void> changeConnectedDevice(Device? d, String name) async {
    _connectedDevice = d;
    _connectedDeviceName = name;
    notifyListeners();
  }

  Future<void> controlOpened(bool b) async {
    _openedControl = b;
    notifyListeners();
  }

  Future<void> lastDeviceInit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _lastDevice = (prefs.getString('vehicle') ?? "--------");
    notifyListeners();
  }

  // Future<void> connectToLastDevice(BuildContext context) async {
  //   await scan(context);
  //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //     content: Text("Connecting to last device"),
  //     duration: const Duration(seconds: 2),
  //   ));
  //   await lastDeviceInit();
  //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //     content: Text("Last Device Init"),
  //     duration: const Duration(seconds: 2),
  //   ));
  //   if (_lastDevice != "--------") {
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //       content: Text("Last Device Exists: $_lastDevice"),
  //       duration: const Duration(seconds: 2),
  //     ));
  //     final scanResult = checksr(_lastDevice);
  //     final device = scanResult!.connect(connectTimeout: 10000);
  //     changeConnectedDevice(device, _lastDevice);
  //     notifyListeners();

  //     // _scanResultList.forEach((element) {
  //     //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //     //     content: Text("Checking ${element.name}"),
  //     //     duration: const Duration(seconds: 2),
  //     //   ));
  //     //   if (element.name == _lastDevice) {
  //     //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //     //       content: Text("Found ${element.name}"),
  //     //       duration: const Duration(seconds: 2),
  //     //     ));
  //     //     Device? device = element.connect(connectTimeout: 10000);
  //     //     changeConnectedDevice(device, element.name!);
  //     //     changeLastDevice(element.name!);
  //     //     notifyListeners();
  //     //   }
  //     // });
  //   }
  // }

  Future<void> stopScan() async {
    try {
      FlutterBlueElves.instance.stopScan();
      notifyListeners();
    } catch (e) {
    }
  }

  // Future<void> scan(BuildContext context) async {
  //   BluetoothProvider bp = context.read<BluetoothProvider>();
  //   SavedDevicesProvider sdp = context.read<SavedDevicesProvider>();
  //   DataProvider dp = context.read<DataProvider>();
  //   _openedControl = false;
  //   notifyListeners();
  //   try {
  //     if (_scanning) {
  //       FlutterBlueElves.instance.stopScan();
  //     } else {
  //       if (bp.bluetoothOn && bp.gpsOn) {
  //         _scanning = true;
  //         notifyListeners();
  //         _hideConnectedList = [];
  //         notifyListeners();
  //         getHideConnectedDevice();
  //         notifyListeners();
  //         _scanResultList = [];
  //         notifyListeners();
  //         FlutterBlueElves.instance.startScan(10000).listen((event) async {
  //           _scanResultList.insert(0, event);
  //           notifyListeners();
  //           // if (dp.autoConnect) {
  //           // lastDeviceInit();
  //           // await sdp.init();
  //           // print(sdp.devices.length);
  //           // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //           //   content: Text("SDP: ${sdp.devices.length}"),
  //           //   duration: const Duration(seconds: 2),
  //           // ));
  //           //   connectToLastDevice(context);
  //           // }
  //           // if (dp.autoConnect) {
  //           //   lastDeviceInit();
  //           //   String ss = event.name ?? "-----";
  //           //   String s = ss.trim();
  //           //   if (!_openedControl && s == _lastDevice.trim() && s != "-----") {
  //           //     stopScan();
  //           //     changeTabIndex(1);
  //           //     Device toConnectDevice = event.connect(connectTimeout: 10000);
  //           //     changeConnectedDevice(toConnectDevice, event.name ?? "-----");
  //           //     changeLastDevice(s);

  //           //     notifyListeners();
  //           //   }
  //           // }
  //           // notifyListeners();
  //         }).onDone(() {
  //           _scanning = false;
  //           notifyListeners();
  //         });
  //       }
  //     }
  //   } catch (e) {
  //     print(e);
  //   }
  //   notifyListeners();
  // }

  Future<void> scan(BuildContext context) async {
    context.read<SavedDevicesProvider>();
    context.read<DataProvider>();
    LocationProvider lp = context.read<LocationProvider>();
    UserDataProvider udp = context.read<UserDataProvider>();
    _openedControl = false;
    notifyListeners();
    try {
      if (_scanning) {
        // FlutterBlueElves.instance.stopScan();
      } else {
        _scanning = true;
        notifyListeners();
        _hideConnectedList = [];
        notifyListeners();
        getHideConnectedDevice();
        notifyListeners();
        _scanResultList = [];
        notifyListeners();
        FlutterBlueElves.instance.startScan(10000).listen((event) async {
          _scanResultList.insert(0, event);
          if (true) {
            String ss = event.name ?? "-----";
            String s = ss.trim();
            if (s == udp.user?.vehicle.trim() && s != "-----") {
              stopScan();
              Device toConnectDevice = event.connect(connectTimeout: 10000);
              lp.pushLocation(udp.user!.phone);
              changeConnectedDevice(toConnectDevice, _lastDevice);
              // changeLastDevice(s);
              changeTabIndex(1);
            }
          }

          // if (true) {
          //   await sdp.init();
          //   for (int i = 0; i < sdp.devices.length; i++) {
          //     if (sdp.devices[i].name == event.name) {
          //       stopScan();
          //       Device toConnectDevice = event.connect(connectTimeout: 10000);
          //       lp.pushLocation(udp.user!.phone);
          //       changeConnectedDevice(toConnectDevice, event.name ?? "-----");
          //       // changeLastDevice(event.name ?? "-----");
          //       changeTabIndex(1);
          //     }
          //   }
          // }
          notifyListeners();
        }).onDone(() {
          _scanning = false;
          notifyListeners();
        });
      }
    } catch (e) {
    }
    notifyListeners();
  }

  Future<void> getHideConnectedDevice() async {
    FlutterBlueElves.instance.getHideConnectedDevices().then((values) {
      _hideConnectedList = values;
      notifyListeners();
    });
  }
}
