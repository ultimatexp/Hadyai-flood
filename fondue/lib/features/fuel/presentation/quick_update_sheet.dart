import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/gas_station.dart';
import '../domain/fuel_status.dart';
import 'fuel_providers.dart';
import 'widgets/signal_bars.dart';

double _haversine(double lat1, double lng1, double lat2, double lng2) {
  const R = 6371.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLng = (lng2 - lng1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLng / 2) * sin(dLng / 2);
  return R * 2 * atan2(sqrt(a), sqrt(1 - a));
}

const _brandColors = <String, Color>{
  'PTT': Color(0xFF2D5CA0),
  'Bangchak': Color(0xFF00A651),
  'Shell': Color(0xFFFFB81C),
  'Esso': Color(0xFFD41E31),
  'Caltex': Color(0xFFE2231A),
  'Susco': Color(0xFFE4002B),
};

void showQuickUpdateSheet(BuildContext context, WidgetRef ref, List<GasStation> stations) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QuickUpdateContent(stations: stations),
  );
}

class _QuickUpdateContent extends ConsumerStatefulWidget {
  final List<GasStation> stations;
  const _QuickUpdateContent({required this.stations});

  @override
  ConsumerState<_QuickUpdateContent> createState() => _QuickUpdateContentState();
}

class _QuickUpdateContentState extends ConsumerState<_QuickUpdateContent> {
  String? _submittingKey;
  String? _successKey;

  List<GasStation> get _sortedStations {
    final locAsync = ref.read(userLocationProvider);
    final loc = locAsync.whenOrNull(data: (p) => p);
    if (loc == null) return widget.stations.take(8).toList();

    final withDist = widget.stations.map((s) {
      final dist = _haversine(loc.latitude, loc.longitude, s.lat, s.lng);
      return s.copyWith(distance: dist);
    }).toList()
      ..sort((a, b) => (a.distance ?? 999).compareTo(b.distance ?? 999));

    return withDist.take(8).toList();
  }

  Future<void> _vote(String stationId, String fuelTypeId, String status) async {
    final key = '$stationId-$fuelTypeId';
    setState(() => _submittingKey = key);
    final repo = ref.read(fuelRepositoryProvider);
    final fp = await ref.read(fingerprintProvider.future);
    final ok = await repo.submitVote(
      stationId: stationId,
      fuelTypeId: fuelTypeId,
      status: status,
      fingerprint: fp,
    );
    if (ok) {
      setState(() => _successKey = key);
      ref.invalidate(stationsProvider);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _successKey = null);
    }
    if (mounted) setState(() => _submittingKey = null);
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sortedStations;
    final fuelTypesAsync = ref.watch(fuelTypesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📢 รายงานสถานะน้ำมัน',
                              style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                          const SizedBox(height: 2),
                          Text('ปั๊มใกล้คุณ — แตะเพื่อรายงาน',
                              style: GoogleFonts.prompt(fontSize: 13, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Station list
              Expanded(
                child: fuelTypesAsync.when(
                  data: (allFuelTypes) => ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final station = sorted[i];
                      final brandColor = _brandColors[station.brand] ?? const Color(0xFF64748B);
                      final types = allFuelTypes.where((ft) => station.fuelTypes.contains(ft.id)).take(4).toList();

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Station header
                            Row(
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: brandColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    station.brand.length > 3 ? station.brand.substring(0, 3) : station.brand,
                                    style: GoogleFonts.prompt(fontSize: 11, fontWeight: FontWeight.w800, color: brandColor),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(station.name,
                                          style: GoogleFonts.prompt(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                                          overflow: TextOverflow.ellipsis),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on, size: 10, color: Colors.grey[400]),
                                          const SizedBox(width: 3),
                                          Text('${station.district}, ${station.province}',
                                              style: GoogleFonts.prompt(fontSize: 11, color: Colors.grey[400])),
                                          if (station.distance != null) ...[
                                            const SizedBox(width: 8),
                                            Icon(Icons.navigation, size: 10, color: const Color(0xFF3B82F6)),
                                            const SizedBox(width: 2),
                                            Text(
                                              station.distance! < 1
                                                  ? '${(station.distance! * 1000).round()}m'
                                                  : '${station.distance!.toStringAsFixed(1)}km',
                                              style: GoogleFonts.prompt(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF3B82F6)),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Fuel vote rows
                            ...types.map((ft) {
                              final key = '${station.id}-${ft.id}';
                              final isSubmitting = _submittingKey == key;
                              final isSuccess = _successKey == key;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8, height: 8,
                                      decoration: BoxDecoration(
                                        color: Color(int.parse(ft.color.replaceFirst('#', '0xFF'))),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(ft.nameTh,
                                          style: GoogleFonts.prompt(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF475569))),
                                    ),
                                    if (isSuccess)
                                      Text('✅ สำเร็จ!',
                                          style: GoogleFonts.prompt(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF22C55E)))
                                    else
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _MiniVoteBtn(label: 'มี', color: const Color(0xFF22C55E), isLoading: isSubmitting, onTap: () => _vote(station.id, ft.id, 'available')),
                                          const SizedBox(width: 4),
                                          _MiniVoteBtn(label: 'หมด', color: const Color(0xFFEF4444), isLoading: isSubmitting, onTap: () => _vote(station.id, ft.id, 'out_of_stock')),
                                          const SizedBox(width: 4),
                                          _MiniVoteBtn(label: 'เติมใหม่', color: const Color(0xFF3B82F6), isLoading: isSubmitting, onTap: () => _vote(station.id, ft.id, 'refilled')),
                                        ],
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(child: Text('เกิดข้อผิดพลาด')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniVoteBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  const _MiniVoteBtn({required this.label, required this.color, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.prompt(fontSize: 11, fontWeight: FontWeight.w600, color: color),
        ),
      ),
    );
  }
}
