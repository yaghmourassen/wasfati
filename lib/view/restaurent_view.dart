
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import '../controller/restaurant_controller.dart';
import '../generated/l10n/app_localizations.dart';
import '../model/restaurant_model.dart';
import '../services/restaurant_rating_service.dart';

const Color primaryGreen = Color(0xFF2E7D32);
const Color lightGreen = Color(0xFFE8F5E9);

class RestaurantView extends StatelessWidget {
  const RestaurantView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RestaurantController()..initializeLocation(),
      child: const _RestaurantViewBody(),
    );
  }
}

class _RestaurantViewBody extends StatelessWidget {
  const _RestaurantViewBody();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controller = context.watch<RestaurantController>();

    final mapCenter =
        controller.userLocation ?? RestaurantController.defaultLocation;

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
            onPressed: controller.isLoading
                ? null
                : () => controller.initializeLocation(),
            tooltip: t.refreshRestaurants,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          // Map background.
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: FlutterMap(
                  mapController: controller.mapController,
                  options: MapOptions(
                    initialCenter: mapCenter,
                    initialZoom: 14,
                    minZoom: 5,
                    maxZoom: 19,
                    onMapReady: controller.onMapReady,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.wasfati',
                    ),
                    if (controller.routePoints.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: controller.routePoints,
                            strokeWidth: 5,
                            color: Colors.blueAccent,
                            borderStrokeWidth: 2,
                            borderColor: Colors.white,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: controller.userLocation ??
                              RestaurantController.defaultLocation,
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
                        ...controller.restaurants.map(
                              (restaurant) => Marker(
                            point: restaurant.location,
                            width: 52,
                            height: 62,
                            child: GestureDetector(
                              onTap: () => _showRestaurantDetails(
                                context,
                                restaurant,
                                controller,
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
                    const RichAttributionWidget(
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
          ),

          // Route information card.
          if (controller.selectedRestaurant != null)
            Positioned(
              top: 12,
              left: 14,
              right: 14,
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.directions_rounded,
                        color: primaryGreen,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              controller.selectedRestaurant!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            if (controller.isLoadingRoute)
                              const LinearProgressIndicator(
                                color: primaryGreen,
                              )
                            else if (controller.routePoints.length >= 2)
                              Text(
                                '${controller.formatRouteDistance(controller.routeDistanceMeters ?? 0)}'
                                    ' • '
                                    '${controller.formatRouteDuration(controller.routeDurationSeconds ?? 0)}',
                                style: theme.textTheme.bodySmall,
                              )
                            else if (controller.routeErrorMessage != null)
                                Text(
                                  controller.routeErrorMessage!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                )
                              else
                                Text(
                                  _routeText(
                                    context,
                                    'Preparing route...',
                                    'جارٍ تجهيز الطريق...',
                                  ),
                                  style: theme.textTheme.bodySmall,
                                ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: _routeText(
                          context,
                          'Clear route',
                          'إخفاء الطريق',
                        ),
                        onPressed: controller.clearRoute,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Draggable restaurant panel.
          DraggableScrollableSheet(
            initialChildSize: 0.30,
            minChildSize: 0.17,
            maxChildSize: 0.78,
            snap: true,
            snapSizes: const [0.17, 0.42, 0.78],
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(26),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        isDark ? 0.20 : 0.08,
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  physics: const ClampingScrollPhysics(),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 10,
                        bottom: 8,
                      ),
                      child: Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: theme.dividerColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        4,
                        20,
                        12,
                      ),
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
                                  controller.isLoading
                                      ? t.searchingNearbyPlaces
                                      : '${controller.restaurants.length} places found',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                    theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (controller.restaurants.isNotEmpty)
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
                                '${controller.restaurants.length}',
                                style: const TextStyle(
                                  color: primaryGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Restaurant list.
                    _buildListContent(
                      context,
                      t,
                      controller,
                    ),
                  ],
                ),
              );
            },
          ),

          // Current-location button.
          Positioned(
            right: 12,
            top: 12,
            child: Material(
              color: theme.cardColor,
              elevation: 4,
              shape: const CircleBorder(),
              child: IconButton(
                onPressed: controller.userLocation == null
                    ? null
                    : controller.centerOnUser,
                icon: const Icon(
                  Icons.my_location_rounded,
                  color: primaryGreen,
                ),
                tooltip: t.restaurantsTitle,
                iconSize: 23,
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListContent(
      BuildContext context,
      AppLocalizations t,
      RestaurantController controller,
      ) {
    final theme = Theme.of(context);

    if (controller.isLoading && controller.restaurants.isEmpty) {
      return Padding(
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
              t.findingYourLocation,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (controller.errorMessage != null &&
        controller.restaurants.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.location_searching_rounded,
        title: t.errorOccurred,
        message: controller.errorMessage!,
        buttonLabel: t.tryAgain,
        onPressed: () => controller.initializeLocation(),
      );
    }

    if (controller.restaurants.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.search_off_rounded,
        title: t.noRestaurantsFound,
        message: t.noRestaurantsMessage,
        buttonLabel: t.tryAgain,
        onPressed: () => controller.initializeLocation(),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 18),
      child: Column(
        children: [
          for (int i = 0; i < controller.restaurants.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _RestaurantCard(
              restaurant: controller.restaurants[i],
              onTap: () => _showRestaurantDetails(
                context,
                controller.restaurants[i],
                controller,
              ),
            ),
          ],
        ],
      ),
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

    return Padding(
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
            onPressed: onPressed,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 19,
            ),
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
    );
  }

  void _showRestaurantDetails(
      BuildContext context,
      Restaurant restaurant,
      RestaurantController controller,
      ) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

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
              padding: const EdgeInsets.fromLTRB(
                24,
                12,
                24,
                24,
              ),
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

                  // Five-star restaurant rating.
                  const SizedBox(height: 12),
                  _RestaurantRatingSection(
                    restaurantId: restaurant.id,
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
                        controller.formatDistance(
                          restaurant.distanceMeters!,
                        ),
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
                      onPressed: controller.userLocation == null ||
                          controller.isLoadingRoute
                          ? null
                          : () async {
                        Navigator.pop(context);
                        await controller.showRouteToRestaurant(
                          restaurant,
                        );
                      },
                      icon: const Icon(Icons.directions_rounded),
                      label: Text(
                        _routeText(
                          context,
                          'Show route',
                          'اعرض الطريق',
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check_rounded),
                      label: Text(t.done ?? 'Done'),
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
}

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

class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
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
                            restaurant.distanceMeters! < 1000
                                ? '${restaurant.distanceMeters!.round()} m away'
                                : '${(restaurant.distanceMeters! / 1000).toStringAsFixed(1)} km away',
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
}

String _routeText(
    BuildContext context,
    String english,
    String arabic,
    ) {
  return Localizations.localeOf(context).languageCode == 'ar'
      ? arabic
      : english;
}

// -----------------------------------------------------------------------------
// Restaurant rating widget.
// Each authenticated user can submit one rating per restaurant and update it.
// -----------------------------------------------------------------------------

class _RestaurantRatingSection extends StatefulWidget {
  final String restaurantId;

  const _RestaurantRatingSection({
    required this.restaurantId,
  });

  @override
  State<_RestaurantRatingSection> createState() =>
      _RestaurantRatingSectionState();
}

class _RestaurantRatingSectionState
    extends State<_RestaurantRatingSection> {
  final RestaurantRatingService _service = RestaurantRatingService();

  int _selectedRating = 0;
  int _savedRating = 0;
  double _averageRating = 0;
  int _ratingCount = 0;

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    if (FirebaseAuth.instance.currentUser == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final results = await Future.wait<Object?>([
        _service.getUserRating(widget.restaurantId),
        _service.getRatingSummary(widget.restaurantId),
      ]);

      if (!mounted) return;

      final userRating = results[0] as int?;
      final summary = results[1] as RestaurantRatingSummary;

      setState(() {
        _savedRating = userRating ?? 0;
        _selectedRating = userRating ?? 0;
        _averageRating = summary.averageRating;
        _ratingCount = summary.ratingCount;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = AppLocalizations.of(context)!.ratingError;
      });
    }
  }

  Future<void> _submitRating() async {
    final t = AppLocalizations.of(context)!;

    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.loginToRate)),
      );
      return;
    }

    if (_selectedRating < 1 ||
        _selectedRating > 5 ||
        _isSubmitting) {
      return;
    }

    final isUpdating = _savedRating > 0;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _service.submitRating(
        restaurantId: widget.restaurantId,
        rating: _selectedRating,
      );

      // Refresh the average and count after saving.
      final summary = await _service.getRatingSummary(
        widget.restaurantId,
      );

      if (!mounted) return;

      setState(() {
        _savedRating = _selectedRating;
        _averageRating = summary.averageRating;
        _ratingCount = summary.ratingCount;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUpdating ? t.ratingUpdated : t.ratingSubmitted,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = t.ratingError;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: primaryGreen,
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightGreen.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            t.restaurantRating,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          if (isLoggedIn) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Colors.amber,
                  size: 27,
                ),
                const SizedBox(width: 5),
                Text(
                  _averageRating.toStringAsFixed(1),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '($_ratingCount)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              t.rateRestaurant,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final star = index + 1;

                return IconButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                    setState(() {
                      _selectedRating = star;
                    });
                  },
                  tooltip: '$star',
                  iconSize: 34,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    star <= _selectedRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: Colors.amber.shade700,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting || _selectedRating == 0
                    ? null
                    : _submitRating,
                style: FilledButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: primaryGreen.withOpacity(0.4),
                  disabledForegroundColor: Colors.white70,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  _savedRating > 0
                      ? t.updateRating
                      : t.submitRating,
                ),
              ),
            ),
          ] else
            Text(
              t.loginToRate,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),

          if (_ratingCount == 0 && isLoggedIn) ...[
            const SizedBox(height: 8),
            Text(
              t.noRatingsYet,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
