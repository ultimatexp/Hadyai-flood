import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/food_scan_result.dart';
import 'food_scan_providers.dart';
import 'food_analysis_result_screen.dart';

class FoodScanHistoryScreen extends ConsumerWidget {
  final String petProfileId;

  const FoodScanHistoryScreen({super.key, required this.petProfileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scansAsync = ref.watch(foodScanHistoryProvider(petProfileId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scan History',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: scansAsync.when(
        data: (scans) {
          if (scans.isEmpty) return _buildEmpty();
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: scans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _buildHistoryCard(context, scans[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No scan history',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Scanned food labels will appear here',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, FoodScanResult scan) {
    Color verdictColor;
    IconData verdictIcon;
    switch (scan.verdict) {
      case 'SUITABLE':
        verdictColor = const Color(0xFF4CAF50);
        verdictIcon = Icons.check_circle;
        break;
      case 'NOT_RECOMMENDED':
        verdictColor = const Color(0xFFEF5350);
        verdictIcon = Icons.cancel;
        break;
      default:
        verdictColor = const Color(0xFFFFC107);
        verdictIcon = Icons.warning_rounded;
    }

    final dateStr = _formatDate(scan.createdAt);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FoodAnalysisResultScreen(result: scan),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: verdictColor.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Food image or icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: verdictColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: scan.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        scan.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.fastfood, color: verdictColor, size: 28),
                      ),
                    )
                  : Icon(Icons.fastfood, color: verdictColor, size: 28),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scan.productName ?? 'Unknown Food',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(verdictIcon, size: 14, color: verdictColor),
                      const SizedBox(width: 4),
                      Text(
                        scan.verdict.replaceAll('_', ' '),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: verdictColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: verdictColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${scan.score}/10',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: verdictColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(Icons.chevron_right, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
