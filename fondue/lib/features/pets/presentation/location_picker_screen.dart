import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/theme/app_theme.dart';

/// Parses "(lat, lng)" or "lat, lng" pasted from Google Maps (lat then lng).
LatLng? parseLatLngPaste(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return null;
  var inner = s;
  if (inner.startsWith('(') && inner.endsWith(')')) {
    inner = inner.substring(1, inner.length - 1).trim();
  }
  final comma = inner.indexOf(',');
  if (comma == -1) return null;
  final lat = double.tryParse(inner.substring(0, comma).trim());
  final lng = double.tryParse(inner.substring(comma + 1).trim());
  if (lat == null || lng == null) return null;
  if (lat.abs() > 90 || lng.abs() > 180) return null;
  return LatLng(lat, lng);
}

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
  final TextEditingController _pasteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentCenter = LatLng(widget.initialLat, widget.initialLng);
  }

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    setState(() {
      _currentCenter = camera.center;
    });
  }

  void _applyPastedCoords() {
    final parsed = parseLatLngPaste(_pasteController.text);
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid format. Use (latitude, longitude) e.g. (13.3226994, 101.1165946)',
          ),
        ),
      );
      return;
    }
    setState(() => _currentCenter = parsed);
    _mapController.move(parsed, _mapController.camera.zoom);
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paste from Google Maps',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  'Example: (13.3226994, 101.1165946) or 13.3226994, 101.1165946 — latitude first, then longitude.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _pasteController,
                        decoration: const InputDecoration(
                          hintText: '(13.3226994, 101.1165946)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.text,
                        autocorrect: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _applyPastedCoords,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
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
                const Center(
                  child: Icon(Icons.location_on, color: Colors.red, size: 48),
                ),
                Positioned(
                  bottom: 40,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: const Text(
                      'Move the map to place the pin, or paste coordinates above',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
