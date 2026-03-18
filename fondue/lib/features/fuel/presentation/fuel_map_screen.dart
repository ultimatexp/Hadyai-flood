import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/config/constants.dart';
import '../domain/gas_station.dart';
import '../domain/fuel_status.dart';
import 'fuel_providers.dart';
import 'station_panel.dart';
import 'quick_update_sheet.dart';
import 'oil_price_widget.dart';
import '../../donate/donate_screen.dart';

const _brandColors = <String, Color>{
  'PTT': Color(0xFF2D5CA0),
  'Bangchak': Color(0xFF00A651),
  'Shell': Color(0xFFFFB900),
  'Esso': Color(0xFFD41E31),
  'Caltex': Color(0xFFE2231A),
  'Susco': Color(0xFFFF6B00),
  'PT': Color(0xFF0066B3),
  'Sinopec': Color(0xFFC8102E),
};

class FuelMapScreen extends ConsumerStatefulWidget {
  const FuelMapScreen({super.key});

  @override
  ConsumerState<FuelMapScreen> createState() => _FuelMapScreenState();
}

class _FuelMapScreenState extends ConsumerState<FuelMapScreen> {
  final MapController _mapController = MapController();

  Color _getStationColor(GasStation station) {
    if (station.fuelStatus.isEmpty) return const Color(0xFF94A3B8);

    bool hasConfirmedOut = false;
    bool hasConfirmedAvailable = false;

    for (final status in station.fuelStatus.values) {
      final decisive = getDecisiveStatus(status);
      if (decisive.color == const Color(0xFFEF4444) && decisive.bars == 3) {
        hasConfirmedOut = true;
      }
      if (decisive.color == const Color(0xFF22C55E) && decisive.bars == 3) {
        hasConfirmedAvailable = true;
      }
    }

    if (hasConfirmedOut) return const Color(0xFFEF4444);
    if (hasConfirmedAvailable) return const Color(0xFF22C55E);
    return const Color(0xFFF59E0B);
  }

  double _radiusToZoom(double radius) {
    if (radius <= 5) return 14;
    if (radius <= 10) return 13;
    if (radius <= 25) return 11;
    if (radius <= 50) return 10;
    return 9;
  }

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredStationsProvider);
    final stationsAsync = ref.watch(stationsProvider);
    final locationAsync = ref.watch(userLocationProvider);
    final radius = ref.watch(selectedRadiusProvider);
    final selectedFuelType = ref.watch(selectedFuelTypeProvider);
    final selectedBrand = ref.watch(selectedBrandProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Map
          locationAsync.when(
            data: (location) {
              final center = location != null
                  ? LatLng(location.latitude, location.longitude)
                  : const LatLng(7.0058, 100.4745); // Hat Yai fallback

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: _radiusToZoom(radius),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=${AppConstants.mapTilerKey}',
                    maxZoom: 19,
                  ),
                  // User location marker
                  if (location != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(location.latitude, location.longitude),
                          width: 20,
                          height: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  // Station markers
                  filteredAsync.when(
                    data: (stations) => MarkerLayer(
                      markers: stations.map((station) {
                        final color = _getStationColor(station);
                        return Marker(
                          point: LatLng(station.lat, station.lng),
                          width: 36,
                          height: 36,
                          child: GestureDetector(
                            onTap: () {
                              showStationPanel(context, ref, station);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.local_gas_station,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    loading: () => const MarkerLayer(markers: []),
                    error: (_, __) => const MarkerLayer(markers: []),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('ไม่สามารถโหลดแผนที่ได้')),
          ),

          // Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Back button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, size: 20),
                      onPressed: () => Navigator.pop(context),
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Title
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_gas_station,
                              color: Color(0xFFF59E0B), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'สถานะน้ำมัน',
                            style: GoogleFonts.prompt(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Radius selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: DropdownButton<double>(
                      value: radius,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.expand_more, size: 18),
                      style: GoogleFonts.prompt(
                        fontSize: 13,
                        color: const Color(0xFF475569),
                      ),
                      items: const [
                        DropdownMenuItem(value: 5, child: Text('5 กม.')),
                        DropdownMenuItem(value: 10, child: Text('10 กม.')),
                        DropdownMenuItem(value: 25, child: Text('25 กม.')),
                        DropdownMenuItem(value: 50, child: Text('50 กม.')),
                        DropdownMenuItem(value: 100, child: Text('100 กม.')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(selectedRadiusProvider.notifier).set(value);
                          _mapController.move(
                              _mapController.camera.center, _radiusToZoom(value));
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Donate button in header area
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 8,
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DonateScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.3), blurRadius: 8)],
                ),
                child: const Text('☕', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),

          // Fuel type filter row with label
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 4),
                    child: Text('ประเภทน้ำมัน',
                      style: GoogleFonts.prompt(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF64748B), letterSpacing: 0.5)),
                  ),
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterPill(
                          label: '⛽ ทั้งหมด',
                          active: selectedFuelType.isEmpty,
                          isFuel: true,
                          onTap: () => ref.read(selectedFuelTypeProvider.notifier).set(''),
                        ),
                        const SizedBox(width: 6),
                        _FilterPill(
                          label: '🟡 ดีเซล',
                          active: selectedFuelType == 'diesel_b7',
                          isFuel: true,
                          onTap: () => ref.read(selectedFuelTypeProvider.notifier).set(
                              selectedFuelType == 'diesel_b7' ? '' : 'diesel_b7'),
                        ),
                        const SizedBox(width: 6),
                        _FilterPill(
                          label: '🟢 91',
                          active: selectedFuelType == 'gasohol_91',
                          isFuel: true,
                          onTap: () => ref.read(selectedFuelTypeProvider.notifier).set(
                              selectedFuelType == 'gasohol_91' ? '' : 'gasohol_91'),
                        ),
                        const SizedBox(width: 6),
                        _FilterPill(
                          label: '🔵 95',
                          active: selectedFuelType == 'gasohol_95',
                          isFuel: true,
                          onTap: () => ref.read(selectedFuelTypeProvider.notifier).set(
                              selectedFuelType == 'gasohol_95' ? '' : 'gasohol_95'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Brand filter row with label
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 106),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 4),
                    child: Text('แบรนด์',
                      style: GoogleFonts.prompt(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF64748B), letterSpacing: 0.5)),
                  ),
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ...['PTT', 'Bangchak', 'Shell', 'Caltex', 'Esso', 'Susco', 'PT', 'Sinopec'].map((b) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: _FilterPill(
                                label: b,
                                active: selectedBrand == b,
                                isFuel: false,
                                brandName: b,
                                onTap: () => ref.read(selectedBrandProvider.notifier).set(
                                    selectedBrand == b ? '' : b),
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Station count badge
          filteredAsync.when(
            data: (stations) => Positioned(
              left: 16,
              bottom: 130,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  'พบ ${stations.length} สถานี',
                  style: GoogleFonts.prompt(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),

          // Locate me FAB
          Positioned(
            right: 16,
            bottom: 130,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.my_location, color: Color(0xFF3B82F6)),
                onPressed: () async {
                  ref.invalidate(userLocationProvider);
                  final loc = await ref.read(userLocationProvider.future);
                  if (loc != null) {
                    _mapController.move(
                      LatLng(loc.latitude, loc.longitude),
                      _radiusToZoom(radius),
                    );
                  }
                },
              ),
            ),
          ),

          // Quick update FAB — centered bottom
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: stationsAsync.when(
                data: (stations) => Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => showQuickUpdateSheet(context, ref, stations),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_comment,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'แจ้งน้ำมันหมด',
                            style: GoogleFonts.prompt(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
            ),
          ),
          // Oil price widget
          const OilPriceWidget(),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool active;
  final bool isFuel;
  final String? brandName;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.active,
    required this.isFuel,
    required this.onTap,
    this.brandName,
  });

  @override
  Widget build(BuildContext context) {
    final brandColor = brandName != null ? _brandColors[brandName] : null;

    // Determine colors based on type
    Color bgColor;
    Color borderColor;
    Color textColor;
    List<BoxShadow> shadows;

    if (active) {
      if (isFuel) {
        // Fuel active: orange gradient-like solid
        bgColor = const Color(0xFFF59E0B);
        borderColor = Colors.transparent;
        textColor = Colors.white;
        shadows = [BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))];
      } else if (brandColor != null) {
        // Brand active: solid brand color
        bgColor = brandColor;
        borderColor = Colors.transparent;
        textColor = brandColor == const Color(0xFFFFB900) ? const Color(0xFF333333) : Colors.white;
        shadows = [BoxShadow(color: brandColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))];
      } else {
        bgColor = const Color(0xFF3B82F6);
        borderColor = Colors.transparent;
        textColor = Colors.white;
        shadows = [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))];
      }
    } else {
      if (brandColor != null) {
        // Brand inactive: tinted background
        bgColor = brandColor.withOpacity(0.08);
        borderColor = brandColor.withOpacity(0.25);
        textColor = brandColor;
      } else {
        bgColor = Colors.white.withOpacity(0.95);
        borderColor = Colors.black.withOpacity(0.08);
        textColor = const Color(0xFF64748B);
      }
      shadows = [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 3, offset: const Offset(0, 1))];
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: shadows,
          ),
          child: Text(
            label,
            style: GoogleFonts.prompt(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
