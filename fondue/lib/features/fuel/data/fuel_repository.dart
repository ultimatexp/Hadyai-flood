import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/constants.dart';
import '../domain/gas_station.dart';
import '../domain/fuel_type.dart';

class FuelRepository {
  final SupabaseClient _client;

  FuelRepository(this._client);

  /// Fetch fuel types from Supabase
  Future<List<FuelType>> fetchFuelTypes() async {
    final response = await _client
        .from('fuel_types')
        .select()
        .order('sort_order', ascending: true);

    return (response as List<dynamic>)
        .map((json) => FuelType.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch stations via Next.js API route (handles fuel_status aggregation)
  Future<List<GasStation>> fetchStations({
    required double lat,
    required double lng,
    double radius = 10,
    String? brand,
    String? search,
  }) async {
    final params = <String, String>{
      'lat': lat.toString(),
      'lng': lng.toString(),
      'radius': radius.toString(),
    };
    if (brand != null && brand.isNotEmpty) params['brand'] = brand;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final uri = Uri.parse('${AppConstants.apiBaseUrl}/api/fuel/stations')
        .replace(queryParameters: params);

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch stations: ${response.statusCode}');
    }

    final body = json.decode(response.body);
    final data = body['stations'] as List<dynamic>? ?? [];
    return data
        .map((json) => GasStation.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Submit a vote
  Future<bool> submitVote({
    required String stationId,
    required String fuelTypeId,
    required String status,
    required String fingerprint,
    String? note,
  }) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/api/fuel/vote');

    final body = {
      'station_id': stationId,
      'fuel_type_id': fuelTypeId,
      'status': status,
      'fingerprint': fingerprint,
    };
    if (note != null && note.isNotEmpty) body['note'] = note;

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    return response.statusCode == 200;
  }

  /// Update station name
  Future<bool> updateStationName({
    required String stationId,
    required String newName,
  }) async {
    final uri =
        Uri.parse('${AppConstants.apiBaseUrl}/api/fuel/stations/update');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'id': stationId, 'name': newName}),
    );

    return response.statusCode == 200;
  }
}
