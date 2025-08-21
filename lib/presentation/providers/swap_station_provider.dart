import 'package:ezing/data/datasource/mongodb.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mongo_dart/mongo_dart.dart';

class SwapStationProvider with ChangeNotifier {

  Future<Map<String, dynamic>?> getAssignedSwapStation(String phone) async {
    final _usersCollection = (await MongoDBConnection.instance.getDb()).collection('users');
    final _swapStationsCollection = (await MongoDBConnection.instance.getDb()).collection('swap_stations');

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
