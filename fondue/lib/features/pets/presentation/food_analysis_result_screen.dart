import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/food_scan_result.dart';

class FoodAnalysisResultScreen extends StatefulWidget {
  final FoodScanResult result;

  const FoodAnalysisResultScreen({super.key, required this.result});

  @override
  State<FoodAnalysisResultScreen> createState() =>
      _FoodAnalysisResultScreenState();
}

class _FoodAnalysisResultScreenState extends State<FoodAnalysisResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _scoreController;
  late Animation<double> _scoreAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _ingredientsExpanded = false;

  @override
  void initState() {
    super.initState();
    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreAnimation = Tween<double>(begin: 0, end: widget.result.score / 10)
        .animate(CurvedAnimation(
      parent: _scoreController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      _scoreController.forward();
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildVerdictHeroCard(),
                    const SizedBox(height: 20),
                    _buildScoreAndProduct(),
                    const SizedBox(height: 20),
                    _buildWarningsSection(),
                    const SizedBox(height: 20),
                    _buildIngredientsSection(),
                    const SizedBox(height: 20),
                    _buildNutritionalBreakdown(),
                    const SizedBox(height: 20),
                    _buildAiAnalysisSection(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: _verdictColor.withOpacity(0.95),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Analysis Result',
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
    );
  }

  Color get _verdictColor {
    switch (widget.result.verdict) {
      case 'SUITABLE':
        return const Color(0xFF4CAF50);
      case 'NOT_RECOMMENDED':
        return const Color(0xFFEF5350);
      default:
        return const Color(0xFFFF9800);
    }
  }

  IconData get _verdictIcon {
    switch (widget.result.verdict) {
      case 'SUITABLE':
        return Icons.check_circle_rounded;
      case 'NOT_RECOMMENDED':
        return Icons.cancel_rounded;
      default:
        return Icons.warning_rounded;
    }
  }

  String get _verdictLabel {
    switch (widget.result.verdict) {
      case 'SUITABLE':
        return 'Suitable for your pet';
      case 'NOT_RECOMMENDED':
        return 'Not Recommended';
      default:
        return 'Use with Caution';
    }
  }

  String get _verdictEmoji {
    switch (widget.result.verdict) {
      case 'SUITABLE':
        return '✅';
      case 'NOT_RECOMMENDED':
        return '❌';
      default:
        return '⚠️';
    }
  }

  Widget _buildVerdictHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _verdictColor,
            _verdictColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _verdictColor.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(_verdictIcon, size: 56, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            _verdictEmoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            _verdictLabel,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.result.productName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.result.productName!,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreAndProduct() {
    return Row(
      children: [
        // Score Gauge
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Quality Score',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: AnimatedBuilder(
                    animation: _scoreAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _ScoreGaugePainter(
                          progress: _scoreAnimation.value,
                          color: _verdictColor,
                        ),
                        child: Center(
                          child: Text(
                            '${widget.result.score}',
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _verdictColor,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'out of 10',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Quick Stats
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickStat(
                  Icons.science_outlined,
                  '${widget.result.ingredients.length}',
                  'Ingredients',
                ),
                const SizedBox(height: 14),
                _buildQuickStat(
                  Icons.warning_amber_rounded,
                  '${widget.result.warnings.length}',
                  'Warnings',
                  color: widget.result.warnings.isNotEmpty
                      ? Colors.orange
                      : Colors.green,
                ),
                const SizedBox(height: 14),
                _buildQuickStat(
                  Icons.verified_rounded,
                  widget.result.verdict.replaceAll('_', '\n'),
                  'Verdict',
                  color: _verdictColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStat(IconData icon, String value, String label,
      {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? Colors.grey[500]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color ?? Colors.black87,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWarningsSection() {
    if (widget.result.warnings.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 22, color: Color(0xFFFF9800)),
            const SizedBox(width: 8),
            Text(
              'Warnings',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...widget.result.warnings.map(
          (warning) => Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFFF9800).withOpacity(0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline,
                    size: 18, color: Color(0xFFFF9800)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    warning,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.brown[700],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsSection() {
    if (widget.result.ingredients.isEmpty) return const SizedBox();

    final displayedIngredients = _ingredientsExpanded
        ? widget.result.ingredients
        : widget.result.ingredients.take(8).toList();

    // Find problematic ingredients (present in warnings)
    final warningText = widget.result.warnings.join(' ').toLowerCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list_alt, size: 22, color: Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              Text(
                'Ingredients (${widget.result.ingredients.length})',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: displayedIngredients.map((ingredient) {
              final isProblem =
                  warningText.contains(ingredient.toLowerCase());
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isProblem
                      ? const Color(0xFFEF5350).withOpacity(0.1)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                  border: isProblem
                      ? Border.all(
                          color: const Color(0xFFEF5350).withOpacity(0.4))
                      : null,
                ),
                child: Text(
                  ingredient,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: isProblem ? FontWeight.w700 : FontWeight.w500,
                    color: isProblem
                        ? const Color(0xFFEF5350)
                        : Colors.grey[700],
                  ),
                ),
              );
            }).toList(),
          ),
          if (widget.result.ingredients.length > 8) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () =>
                  setState(() => _ingredientsExpanded = !_ingredientsExpanded),
              child: Text(
                _ingredientsExpanded
                    ? 'Show less'
                    : 'Show all ${widget.result.ingredients.length} ingredients',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: const Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNutritionalBreakdown() {
    final analysis = widget.result.guaranteedAnalysis;
    if (analysis.isEmpty) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded,
                  size: 22, color: Color(0xFF42A5F5)),
              const SizedBox(width: 8),
              Text(
                'Nutritional Breakdown',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...analysis.entries.map((entry) {
            final percentage = _extractPercentage(entry.value.toString());
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _capitalizeFirst(entry.key),
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        entry.value.toString(),
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _nutrientColor(entry.key),
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAiAnalysisSection() {
    if (widget.result.aiAnalysis == null ||
        widget.result.aiAnalysis!.isEmpty) {
      return const SizedBox();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  size: 22, color: Color(0xFF7C4DFF)),
              const SizedBox(width: 8),
              Text(
                'AI Analysis',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.result.aiAnalysis!,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // Helpers
  double _extractPercentage(String value) {
    final match = RegExp(r'(\d+\.?\d*)').firstMatch(value);
    if (match != null) return double.tryParse(match.group(1)!) ?? 0;
    return 0;
  }

  String _capitalizeFirst(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Color _nutrientColor(String nutrient) {
    switch (nutrient.toLowerCase()) {
      case 'protein':
        return const Color(0xFFEF5350);
      case 'fat':
        return const Color(0xFFFF9800);
      case 'fiber':
        return const Color(0xFF4CAF50);
      case 'moisture':
        return const Color(0xFF42A5F5);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}

/// Custom painter for the animated score gauge
class _ScoreGaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ScoreGaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 4;

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.75,
      pi * 1.5,
      false,
      bgPaint,
    );

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.75,
      pi * 1.5 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreGaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
