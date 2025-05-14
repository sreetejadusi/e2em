// ignore_for_file: use_build_context_synchronously, empty_catches

import 'dart:async';
import 'dart:typed_data';
import 'package:ezing/data/functions/converters.dart';
import 'package:ezing/presentation/providers/ble_data_provider.dart';
import 'package:ezing/presentation/providers/bluetooth_device_provider.dart';
import 'package:ezing/presentation/providers/location_provider.dart';
import 'package:ezing/presentation/providers/user_data_provider.dart';
import 'package:ezing/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ControlScreen extends StatefulWidget {
  final BluetoothDevice device;
  final Function(String key) rebuild;

  const ControlScreen({super.key, required this.rebuild, required this.device});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen>
    with TickerProviderStateMixin {
  String temp = "----";
  int battery = 0;
  int mode = 0;
  double rangeLeft = 0.0;
  String vehicleID = "000";
  int a = 0;
  int b = 0;
  String cycleId = "000";
  bool isLoading = false;
  String name = "------";
  double velocity = 0;
  GeolocatorPlatform locator = GeolocatorPlatform.instance;

  BluetoothConnectionState deviceState = BluetoothConnectionState.disconnected;
  List<BluetoothService> services = [];
  late StreamSubscription<BluetoothConnectionState> _stateStream;
  StreamSubscription<List<int>>? _notificationStream;

  late BluetoothCharacteristic? readChar;
  late BluetoothCharacteristic? writeChar;

  void showStatusSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> load() async {
    try {
      setState(() => isLoading = true);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      name = prefs.getString('name') ?? "------";
      await Geolocator.requestPermission();
      if (!await Geolocator.isLocationServiceEnabled()) {
        showStatusSnackBar("Location services disabled. Opening settings...");
        await Geolocator.openLocationSettings();
      }
    } catch (e) {
      showStatusSnackBar("Initialization error: ${e.toString()}",
          isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  String parseCycleId(String name) {
    return name.contains("Trydan")
        ? name.replaceAll("Trydan", "").trim()
        : "000";
  }

  @override
  void initState() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    super.initState();
    final bdp = context.read<BluetoothDevicesProvider>();
    cycleId = parseCycleId(bdp.connectedDeviceName ?? "000");
    load();

    locator
        .getPositionStream(
            locationSettings:
                const LocationSettings(accuracy: LocationAccuracy.high))
        .listen((position) async {
      try {
        Position updated = await locator.getCurrentPosition(
            locationSettings:
                const LocationSettings(accuracy: LocationAccuracy.high));
        if (!isLoading) {
          setState(
              () => velocity = ((position.speed + updated.speed) / 2) * 3.6);
        }
      } catch (e) {
        showStatusSnackBar("Location error: ${e.toString()}", isError: true);
      }
    });

    _stateStream = widget.device.connectionState.listen((event) async {
      setState(() => deviceState = event);
      if (event == BluetoothConnectionState.connected) {
        showStatusSnackBar("Device connected");
        await discoverServices();
      } else if (event == BluetoothConnectionState.disconnected) {
        showStatusSnackBar("Device disconnected", isError: true);
      }
    });

    widget.device.connect();
  }

  Future<void> discoverServices() async {
    try {
      services = await widget.device.discoverServices();
      List<BluetoothService> custom = services
          .where((s) =>
              !s.uuid.toString().contains("1800") &&
              !s.uuid.toString().contains("1801"))
          .toList();
      if (custom.length >= 2) {
        writeChar =
            custom[0].characteristics.firstWhere((c) => c.properties.write);
        readChar =
            custom[1].characteristics.firstWhere((c) => c.properties.notify);
        await readChar!.setNotifyValue(true);
        _notificationStream = readChar!.lastValueStream.listen((value) {
          onMessage(String.fromCharCodes(value));
        });
      }
    } catch (e) {
      showStatusSnackBar("Service discovery error: ${e.toString()}",
          isError: true);
    }
  }

  void onMessage(String mes) async {
    try {
      List<String> m = mes.trim().split(',');
      if (m.length >= 6) {
        setState(() {
          vehicleID = m[0];
          rangeLeft = double.tryParse(m[2]) ?? 0.0;
          battery = (int.tryParse(m[3]) ?? 0).clamp(0, 100);
          a = int.tryParse(m[4]) ?? 0;
          b = int.tryParse(m[5]) ?? 0;
        });
        final prefs = await SharedPreferences.getInstance();
        prefs.setInt('batteryPercentage', battery);
        context.read<BLEDataProvider>().logBLEData(m);
      }
    } catch (e) {
      showStatusSnackBar("Message parse error: ${e.toString()}", isError: true);
    }
  }

  Future<void> send(String mes) async {
    try {
      await writeChar?.write(alpha_to_UInt8List(mes));
      showStatusSnackBar("Sent: $mes");
    } catch (e) {
      showStatusSnackBar("Send error: ${e.toString()}", isError: true);
    }
  }

  Future<void> _sendCommand(int modeNum) async {
    if (isLoading) {
      return;
    }
    setState(() => isLoading = true);
    final completer = Completer<bool>();

    StreamSubscription<List<int>>? sub;
    try {
      await send(modeNum == 0 ? 'E2EM0' : 'E2EM1');

      sub = readChar!.lastValueStream.listen((data) {
        final response = String.fromCharCodes(data).split(',');
        print(response);
        int receivedMode = int.tryParse(response[1]) ?? -1;
        // if (receivedMode == modeNum) {
        //   completer.complete(true);
        //   showStatusSnackBar("Mode confirmed");
        // } else {
        //   completer.complete(false);
        //   showStatusSnackBar("Mode mismatch", isError: true);
        // }
      });

      setState(() {
        mode = modeNum;
      });
    } catch (e) {
      showStatusSnackBar("Command failed: ${e.toString()}", isError: true);
    } finally {
      await sub?.cancel();
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _stateStream.cancel();
    _notificationStream?.cancel();
    widget.device.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bdp = context.watch<BluetoothDevicesProvider>();
    final udp = context.watch<UserDataProvider>();
    final lp = context.watch<LocationProvider>();

    return HomeScreen(
      hasDevice: true,
      deviceName: bdp.connectedDeviceName ?? "",
      connected: deviceState == BluetoothConnectionState.connected,
      connect: () async {
        try {
          await widget.device.connect(timeout: const Duration(seconds: 10));
          showStatusSnackBar("Connecting...");
        } catch (e) {
          showStatusSnackBar("Connect failed: ${e.toString()}", isError: true);
        }
      },
      disconnect: () async {
        try {
          await widget.device.disconnect();
          showStatusSnackBar("Disconnecting...");
        } catch (e) {
          showStatusSnackBar("Disconnect failed: ${e.toString()}",
              isError: true);
        }
      },
      mode: mode,
      battery: battery,
      speed: velocity.toInt(),
      rangeLeft: rangeLeft,
      modeChange: (modeNum) async {
        await udp.syncUserData();
        await udp.getUserData();
        if (udp.user!.flag) {
          showStatusSnackBar("Contact Admin", isError: true);
        } else if (deviceState == BluetoothConnectionState.connected) {
          await _sendCommand(modeNum);
          await lp.pushLocation(udp.user!.phone);
        } else {
          showStatusSnackBar("Device not connected", isError: true);
        }
      },
      isLoading: isLoading,
    );
  }
}
