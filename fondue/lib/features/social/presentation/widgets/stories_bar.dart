
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/story.dart';
import '../../data/social_providers.dart';

/// Instagram-style stories bar at top of feed
class StoriesBar extends ConsumerWidget {
  const StoriesBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(activeStoriesProvider);

    return storiesAsync.when(
      data: (groups) {
        if (groups.isEmpty) {
          return const SizedBox.shrink();
        }
        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: groups.length + 1, // +1 for "Your Story"
            itemBuilder: (context, index) {
              if (index == 0) {
                return _YourStoryCircle(onTap: () {
                  // TODO: Open camera / story creator
                });
              }
              final group = groups[index - 1];
              return _StoryCircle(
                group: group,
                onTap: () => _openStoryViewer(context, groups, index - 1),
              );
            },
          ),
        );
      },
      loading: () => SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: 5,
          itemBuilder: (context, index) => const _StoryShimmer(),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _openStoryViewer(BuildContext context, List<StoryGroup> groups, int startIndex) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => StoryViewer(
          groups: groups,
          initialGroupIndex: startIndex,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

class _YourStoryCircle extends StatelessWidget {
  final VoidCallback onTap;
  const _YourStoryCircle({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[100],
                  ),
                  child: Icon(Icons.add, color: Colors.grey[600], size: 28),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Story ของคุณ',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryCircle extends StatelessWidget {
  final StoryGroup group;
  final VoidCallback onTap;

  const _StoryCircle({required this.group, required this.onTap});

  Color _ringColor() {
    return switch (group.primaryType) {
      StoryType.shelter => const Color(0xFFFF9800),
      StoryType.petUpdate => const Color(0xFF2196F3),
      StoryType.reunion => const Color(0xFFFFD700),
      StoryType.alert => const Color(0xFFEF5350),
      _ => const Color(0xFF4CAF50),
    };
  }

  @override
  Widget build(BuildContext context) {
    final ringColor = _ringColor();

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: group.hasUnviewed
                    ? LinearGradient(
                        colors: [ringColor, ringColor.withOpacity(0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border: group.hasUnviewed
                    ? null
                    : Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: group.userAvatar != null
                      ? Image.network(
                          group.userAvatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _defaultAvatar(),
                        )
                      : _defaultAvatar(),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 68,
              child: Text(
                group.userName ?? 'User',
                style: const TextStyle(fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultAvatar() => Container(
    color: Colors.grey[200],
    child: Icon(Icons.person, color: Colors.grey[400]),
  );
}

class _StoryShimmer extends StatelessWidget {
  const _StoryShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 48,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STORY VIEWER (full screen, tap to advance)
// ============================================================

class StoryViewer extends StatefulWidget {
  final List<StoryGroup> groups;
  final int initialGroupIndex;

  const StoryViewer({
    super.key,
    required this.groups,
    required this.initialGroupIndex,
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer>
    with SingleTickerProviderStateMixin {
  late int _currentGroupIndex;
  int _currentStoryIndex = 0;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _currentGroupIndex = widget.initialGroupIndex;
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _nextStory();
        }
      });
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  List<Story> get _currentStories => widget.groups[_currentGroupIndex].stories;
  Story get _currentStory => _currentStories[_currentStoryIndex];

  void _nextStory() {
    if (_currentStoryIndex < _currentStories.length - 1) {
      setState(() => _currentStoryIndex++);
      _progressController.forward(from: 0.0);
    } else if (_currentGroupIndex < widget.groups.length - 1) {
      setState(() {
        _currentGroupIndex++;
        _currentStoryIndex = 0;
      });
      _progressController.forward(from: 0.0);
    } else {
      Navigator.pop(context);
    }
  }

  void _prevStory() {
    if (_currentStoryIndex > 0) {
      setState(() => _currentStoryIndex--);
      _progressController.forward(from: 0.0);
    } else if (_currentGroupIndex > 0) {
      setState(() {
        _currentGroupIndex--;
        _currentStoryIndex = widget.groups[_currentGroupIndex].stories.length - 1;
      });
      _progressController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = _currentStory;
    final group = widget.groups[_currentGroupIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 3) {
            _prevStory();
          } else {
            _nextStory();
          }
        },
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 500) {
            Navigator.pop(context);
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Story image
            Image.network(
              story.mediaUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[900],
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
                ),
              ),
            ),

            // Gradient overlays
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
              ),
            ),

            // Progress bars
            SafeArea(
              child: Column(
                children: [
                  // Progress indicators
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: List.generate(_currentStories.length, (index) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: index < _currentStoryIndex
                                  ? Container(height: 3, color: Colors.white)
                                  : index == _currentStoryIndex
                                      ? AnimatedBuilder(
                                          animation: _progressController,
                                          builder: (context, _) {
                                            return LinearProgressIndicator(
                                              value: _progressController.value,
                                              backgroundColor: Colors.white30,
                                              valueColor: const AlwaysStoppedAnimation(Colors.white),
                                              minHeight: 3,
                                            );
                                          },
                                        )
                                      : Container(height: 3, color: Colors.white30),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: group.userAvatar != null
                              ? NetworkImage(group.userAvatar!)
                              : null,
                          child: group.userAvatar == null
                              ? const Icon(Icons.person, size: 16, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.userName ?? 'User',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _timeAgo(story.createdAt),
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Caption
                  if (story.caption != null)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        story.caption!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Bottom actions
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white30),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'ส่งข้อความ...',
                                style: TextStyle(color: Colors.white54, fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.favorite_border, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        const Icon(Icons.share_outlined, color: Colors.white, size: 28),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชม. ที่แล้ว';
    return '${diff.inDays} วันที่แล้ว';
  }
}
