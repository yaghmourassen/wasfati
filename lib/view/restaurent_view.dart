import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../generated/l10n/app_localizations.dart';

const Color primaryGreen = Color(0xFF2E7D32);

class RestaurantView extends StatefulWidget {
  const RestaurantView({super.key});

  @override
  State<RestaurantView> createState() => _RestaurantViewState();
}

class _RestaurantViewState extends State<RestaurantView> {
  // ============================================================
  // GEOAPIFY
  // ============================================================

  // Put your NEW Geoapify Places API key here.
  static const String _geoapifyApiKey =
      '98be29a016f844178dd750df7b1f834d';

  static const String _geoapifyPlacesUrl =
      'https://api.geoapify.com/v2/places';

  // ============================================================
  // LOCATION
  // ============================================================

  // Used only to display the map if GPS is unavailable.
  // Restaurants are NEVER searched using this fallback.
  static const LatLng defaultLocation = LatLng(
    36.7538,
    3.0588,
  );

  final MapController _mapController = MapController();

  List<_Restaurant> _restaurants = [];

  LatLng? _userLocation;

  bool _isLoading = true;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _initializeLocation();
  }

  // ============================================================
  // INITIALIZE LOCATION
  // ============================================================

  Future<void> _initializeLocation() async {
    debugPrint('🚀 RestaurantView: initializing location...');

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      debugPrint(
        '📍 Location service enabled: $serviceEnabled',
      );

      if (!serviceEnabled) {
        throw Exception(
          'Location services are disabled.',
        );
      }

      LocationPermission permission =
      await Geolocator.checkPermission();

      debugPrint(
        '📍 Current location permission: $permission',
      );

      if (permission == LocationPermission.denied) {
        permission =
        await Geolocator.requestPermission();

        debugPrint(
          '📍 Requested location permission: $permission',
        );
      }

      if (permission == LocationPermission.denied) {
        throw Exception(
          'Location permission was denied.',
        );
      }

      if (permission ==
          LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is permanently denied.',
        );
      }

      debugPrint(
        '📍 Getting current GPS position...',
      );

      final position =
      await Geolocator.getCurrentPosition(
        locationSettings:
        const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final location = LatLng(
        position.latitude,
        position.longitude,
      );

      debugPrint(
        '📍 GPS location: '
            '${position.latitude}, ${position.longitude}',
      );

      if (!mounted) return;

      setState(() {
        _userLocation = location;
      });

      debugPrint(
        '🍽️ Starting restaurant search...',
      );

      await _loadRestaurants(
        location: location,
      );

      if (!mounted) return;

      _mapController.move(
        location,
        14,
      );
    } catch (e) {
      debugPrint(
        '❌ Location error: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
        'Unable to get your location. '
            'Please enable location permission and try again.';
      });
    }
  }

  // ============================================================
  // LOAD RESTAURANTS FROM GEOAPIFY
  // ============================================================

  Future<void> _loadRestaurants({
    LatLng? location,
  }) async {
    final searchLocation =
        location ?? _userLocation;

    if (searchLocation == null) {
      debugPrint(
        '❌ Restaurant search cancelled: no location.',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
        'Your current location is unavailable.';
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
      final latitude =
          searchLocation.latitude;

      final longitude =
          searchLocation.longitude;

      debugPrint(
        '📍 Searching restaurants around: '
            '$latitude, $longitude',
      );

      const radius = 10000;

      // Geoapify syntax:
      // circle:LONGITUDE,LATITUDE,RADIUS
      final filter =
          'circle:$longitude,$latitude,$radius';

      final uri = Uri.parse(
        _geoapifyPlacesUrl,
      ).replace(
        queryParameters: {
          'categories':
          'catering.restaurant,'
              'catering.fast_food,'
              'catering.cafe,'
              'catering.food_court',
          'filter': filter,
          'bias':
          'proximity:$longitude,$latitude',
          'limit': '500',
          'lang': 'en',
          'apiKey': _geoapifyApiKey,
        },
      );

      debugPrint(
        '🌐 Geoapify request started...',
      );

      debugPrint(
        '🌐 Search radius: ${radius}m',
      );

      final response = await http
          .get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      )
          .timeout(
        const Duration(seconds: 30),
      );

      debugPrint(
        '🌐 Geoapify status: '
            '${response.statusCode}',
      );

      if (response.statusCode != 200) {
        debugPrint(
          '❌ Geoapify response:',
        );

        debugPrint(
          response.body,
        );

        throw Exception(
          'Geoapify returned '
              '${response.statusCode}',
        );
      }

      if (response.body.isEmpty) {
        throw Exception(
          'Geoapify returned an empty response.',
        );
      }

      final data =
      jsonDecode(response.body);

      final features =
          data['features']
          as List<dynamic>? ??
              [];

      debugPrint(
        '🍽️ Geoapify returned '
            '${features.length} places',
      );

      final restaurants =
      <_Restaurant>[];

      final seenPlaceIds =
      <String>{};

      for (final feature in features) {
        try {
          final properties =
          Map<String, dynamic>.from(
            feature['properties'] ??
                {},
          );

          final name =
          properties['name']
              ?.toString()
              .trim();

          if (name == null ||
              name.isEmpty) {
            debugPrint(
              '⚠️ Skipping place without name',
            );

            continue;
          }

          final latitudeValue =
          properties['lat'];

          final longitudeValue =
          properties['lon'];

          if (latitudeValue == null ||
              longitudeValue == null) {
            debugPrint(
              '⚠️ Skipping "$name": '
                  'missing coordinates',
            );

            continue;
          }

          final restaurantLatitude =
          (latitudeValue as num)
              .toDouble();

          final restaurantLongitude =
          (longitudeValue as num)
              .toDouble();

          final placeId =
          properties['place_id']
              ?.toString();

          // Prevent duplicates.
          if (placeId != null &&
              placeId.isNotEmpty) {
            if (seenPlaceIds
                .contains(placeId)) {
              continue;
            }

            seenPlaceIds.add(placeId);
          }

          final formattedAddress =
          properties['formatted']
              ?.toString()
              .trim();

          final addressLine1 =
          properties['address_line1']
              ?.toString()
              .trim();

          final addressLine2 =
          properties['address_line2']
              ?.toString()
              .trim();

          String? address;

          if (formattedAddress != null &&
              formattedAddress.isNotEmpty) {
            address = formattedAddress;
          } else if (addressLine1 != null &&
              addressLine1.isNotEmpty) {
            if (addressLine2 != null &&
                addressLine2.isNotEmpty) {
              address =
              '$addressLine1, $addressLine2';
            } else {
              address = addressLine1;
            }
          }

          final datasource =
          properties['datasource'];

          final raw =
          datasource is Map
              ? datasource['raw']
              : null;

          final phone =
          raw is Map
              ? raw['phone']?.toString() ??
              properties['phone']
                  ?.toString()
              : properties['phone']
              ?.toString();

          final website =
          raw is Map
              ? raw['website']?.toString() ??
              properties['website']
                  ?.toString()
              : properties['website']
              ?.toString();

          final distanceValue =
          properties['distance'];

          final distanceMeters =
          distanceValue is num
              ? distanceValue.toDouble()
              : null;

          restaurants.add(
            _Restaurant(
              name: name,
              location: LatLng(
                restaurantLatitude,
                restaurantLongitude,
              ),
              address: address,
              phone: phone,
              website: website,
              distanceMeters:
              distanceMeters,
            ),
          );
        } catch (e) {
          debugPrint(
            '⚠️ Failed to parse place: $e',
          );
        }
      }

      // Sort locally by real geographic distance.
      const distance = Distance();

      restaurants.sort(
            (a, b) {
          final distanceA =
          distance.as(
            LengthUnit.Meter,
            searchLocation,
            a.location,
          );

          final distanceB =
          distance.as(
            LengthUnit.Meter,
            searchLocation,
            b.location,
          );

          return distanceA.compareTo(
            distanceB,
          );
        },
      );

      debugPrint(
        '✅ Restaurants after filtering: '
            '${restaurants.length}',
      );

      if (!mounted) return;

      setState(() {
        _restaurants = restaurants;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        '❌ Restaurant loading error: $e',
      );

      if (!mounted) return;

      setState(() {
        _restaurants = [];
        _isLoading = false;
        _errorMessage =
        'Unable to load nearby restaurants. '
            'Please try again.';
      });
    }
  }

  // ============================================================
  // REFRESH LOCATION
  // ============================================================

  Future<void> _refreshWithCurrentLocation() async {
    debugPrint(
      '🔄 Refreshing restaurant location...',
    );

    try {
      final serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        setState(() {
          _errorMessage =
          'Location services are disabled.';
        });

        return;
      }

      LocationPermission permission =
      await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
        await Geolocator.requestPermission();
      }

      if (permission ==
          LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          _errorMessage =
          'Location permission is required.';
        });

        return;
      }

      final position =
      await Geolocator.getCurrentPosition(
        locationSettings:
        const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final location = LatLng(
        position.latitude,
        position.longitude,
      );

      debugPrint(
        '🔄 Refreshed GPS location: '
            '${position.latitude}, ${position.longitude}',
      );

      if (!mounted) return;

      setState(() {
        _userLocation = location;
      });

      _mapController.move(
        location,
        14,
      );

      await _loadRestaurants(
        location: location,
      );
    } catch (e) {
      debugPrint(
        '❌ Refresh location error: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
        'Unable to get your current location.';
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final t =
    AppLocalizations.of(context)!;

    final theme =
    Theme.of(context);

    final isDark =
        theme.brightness ==
            Brightness.dark;

    final mapCenter =
        _userLocation ??
            defaultLocation;

    return Scaffold(
      backgroundColor:
      theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
        theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme:
        const IconThemeData(
          color: primaryGreen,
        ),
        title: Text(
          t.restaurantsTitle,
          style:
          const TextStyle(
            color: primaryGreen,
            fontWeight:
            FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading
                ? null
                : _refreshWithCurrentLocation,
            tooltip: 'Refresh',
            icon:
            const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: Container(
              margin:
              const EdgeInsets.fromLTRB(
                12,
                8,
                12,
                8,
              ),
              clipBehavior:
              Clip.antiAlias,
              decoration:
              BoxDecoration(
                borderRadius:
                BorderRadius.circular(
                  20,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                    Colors.black.withOpacity(
                      isDark
                          ? 0.25
                          : 0.08,
                    ),
                    blurRadius: 14,
                    offset:
                    const Offset(
                      0,
                      5,
                    ),
                  ),
                ],
              ),
              child: FlutterMap(
                mapController:
                _mapController,
                options:
                MapOptions(
                  initialCenter:
                  mapCenter,
                  initialZoom: 14,
                  minZoom: 5,
                  maxZoom: 19,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                    'https://tile.openstreetmap.org/'
                        '{z}/{x}/{y}.png',
                    userAgentPackageName:
                    'com.example.wasfati',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point:
                        _userLocation ??
                            defaultLocation,
                        width: 50,
                        height: 50,
                        child:
                        Container(
                          decoration:
                          BoxDecoration(
                            color:
                            Colors.blue,
                            shape:
                            BoxShape.circle,
                            border:
                            Border.all(
                              color:
                              Colors.white,
                              width: 4,
                            ),
                            boxShadow:
                            const [
                              BoxShadow(
                                color:
                                Colors.black26,
                                blurRadius:
                                6,
                              ),
                            ],
                          ),
                          child:
                          const Icon(
                            Icons
                                .my_location,
                            color:
                            Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      ..._restaurants.map(
                            (
                            restaurant,
                            ) {
                          return Marker(
                            point:
                            restaurant
                                .location,
                            width: 55,
                            height: 65,
                            child:
                            GestureDetector(
                              onTap: () {
                                _showRestaurant(
                                  context,
                                  restaurant,
                                );
                              },
                              child:
                              Column(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration:
                                    BoxDecoration(
                                      color:
                                      primaryGreen,
                                      shape:
                                      BoxShape.circle,
                                      border:
                                      Border.all(
                                        color:
                                        Colors.white,
                                        width: 3,
                                      ),
                                      boxShadow:
                                      const [
                                        BoxShadow(
                                          color:
                                          Colors.black26,
                                          blurRadius:
                                          6,
                                          offset:
                                          Offset(
                                            0,
                                            2,
                                          ),
                                        ),
                                      ],
                                    ),
                                    child:
                                    const Icon(
                                      Icons
                                          .restaurant_rounded,
                                      color:
                                      Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                  const Icon(
                                    Icons
                                        .arrow_drop_down,
                                    color:
                                    primaryGreen,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration:
              BoxDecoration(
                color:
                theme.cardColor,
                borderRadius:
                const BorderRadius
                    .vertical(
                  top:
                  Radius.circular(
                    24,
                  ),
                ),
              ),
              child:
              _buildRestaurantList(
                context,
                t,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESTAURANT LIST
  // ============================================================

  Widget _buildRestaurantList(
      BuildContext context,
      AppLocalizations t,
      ) {
    final theme =
    Theme.of(context);

    if (_isLoading) {
      return const Center(
        child:
        CircularProgressIndicator(
          color: primaryGreen,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding:
          const EdgeInsets.all(
            24,
          ),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              const Icon(
                Icons
                    .location_off_rounded,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(
                height: 12,
              ),
              Text(
                _errorMessage!,
                textAlign:
                TextAlign.center,
                style:
                TextStyle(
                  color: theme
                      .textTheme
                      .bodyMedium
                      ?.color,
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              ElevatedButton.icon(
                onPressed:
                _initializeLocation,
                icon:
                const Icon(
                  Icons
                      .my_location_rounded,
                ),
                label:
                const Text(
                  'Try again',
                ),
                style:
                ElevatedButton
                    .styleFrom(
                  backgroundColor:
                  primaryGreen,
                  foregroundColor:
                  Colors.white,
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_restaurants.isEmpty) {
      return Center(
        child: Padding(
          padding:
          const EdgeInsets.all(
            24,
          ),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              const Icon(
                Icons
                    .restaurant_outlined,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(
                height: 12,
              ),
              Text(
                'No restaurants found nearby.',
                textAlign:
                TextAlign.center,
                style:
                TextStyle(
                  color: theme
                      .textTheme
                      .bodyMedium
                      ?.color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
          const EdgeInsets.fromLTRB(
            20,
            18,
            20,
            10,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFE8F5E9,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    13,
                  ),
                ),
                child:
                const Icon(
                  Icons
                      .restaurant_rounded,
                  color:
                  primaryGreen,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Text(
                  t.exploreRestaurants,
                  style:
                  TextStyle(
                    fontSize: 19,
                    fontWeight:
                    FontWeight.bold,
                    color: theme
                        .textTheme
                        .titleLarge
                        ?.color,
                  ),
                ),
              ),
              Text(
                '${_restaurants.length}',
                style:
                const TextStyle(
                  color:
                  primaryGreen,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child:
          ListView.separated(
            padding:
            const EdgeInsets.fromLTRB(
              20,
              4,
              20,
              20,
            ),
            itemCount:
            _restaurants.length,
            separatorBuilder:
                (_, __) =>
            const SizedBox(
              height: 10,
            ),
            itemBuilder:
                (context, index) {
              final restaurant =
              _restaurants[index];

              return _RestaurantCard(
                restaurant:
                restaurant,
                onTap: () {
                  _showRestaurant(
                    context,
                    restaurant,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RESTAURANT DETAILS
  // ============================================================

  void _showRestaurant(
      BuildContext context,
      _Restaurant restaurant,
      ) {
    final theme =
    Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor:
      theme.cardColor,
      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top:
          Radius.circular(
            24,
          ),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.all(
              24,
            ),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration:
                  BoxDecoration(
                    color:
                    Colors.grey.shade400,
                    borderRadius:
                    BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration:
                  BoxDecoration(
                    color:
                    const Color(
                      0xFFE8F5E9,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      18,
                    ),
                  ),
                  child:
                  const Icon(
                    Icons
                        .restaurant_rounded,
                    color:
                    primaryGreen,
                    size: 32,
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                Text(
                  restaurant.name,
                  textAlign:
                  TextAlign.center,
                  style:
                  const TextStyle(
                    fontSize: 21,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
                if (restaurant
                    .distanceMeters !=
                    null) ...[
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    _formatDistance(
                      restaurant
                          .distanceMeters!,
                    ),
                    style:
                    const TextStyle(
                      color:
                      primaryGreen,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ],
                if (restaurant.address !=
                    null) ...[
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      const Icon(
                        Icons
                            .location_on_outlined,
                        size: 20,
                        color:
                        primaryGreen,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child:
                        Text(
                          restaurant
                              .address!,
                          style:
                          TextStyle(
                            color: theme
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(
                              0.7,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (restaurant.phone !=
                    null) ...[
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons
                            .phone_outlined,
                        size: 20,
                        color:
                        primaryGreen,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child:
                        Text(
                          restaurant
                              .phone!,
                          style:
                          TextStyle(
                            color: theme
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(
                              0.7,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (restaurant.website !=
                    null) ...[
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons
                            .language_rounded,
                        size: 20,
                        color:
                        primaryGreen,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child:
                        Text(
                          restaurant
                              .website!,
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          TextStyle(
                            color: theme
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(
                              0.7,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(
                  height: 22,
                ),
                SizedBox(
                  width:
                  double.infinity,
                  height: 50,
                  child:
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
                    },
                    icon:
                    const Icon(
                      Icons
                          .close_rounded,
                    ),
                    label:
                    const Text(
                      'Close',
                    ),
                    style:
                    ElevatedButton
                        .styleFrom(
                      backgroundColor:
                      primaryGreen,
                      foregroundColor:
                      Colors.white,
                      elevation: 0,
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // DISTANCE FORMAT
  // ============================================================

  String _formatDistance(
      double meters,
      ) {
    if (meters < 1000) {
      return '${meters.round()} m away';
    }

    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }
}

// ================================================================
// RESTAURANT MODEL
// ================================================================

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

// ================================================================
// RESTAURANT CARD
// ================================================================

class _RestaurantCard
    extends StatelessWidget {
  final _Restaurant restaurant;
  final VoidCallback onTap;

  const _RestaurantCard({
    required this.restaurant,
    required this.onTap,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    return Material(
      color: theme
          .scaffoldBackgroundColor,
      borderRadius:
      BorderRadius.circular(
        16,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        child: Padding(
          padding:
          const EdgeInsets.all(
            13,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFE8F5E9,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
                child:
                const Icon(
                  Icons
                      .restaurant_rounded,
                  color:
                  primaryGreen,
                ),
              ),
              const SizedBox(
                width: 13,
              ),
              Expanded(
                child:
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      restaurant.name,
                      maxLines: 1,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style:
                      const TextStyle(
                        fontSize: 15,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      restaurant.address ??
                          'Nearby restaurant',
                      maxLines: 1,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style:
                      TextStyle(
                        fontSize: 12,
                        color: theme
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withOpacity(
                          0.6,
                        ),
                      ),
                    ),
                    if (restaurant
                        .distanceMeters !=
                        null) ...[
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        _formatCardDistance(
                          restaurant
                              .distanceMeters!,
                        ),
                        style:
                        const TextStyle(
                          fontSize: 11,
                          color:
                          primaryGreen,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons
                    .chevron_right_rounded,
                color:
                primaryGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCardDistance(
      double meters,
      ) {
    if (meters < 1000) {
      return '${meters.round()} m away';
    }

    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }
}