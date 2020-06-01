import 'package:google_maps_flutter/google_maps_flutter.dart';
class LocationResult {
  String address;
  LatLng latLng;

  LocationResult({this.latLng, this.address});

  @override
  String toString() {
    return 'LocationResult{address: $address, latLng: $latLng}';
  }
}