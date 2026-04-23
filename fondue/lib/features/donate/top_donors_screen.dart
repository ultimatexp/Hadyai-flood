import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/constants.dart';
import 'donation_models.dart' show TopDonor, donationInitial;
import 'donation_providers.dart';

class TopDonorsScreen extends ConsumerWidget {
  const TopDonorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(topDonorsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF1E1B4B)],
            stops: [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: Color(0x99FFFFFF)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Text('🏆', style: GoogleFonts.prompt(fontSize: 48)),
                    const SizedBox(height: 8),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFBBF24), Color(0xFFF472B6), Color(0xFFA78BFA)],
                      ).createShader(bounds),
                      child: Text(
                        'สุดยอดผู้ใจบุญ',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.prompt(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'รวมยอดจากผู้ที่ระบุชื่อบน Stripe เท่านั้น',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.prompt(fontSize: 12, color: Colors.white.withValues(alpha: 0.55), height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _openDonatePage(context),
                          borderRadius: BorderRadius.circular(24),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.55)),
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'มาเป็นผู้สนับสนุนของเรา',
                                  style: GoogleFonts.prompt(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.95),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.open_in_new_rounded,
                                  size: 18,
                                  color: const Color(0xFFFBBF24).withValues(alpha: 0.9),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: async.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFBBF24))),
                  error: (_, _) => Center(
                    child: Text('โหลดไม่สำเร็จ', style: GoogleFonts.prompt(color: Colors.white70)),
                  ),
                  data: (list) {
                    if (list.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'ยังไม่มีข้อมูลอันดับ\nบริจาคผ่านเว็บแล้วระบุชื่อเพื่อขึ้นกระดานเกียรติยศ',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.prompt(fontSize: 14, color: Colors.white.withValues(alpha: 0.65), height: 1.6),
                          ),
                        ),
                      );
                    }
                    final top3 = list.take(3).toList();
                    return RefreshIndicator(
                      color: const Color(0xFFFBBF24),
                      onRefresh: () async => ref.invalidate(topDonorsProvider),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        children: [
                          _Podium(top3: top3),
                          if (list.length > 3) ...[
                            const SizedBox(height: 28),
                            Text(
                              'อันดับถัดไป',
                              style: GoogleFonts.prompt(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...list.skip(3).toList().asMap().entries.map((e) {
                              final rank = e.key + 4;
                              final d = e.value;
                              return _RankRow(rank: rank, donor: d);
                            }),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _openDonatePage(BuildContext context) async {
  final uri = Uri.parse('${AppConstants.apiBaseUrl}/donate');
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เปิดเบราว์เซอร์ไม่สำเร็จ', style: GoogleFonts.prompt())),
      );
    }
  }
}

class _Podium extends StatelessWidget {
  final List<TopDonor> top3;

  const _Podium({required this.top3});

  @override
  Widget build(BuildContext context) {
    final second = top3.length > 1 ? top3[1] : null;
    final first = top3.isNotEmpty ? top3[0] : null;
    final third = top3.length > 2 ? top3[2] : null;

    return SizedBox(
      height: 280,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: _PodiumSlot(rank: 2, donor: second, height: 150, scale: 1.0)),
          Expanded(child: _PodiumSlot(rank: 1, donor: first, height: 200, scale: 1.18)),
          Expanded(child: _PodiumSlot(rank: 3, donor: third, height: 130, scale: 0.95)),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final int rank;
  final TopDonor? donor;
  final double height;
  final double scale;

  const _PodiumSlot({
    required this.rank,
    required this.donor,
    required this.height,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉';
    final d = donor;
    return Transform.scale(
      scale: scale,
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (d != null) ...[
              Text(medal, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: rank == 1
                        ? const [Color(0xFFFBBF24), Color(0xFFF59E0B)]
                        : rank == 2
                            ? const [Color(0xFFE2E8F0), Color(0xFF94A3B8)]
                            : const [Color(0xFFFB923C), Color(0xFFC2410C)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (rank == 1 ? const Color(0xFFFBBF24) : Colors.white).withValues(alpha: 0.35),
                      blurRadius: rank == 1 ? 22 : 10,
                      spreadRadius: rank == 1 ? 1 : 0,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: d.avatarAssetPath != null
                    ? Image.asset(
                        d.avatarAssetPath!,
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                      )
                    : Text(
                        donationInitial(d.displayName),
                        style: GoogleFonts.prompt(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: rank == 2 ? const Color(0xFF1E293B) : Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 10),
              Text(
                d.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.prompt(
                  fontSize: rank == 1 ? 15 : 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                d.totalThbText,
                style: GoogleFonts.prompt(
                  fontSize: rank == 1 ? 20 : 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFFBBF24),
                ),
              ),
            ] else
              Text('—', style: GoogleFonts.prompt(color: Colors.white38, fontSize: 32)),
            const SizedBox(height: 12),
            Container(
              height: height * 0.35,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF6366F1).withValues(alpha: 0.85),
                    const Color(0xFF312E81),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border.all(color: Colors.white24),
              ),
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '#$rank',
                  style: GoogleFonts.prompt(
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final TopDonor donor;

  const _RankRow({required this.rank, required this.donor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '#$rank',
                style: GoogleFonts.prompt(fontWeight: FontWeight.w800, color: const Color(0xFFFBBF24)),
              ),
            ),
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF6366F1),
              backgroundImage:
                  donor.avatarAssetPath != null ? AssetImage(donor.avatarAssetPath!) : null,
              child: donor.avatarAssetPath == null
                  ? Text(
                      donationInitial(donor.displayName),
                      style: GoogleFonts.prompt(fontWeight: FontWeight.w800, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donor.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.prompt(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  Text(
                    '${donor.donationCount} ครั้ง',
                    style: GoogleFonts.prompt(fontSize: 11, color: Colors.white54),
                  ),
                ],
              ),
            ),
            Text(
              donor.totalThbText,
              style: GoogleFonts.prompt(fontWeight: FontWeight.w800, color: const Color(0xFFA78BFA)),
            ),
          ],
        ),
      ),
    );
  }
}
