import 'fuel_status.dart';

class GasStation {
  final String id;
  final String name;
  final String brand;
  final double lat;
  final double lng;
  final String address;
  final String province;
  final String district;
  final List<String> fuelTypes;
  final bool isVerified;
  final Map<String, FuelStatus> fuelStatus;
  final double? distance; // km from user, set client-side

  const GasStation({
    required this.id,
    required this.name,
    required this.brand,
    required this.lat,
    required this.lng,
    required this.address,
    required this.province,
    required this.district,
    required this.fuelTypes,
    required this.isVerified,
    required this.fuelStatus,
    this.distance,
  });

  factory GasStation.fromJson(Map<String, dynamic> json) {
    final fuelStatusMap = <String, FuelStatus>{};
    if (json['fuel_status'] is Map) {
      (json['fuel_status'] as Map<String, dynamic>).forEach((key, value) {
        if (value is Map<String, dynamic>) {
          fuelStatusMap[key] = FuelStatus.fromJson(value);
        }
      });
    }

    return GasStation(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      address: json['address'] as String? ?? '',
      province: json['province'] as String? ?? '',
      district: json['district'] as String? ?? '',
      fuelTypes: (json['fuel_types'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isVerified: json['is_verified'] as bool? ?? false,
      fuelStatus: fuelStatusMap,
    );
  }

  GasStation copyWith({String? name, double? distance}) {
    return GasStation(
      id: id,
      name: name ?? this.name,
      brand: brand,
      lat: lat,
      lng: lng,
      address: address,
      province: province,
      district: district,
      fuelTypes: fuelTypes,
      isVerified: isVerified,
      fuelStatus: fuelStatus,
      distance: distance ?? this.distance,
    );
  }
}
