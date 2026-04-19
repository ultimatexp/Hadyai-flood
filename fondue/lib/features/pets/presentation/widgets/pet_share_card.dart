import 'dart:math' show max, min;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/pet.dart';

/// Square social-share layout: photo left (60%), details right (40%), LOST/FOUND badge top-left on photo,
/// Fondue wordmark under the logo bottom-right.
/// Use [PetShareCard.exportPngBytes] to rasterize for sharing.
class PetShareCard extends StatelessWidget {
  final Pet pet;
  final String? photoUrl;

  const PetShareCard({
    super.key,
    required this.pet,
    this.photoUrl,
  });

  static String? primaryPhotoUrl(Pet pet) {
    final u = pet.imageUrl?.trim();
    if (u != null && u.isNotEmpty) return u;
    for (final raw in pet.images) {
      final s = raw.trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  static String statusLabelTh(String status) {
    switch (status.toUpperCase()) {
      case 'LOST':
        return 'สัตว์เลี้ยงหาย';
      case 'FOUND':
        return 'พบสัตว์เลี้ยง';
      case 'REUNITED':
        return 'กลับบ้านแล้ว';
      default:
        return status;
    }
  }

  static String reportedTimeLabel(Pet pet) {
    switch (pet.status.toUpperCase()) {
      case 'LOST':
        return 'วันเวลาที่รายงานหาย';
      case 'FOUND':
        return 'วันเวลาที่รายงานพบ';
      default:
        return 'วันเวลาที่บันทึก';
    }
  }

  static String formatLocalDateTime(DateTime dt) {
    final l = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.day}/${l.month}/${l.year} ${two(l.hour)}:${two(l.minute)}';
  }

  static String marksText(Pet pet) {
    final parts = <String>[];
    final color = pet.colorMain?.trim();
    if (color != null && color.isNotEmpty) {
      parts.add('สี / ลักษณะ: $color');
    }
    final desc = pet.description?.trim();
    if (desc != null && desc.isNotEmpty) {
      parts.add(desc);
    }
    if (parts.isEmpty) return '—';
    return parts.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final url = photoUrl ?? primaryPhotoUrl(pet);
    final name = pet.name?.trim().isNotEmpty == true ? pet.name!.trim() : 'ไม่มีชื่อ';
    final species = pet.species.trim();
    final statusTh = statusLabelTh(pet.status);
    final timeLabel = reportedTimeLabel(pet);
    final when = formatLocalDateTime(pet.createdAt);
    final marks = marksText(pet);
    final contact = pet.contactInfo?.trim().isNotEmpty == true
        ? pet.contactInfo!.trim()
        : 'ดูรายละเอียดในแอป Fondue';

    final lost = pet.status.toUpperCase() == 'LOST';
    final chipColor = lost ? const Color(0xFFE53935) : const Color(0xFF2E7D32);

    return ClipRect(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: full-height photo (60%) + LOST/FOUND top-left
          Expanded(
            flex: 60,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: const Color(0xFF1a1a1a),
                  child: url != null
                      ? Image.network(
                          url,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, _, _) => _photoPlaceholder(),
                        )
                      : _photoPlaceholder(),
                ),
                Positioned(
                  top: 20,
                  left: 20,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: chipColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Text(
                        statusTh,
                        style: GoogleFonts.prompt(
                          color: Colors.white,
                          fontSize: 60,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Right: info + footer (logo + Fondue labels) 40%
          Expanded(
            flex: 40,
            child: ColoredBox(
              color: const Color(0xFF121826),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        const hPad = 18.0;
                        const vPad = 18.0; // 12 top + 6 bottom
                        final innerW = max(40.0, w - hPad * 2);
                        final innerH = max(40.0, constraints.maxHeight - vPad);
                        final textW = innerW;

                        // Single FittedBox scales the whole block so large fonts never overflow
                        // the right column (preview + PNG export).
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(hPad, 12, hPad, 6),
                          child: SizedBox(
                            width: innerW,
                            height: innerH,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.topLeft,
                              child: SizedBox(
                                width: textW,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.prompt(
                                        color: Colors.white,
                                        fontSize: 128,
                                        fontWeight: FontWeight.w800,
                                        height: 1.05,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      species,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.prompt(
                                        color: Colors.white70,
                                        fontSize: 68,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '$timeLabel: $when',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.prompt(
                                        color: const Color(0xFFB0BEC5),
                                        fontSize: 44,
                                        fontWeight: FontWeight.w500,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'ลักษณะเด่น',
                                      style: GoogleFonts.prompt(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      marks,
                                      maxLines: 12,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.prompt(
                                        color: const Color(0xFFCFD8DC),
                                        fontSize: 40,
                                        height: 1.32,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ติดต่อ',
                          style: GoogleFonts.prompt(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          contact,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.prompt(
                            color: const Color(0xFFFFCC80),
                            fontSize: 40,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 14, 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Image.asset(
                                  'assets/icon.png',
                                  width: 104,
                                  height: 104,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Fondue',
                              style: GoogleFonts.prompt(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              'ค้นหาสุนัข & แมว',
                              style: GoogleFonts.prompt(
                                color: Colors.white70,
                                fontSize: 26,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'fondue.app',
                              style: GoogleFonts.prompt(
                                color: Colors.white54,
                                fontSize: 22,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _photoPlaceholder() {
    return ColoredBox(
      color: const Color(0xFF263238),
      child: Center(
        child: Icon(Icons.pets, size: 240, color: Colors.white.withValues(alpha: 0.35)),
      ),
    );
  }

  /// Renders [PetShareCard] off-screen and returns PNG bytes (square).
  static Future<Uint8List?> exportPngBytes(
    BuildContext context,
    Pet pet, {
    double logicalSize = 900,
    double pixelRatio = 2,
  }) async {
    final url = primaryPhotoUrl(pet);
    if (url != null) {
      try {
        await precacheImage(NetworkImage(url), context);
      } catch (_) {}
    }

    if (!context.mounted) return null;

    final key = GlobalKey();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: -8000,
        top: 0,
        child: Material(
          color: Colors.transparent,
          child: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: logicalSize,
              height: logicalSize,
              child: PetShareCard(pet: pet, photoUrl: url),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    await Future<void>.delayed(Duration.zero);
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 80));

    Uint8List? out;
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: pixelRatio);
        final bd = await image.toByteData(format: ui.ImageByteFormat.png);
        out = bd?.buffer.asUint8List();
        image.dispose();
      }
    } finally {
      entry.remove();
    }
    return out;
  }

  /// Bottom sheet: live square preview of [PetShareCard], then share on confirm.
  static Future<void> showPreviewThenShare(BuildContext context, Pet pet) async {
    final parentContext = context;
    final url = primaryPhotoUrl(pet);
    if (url != null) {
      try {
        await precacheImage(NetworkImage(url), parentContext);
      } catch (_) {}
    }
    if (!parentContext.mounted) return;

    await showModalBottomSheet<void>(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final sz = MediaQuery.sizeOf(sheetContext);
        final side = min(sz.width - 40, sz.height * 0.48).clamp(200.0, 440.0);

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 10,
            bottom: MediaQuery.paddingOf(sheetContext).bottom + 16,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  tooltip: 'ปิด',
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  icon: const Icon(Icons.close_rounded, size: 26),
                  color: const Color(0xFF475569),
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.all(8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 40, 0),
                child: Text(
                  'ตัวอย่างก่อนแชร์',
                  style: GoogleFonts.prompt(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 40, 0),
                child: Text(
                  'รูปสี่เหลี่ยมนี้จะถูกส่งไปยังแอปโซเชียลที่คุณเลือก',
                  style: GoogleFonts.prompt(fontSize: 13, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: side,
                height: side,
                child: Material(
                  elevation: 6,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 900,
                      height: 900,
                      child: PetShareCard(
                        pet: pet,
                        photoUrl: url,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                      await WidgetsBinding.instance.endOfFrame;
                      if (parentContext.mounted) {
                        await saveImageToGallery(
                          parentContext,
                          pet,
                          showExportProgress: false,
                        );
                      }
                    },
                    icon: const Icon(Icons.download_outlined, size: 22),
                    label: Text(
                      'บันทึกรูป',
                      style: GoogleFonts.prompt(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF9800),
                      side: const BorderSide(color: Color(0xFFFF9800)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                      await WidgetsBinding.instance.endOfFrame;
                      if (parentContext.mounted) {
                        await shareAsImage(
                          parentContext,
                          pet,
                          showExportProgress: false,
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                      child: Text(
                        'แชร์',
                        style: GoogleFonts.prompt(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
      },
    );
  }

  /// Base file name (no extension) for share / gallery save.
  static String _pngBaseName(Pet pet) {
    final name = pet.name?.trim().isNotEmpty == true ? pet.name!.trim() : 'pet';
    final safeName = name.replaceAll(RegExp(r'[^\w\-ก-๙]+'), '_').replaceAll(RegExp(r'_+'), '_');
    final idPart = pet.id.length > 8 ? pet.id.substring(0, 8) : pet.id;
    return 'fondue_${safeName}_$idPart';
  }

  /// Renders PNG and saves to the device photo library (no share sheet).
  static Future<void> saveImageToGallery(
    BuildContext context,
    Pet pet, {
    bool showExportProgress = true,
  }) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (showExportProgress) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('กำลังสร้างรูป...'), duration: Duration(seconds: 2)),
      );
    }

    final bytes = await exportPngBytes(context, pet);
    if (!context.mounted) return;

    if (showExportProgress) {
      messenger?.hideCurrentSnackBar();
    }

    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('สร้างรูปไม่สำเร็จ ลองอีกครั้ง')),
      );
      return;
    }

    final base = _pngBaseName(pet);
    try {
      await Gal.putImageBytes(bytes, name: base);
    } on GalException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('บันทึกรูปไม่สำเร็จ (${e.type.name})')),
        );
      }
      return;
    } on MissingPluginException {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text('บันทึกรูปยังไม่พร้อม — หยุดแอปแล้วเปิดใหม่ (full restart) แล้วลองอีกครั้ง'),
          ),
        );
      }
      return;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('บันทึกรูปไม่สำเร็จ: $e')),
        );
      }
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('บันทึกรูปลงเครื่องแล้ว')),
      );
    }
  }

  /// Builds PNG and opens the platform share sheet.
  static Future<void> shareAsImage(
    BuildContext context,
    Pet pet, {
    bool showExportProgress = true,
  }) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (showExportProgress) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('กำลังสร้างรูปแชร์...'), duration: Duration(seconds: 2)),
      );
    }

    final bytes = await exportPngBytes(context, pet);
    if (!context.mounted) return;

    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('สร้างรูปไม่สำเร็จ ลองอีกครั้ง')),
      );
      return;
    }

    if (showExportProgress) {
      messenger?.hideCurrentSnackBar();
    }

    final displayName = pet.name?.trim().isNotEmpty == true ? pet.name!.trim() : 'pet';
    final file = XFile.fromData(
      bytes,
      mimeType: 'image/png',
      name: '${_pngBaseName(pet)}.png',
    );

    final statusTh = statusLabelTh(pet.status);
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [file],
          text: 'Fondue — $statusTh: $displayName',
        ),
      );
    } on MissingPluginException {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text(
              'แชร์ไม่พร้อมใช้งาน (ต้องสตาร์ทแอปใหม่หลังติดตั้งปลั๊กอิน) — ลองกดบันทึกรูปแทน',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('แชร์ไม่สำเร็จ: $e')),
        );
      }
    }
  }
}
