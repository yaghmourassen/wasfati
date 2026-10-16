
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../model/restaurant_model.dart';
import '../services/restaurant_service.dart';

class RestaurantController extends ChangeNotifier {
  final RestaurantService _service = RestaurantService();
  final MapController mapController = MapController();

  static const LatLng defaultLocation = LatLng(36.7538, 3.0588);

  List<Restaurant> restaurants = [];
  LatLng? userLocation;

  // Route navigation state
  Restaurant? selectedRestaurant;
  List<LatLng> routePoints = [];
  double? routeDistanceMeters;
  double? routeDurationSeconds;
  bool isLoadingRoute = false;
  String? routeErrorMessage;

  bool isLoading = true;
  bool mapReady = false;
  String? errorMessage;

  StreamSubscription<Position>? _positionSubscription;
  bool _isDisposed = false;
  bool _isFetchingRoute = false;
  LatLng? _lastRouteOrigin;

  Future<void> initializeLocation() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    await _positionSubscription?.cancel();
    _positionSubscription = null;

    try {
      final serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission =
      await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is unavailable.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      userLocation = LatLng(
        position.latitude,
        position.longitude,
      );

      notifyListeners();

      _startLocationTracking();

      await loadRestaurants();

      if (mapReady && userLocation != null) {
        mapController.move(userLocation!, 14);
      }
    } catch (e) {
      if (_isDisposed) return;

      isLoading = false;
      errorMessage =
      'Unable to get your location. Please check your settings.';
      notifyListeners();
    }
  }

  void _startLocationTracking() {
    _positionSubscription?.cancel();

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
          (Position position) {
        if (_isDisposed) return;

        userLocation = LatLng(
          position.latitude,
          position.longitude,
        );

        notifyListeners();

        // Refresh the route after meaningful movement.
        _refreshRouteIfNeeded();
      },
      onError: (Object error) {
        debugPrint('GPS tracking error: $error');
      },
    );
  }

  Future<void> loadRestaurants() async {
    final searchLocation = userLocation ?? defaultLocation;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      restaurants =
      await _service.fetchNearbyRestaurants(searchLocation);

      isLoading = false;
      if (!_isDisposed) notifyListeners();
    } catch (e) {
      if (_isDisposed) return;

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

  void centerOnUser() {
    if (!mapReady || userLocation == null) return;

    mapController.move(userLocation!, 16);
  }

  /// Fetches a real road route from the current location
  /// to the selected restaurant using the OSRM routing service.
  Future<void> showRouteToRestaurant(Restaurant restaurant) async {
    final origin = userLocation;

    if (origin == null) {
      routeErrorMessage = 'Your current location is unavailable.';
      notifyListeners();
      return;
    }

    selectedRestaurant = restaurant;
    isLoadingRoute = true;
    routeErrorMessage = null;
    routePoints = [];
    routeDistanceMeters = null;
    routeDurationSeconds = null;
    _lastRouteOrigin = origin;

    notifyListeners();

    await _fetchRoute(origin, restaurant);
  }

  Future<void> _fetchRoute(
      LatLng origin,
      Restaurant destination,
      ) async {
    if (_isDisposed || _isFetchingRoute) return;

    _isFetchingRoute = true;

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
            '${origin.longitude},${origin.latitude};'
            '${destination.location.longitude},'
            '${destination.location.latitude}'
            '?overview=full&geometries=geojson',
      );

      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception('Route service unavailable.');
      }

      final data =
      jsonDecode(response.body) as Map<String, dynamic>;

      if (data['code'] != 'Ok') {
        throw Exception('No route found.');
      }

      final routes = data['routes'] as List<dynamic>;

      if (routes.isEmpty) {
        throw Exception('No route found.');
      }

      final route = routes.first as Map<String, dynamic>;
      final geometry =
      route['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List<dynamic>;

      final points = coordinates.map((coordinate) {
        final values = coordinate as List<dynamic>;

        // GeoJSON uses [longitude, latitude].
        return LatLng(
          (values[1] as num).toDouble(),
          (values[0] as num).toDouble(),
        );
      }).toList();

      if (_isDisposed ||
          selectedRestaurant != destination) {
        return;
      }

      routePoints = points;
      routeDistanceMeters =
          (route['distance'] as num?)?.toDouble();
      routeDurationSeconds =
          (route['duration'] as num?)?.toDouble();
      routeErrorMessage = null;
    } catch (e) {
      if (_isDisposed) return;

      routePoints = [];
      routeErrorMessage =
      'Unable to calculate the route. Please try again.';
      debugPrint('Route calculation error: $e');
    } finally {
      _isFetchingRoute = false;

      if (!_isDisposed) {
        isLoadingRoute = false;
        notifyListeners();
      }
    }
  }

  void _refreshRouteIfNeeded() {
    final destination = selectedRestaurant;
    final origin = userLocation;
    final previousOrigin = _lastRouteOrigin;

    if (destination == null ||
        origin == null ||
        previousOrigin == null ||
        _isFetchingRoute) {
      return;
    }

    final movedMeters = Geolocator.distanceBetween(
      previousOrigin.latitude,
      previousOrigin.longitude,
      origin.latitude,
      origin.longitude,
    );

    if (movedMeters >= 100) {
      _lastRouteOrigin = origin;
      isLoadingRoute = true;
      notifyListeners();

      unawaited(_fetchRoute(origin, destination));
    }
  }

  void clearRoute() {
    selectedRestaurant = null;
    routePoints = [];
    routeDistanceMeters = null;
    routeDurationSeconds = null;
    routeErrorMessage = null;
    isLoadingRoute = false;
    _lastRouteOrigin = null;

    notifyListeners();
  }

  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m away';
    }

    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }

  String formatRouteDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }

    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String formatRouteDuration(double seconds) {
    final minutes = (seconds / 60).round();

    if (minutes < 60) {
      return '$minutes min';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    return remainingMinutes == 0
        ? '$hours h'
        : '$hours h $remainingMinutes min';
  }

  @override
  void dispose() {
    _isDisposed = true;
    _positionSubscription?.cancel();
    _positionSubscription = null;

    super.dispose();
  }
}
