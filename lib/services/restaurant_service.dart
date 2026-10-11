import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_places_sdk_plus/google_places_sdk_plus.dart' as places;
import 'package:latlong2/latlong.dart';
import '../model/restaurant_model.dart';

class RestaurantService {
  static const String _googlePlacesApiKey = 'AIzaSyAswcTw462l0DnxU2pOkm8fDTXdSGCESJQ';
  final places.FlutterGooglePlacesSdk _placesClient =
  places.FlutterGooglePlacesSdk(_googlePlacesApiKey);

  Future<List<Restaurant>> fetchNearbyRestaurants(LatLng searchLocation) async {
    try {
      final response = await _placesClient.searchNearby(
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
        rankPreference: places.NearbySearchRankPreference.Distance,
        fields: const [
          places.PlaceField.Id,
          places.PlaceField.DisplayName,
          places.PlaceField.Location,
          places.PlaceField.FormattedAddress,
          places.PlaceField.NationalPhoneNumber,
          places.PlaceField.WebsiteUri,
        ],
      ).timeout(const Duration(seconds: 30));

      final restaurants = <Restaurant>[];
      final seenPlaceIds = <String>{};
      const distanceCalculator = Distance();

      for (final place in response.places) {
        try {
          final name = (place.displayName?.text ?? place.name ?? '').trim();
          final coordinates = place.latLng;

          if (name.isEmpty || coordinates == null) continue;

          final placeId = place.id;
          if (placeId != null && placeId.isNotEmpty) {
            if (!seenPlaceIds.add(placeId)) continue;
          }

          final restaurantLocation = LatLng(coordinates.lat, coordinates.lng);
          final distanceMeters = distanceCalculator.as(
            LengthUnit.Meter,
            searchLocation,
            restaurantLocation,
          );

          restaurants.add(
            Restaurant(
              name: name,
              location: restaurantLocation,
              address: place.address?.trim().isEmpty ?? true ? null : place.address?.trim(),
              phone: place.phoneNumber?.trim().isEmpty ?? true ? null : place.phoneNumber?.trim(),
              website: place.websiteUri?.toString().trim().isEmpty ?? true ? null : place.websiteUri?.toString().trim(),
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