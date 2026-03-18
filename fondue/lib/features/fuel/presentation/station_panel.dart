import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/gas_station.dart';
import '../domain/fuel_type.dart';
import '../domain/fuel_status.dart';
import 'fuel_providers.dart';
import 'widgets/signal_bars.dart';

const _brandColors = <String, Color>{
  'PTT': Color(0xFF2D5CA0),
  'Bangchak': Color(0xFF00A651),
  'Shell': Color(0xFFFFB81C),
  'Esso': Color(0xFFD41E31),
  'Caltex': Color(0xFFE2231A),
  'Susco': Color(0xFFE4002B),
  'Other': Color(0xFF64748B),
};

void showStationPanel(BuildContext context, WidgetRef ref, GasStation station) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _StationPanelContent(station: station),
  );
}

class _StationPanelContent extends ConsumerStatefulWidget {
  final GasStation station;
  const _StationPanelContent({required this.station});

  @override
  ConsumerState<_StationPanelContent> createState() => _StationPanelContentState();
}

class _StationPanelContentState extends ConsumerState<_StationPanelContent> {
  bool _isEditingName = false;
  late TextEditingController _nameController;
  bool _savingName = false;
  String? _submittingKey;
  String? _successKey;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.station.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty || newName == widget.station.name) {
      setState(() => _isEditingName = false);
      return;
    }
    setState(() => _savingName = true);
    final repo = ref.read(fuelRepositoryProvider);
    final ok = await repo.updateStationName(stationId: widget.station.id, newName: newName);
    if (ok) {
      ref.invalidate(stationsProvider);
      setState(() => _isEditingName = false);
    }
    setState(() => _savingName = false);
  }

  Future<void> _vote(String fuelTypeId, String status) async {
    final key = '${widget.station.id}-$fuelTypeId';
    setState(() => _submittingKey = key);
    final repo = ref.read(fuelRepositoryProvider);
    final fp = await ref.read(fingerprintProvider.future);
    final ok = await repo.submitVote(
      stationId: widget.station.id,
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
    final fuelTypesAsync = ref.watch(fuelTypesProvider);
    final station = widget.station;
    final brandColor = _brandColors[station.brand] ?? const Color(0xFF64748B);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4)),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  // Brand logo
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: brandColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      station.brand.length > 3 ? station.brand.substring(0, 3) : station.brand,
                      style: GoogleFonts.prompt(
                        fontSize: 12, fontWeight: FontWeight.w700, color: brandColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name row
                        _isEditingName
                            ? Row(children: [
                                Expanded(
                                  child: TextField(
                                    controller: _nameController,
                                    autofocus: true,
                                    style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w700),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onSubmitted: (_) => _saveName(),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                TextButton(
                                  onPressed: _savingName ? null : _saveName,
                                  child: Text(_savingName ? '...' : 'บันทึก'),
                                ),
                                TextButton(
                                  onPressed: () => setState(() => _isEditingName = false),
                                  child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
                                ),
                              ])
                            : Row(children: [
                                Flexible(
                                  child: Text(
                                    station.name,
                                    style: GoogleFonts.prompt(
                                      fontSize: 18, fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => setState(() => _isEditingName = true),
                                  child: Icon(Icons.edit, size: 16, color: Colors.grey[400]),
                                ),
                              ]),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 13, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              '${station.district}, ${station.province}',
                              style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Section title
              Text(
                '⛽ สถานะน้ำมันแต่ละชนิด',
                style: GoogleFonts.prompt(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 10),

              // Fuel cards
              fuelTypesAsync.when(
                data: (allFuelTypes) {
                  final types = allFuelTypes
                      .where((ft) => station.fuelTypes.contains(ft.id))
                      .toList();

                  return Column(
                    children: types.map((ft) {
                      final status = station.fuelStatus[ft.id];
                      final decisive = getDecisiveStatus(status);
                      final key = '${station.id}-${ft.id}';
                      final isSubmitting = _submittingKey == key;
                      final isSuccess = _successKey == key;
                      final isOut = decisive.color == const Color(0xFFEF4444);
                      final isAvailable = decisive.color == const Color(0xFF22C55E);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isOut
                              ? const Color(0xFFFEF2F2)
                              : isAvailable
                                  ? const Color(0xFFF0FDF4)
                                  : Colors.grey[50],
                          border: Border.all(
                            color: isOut
                                ? const Color(0xFFFECACA)
                                : isAvailable
                                    ? const Color(0xFFBBF7D0)
                                    : Colors.grey.shade200,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fuel name + status badge
                            Row(
                              children: [
                                Container(
                                  width: 10, height: 10,
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(ft.color.replaceFirst('#', '0xFF'))),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    ft.nameTh,
                                    style: GoogleFonts.prompt(
                                      fontSize: 14, fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: decisive.color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SignalBars(count: decisive.bars, color: decisive.color),
                                      const SizedBox(width: 6),
                                      Text(
                                        decisive.label,
                                        style: GoogleFonts.prompt(
                                          fontSize: 11, fontWeight: FontWeight.w600,
                                          color: decisive.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Meta info
                            if (status != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text('👥 ${status.voteCount} โหวต',
                                      style: GoogleFonts.prompt(fontSize: 11, color: Colors.grey[500])),
                                  const SizedBox(width: 12),
                                  Text('🎯 ${status.confidence.toInt()}% เห็นด้วย',
                                      style: GoogleFonts.prompt(fontSize: 11, color: Colors.grey[500])),
                                ],
                              ),
                            ],

                            // Needs verify banner
                            if (decisive.needsVerify) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withOpacity(0.06),
                                  border: Border.all(
                                    color: const Color(0xFFF59E0B).withOpacity(0.2),
                                    style: BorderStyle.solid,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '📢 ข้อมูลนี้ยังไม่ชัวร์ — ช่วยยืนยันสถานะด้านล่าง!',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.prompt(
                                    fontSize: 11, fontWeight: FontWeight.w600,
                                    color: const Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 8),

                            // Vote buttons
                            if (isSuccess)
                              Center(
                                child: Text('✅ สำเร็จ!',
                                    style: GoogleFonts.prompt(
                                        fontSize: 13, fontWeight: FontWeight.w600,
                                        color: const Color(0xFF22C55E))),
                              )
                            else
                              Row(
                                children: [
                                  _VoteButton(
                                    label: 'มีน้ำมัน',
                                    icon: Icons.check_circle_outline,
                                    color: const Color(0xFF22C55E),
                                    isLoading: isSubmitting,
                                    onTap: () => _vote(ft.id, 'available'),
                                  ),
                                  const SizedBox(width: 6),
                                  _VoteButton(
                                    label: 'หมดแล้ว',
                                    icon: Icons.cancel_outlined,
                                    color: const Color(0xFFEF4444),
                                    isLoading: isSubmitting,
                                    onTap: () => _vote(ft.id, 'out_of_stock'),
                                  ),
                                  const SizedBox(width: 6),
                                  _VoteButton(
                                    label: 'เติมใหม่',
                                    icon: Icons.refresh,
                                    color: const Color(0xFF3B82F6),
                                    isLoading: isSubmitting,
                                    onTap: () => _vote(ft.id, 'refilled'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('ไม่สามารถโหลดประเภทน้ำมันได้'),
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _VoteButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  const _VoteButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            border: Border.all(color: color.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.prompt(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
