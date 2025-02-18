import 'package:ezing/data/datasource/mongodb.dart';
import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart';

class BLEDataProvider with ChangeNotifier {
  final DbCollection _bleDataCollection = mongoDB.db.collection('ble_data');
  static const int _maxHistorySize = 100;
  String? get vehicleId => _vehicleId;
  int? get km => _km;
  int get batteryPercentage => _batteryPercentage;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String? get a => _a;
  String? get b => _b;
  String? _vehicleId;
  int? _km;
  int _batteryPercentage = -1;
  double? _latitude;
  double? _longitude;
  String? _a;
  String? _b;

  void _storeValues(String rawData) {
    List<String> values = rawData.split(',');

    if (values.length < 6) {
      debugPrint("Invalid BLE data format");
      return;
    }

    _vehicleId = values[0];
    _km = int.tryParse(values[1]) ?? 0;
    _batteryPercentage = int.tryParse(values[2]) ?? 0;
    _latitude = double.tryParse(values[3]) ?? 0.0;
    _longitude = double.tryParse(values[4]) ?? 0.0;
    _a = values[5];
    _b = values.length > 6 ? values[6] : "";
  }

  Future<void> logBLEData(String rawData, String deviceId) async {
    try {
      _storeValues(rawData);
      List<String> values = rawData.split(',');

      if (values.length < 6) {
        debugPrint("Invalid BLE data format");
        return;
      }

      final data = {
        'vehicle_id': values[0],
        'km': int.tryParse(values[1]) ?? 0,
        'battery_percentage': int.tryParse(values[2]) ?? 0,
        'location': {
          'lat': double.tryParse(values[3]) ?? 0.0,
          'lon': double.tryParse(values[4]) ?? 0.0,
        },
        'a': values[5],
        'b': values.length > 6 ? values[6] : "",
        'timestamp': DateTime.now().toIso8601String(),
      };

      final deviceDocument =
          await _bleDataCollection.findOne({'deviceId': deviceId});

      if (deviceDocument != null) {
        List<dynamic> history = deviceDocument['history'] ?? [];
        if (history.length >= _maxHistorySize) {
          history.removeAt(0);
        }
        history.add(data);

        await _bleDataCollection.updateOne(
          where.eq('deviceId', deviceId),
          modify.set('history', history),
        );
      } else {
        await _bleDataCollection.insert({
          'deviceId': deviceId,
          'history': [data],
        });
      }

      debugPrint("BLE Data logged: $data");
    } catch (e) {
      debugPrint("Error logging BLE data: $e");
    }
  }
}
