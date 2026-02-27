import 'package:flutter/material.dart';

/// A shimmer effect widget that provides a glowing sweep animation
/// to indicate loading content. No external dependency needed.
class Shimmer extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const Shimmer({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat()
      ..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: [
            widget.baseColor,
            widget.highlightColor,
            widget.baseColor,
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment(-1.0 + 2.0 * _controller.value, -0.3),
          end: Alignment(1.0 + 2.0 * _controller.value, 0.3),
        ).createShader(bounds);
      },
      child: widget.child,
    );
  }
}

// ── Building Blocks ──────────────────────────────────────────────

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class ShimmerLine extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerLine({
    super.key,
    this.width = double.infinity,
    this.height = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class ShimmerCircle extends StatelessWidget {
  final double radius;

  const ShimmerCircle({super.key, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ── Composite Skeletons ──────────────────────────────────────────

/// Skeleton that mimics a PetCard layout
class PetCardSkeleton extends StatelessWidget {
  const PetCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            const ShimmerBox(width: double.infinity, height: 180, borderRadius: 16),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      ShimmerBox(width: 60, height: 16, borderRadius: 4),
                      ShimmerBox(width: 80, height: 14, borderRadius: 4),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const ShimmerLine(width: 120, height: 18),
                  const SizedBox(height: 8),
                  const ShimmerLine(width: 200),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton that mimics a chat conversation tile
class ChatTileSkeleton extends StatelessWidget {
  const ChatTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const ShimmerCircle(radius: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerLine(width: 120, height: 16),
                  SizedBox(height: 8),
                  ShimmerLine(width: 200, height: 14),
                ],
              ),
            ),
            const ShimmerBox(width: 40, height: 14, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for a stat card
class StatCardSkeleton extends StatelessWidget {
  const StatCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: const [
            ShimmerBox(width: 40, height: 28, borderRadius: 4),
            SizedBox(height: 8),
            ShimmerLine(width: 50, height: 12),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for a notification card
class NotificationSkeleton extends StatelessWidget {
  const NotificationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerCircle(radius: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerLine(width: 80, height: 12),
                  SizedBox(height: 8),
                  ShimmerLine(width: 160, height: 16),
                  SizedBox(height: 6),
                  ShimmerLine(height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small horizontal pet card skeleton (for overview latest list)
class PetCardSmallSkeleton extends StatelessWidget {
  const PetCardSmallSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: ShimmerBox(width: 140, height: double.infinity, borderRadius: 12),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerLine(width: 80, height: 14),
                  SizedBox(height: 4),
                  ShimmerLine(width: 50, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
