
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_places_sdk_plus/google_places_sdk_plus.dart' as places;
import 'package:latlong2/latlong.dart';

import '../model/restaurant_model.dart';

class RestaurantService {
static const String _googlePlacesApiKey =
'AIzaSyAswcTw462l0DnxU2pOkm8fDTXdSGCESJQ';

final places.FlutterGooglePlacesSdk _placesClient =
places.FlutterGooglePlacesSdk(_googlePlacesApiKey);

Future<List<Restaurant>> fetchNearbyRestaurants(
LatLng searchLocation,
) async {
try {
final response = await _placesClient
    .searchNearby(
locationRestriction: places.CircularBounds(
center: places.LatLng(
lat: searchLocation.latitude,
lng: searchLocation.longitude,
),
radius: 10000,
),
includedTypes: const [
'restaurant',
'cafe',
'fast_food_restaurant',
'food_court',
],
maxResultCount: 20,
rankPreference:
places.NearbySearchRankPreference.Distance,
fields: const [
places.PlaceField.Id,
places.PlaceField.DisplayName,
places.PlaceField.Location,
places.PlaceField.FormattedAddress,
places.PlaceField.NationalPhoneNumber,
places.PlaceField.WebsiteUri,
],
)
    .timeout(const Duration(seconds: 30));

final restaurants = <Restaurant>[];
final seenPlaceIds = <String>{};
const distanceCalculator = Distance();

for (final place in response.places) {
try {
final name =
(place.displayName?.text ?? place.name ?? '').trim();
final coordinates = place.latLng;
final placeId = place.id;

// A stable ID is required to associate ratings with a restaurant.
if (name.isEmpty ||
coordinates == null ||
placeId == null ||
placeId.isEmpty) {
continue;
}

// Ignore duplicate results for the same Google Place.
if (!seenPlaceIds.add(placeId)) {
continue;
}

final restaurantLocation = LatLng(
coordinates.lat,
coordinates.lng,
);

final distanceMeters = distanceCalculator.as(
LengthUnit.Meter,
searchLocation,
restaurantLocation,
);

final address = place.address?.trim();
final phone = place.phoneNumber?.trim();
final website = place.websiteUri?.toString().trim();

restaurants.add(
Restaurant(
id: placeId,
name: name,
location: restaurantLocation,
address:
address == null || address.isEmpty ? null : address,
phone: phone == null || phone.isEmpty ? null : phone,
website:
website == null || website.isEmpty ? null : website,
distanceMeters: distanceMeters,
),
);
} catch (e) {
debugPrint('Erreur d’analyse d’un lieu : $e');
}
}

restaurants.sort(
(a, b) => (a.distanceMeters ?? double.infinity).compareTo(
b.distanceMeters ?? double.infinity,
),
);

return restaurants;
} catch (e, stackTrace) {
debugPrint('Erreur Google Places : $e');
debugPrintStack(stackTrace: stackTrace);
rethrow;
}
}
}
