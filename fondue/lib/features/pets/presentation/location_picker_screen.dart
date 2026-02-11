import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/theme/app_theme.dart';

class LocationPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const LocationPickerScreen({
    super.key,
    this.initialLat = 7.005, // Default Hadyai
    this.initialLng = 100.476,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late final MapController _mapController;
  late LatLng _currentCenter;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentCenter = LatLng(widget.initialLat, widget.initialLng);
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    setState(() {
      _currentCenter = camera.center;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _currentCenter);
            },
            child: const Text('CONFIRM', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 15.0,
              onPositionChanged: _onPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}@2x.png?key=${AppConstants.mapTilerKey}',
                userAgentPackageName: 'com.fondue.app',
                retinaMode: true,
              ),
            ],
          ),
          // Center Marker / Crosshair
          const Center(
            child: Icon(Icons.location_on, color: Colors.red, size: 48),
          ),
          // Helper Text
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: const Text(
                'Move the map to place the pin',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
