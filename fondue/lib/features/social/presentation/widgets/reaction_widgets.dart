import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/reaction.dart';
import '../../data/social_providers.dart';

/// Double-tap to ❤️ with animated heart burst overlay
class DoubleTapReaction extends StatefulWidget {
  final Widget child;
  final ReactableEntityType entityType;
  final String entityId;
  final VoidCallback? onReacted;

  const DoubleTapReaction({
    super.key,
    required this.child,
    required this.entityType,
    required this.entityId,
    this.onReacted,
  });

  @override
  State<DoubleTapReaction> createState() => _DoubleTapReactionState();
}

class _DoubleTapReactionState extends State<DoubleTapReaction>
    with TickerProviderStateMixin {
  bool _showHeart = false;
  late AnimationController _heartController;
  late Animation<double> _heartScale;
  late Animation<double> _heartOpacity;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _heartScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.4), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(CurvedAnimation(
      parent: _heartController,
      curve: Curves.easeOut,
    ));
    _heartOpacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_heartController);
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _triggerHeart() async {
    HapticFeedback.mediumImpact();
    setState(() => _showHeart = true);
    _heartController.forward(from: 0.0);

    try {
      await toggleReaction(
        entityType: widget.entityType,
        entityId: widget.entityId,
        reactionType: ReactionType.heart,
      );
      widget.onReacted?.call();
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _showHeart = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _triggerHeart,
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.child,
          if (_showHeart)
            AnimatedBuilder(
              animation: _heartController,
              builder: (context, child) {
                return Opacity(
                  opacity: _heartOpacity.value,
                  child: Transform.scale(
                    scale: _heartScale.value,
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 100,
                      shadows: [
                        Shadow(
                          blurRadius: 20,
                          color: Colors.red,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Floating reaction picker bar (long-press to show)
class ReactionPicker extends StatefulWidget {
  final ReactableEntityType entityType;
  final String entityId;
  final Set<ReactionType> activeReactions;
  final VoidCallback? onChanged;

  const ReactionPicker({
    super.key,
    required this.entityType,
    required this.entityId,
    this.activeReactions = const {},
    this.onChanged,
  });

  @override
  State<ReactionPicker> createState() => _ReactionPickerState();
}

class _ReactionPickerState extends State<ReactionPicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    if (_isOpen) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() => _isOpen = !_isOpen);
  }

  void _react(ReactionType type) async {
    HapticFeedback.mediumImpact();
    try {
      await toggleReaction(
        entityType: widget.entityType,
        entityId: widget.entityId,
        reactionType: type,
      );
      widget.onChanged?.call();
    } catch (_) {}
    _toggle();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Floating reaction bar
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return ClipRect(
              child: Align(
                alignment: Alignment.bottomCenter,
                heightFactor: _controller.value,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: ReactionType.values.map((type) {
                      final isActive = widget.activeReactions.contains(type);
                      return _EmojiButton(
                        emoji: type.emoji,
                        isActive: isActive,
                        delay: ReactionType.values.indexOf(type) * 50,
                        animation: _controller,
                        onTap: () => _react(type),
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
          },
        ),
        // Trigger button (heart icon)
        GestureDetector(
          onTap: () => _react(ReactionType.heart),
          onLongPress: _toggle,
          child: Icon(
            widget.activeReactions.contains(ReactionType.heart)
                ? Icons.favorite
                : Icons.favorite_border,
            color: widget.activeReactions.contains(ReactionType.heart)
                ? Colors.red
                : Colors.grey[600],
            size: 28,
          ),
        ),
      ],
    );
  }
}

class _EmojiButton extends StatelessWidget {
  final String emoji;
  final bool isActive;
  final int delay;
  final Animation<double> animation;
  final VoidCallback onTap;

  const _EmojiButton({
    required this.emoji,
    required this.isActive,
    required this.delay,
    required this.animation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final progress = ((animation.value * 1000 - delay) / 200).clamp(0.0, 1.0);
          return Transform.scale(
            scale: 0.5 + (progress * 0.5),
            child: Opacity(
              opacity: progress,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive ? Colors.orange.withOpacity(0.15) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Reaction count bar showing emoji counts
class ReactionCountBar extends StatelessWidget {
  final ReactionCounts counts;
  final Set<ReactionType> myReactions;
  final int commentCount;
  final VoidCallback? onCommentTap;
  final VoidCallback? onShareTap;

  const ReactionCountBar({
    super.key,
    required this.counts,
    this.myReactions = const {},
    this.commentCount = 0,
    this.onCommentTap,
    this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    // Build emoji summary — show top 3 reactions with highest counts
    final sorted = ReactionType.values
        .where((t) => counts.countFor(t) > 0)
        .toList()
      ..sort((a, b) => counts.countFor(b).compareTo(counts.countFor(a)));

    return Row(
      children: [
        // Emoji bubbles
        if (sorted.isNotEmpty) ...[
          ...sorted.take(3).map((t) => Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Text(t.emoji, style: const TextStyle(fontSize: 16)),
          )),
          const SizedBox(width: 4),
          Text(
            '${counts.total}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
        const Spacer(),
        // Comment count
        if (commentCount > 0)
          GestureDetector(
            onTap: onCommentTap,
            child: Text(
              '$commentCount ความคิดเห็น',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ),
        if (onShareTap != null) ...[
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onShareTap,
            child: Icon(Icons.share_outlined, size: 20, color: Colors.grey[500]),
          ),
        ],
      ],
    );
  }
}
