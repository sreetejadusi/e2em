import 'dart:async';
import 'dart:math';
import 'package:ezing/data/functions/converters.dart';
import 'package:ezing/presentation/providers/bluetooth_device_provider.dart';
import 'package:ezing/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_elves/flutter_blue_elves.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class ControlScreen extends StatefulWidget {
  final Device device;
  final Function(String key) rebuild;
  const ControlScreen({Key? key, required this.rebuild, required this.device})
      : super(key: key);

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen>
    with TickerProviderStateMixin {
  String temp = "----";
  int battery = 0;
  int mode = 1;
  double rangeLeft = 0.0;
  String cycleId = "000";

  List<BleService> services = [];
  List<String> readUUIDS = [];
  List<String> writeUUIDS = [];
  DeviceState deviceState = DeviceState.disconnected;
  late StreamSubscription<BleService> _serviceDiscoveryStream;
  late StreamSubscription<DeviceState> _stateStream;
  late StreamSubscription<DeviceSignalResult> _deviceSignalResultStream;
  bool isLoading = false;
  String name = "------";
  double velocity = 0;
  GeolocatorPlatform locator = GeolocatorPlatform.instance;

  Future<void> locationAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
    }
  }

  Future<void> load() async {
    setState(() => isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => name = prefs.getString('name') ?? "------");
    await Geolocator.requestPermission();
    await locationAccess();
    setState(() => isLoading = false);
  }

  String parseCycleId(String name) {
    return name.contains("Trydan")
        ? name.replaceAll("Trydan", "").trim()
        : "000";
  }

  @override
  void initState() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    BluetoothDevicesProvider bdp = context.read<BluetoothDevicesProvider>();
    load();
    cycleId = parseCycleId(bdp.connectedDeviceName ?? "000");
    super.initState();

    locator
        .getPositionStream(
            locationSettings: LocationSettings(accuracy: LocationAccuracy.high))
        .listen((Position position) {
      locator
          .getCurrentPosition(
              locationSettings:
                  LocationSettings(accuracy: LocationAccuracy.high))
          .then((Position updatedPosition) {
        if (!isLoading) {
          setState(() =>
              velocity = ((position.speed + updatedPosition.speed) / 2) * 3.6);
        }
      });
    });

    _serviceDiscoveryStream =
        widget.device.serviceDiscoveryStream.listen((event) {
      setState(() => services.add(event));
      List<BleService> customServices = services
          .where((element) =>
              element.serviceUuid.substring(4, 8) != "1800" &&
              element.serviceUuid.substring(4, 8) != "1801")
          .toList();
      if (customServices.length >= 2) {
        readUUIDS.clear();
        writeUUIDS.clear();
        writeUUIDS.addAll([
          customServices[0].serviceUuid,
          customServices[0].characteristics[0].uuid
        ]);
        readUUIDS.addAll([
          customServices[1].serviceUuid,
          customServices[1].characteristics[0].uuid
        ]);
        if (customServices[1]
            .characteristics[0]
            .properties
            .contains(CharacteristicProperties.notify)) {
          widget.device
              .setNotify(customServices[1].serviceUuid, readUUIDS[1], true);
        }
      }
    });

    deviceState = widget.device.state;
    if (deviceState == DeviceState.connected) {
      if (!widget.device.isWatchingRssi) widget.device.startWatchRssi();
      widget.device.discoveryService();
    }
    _stateStream = widget.device.stateStream.listen((event) {
      if (event == DeviceState.connected) {
        if (!widget.device.isWatchingRssi) widget.device.startWatchRssi();
        services.clear();
        widget.device.discoveryService();
      }
      setState(() => deviceState = event);
    });

    _deviceSignalResultStream =
        widget.device.deviceSignalResultStream.listen((event) {
      if (event.data != null && event.data!.isNotEmpty) {
        onMessage(String.fromCharCodes(event.data!));
      }
    });
  }

  void onMessage(String mes) {
    List<String> m = mes.trim().split(',');
    if (m.length >= 3) {
      try {
        setState(() {
          mode = int.tryParse(m[1]) ?? 1;
          battery = (int.tryParse(m[2]) ?? 0).clamp(0, 100);
          rangeLeft = double.tryParse(m[0]) ?? 0.0;
        });
      } catch (_) {}
    }
  }

  void send(String mes) {
    widget.device
        .writeData(writeUUIDS[0], writeUUIDS[1], true, alpha_to_UInt8List(mes));
  }

  @override
  void dispose() {
    if (widget.device.state == DeviceState.connected) {
      widget.device.disConnect();
    }
    _deviceSignalResultStream.cancel();
    _serviceDiscoveryStream.cancel();
    _stateStream.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    BluetoothDevicesProvider bdp = context.watch<BluetoothDevicesProvider>();
    return HomeScreen(
      hasDevice: true,
      deviceName: bdp.connectedDeviceName ?? "",
      connecting: deviceState == DeviceState.connecting,
      connected: deviceState == DeviceState.connected,
      connect: () => widget.device.connect(connectTimeout: 10000),
      disconnect: () => widget.device.disConnect(),
      mode: mode,
      battery: battery,
      speed: velocity.toInt(),
      rangeLeft: rangeLeft,
      modeChange: (int modeNum) {
        setState(() => mode = modeNum);
        send("$cycleId,$modeNum");
      },
    );
  }
}
