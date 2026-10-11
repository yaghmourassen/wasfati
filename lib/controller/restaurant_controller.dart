import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../model/restaurant_model.dart';
import '../services/restaurant_service.dart';

class RestaurantController extends ChangeNotifier {
  final RestaurantService _service = RestaurantService();
  final MapController mapController = MapController();

  static const LatLng defaultLocation = LatLng(36.7538, 3.0588);

  List<Restaurant> restaurants = [];
  LatLng? userLocation;
  bool isLoading = true;
  bool mapReady = false;
  String? errorMessage;

  Future<void> initializeLocation() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is permanently denied.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      userLocation = LatLng(position.latitude, position.longitude);
      notifyListeners();

      await loadRestaurants();

      if (mapReady && userLocation != null) {
        mapController.move(userLocation!, 14);
      }
    } catch (e) {
      isLoading = false;
      errorMessage = 'Unable to get your location. Please check your settings.';
      notifyListeners();
    }
  }

  Future<void> loadRestaurants() async {
    final searchLocation = userLocation ?? defaultLocation;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      restaurants = await _service.fetchNearbyRestaurants(searchLocation);
      isLoading = false;
      notifyListeners();
    } catch (e) {
      restaurants = [];
      isLoading = false;
      errorMessage = 'Unable to load nearby restaurants.';
      notifyListeners();
    }
  }

  void onMapReady() {
    mapReady = true;
    if (userLocation != null) {
      mapController.move(userLocation!, 14);
    }
    notifyListeners();
  }

  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m away';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }
}