import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';
import '../data/chat_providers.dart';
import '../data/chat_repository.dart';
import '../domain/message.dart';
import '../../moderation/presentation/report_dialog.dart';
import '../../moderation/presentation/block_user_dialog.dart';
import '../../pets/presentation/pet_providers.dart';

bool _videoGuardInstalled = false;
bool _videoChannelBroken = false;
void Function(FlutterErrorDetails details)? _previousFlutterErrorHandler;
bool Function(Object error, StackTrace stack)? _previousPlatformErrorHandler;

bool _isAvFoundationVideoInitError(Object error) {
  final text = error.toString();
  return text.contains('AVFoundationVideoPlayerApi.initialize') ||
      text.contains('video_player_avfoundation.AVFoundationVideoPlayerApi.initialize') ||
      text.contains('Unable to establish connection on channel');
}

void _ensureVideoErrorGuardInstalled() {
  if (_videoGuardInstalled) return;
  _videoGuardInstalled = true;

  _previousFlutterErrorHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    final exception = details.exception;
    if (_isAvFoundationVideoInitError(exception)) {
      _videoChannelBroken = true;
      return;
    }
    _previousFlutterErrorHandler?.call(details);
  };

  _previousPlatformErrorHandler = ui.PlatformDispatcher.instance.onError;
  ui.PlatformDispatcher.instance.onError = (error, stack) {
    if (_isAvFoundationVideoInitError(error)) {
      _videoChannelBroken = true;
      return true;
    }
    final prev = _previousPlatformErrorHandler;
    return prev?.call(error, stack) ?? false;
  };
}

/// Real-time chat screen
class ChatDetailScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String name;
  final String avatar;
  final String? phoneNumber;
  final String? petStatus;
  final String? petName;
  final String? otherUserId;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.name,
    required this.avatar,
    this.phoneNumber,
    this.petStatus,
    this.petName,
    this.otherUserId,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  Message? _replyMessage;
  bool _isSending = false;
  bool _isCompressingVideo = false;
  final List<_PendingMediaMessage> _pendingMedia = [];

  String? get currentUserId => Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    // Mark messages as read when entering the chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatRepositoryProvider).markAsRead(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    setState(() => _isSending = true);
    
    try {
      final repo = ref.read(chatRepositoryProvider);
      await repo.sendMessage(
        conversationId: widget.conversationId,
        content: _messageController.text.trim(),
        replyToId: _replyMessage?.id,
      );
      
      _messageController.clear();
      setState(() => _replyMessage = null);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickImageFile(XFile pickedFile, {required String pendingId}) async {
    try {
      if (mounted) setState(() => _isSending = true);

      // Upload image to Supabase Storage
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
      final bytes = await File(pickedFile.path).readAsBytes();

      await Supabase.instance.client.storage
          .from('chat-images')
          .uploadBinary(fileName, bytes);

      final imageUrl = Supabase.instance.client.storage
          .from('chat-images')
          .getPublicUrl(fileName);

      final repo = ref.read(chatRepositoryProvider);
      await repo.sendMessage(
        conversationId: widget.conversationId,
        imageUrl: imageUrl,
      );

      _removePendingMedia(pendingId);
      _scrollToBottom();
    } catch (e) {
      _markPendingMediaFailed(pendingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickVideoFile(XFile picked, {required String pendingId}) async {
    if (_isCompressingVideo) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video is still compressing, please wait...')),
        );
      }
      return;
    }

    try {
      if (mounted) setState(() => _isSending = true);
      _isCompressingVideo = true;

      // Defensive reset in case previous compression was left hanging.
      try {
        await VideoCompress.cancelCompression();
      } catch (_) {}

      // Best-effort compression to reduce upload/storage footprint.
      final uploadPath = await _compressVideoPathWithFallback(picked.path);
      final file = File(uploadPath);
      final bytes = await file.readAsBytes().timeout(const Duration(seconds: 20));

      final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      await Supabase.instance.client.storage
          .from('chat-images')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'video/mp4'),
          )
          .timeout(const Duration(seconds: 120));
      final videoUrl = Supabase.instance.client.storage
          .from('chat-images')
          .getPublicUrl(fileName);

      final repo = ref.read(chatRepositoryProvider);
      await repo.sendMessage(
        conversationId: widget.conversationId,
        imageUrl: videoUrl,
      ).timeout(const Duration(seconds: 25));
      _removePendingMedia(pendingId);
      _scrollToBottom();
    } catch (e) {
      _markPendingMediaFailed(pendingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send video: $e')),
        );
      }
    } finally {
      _isCompressingVideo = false;
      await _safeClearVideoCompressCache();
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<String> _compressVideoPathWithFallback(String sourcePath) async {
    MediaInfo? compressed;
    try {
      compressed = await VideoCompress.compressVideo(
        sourcePath,
        quality: VideoQuality.MediumQuality,
        includeAudio: true,
        deleteOrigin: false,
      ).timeout(const Duration(seconds: 20), onTimeout: () => null);
    } catch (e) {
      final msg = e.toString();
      final isBusy = msg.contains('Already have a compression process');
      if (isBusy) {
        try {
          await VideoCompress.cancelCompression();
        } catch (_) {}
        await Future<void>.delayed(const Duration(milliseconds: 500));
        try {
          compressed = await VideoCompress.compressVideo(
            sourcePath,
            quality: VideoQuality.MediumQuality,
            includeAudio: true,
            deleteOrigin: false,
          ).timeout(const Duration(seconds: 20), onTimeout: () => null);
        } catch (_) {
          // Final fallback to original file path if plugin still busy.
          return sourcePath;
        }
      } else {
        return sourcePath;
      }
    }
    return compressed?.path ?? sourcePath;
  }

  Future<void> _safeClearVideoCompressCache() async {
    try {
      await VideoCompress.deleteAllCache();
    } on MissingPluginException {
      // Some plugin/platform builds don't expose deleteAllCache.
    } catch (_) {
      // Non-fatal cleanup failure.
    }
  }

  Future<void> _pickAndSendMedia() async {
    try {
      final picked = await _picker.pickMedia(requestFullMetadata: false);
      if (picked == null) return;
      final path = picked.path.toLowerCase();
      final isVideo = path.endsWith('.mp4') ||
          path.endsWith('.mov') ||
          path.endsWith('.webm') ||
          path.endsWith('.m4v') ||
          path.endsWith('.3gp');
      final pendingId = _createPendingMedia(
        localPath: picked.path,
        isVideo: isVideo,
      );

      if (isVideo) {
        await _pickVideoFile(picked, pendingId: pendingId);
      } else {
        await _pickImageFile(picked, pendingId: pendingId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick media: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _reportUser() async {
    if (widget.otherUserId == null) return;

    final reported = await ReportDialog.show(
      context,
      reportedUserId: widget.otherUserId,
      entityId: widget.conversationId,
      entityType: 'chat',
      reportedName: widget.name,
    );

    if (reported == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted. Thank you for helping keep our community safe.')),
      );
    }
  }

  void _blockUser() async {
    if (widget.otherUserId == null) return;

    final blocked = await BlockUserDialog.show(
      context,
      ref,
      blockedUserId: widget.otherUserId!,
      blockedUserName: widget.name,
    );

    if (blocked == true && mounted) {
      ref.invalidate(conversationsProvider);
      Navigator.pop(context);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesStreamProvider(widget.conversationId));

    return Scaffold(
      backgroundColor: const Color(0xFF8CABD9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF9800),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              child: ClipOval(
                child: Image.network(
                  widget.avatar,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Active now',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.call, color: Colors.white),
              onPressed: () => _makePhoneCall(widget.phoneNumber!),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'report') _reportUser();
              if (value == 'block') _blockUser();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Report User'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Block User'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Pet Status Banner
          if (widget.petStatus != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: widget.petStatus == 'lost'
                  ? Colors.red.shade100
                  : Colors.green.shade100,
              child: Row(
                children: [
                  Icon(
                    widget.petStatus == 'lost' ? Icons.pets : Icons.check_circle,
                    color: widget.petStatus == 'lost'
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.petStatus == 'lost'
                          ? '🔍 Lost Pet: ${widget.petName ?? "Unknown"}'
                          : '✅ Found Pet: ${widget.petName ?? "Unknown"}',
                      style: TextStyle(
                        color: widget.petStatus == 'lost'
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Messages
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                final hasNoItems = messages.isEmpty && _pendingMedia.isEmpty;
                if (hasNoItems) {
                  return const Center(
                    child: Text(
                      'No messages yet.\nSay hello! 👋',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  itemCount: messages.length + _pendingMedia.length,
                  itemBuilder: (context, index) {
                    if (index >= messages.length) {
                      final pending = _pendingMedia[index - messages.length];
                      return _buildPendingMediaBubble(pending);
                    }
                    final msg = messages[index];
                    final isMe = msg.senderId == currentUserId;
                    final showAvatar = !isMe &&
                        (index == 0 || messages[index - 1].senderId == currentUserId);
                    return _buildMessageBubble(msg, isMe, showAvatar, index, messages);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Error: $err', style: const TextStyle(color: Colors.white)),
              ),
            ),
          ),

          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message msg, bool isMe, bool showAvatar, int index, List<Message> messages) {
    return GestureDetector(
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _replyMessage = msg);
                },
              ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    await ref.read(chatRepositoryProvider).deleteMessage(msg.id);
                  },
                ),
            ],
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: 8,
          left: isMe ? 60 : 0,
          right: isMe ? 0 : 60,
        ),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar for other person
            if (!isMe && showAvatar)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white24,
                  child: ClipOval(
                    child: Image.network(
                      widget.avatar,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              )
            else if (!isMe)
              const SizedBox(width: 40),

            // Message bubble
            Flexible(
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (_) {
                      final isMediaOnly = msg.imageUrl != null &&
                          (msg.content == null || msg.content!.trim().isEmpty);
                      return Container(
                        padding: isMediaOnly
                            ? EdgeInsets.zero
                            : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMediaOnly
                              ? Colors.transparent
                              : (isMe ? const Color(0xFFFF9800) : Colors.white),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isMe ? 18 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 18),
                          ),
                          boxShadow: isMediaOnly
                              ? const []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (msg.imageUrl != null)
                              _isVideoUrl(msg.imageUrl!)
                                  ? _ChatVideoBubble(url: msg.imageUrl!)
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        msg.imageUrl!,
                                        width: 200,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                      ),
                                    )
                            else if (msg.content != null)
                              Text(
                                msg.content!,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                  fontSize: 15,
                                  height: 1.3,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  // Time
                  Text(
                    _formatTime(msg.createdAt),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
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

  Widget _buildPendingMediaBubble(_PendingMediaMessage pending) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 60),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: pending.isVideo
                      ? Container(
                          width: 220,
                          height: 220,
                          color: Colors.black87,
                          alignment: Alignment.center,
                          child: const Icon(Icons.videocam, color: Colors.white, size: 40),
                        )
                      : Image.file(
                          File(pending.localPath),
                          width: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 220,
                            height: 140,
                            color: Colors.black12,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (pending.status == _PendingMediaStatus.sending) ...[
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Sending...',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ] else ...[
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 13),
                      const SizedBox(width: 4),
                      const Text(
                        'Failed',
                        style: TextStyle(color: Colors.redAccent, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final localTime = dateTime.toLocal();
    return '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
  }

  bool _isVideoUrl(String url) {
    final clean = url.split('?').first.toLowerCase();
    return clean.endsWith('.mp4') ||
        clean.endsWith('.mov') ||
        clean.endsWith('.webm') ||
        clean.endsWith('.m4v');
  }

  String _createPendingMedia({
    required String localPath,
    required bool isVideo,
  }) {
    final id = 'pending_${DateTime.now().microsecondsSinceEpoch}';
    _pendingMedia.add(
      _PendingMediaMessage(
        id: id,
        localPath: localPath,
        isVideo: isVideo,
      ),
    );
    if (mounted) setState(() {});
    _scrollToBottom();
    return id;
  }

  void _markPendingMediaFailed(String id) {
    final idx = _pendingMedia.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    _pendingMedia[idx] =
        _pendingMedia[idx].copyWith(status: _PendingMediaStatus.failed);
    if (mounted) setState(() {});
  }

  void _removePendingMedia(String id) {
    _pendingMedia.removeWhere((e) => e.id == id);
    if (mounted) setState(() {});
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyMessage != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[100],
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Replying to: ${_replyMessage!.content ?? "📷 Image"}',
                      style: const TextStyle(color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setState(() => _replyMessage = null),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.perm_media_outlined),
                color: Colors.grey[600],
                tooltip: 'Upload photo or video',
                onPressed: _isSending ? null : _pickAndSendMedia,
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 9,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: 'Message',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isSending ? null : _sendMessage,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _isSending ? Colors.grey : const Color(0xFFFF9800),
                    shape: BoxShape.circle,
                  ),
                  child: _isSending
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _PendingMediaStatus { sending, failed }

class _PendingMediaMessage {
  final String id;
  final String localPath;
  final bool isVideo;
  final _PendingMediaStatus status;

  const _PendingMediaMessage({
    required this.id,
    required this.localPath,
    required this.isVideo,
    this.status = _PendingMediaStatus.sending,
  });

  _PendingMediaMessage copyWith({
    _PendingMediaStatus? status,
  }) {
    return _PendingMediaMessage(
      id: id,
      localPath: localPath,
      isVideo: isVideo,
      status: status ?? this.status,
    );
  }
}

class _ChatVideoBubble extends StatefulWidget {
  final String url;
  const _ChatVideoBubble({required this.url});

  @override
  State<_ChatVideoBubble> createState() => _ChatVideoBubbleState();
}

class _ChatVideoBubbleState extends State<_ChatVideoBubble> {
  VideoPlayerController? _controller;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _ensureVideoErrorGuardInstalled();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    await _controller?.dispose();
    _controller = null;

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
        await c.initialize().timeout(const Duration(seconds: 8));
        c.setLooping(true);
        if (!mounted) {
          await c.dispose();
          return;
        }
        _videoChannelBroken = false;
        setState(() {
          _controller = c;
          _loading = false;
          _failed = false;
        });
        return;
      } catch (_) {
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 350));
        }
      }
    }
    if (mounted) {
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    final c = _controller;
    if (c == null) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _failed ? _initPlayer : _togglePlayPause,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (c != null && !_failed)
              SizedBox(
                width: 220,
                child: AspectRatio(
                  aspectRatio: c.value.aspectRatio == 0 ? (9 / 16) : c.value.aspectRatio,
                  child: VideoPlayer(c),
                ),
              )
            else
              Container(
                width: 220,
                height: 160,
                color: Colors.black87,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _failed ? Icons.videocam_off : Icons.videocam,
                      color: Colors.white70,
                      size: 32,
                    ),
                    if (_failed) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Tap to retry',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            if (_loading)
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            else if (!_failed)
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white70),
                ),
                child: Icon(
                  (c?.value.isPlaying ?? false) ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: InkWell(
                onTap: () async {
                  if (_failed || c == null) return;
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _ChatVideoFullscreenPage(url: widget.url),
                    ),
                  );
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.fullscreen,
                    color: Colors.white70,
                    size: 20,
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

class _ChatVideoFullscreenPage extends StatefulWidget {
  final String url;
  const _ChatVideoFullscreenPage({required this.url});

  @override
  State<_ChatVideoFullscreenPage> createState() => _ChatVideoFullscreenPageState();
}

class _ChatVideoFullscreenPageState extends State<_ChatVideoFullscreenPage> {
  VideoPlayerController? _controller;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _ensureVideoErrorGuardInstalled();
    _initFullscreenPlayer();
  }

  Future<void> _initFullscreenPlayer() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await c.initialize().timeout(const Duration(seconds: 8));
      c.play();
      c.setLooping(true);
      if (!mounted) {
        await c.dispose();
        return;
      }
      _videoChannelBroken = false;
      setState(() {
        _controller = c;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : _failed || c == null
                    ? const Icon(Icons.videocam_off, color: Colors.white70, size: 40)
                    : GestureDetector(
                        onTap: () {
                          if (c.value.isPlaying) {
                            c.pause();
                          } else {
                            c.play();
                          }
                          setState(() {});
                        },
                        child: SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: c.value.size.width,
                              height: c.value.size.height,
                              child: VideoPlayer(c),
                            ),
                          ),
                        ),
                      ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 6,
            left: 8,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
