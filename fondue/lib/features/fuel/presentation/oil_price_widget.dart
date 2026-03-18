import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/constants.dart';

class OilPrice {
  final String name;
  final String? fuelId;
  final double priceToday;
  final double priceYesterday;
  final double priceTomorrow;
  final double diffYesterday;
  final double diffTomorrow;

  OilPrice({
    required this.name,
    this.fuelId,
    required this.priceToday,
    required this.priceYesterday,
    required this.priceTomorrow,
    required this.diffYesterday,
    required this.diffTomorrow,
  });

  factory OilPrice.fromJson(Map<String, dynamic> json) => OilPrice(
        name: json['name'] as String,
        fuelId: json['fuel_id'] as String?,
        priceToday: (json['price_today'] as num).toDouble(),
        priceYesterday: (json['price_yesterday'] as num).toDouble(),
        priceTomorrow: (json['price_tomorrow'] as num).toDouble(),
        diffYesterday: (json['diff_yesterday'] as num).toDouble(),
        diffTomorrow: (json['diff_tomorrow'] as num).toDouble(),
      );
}

class OilPriceWidget extends StatefulWidget {
  const OilPriceWidget({super.key});

  @override
  State<OilPriceWidget> createState() => _OilPriceWidgetState();
}

class _OilPriceWidgetState extends State<OilPriceWidget> {
  List<OilPrice>? _prices;
  String? _remark;
  String? _priceDate;
  String? _source;
  bool _loading = true;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _fetchPrices();
  }

  Future<void> _fetchPrices() async {
    try {
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/api/fuel/prices');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final list = (body['prices'] as List<dynamic>)
            .map((j) => OilPrice.fromJson(j as Map<String, dynamic>))
            .toList();
        final meta = body['metadata'] as Map<String, dynamic>?;
        if (mounted) {
          setState(() {
            _prices = list;
            _remark = meta?['remark'] as String?;
            _priceDate = meta?['price_date'] as String?;
            _source = meta?['source'] as String?;
            _loading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _prices == null) {
      return Positioned(
        left: 16,
        right: 16,
        bottom: 16,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 10),
              Text('กำลังโหลดราคาน้ำมัน...', style: GoogleFonts.prompt(fontSize: 12, color: const Color(0xFF94A3B8))),
            ],
          ),
        ),
      );
    }

    final keyFuels = _prices!.where((p) =>
        ['gasohol_91', 'gasohol_95', 'diesel_b7', 'diesel'].contains(p.fuelId)).toList();
    final hasTomorrowChanges = _prices!.any((p) => p.diffTomorrow != 0);

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Expanded panel
          if (_expanded) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.98),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 24, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('💰 ราคาน้ำมัน', style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                        if (_remark != null)
                          Text(_remark!, style: GoogleFonts.prompt(fontSize: 11, color: const Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                  // Column headers
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text('ชนิด', style: GoogleFonts.prompt(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8)))),
                        SizedBox(width: 70, child: Text('วันนี้', textAlign: TextAlign.right, style: GoogleFonts.prompt(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF3B82F6)))),
                        SizedBox(width: 100, child: Text('พรุ่งนี้', textAlign: TextAlign.right, style: GoogleFonts.prompt(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFF59E0B)))),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1.5, indent: 16, endIndent: 16),
                  // Price rows
                  ..._prices!.map((fuel) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(fuel.name, style: GoogleFonts.prompt(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF475569)),
                                overflow: TextOverflow.ellipsis),
                            ),
                            SizedBox(
                              width: 70,
                              child: Text('฿${fuel.priceToday.toStringAsFixed(2)}',
                                textAlign: TextAlign.right,
                                style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                            ),
                            SizedBox(
                              width: 100,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('฿${fuel.priceTomorrow.toStringAsFixed(2)}',
                                    style: GoogleFonts.prompt(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: fuel.diffTomorrow > 0 ? const Color(0xFFEF4444)
                                          : fuel.diffTomorrow < 0 ? const Color(0xFF22C55E)
                                          : const Color(0xFF64748B),
                                    )),
                                  if (fuel.diffTomorrow != 0) ...[
                                    const SizedBox(width: 4),
                                    _buildChangeBadge(fuel.diffTomorrow, showValue: true),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                  // Tomorrow warning
                  if (hasTomorrowChanges)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.06),
                        border: Border(top: BorderSide(color: const Color(0xFFF59E0B).withOpacity(0.1))),
                      ),
                      child: Text('⚠️ ราคาน้ำมันพรุ่งนี้มีการเปลี่ยนแปลง',
                          style: GoogleFonts.prompt(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFB45309))),
                    ),
                  // Footer
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                    child: Text(
                      'ข้อมูลจาก ${_source ?? 'Bangchak'} · อัพเดท ${_priceDate ?? '-'}',
                      style: GoogleFonts.prompt(fontSize: 10, color: const Color(0xFF94A3B8)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Mini ticker bar
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  _buildIcon(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (int i = 0; i < keyFuels.length; i++) ...[
                            if (i > 0)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text('·', style: TextStyle(color: Colors.black.withOpacity(0.15), fontSize: 12)),
                              ),
                            Text(_shortName(keyFuels[i].name),
                                style: GoogleFonts.prompt(fontSize: 10, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8))),
                            const SizedBox(width: 4),
                            Text('฿${keyFuels[i].priceToday.toStringAsFixed(2)}',
                                style: GoogleFonts.prompt(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                            if (keyFuels[i].diffTomorrow != 0) ...[
                              const SizedBox(width: 3),
                              _buildChangeBadge(keyFuels[i].diffTomorrow, label: 'พรุ่งนี้'),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(_expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                      size: 14, color: const Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.local_gas_station, size: 12, color: Colors.white),
    );
  }

  Widget _buildChangeBadge(double diff, {bool showValue = false, String? label}) {
    final isUp = diff > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: isUp ? const Color(0xFFEF4444).withOpacity(0.15) : const Color(0xFF22C55E).withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null)
            Text('$label ', style: GoogleFonts.prompt(fontSize: 8, color: isUp ? const Color(0xFFEF4444) : const Color(0xFF22C55E))),
          Icon(isUp ? Icons.trending_up : Icons.trending_down, size: 10, color: isUp ? const Color(0xFFEF4444) : const Color(0xFF22C55E)),
          if (showValue)
            Text(' ${isUp ? '+' : ''}${diff.toStringAsFixed(2)}',
                style: GoogleFonts.prompt(fontSize: 9, fontWeight: FontWeight.w600, color: isUp ? const Color(0xFFEF4444) : const Color(0xFF22C55E))),
        ],
      ),
    );
  }

  String _shortName(String name) {
    return name
        .replaceAll('S EVO', '')
        .replaceAll(RegExp(r'S$'), '')
        .replaceAll('ไฮ', '')
        .replaceAll(RegExp(r'พรีเมียม\s*\d*\s*'), '')
        .trim();
  }
}
