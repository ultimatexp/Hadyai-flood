import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'donation_models.dart';

/// Horizontal auto-scrolling latest donors + donate icon (right).
/// [forLightBackground] — home tab (light) vs donate page (dark).
class LatestDonorsStrip extends StatefulWidget {
  final List<Donation> donations;
  final bool forLightBackground;

  const LatestDonorsStrip({
    super.key,
    required this.donations,
    this.forLightBackground = false,
  });

  @override
  State<LatestDonorsStrip> createState() => _LatestDonorsStripState();
}

class _LatestDonorsStripState extends State<LatestDonorsStrip> {
  static const double _tileW = 56;
  static const double _sepW = 6;
  static const double _scrollStep = _tileW + _sepW;
  static const int _minTilesForScroll = 16;

  final ScrollController _scroll = ScrollController();
  Timer? _timer;

  /// Repeat donors so the list always has enough width to auto-scroll smoothly.
  List<Donation> _paddedDonations(List<Donation> src) {
    if (src.isEmpty) return src;
    if (src.length >= _minTilesForScroll) return src;
    final out = <Donation>[];
    var i = 0;
    while (out.length < _minTilesForScroll) {
      out.add(src[i % src.length]);
      i++;
    }
    return out;
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1600), (_) => _nudge());
  }

  void _nudge() {
    if (!mounted || widget.donations.isEmpty) return;
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    if (max <= 4) return;
    final next = _scroll.offset + _scrollStep * 0.85;
    if (next >= max - 2) {
      _scroll.jumpTo(0);
    } else {
      _scroll.animateTo(
        next.clamp(0.0, max),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void didUpdateWidget(covariant LatestDonorsStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.donations.length != widget.donations.length ||
        oldWidget.donations.map((e) => e.id).join() != widget.donations.map((e) => e.id).join()) {
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Color get _titleColor =>
      widget.forLightBackground ? const Color(0xFF374151) : Colors.white.withValues(alpha: 0.85);

  Color get _mutedColor =>
      widget.forLightBackground ? const Color(0xFF6B7280) : Colors.white.withValues(alpha: 0.55);

  Color get _borderColor => widget.forLightBackground ? const Color(0xFFE5E7EB) : Colors.white.withValues(alpha: 0.1);

  Color get _cardFill =>
      widget.forLightBackground ? Colors.white : Colors.white.withValues(alpha: 0.06);

  static const double _donateIconPx = 80;

  double get _stripHeight => widget.forLightBackground ? 88 : 96;

  @override
  Widget build(BuildContext context) {
    if (widget.donations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: _cardFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                widget.forLightBackground
                    ? 'ยังไม่มีรายการบริจาคล่าสุด — ร่วมสนับสนุนทีมงานได้จากเมนูบริจาค'
                    : 'ยังไม่มีรายการบริจาคล่าสุด — เป็นคนแรกบนเว็บด้วย Stripe ได้เลย',
                style: GoogleFonts.prompt(
                  fontSize: widget.forLightBackground ? 10 : 11,
                  color: _mutedColor,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(width: 6),
            DonateStripIcon(size: _donateIconPx),
          ],
        ),
      );
    }

    final scrollItems = _paddedDonations(widget.donations);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 3),
          child: Text(
            widget.forLightBackground ? 'ผู้บริจาคล่าสุด' : 'ผู้บริจาคล่าสุด (Stripe)',
            style: GoogleFonts.prompt(
              fontSize: widget.forLightBackground ? 10 : 11,
              fontWeight: FontWeight.w700,
              color: _titleColor,
            ),
          ),
        ),
        SizedBox(
          height: _stripHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: ListView.separated(
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: scrollItems.length,
                  separatorBuilder: (_, _) => SizedBox(width: _sepW),
                  itemBuilder: (context, i) {
                    final d = scrollItems[i];
                    return DonorCircleTile(
                      key: ValueKey('donor-tile-$i-${d.id}'),
                      donation: d,
                      forLightBackground: widget.forLightBackground,
                    );
                  },
                ),
              ),
              SizedBox(width: _sepW),
              DonateStripIcon(size: _donateIconPx),
            ],
          ),
        ),
      ],
    );
  }
}

class DonateStripIcon extends StatelessWidget {
  /// Public donate page (Stripe / web).
  static const String donateWebUrl = 'https://thaiflood2025.com/donate';

  final double size;

  const DonateStripIcon({super.key, this.size = 80});

  Future<void> _openDonate(BuildContext context) async {
    final uri = Uri.parse(donateWebUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เปิดเบราว์เซอร์ไม่สำเร็จ', style: GoogleFonts.prompt())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'เลี้ยงกาแฟ',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDonate(context),
          borderRadius: BorderRadius.circular(10),
          child: SvgPicture.asset(
            'assets/icons/donate.svg',
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class DonorCircleTile extends StatelessWidget {
  final Donation donation;
  final bool forLightBackground;

  const DonorCircleTile({
    super.key,
    required this.donation,
    this.forLightBackground = false,
  });

  static const double _avatar = 40;
  static const double _tileWidth = 56;

  @override
  Widget build(BuildContext context) {
    final nameColor = forLightBackground ? const Color(0xFF4B5563) : Colors.white.withValues(alpha: 0.78);
    final amountColor = forLightBackground ? const Color(0xFFD97706) : const Color(0xFFFBBF24);
    return SizedBox(
      width: _tileWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: _avatar,
            height: _avatar,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
              boxShadow: [BoxShadow(color: Color(0x286366F1), blurRadius: 6)],
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: donation.avatarAssetPath != null
                ? Image.asset(
                    donation.avatarAssetPath!,
                    width: _avatar,
                    height: _avatar,
                    fit: BoxFit.cover,
                  )
                : Text(
                    donationInitial(donation.label),
                    style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
          ),
          const SizedBox(height: 2),
          Text(
            donation.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.prompt(fontSize: 9, height: 1.1, color: nameColor),
          ),
          Text(
            donation.amountThbText,
            style: GoogleFonts.prompt(fontSize: 9, fontWeight: FontWeight.w800, color: amountColor),
          ),
        ],
      ),
    );
  }
}
