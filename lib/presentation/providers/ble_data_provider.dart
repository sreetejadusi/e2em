
// ignore_for_file: collection_methods_unrelated_type

import 'package:ezing/data/datasource/mongodb.dart';
import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart';

class BLEDataProvider with ChangeNotifier {
  final DbCollection _bleDataCollection = mongoDB.db.collection('ble_data');
  static const int _maxHistorySize = 100;

  Future<void> logBLEData(List list) async {
    try {
      final data = {
        'vehicleID':list[0],
        'km':list[1],
        'batteryPercentage':list[2],
        'a':list[3],
        'b':list[4],
        'timestamp':DateTime.now().toIso8601String(),
      };

      final deviceDocument =
          await _bleDataCollection.findOne({'deviceId': data[0]});

      if (deviceDocument != null) {
        List<dynamic> history = deviceDocument['history'] ?? [];
        if (history.length >= _maxHistorySize) {
          history.removeAt(0);
        }
        history.add(data);

        await _bleDataCollection.updateOne(
          where.eq('deviceId', data[0]),
          modify.set('history', history),
        );
      } else {
        await _bleDataCollection.insert({
          'deviceId': data[0],
          'history': [data],
        });
      }

      debugPrint("BLE Data logged: $data");
    } catch (e) {
      debugPrint("Error logging BLE data: $e");
    }
  }
}
