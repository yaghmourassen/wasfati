
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_places_sdk_plus/google_places_sdk_plus.dart'
as places;
import 'package:latlong2/latlong.dart';

import '../generated/l10n/app_localizations.dart';

const Color primaryGreen = Color(0xFF2E7D32);
const Color lightGreen = Color(0xFFE8F5E9);

class RestaurantView extends StatefulWidget {
  const RestaurantView({super.key});

  @override
  State<RestaurantView> createState() => _RestaurantViewState();
}

class _RestaurantViewState extends State<RestaurantView> {
  // GOOGLE PLACES API
  // Keep your existing API key here.
  static const String _googlePlacesApiKey = 'AIzaSyAswcTw462l0DnxU2pOkm8fDTXdSGCESJQ';

  late final places.FlutterGooglePlacesSdk _placesClient =
  places.FlutterGooglePlacesSdk(_googlePlacesApiKey);

  // LOCATION
  static const LatLng defaultLocation = LatLng(36.7538, 3.0588);

  final MapController _mapController = MapController();

  List<_Restaurant> _restaurants = [];
  LatLng? _userLocation;

  bool _isLoading = true;
  bool _mapReady = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  // INITIALIZE LOCATION
  Future<void> _initializeLocation() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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

      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is permanently denied. '
              'Enable it in your device settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      final location = LatLng(
        position.latitude,
        position.longitude,
      );

      debugPrint(
        'GPS location: ${position.latitude}, ${position.longitude}',
      );

      if (!mounted) return;

      setState(() {
        _userLocation = location;
      });

      await _loadRestaurants(location: location);

      if (!mounted) return;

      if (_mapReady) {
        _mapController.move(location, 14);
      }
    } catch (e, stackTrace) {
      debugPrint('Location initialization error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
        'Unable to get your location. '
            'Please enable location permission and try again.';
      });
    }
  }

  // LOAD RESTAURANTS FROM GOOGLE PLACES
  Future<void> _loadRestaurants({
    LatLng? location,
  }) async {
    final searchLocation = location ?? _userLocation;

    if (searchLocation == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Your current location is unavailable.';
      });

      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      debugPrint(
        'Searching Google Places near '
            '${searchLocation.latitude}, ${searchLocation.longitude}',
      );

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

      debugPrint(
        'Google Places returned ${response.places.length} places.',
      );

      final restaurants = <_Restaurant>[];
      final seenPlaceIds = <String>{};
      const distanceCalculator = Distance();

      for (final place in response.places) {
        try {
          final name =
          (place.displayName?.text ?? place.name ?? '').trim();

          final coordinates = place.latLng;

          if (name.isEmpty || coordinates == null) {
            continue;
          }

          final placeId = place.id;

          if (placeId != null && placeId.isNotEmpty) {
            if (!seenPlaceIds.add(placeId)) {
              continue;
            }
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

          final rawAddress = place.address?.trim();
          final rawPhone = place.phoneNumber?.trim();
          final rawWebsite = place.websiteUri?.toString().trim();

          restaurants.add(
            _Restaurant(
              name: name,
              location: restaurantLocation,
              address: rawAddress == null || rawAddress.isEmpty
                  ? null
                  : rawAddress,
              phone: rawPhone == null || rawPhone.isEmpty
                  ? null
                  : rawPhone,
              website: rawWebsite == null || rawWebsite.isEmpty
                  ? null
                  : rawWebsite,
              distanceMeters: distanceMeters,
            ),
          );
        } catch (e) {
          debugPrint('Unable to parse Google place: $e');
        }
      }

      restaurants.sort(
            (a, b) => (a.distanceMeters ?? double.infinity).compareTo(
          b.distanceMeters ?? double.infinity,
        ),
      );

      if (!mounted) return;

      setState(() {
        _restaurants = restaurants;
        _isLoading = false;
        _errorMessage = null;
      });

      debugPrint('Restaurants after filtering: ${restaurants.length}');
    } catch (e, stackTrace) {
      debugPrint('Google Places search error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _restaurants = [];
        _isLoading = false;
        _errorMessage =
        'Unable to load nearby restaurants. '
            'Please check your connection and try again.';
      });
    }
  }

  // REFRESH LOCATION
  Future<void> _refreshWithCurrentLocation() async {
    if (_isLoading) return;

    await _initializeLocation();
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final mapCenter = _userLocation ?? defaultLocation;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: primaryGreen),
        title: Text(
          t.restaurantsTitle,
          style: const TextStyle(
            color: primaryGreen,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _refreshWithCurrentLocation,
            tooltip: 'Refresh restaurants',
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // MAP
          Expanded(
            flex: 6,
            child: Container(
              margin: const EdgeInsets.fromLTRB(14, 6, 14, 12),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      isDark ? 0.22 : 0.07,
                    ),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: mapCenter,
                      initialZoom: 14,
                      minZoom: 5,
                      maxZoom: 19,
                      onMapReady: () {
                        _mapReady = true;

                        if (_userLocation != null) {
                          _mapController.move(_userLocation!, 14);
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.wasfati',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _userLocation ?? defaultLocation,
                            width: 48,
                            height: 48,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 7,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.my_location_rounded,
                                color: Colors.white,
                                size: 23,
                              ),
                            ),
                          ),
                          ..._restaurants.map(
                                (restaurant) => Marker(
                              point: restaurant.location,
                              width: 52,
                              height: 62,
                              child: GestureDetector(
                                onTap: () => _showRestaurant(
                                  context,
                                  restaurant,
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: primaryGreen,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 6,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.restaurant_rounded,
                                        color: Colors.white,
                                        size: 21,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_drop_down,
                                      color: primaryGreen,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution(
                            'OpenStreetMap contributors',
                          ),
                        ],
                      ),
                    ],
                  ),

                  // MAP LOCATION LABEL
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: IgnorePointer(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: theme.cardColor.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.near_me_rounded,
                                size: 17,
                                color: primaryGreen,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                _userLocation == null
                                    ? 'Finding your location...'
                                    : 'Restaurants near you',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (_isLoading)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: theme.cardColor.withOpacity(0.96),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 19,
                              height: 19,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.3,
                                color: primaryGreen,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Finding nearby restaurants...',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // RESTAURANT LIST
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      isDark ? 0.12 : 0.035,
                    ),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: _buildRestaurantList(context, t),
            ),
          ),
        ],
      ),
    );
  }

  // RESTAURANT LIST
  Widget _buildRestaurantList(
      BuildContext context,
      AppLocalizations t,
      ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 17, 20, 12),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: primaryGreen,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.exploreRestaurants,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _isLoading
                          ? 'Searching nearby places'
                          : '${_restaurants.length} places found',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (_restaurants.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_restaurants.length}',
                    style: const TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _buildRestaurantListContent(context),
        ),
      ],
    );
  }

  Widget _buildRestaurantListContent(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading && _restaurants.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Finding restaurants near you...',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null && _restaurants.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.location_searching_rounded,
        title: 'Unable to load restaurants',
        message: _errorMessage!,
        buttonLabel: 'Try again',
        onPressed: _refreshWithCurrentLocation,
      );
    }

    if (_restaurants.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.search_off_rounded,
        title: 'No restaurants found',
        message:
        'No nearby places were returned. Refresh your location and try again.',
        buttonLabel: 'Search again',
        onPressed: _refreshWithCurrentLocation,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 18),
      itemCount: _restaurants.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final restaurant = _restaurants[index];

        return _RestaurantCard(
          restaurant: restaurant,
          onTap: () => _showRestaurant(context, restaurant),
        );
      },
    );
  }

  Widget _buildEmptyState(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String message,
        required String buttonLabel,
        required VoidCallback onPressed,
      }) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(21),
              ),
              child: Icon(
                icon,
                color: primaryGreen,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.45,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isLoading ? null : onPressed,
              icon: const Icon(Icons.refresh_rounded, size: 19),
              label: Text(buttonLabel),
              style: FilledButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // RESTAURANT DETAILS
  void _showRestaurant(
      BuildContext context,
      _Restaurant restaurant,
      ) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.restaurant_rounded,
                      color: primaryGreen,
                      size: 35,
                    ),
                  ),
                  const SizedBox(height: 17),
                  Text(
                    restaurant.name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (restaurant.distanceMeters != null) ...[
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: lightGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _formatDistance(restaurant.distanceMeters!),
                        style: const TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  if (restaurant.address != null)
                    _DetailRow(
                      icon: Icons.location_on_outlined,
                      text: restaurant.address!,
                    ),
                  if (restaurant.phone != null) ...[
                    const SizedBox(height: 15),
                    _DetailRow(
                      icon: Icons.phone_outlined,
                      text: restaurant.phone!,
                    ),
                  ],
                  if (restaurant.website != null) ...[
                    const SizedBox(height: 15),
                    _DetailRow(
                      icon: Icons.language_rounded,
                      text: restaurant.website!,
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Done'),
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m away';
    }

    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }
}

// RESTAURANT MODEL
class _Restaurant {
  final String name;
  final LatLng location;
  final String? address;
  final String? phone;
  final String? website;
  final double? distanceMeters;

  const _Restaurant({
    required this.name,
    required this.location,
    this.address,
    this.phone,
    this.website,
    this.distanceMeters,
  });
}

// DETAIL ROW
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: primaryGreen,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 9),
            child: SelectableText(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// RESTAURANT CARD
class _RestaurantCard extends StatelessWidget {
  final _Restaurant restaurant;
  final VoidCallback onTap;

  const _RestaurantCard({
    required this.restaurant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: theme.scaffoldBackgroundColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.12),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 53,
                height: 53,
                decoration: BoxDecoration(
                  color: isDark
                      ? primaryGreen.withOpacity(0.18)
                      : lightGreen,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: primaryGreen,
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (restaurant.address != null)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              restaurant.address!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (restaurant.distanceMeters != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.near_me_outlined,
                            color: primaryGreen,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatCardDistance(
                              restaurant.distanceMeters!,
                            ),
                            style: const TextStyle(
                              fontSize: 11,
                              color: primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: primaryGreen,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCardDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m away';
    }

    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }
}
