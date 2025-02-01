import 'package:ezing/data/datasource/mongodb.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:geocoding/geocoding.dart'; 

class LocationProvider with ChangeNotifier {
  final DbCollection _locationHistoryCollection = mongoDB.db.collection('location_history');
  static const int _maxHistorySize = 100; 

  
  Future<Position> _getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  
  Future<String> _getPlaceName(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        return '${placemark.name}, ${placemark.locality}, ${placemark.country}';
      }
      return 'Unknown Location';
    } catch (e) {
      debugPrint("Error fetching place name: $e");
      return 'Unknown Location';
    }
  }

  
  Future<void> _pushLocationToDatabase(
      Position position, String userId) async {
    try {
      String placeName =
          await _getPlaceName(position.latitude, position.longitude);

      
      final data = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'placeName': placeName,
        'timestamp': DateTime.now().toIso8601String(),
      };

      
      final userDocument =
          await _locationHistoryCollection.findOne({'userId': userId});

      if (userDocument != null) {
        
        List<dynamic> history = userDocument['history'] ?? [];
        if (history.length >= _maxHistorySize) {
          history.removeAt(0); 
        }
        history.add(data); 

        
        await _locationHistoryCollection.updateOne(
          where.eq('userId', userId),
          modify.set('history', history),
        );
      } else {
        
        await _locationHistoryCollection.insert({
          'userId': userId,
          'history': [data],
        });
      }

      debugPrint("Location pushed to database: $data");
    } catch (e) {
      debugPrint("Error pushing location to database: $e");
    }
  }


  
  Future<void> pushLocation(String userId) async {
    final position = await _getCurrentLocation();

    await _pushLocationToDatabase(position, userId);
  }
}
