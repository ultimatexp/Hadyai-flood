import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/chat_providers.dart';
import '../data/chat_repository.dart';
import '../domain/message.dart';

/// Real-time chat screen
class ChatDetailScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String name;
  final String avatar;
  final String? phoneNumber;
  final String? petStatus;
  final String? petName;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.name,
    required this.avatar,
    this.phoneNumber,
    this.petStatus,
    this.petName,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Message? _replyMessage;
  bool _isSending = false;

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

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() => _isSending = true);
      
      try {
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
        
        _scrollToBottom();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send image: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isSending = false);
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
              backgroundImage: NetworkImage(widget.avatar),
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
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
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
                if (messages.isEmpty) {
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
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
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
                  backgroundImage: NetworkImage(widget.avatar),
                ),
              )
            else if (!isMe)
              const SizedBox(width: 40),

            // Message bubble
            Flexible(
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFFFF9800) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 18),
                      ),
                      boxShadow: [
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
                          ClipRRect(
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

  String _formatTime(DateTime dateTime) {
    final localTime = dateTime.toLocal();
    return '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
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
                icon: const Icon(Icons.emoji_emotions_outlined),
                color: Colors.grey[600],
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Emoji Picker coming soon!')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined),
                color: Colors.grey[600],
                onPressed: () => _pickImage(ImageSource.camera),
              ),
              IconButton(
                icon: const Icon(Icons.image_outlined),
                color: Colors.grey[600],
                onPressed: () => _pickImage(ImageSource.gallery),
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
                    decoration: const InputDecoration(
                      hintText: 'Message',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
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
