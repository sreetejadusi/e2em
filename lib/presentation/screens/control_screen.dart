// ignore_for_file: empty_catches

import 'dart:async';
import 'package:ezing/data/functions/converters.dart';
import 'package:ezing/presentation/providers/ble_data_provider.dart';
import 'package:ezing/presentation/providers/bluetooth_device_provider.dart';
import 'package:ezing/presentation/providers/location_provider.dart';
import 'package:ezing/presentation/providers/user_data_provider.dart';
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
  const ControlScreen({super.key, required this.rebuild, required this.device});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen>
    with TickerProviderStateMixin {
  String temp = "----";
  int battery = 0;
  int mode = 0; // Current mode
  double rangeLeft = 0.0;
  String vehicleID = "000";
  int a = 0;
  int b = 0;
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

  void showStatusSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> locationAccess() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        showStatusSnackBar("Location services disabled. Opening settings...");
        await Geolocator.openLocationSettings();
      }
    } catch (e) {
      showStatusSnackBar("Location access error: ${e.toString()}",
          isError: true);
    }
  }

  Future<void> load() async {
    try {
      setState(() => isLoading = true);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() => name = prefs.getString('name') ?? "------");
      await Geolocator.requestPermission();
      await locationAccess();
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
    BluetoothDevicesProvider bdp = context.read<BluetoothDevicesProvider>();
    load();
    cycleId = parseCycleId(bdp.connectedDeviceName ?? "000");
    super.initState();

    try {
      locator
          .getPositionStream(
              locationSettings:
                  const LocationSettings(accuracy: LocationAccuracy.high))
          .listen((Position position) {
        locator
            .getCurrentPosition(
                locationSettings:
                    const LocationSettings(accuracy: LocationAccuracy.high))
            .then((Position updatedPosition) {
          if (!isLoading) {
            setState(() => velocity =
                ((position.speed + updatedPosition.speed) / 2) * 3.6);
          }
        }).catchError((e) {
          showStatusSnackBar("Location update error: ${e.toString()}",
              isError: true);
        });
      });
    } catch (e) {
      showStatusSnackBar("Location stream error: ${e.toString()}",
          isError: true);
    }

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
          try {
            widget.device
                .setNotify(customServices[1].serviceUuid, readUUIDS[1], true);
          } catch (e) {}
        }
      }
    }, onError: (e) {
      showStatusSnackBar("Service discovery error: ${e.toString()}",
          isError: true);
    });

    deviceState = widget.device.state;
    if (deviceState == DeviceState.connected) {
      try {
        if (!widget.device.isWatchingRssi) widget.device.startWatchRssi();
        widget.device.discoveryService();
      } catch (e) {
        showStatusSnackBar("Device setup error: ${e.toString()}",
            isError: true);
      }
    }
    _stateStream = widget.device.stateStream.listen((event) {
      if (event == DeviceState.connected) {
        try {
          if (!widget.device.isWatchingRssi) widget.device.startWatchRssi();
          services.clear();
          widget.device.discoveryService();
          showStatusSnackBar("Device connected");
        } catch (e) {
          showStatusSnackBar("Connection setup error: ${e.toString()}",
              isError: true);
        }
      } else if (event == DeviceState.disconnected) {
        showStatusSnackBar("Device disconnected", isError: true);
      }
      setState(() => deviceState = event);
    }, onError: (e) {
      showStatusSnackBar("State stream error: ${e.toString()}", isError: true);
    });

    _deviceSignalResultStream =
        widget.device.deviceSignalResultStream.listen((event) {
      if (event.data != null && event.data!.isNotEmpty) {
        onMessage(String.fromCharCodes(event.data!));
      }
    }, onError: (e) {
      showStatusSnackBar("Signal stream error: ${e.toString()}", isError: true);
    });
  }

  void onMessage(String mes) {
    try {
      List<String> m = mes.trim().split(',');
      if (m.length >= 3) {
        setState(() {
          vehicleID = m[0];
          rangeLeft = double.tryParse(m[2]) ?? 0.0;
          battery = (int.tryParse(m[3]) ?? 0).clamp(0, 100);
          a = int.tryParse(m[4]) ?? 0;
          b = int.tryParse(m[5]) ?? 0;
        });
        try {
          SharedPreferences.getInstance().then((value) {
            value.setInt(
                'batteryPercentage', (int.tryParse(m[2]) ?? 0).clamp(0, 100));
          });
          context.read<BLEDataProvider>().logBLEData(m);
        } catch (e) {
          showStatusSnackBar("Data storage error: ${e.toString()}",
              isError: true);
        }
      }
    } catch (e) {
      showStatusSnackBar("Message parsing error: ${e.toString()}",
          isError: true);
    }
  }

  void send(String mes) {
    try {
      widget.device.writeData(
          writeUUIDS[0], writeUUIDS[1], true, alpha_to_UInt8List(mes));
      showStatusSnackBar("Sent: $mes");
    } catch (e) {
      showStatusSnackBar("Send error: ${e.toString()}", isError: true);
    }
  }

  Future<void> _sendCommand(int modeNum) async {
    if (isLoading) {
      showStatusSnackBar("Please wait for current operation to complete");
      return;
    }

    setState(() => isLoading = true);
    showStatusSnackBar("Sending command...");

    final completer = Completer<bool>();
    StreamSubscription<DeviceSignalResult>? subscription;

    try {
      // Send the command (E2EM0 or E2EM1)
      send(modeNum == 0 ? 'E2EM0' : 'E2EM1');

      // Listen for response from device
      subscription = widget.device.deviceSignalResultStream.listen((event) {
        if (event.data != null && event.data!.isNotEmpty) {
          // Convert Uint8List to String if needed
          String response = event.data is String
              ? event.data as String
              : String.fromCharCodes(event.data as Uint8List);

          // Check for confirmation response "T,0" or "T,1"

          int receivedMode = int.tryParse(response.substring(2)) ?? -1;
          if (receivedMode == modeNum) {
            completer.complete(true);
            showStatusSnackBar("Mode change confirmed");
          } else {
            completer.complete(false);
            showStatusSnackBar("Mode mismatch", isError: true);
          }
        }
      }, onError: (e) {
        showStatusSnackBar("Communication error", isError: true);
        completer.complete(false);
      });

      // Wait for response with timeout
      final success = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          showStatusSnackBar("No response from device", isError: true);
          return false;
        },
      );

      if (success) {
        setState(() => mode = modeNum);
        showStatusSnackBar("Mode changed successfully");
      }
    } catch (e) {
      showStatusSnackBar("Command failed: ${e.toString()}", isError: true);
    } finally {
      subscription?.cancel();
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    try {
      _deviceSignalResultStream.cancel();
      _serviceDiscoveryStream.cancel();
      _stateStream.cancel();
    } catch (e) {
      debugPrint("Dispose error: ${e.toString()}");
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    BluetoothDevicesProvider bdp = context.watch<BluetoothDevicesProvider>();
    UserDataProvider udp = context.watch<UserDataProvider>();
    LocationProvider lp = context.watch<LocationProvider>();

    return HomeScreen(
      hasDevice: true,
      deviceName: bdp.connectedDeviceName ?? "",
      connecting: deviceState == DeviceState.connecting,
      connected: deviceState == DeviceState.connected,
      connect: () {
        try {
          widget.device.connect(connectTimeout: 10000);
          showStatusSnackBar("Connecting to device...");
        } catch (e) {
          showStatusSnackBar("Connection failed: ${e.toString()}",
              isError: true);
        }
      },
      disconnect: () {
        try {
          widget.device.disConnect();
          showStatusSnackBar("Disconnecting from device...");
        } catch (e) {
          showStatusSnackBar("Disconnection failed: ${e.toString()}",
              isError: true);
        }
      },
      mode: mode,
      battery: battery,
      speed: velocity.toInt(),
      rangeLeft: rangeLeft,
      modeChange: (int modeNum) async {
        await udp.syncUserData();
        await udp.getUserData();
        if (udp.user!.flag) {
          showStatusSnackBar("Contact Admin.", isError: true);
        } else {
          if (deviceState == DeviceState.connected) {
            try {
              await _sendCommand(modeNum);
              await lp.pushLocation(udp.user!.phone);
            } catch (e) {}
          } else {
            showStatusSnackBar("Device not connected", isError: true);
          }
        }
      },
      isLoading: isLoading,
    );
  }
}
