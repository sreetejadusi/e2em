// ignore_for_file: use_build_context_synchronously

import 'package:ezing/data/datasource/mongodb.dart';
import 'package:ezing/presentation/providers/bluetooth_device_provider.dart';
import 'package:ezing/presentation/providers/bluetooth_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BatterySwapProvider with ChangeNotifier {
  final DbCollection _batteriesCollection = mongoDB.db.collection('batteries');
  final DbCollection _swapStationsCollection =
      mongoDB.db.collection('swap_stations');
  final DbCollection _usersCollection = mongoDB.db.collection('users');
  final BluetoothDevicesProvider _bleProvider;
  // final BLEDataProvider _bleDataProvider;
  final BluetoothProvider _bluetoothProvider;

  BatterySwapProvider(
    this._bleProvider,
    this._bluetoothProvider,
    // this._bleDataProvider,
  );

  BatterySwapProvider update(
    BluetoothDevicesProvider bleProvider,
    BluetoothProvider bluetoothProvider,
    // BLEDataProvider bleDataProvider,
  ) {
    return BatterySwapProvider(
      bleProvider,
      bluetoothProvider,
      // bleDataProvider,
    );
  }

  Future<bool> isUserNearSwapStation(String userId) async {
    try {
      final userDocument = await _usersCollection.findOne({'phone': userId});
      if (userDocument == null || userDocument['station'] == null) return false;

      final stationDocument = await _swapStationsCollection
          .findOne({'stationId': userDocument['station']});
      if (stationDocument == null) return false;
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        stationDocument['latitude'],
        stationDocument['longitude'],
      );
      return distance <= 300;
    } catch (e) {
      if (kDebugMode) {
        print("Error checking user proximity: $e");
      }
      return false;
    }
  }

  Future<bool> canSwapBattery(String userId, BuildContext context) async {
    if (!await isUserNearSwapStation(userId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User is not near the swap station"),
        ),
      );
      if (kDebugMode) {
        print("User is not near the swap station");
      }
      return false;
    }

    if (!_bluetoothProvider.bluetoothOn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bluetooth is not enabled"),
        ),
      );
      return false;
    }

    if (_bleProvider.connectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vehicle is not connected via BLE"),
        ),
      );
      return false;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int battery = prefs.getInt('batteryPercentage') ?? 0;
    if (battery > 25) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Battery percentage is above 25%"),
        ),
      );
      return false;
    }
    if (kDebugMode) {
      print(_bleProvider.connectedDevice);
    }
    return true;
  }

  Future<bool> swapBattery(String userId, String oldBatteryId,
      String newBatteryId, BuildContext context) async {
    try {
      if (!await canSwapBattery(userId, context)) return false;

      final existingBattery =
          await _batteriesCollection.findOne({'batteryId': newBatteryId});
      if (existingBattery != null && existingBattery['vehicleId'] != null) {
        return false;
      }

      await _batteriesCollection.updateOne(
        where.eq('batteryId', oldBatteryId),
        modify.set('vehicleId', null),
      );

      await _batteriesCollection.updateOne(
        where.eq('batteryId', newBatteryId),
        modify.set('vehicleId', userId),
      );

      return true;
    } catch (e) {
      return false;
    }
  }
}
