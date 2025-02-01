import 'package:ezing/presentation/providers/bluetooth_provider.dart';
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

  Future<void> changeLastDevice(String name) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('lastDevice', name);
    lastDeviceInit();
    notifyListeners();
  }

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
    _lastDevice = (prefs.getString('lastDevice') ?? "--------");
    notifyListeners();
  }

  Future<void> stopScan() async {
    try {
      FlutterBlueElves.instance.stopScan();
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  Future<void> scan(BuildContext context) async {
    BluetoothProvider bp = context.read<BluetoothProvider>();
    DataProvider dp = context.read<DataProvider>();
    _openedControl = false;
    notifyListeners();
    try {
      if (_scanning) {
        FlutterBlueElves.instance.stopScan();
      } else {
        if (bp.bluetoothOn && bp.gpsOn) {
          _scanning = true;
          notifyListeners();
          _hideConnectedList = [];
          notifyListeners();
          getHideConnectedDevice();
          notifyListeners();
          _scanResultList = [];
          notifyListeners();
          FlutterBlueElves.instance.startScan(10000).listen((event) {
            _scanResultList.insert(0, event);
            notifyListeners();
            if (dp.autoConnect) {
              lastDeviceInit();
              String ss = event.name ?? "-----";
              String s = ss.trim();

              if (!_openedControl && s == _lastDevice.trim() && s != "-----") {
                stopScan();
                changeTabIndex(1);
                Device toConnectDevice = event.connect(connectTimeout: 10000);
                changeConnectedDevice(toConnectDevice, event.name ?? "-----");
                changeLastDevice(s);

                notifyListeners();
              }
            }
            notifyListeners();
          }).onDone(() {
            _scanning = false;
            notifyListeners();
          });
        }
      }
    } catch (e) {
      print(e);
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
