import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothProvider with ChangeNotifier {
  // Private State
  PermissionStatus _bluetoothPermissionStatus = PermissionStatus.denied;
  PermissionStatus _locationPermissionStatus = PermissionStatus.denied;
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  BluetoothAdapterState get adapterState => _adapterState;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  // Public Getters
  bool get isBluetoothOn => _adapterState == BluetoothAdapterState.on;
  bool get hasPermissions =>
      _bluetoothPermissionStatus.isGranted &&
      _locationPermissionStatus.isGranted;

  // A combined getter to easily check if ready for Bluetooth actions
  bool get isReady => isBluetoothOn && hasPermissions;

  BluetoothProvider() {
    // Immediately start listening to the Bluetooth adapter state
    _listenToAdapterState();
  }

  /// Listens to the Bluetooth adapter state and updates the UI accordingly.
  void _listenToAdapterState() {
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      debugPrint("Bluetooth Adapter State changed to: $state");
      notifyListeners();
    });
  }

  /// Call this method from your UI to initiate permission checks and requests.
  Future<void> checkAndRequestPermissions() async {
    // --- 1. Check & Request Bluetooth Permissions ---
    // Note: For Android 12 (API 31) and above, you need bluetoothScan and bluetoothConnect
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse, // Required for BLE scanning
    ].request();

    _bluetoothPermissionStatus =
        statuses[Permission.bluetoothScan] ?? PermissionStatus.denied;
    _locationPermissionStatus =
        statuses[Permission.locationWhenInUse] ?? PermissionStatus.denied;

    notifyListeners();

    // --- 2. Check if Bluetooth is On ---
    // If we have permissions but Bluetooth is off, prompt the user to turn it on.
    if (hasPermissions && !isBluetoothOn) {
      // This will pop up a system dialog asking the user to turn on Bluetooth.
      await FlutterBluePlus.turnOn();
    }
  }

  @override
  void dispose() {
    // ALWAYS cancel subscriptions to prevent memory leaks
    _adapterStateSubscription?.cancel();
    super.dispose();
  }
}
