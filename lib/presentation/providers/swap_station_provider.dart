import 'package:ezing/data/datasource/mongodb.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mongo_dart/mongo_dart.dart';

class SwapStationProvider with ChangeNotifier {
  final DbCollection _swapStationsCollection =
      mongoDB.db.collection('swap_stations');
  final DbCollection _usersCollection = mongoDB.db.collection('users');

  Future<Map<String, dynamic>?> getAssignedSwapStation(String phone) async {
    try {
      final userDocument = await _usersCollection.findOne({'phone': phone});
      if (userDocument == null) {
        debugPrint("User not found");
        return null;
      }

      final String? stationId = userDocument['station'];
      if (stationId == null) {
        debugPrint("No station assigned to user");
        return null;
      }

      final stationDocument = await _swapStationsCollection
          .findOne(where.eq('stationId', stationId));
      if (stationDocument == null) {
        debugPrint("Assigned station not found in database");
        return null;
      }

      return stationDocument;
    } catch (e) {
      debugPrint("Error fetching assigned swap station: $e");
      return null;
    }
  }

  Future<void> navigateToLocation(double latitude, double longitude) async {
    final googleMapsUrl =
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';

    await launchUrl(Uri.parse(googleMapsUrl));
  }

  Future<void> navigateToAssignedSwapStation(String phone) async {
    final station = await getAssignedSwapStation(phone);

    if (station == null) {
      debugPrint("No assigned station found for navigation");
      return;
    }

    final double latitude = station['latitude'];
    final double longitude = station['longitude'];

    await navigateToLocation(latitude, longitude);
  }
}
