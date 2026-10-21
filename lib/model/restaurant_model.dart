import 'package:latlong2/latlong.dart';

class Restaurant {
final String id;
final String name;
final LatLng location;
final String? address;
final String? phone;
final String? website;
final double? distanceMeters;

const Restaurant({
required this.id,
required this.name,
required this.location,
this.address,
this.phone,
this.website,
this.distanceMeters,
});
}
