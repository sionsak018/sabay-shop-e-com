import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:sabay_shop_app/core/router/route_name.dart';
import 'package:sabay_shop_app/features/chat/domain/entities/message_entity.dart';
import 'package:sabay_shop_app/features/chat/presentation/controllers/chat_controller.dart';
import 'package:sabay_shop_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:sabay_shop_app/features/auth/domain/entities/user_entity.dart';
import 'package:sabay_shop_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:sabay_shop_app/core/network/api_endpoints.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sabay_shop_app/features/profile/presentation/screens/public_profile_page.dart';

class ChatDetailPage extends ConsumerStatefulWidget {
  final UserEntity partner;

  const ChatDetailPage({super.key, required this.partner});

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _markAllAsRead();
    });
  }

  void _markAllAsRead() {
    final messagesAsync = ref.read(chatControllerProvider);
    if (messagesAsync.hasValue) {
      final unreadFromPartner = messagesAsync.value!.where((m) => 
        m.fromUserId == widget.partner.id && !m.isRead
      ).toList();
      
      for (var m in unreadFromPartner.take(5)) {
        ref.read(chatControllerProvider.notifier).markAsRead(m.id);
      }
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    try {
      await ref.read(chatControllerProvider.notifier).sendMessage(
        toUserId: widget.partner.id,
        message: content,
      );
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
         await Future.delayed(const Duration(milliseconds: 800));
         final currentMessages = ref.read(chatControllerProvider).value ?? [];
         final exists = currentMessages.any((m) => m.content == content && m.fromUserId != widget.partner.id);
         
         if (exists) {
            _messageController.clear(); 
         } else {
            _showError('Failed to send message. Please try again.');
         }
      }
    }
  }

  Future<void> _sendImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      await ref.read(chatControllerProvider.notifier).sendMessage(
        toUserId: widget.partner.id,
        type: 'image',
        file: File(image.path),
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
         // Wait for polling to confirm if it actually worked
         await Future.delayed(const Duration(seconds: 1, milliseconds: 500));
         final currentMessages = ref.read(chatControllerProvider).value ?? [];
         final hasRecentImage = currentMessages.any((m) => m.type == 'image' && m.fromUserId != widget.partner.id);
         
         if (!hasRecentImage) {
            _showError('Failed to send image');
         }
      }
    }
  }

  Future<void> _sendFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    File file = File(result.files.single.path!);
    final fileName = result.files.single.name;
    
    try {
      await ref.read(chatControllerProvider.notifier).sendMessage(
        toUserId: widget.partner.id,
        message: fileName,
        type: 'file',
        file: file,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
         await Future.delayed(const Duration(seconds: 1, milliseconds: 500));
         final currentMessages = ref.read(chatControllerProvider).value ?? [];
         final hasRecentFile = currentMessages.any((m) => m.content == fileName && m.fromUserId != widget.partner.id);
         
         if (!hasRecentFile) {
            _showError('Failed to send file');
         }
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showOptions(MessageEntity message, bool isMe) {
    final user = ref.read(authControllerProvider).value;
    final myReaction = message.reactions.cast<MessageReactionEntity?>().firstWhere(
      (r) => r?.userId == user?.id,
      orElse: () => null,
    );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['❤️', '👍', '🔥', '😂', '😮', '😢'].map((emoji) {
                  final isSelected = myReaction?.emoji == emoji;
                  return GestureDetector(
                    onTap: () {
                      ref.read(chatControllerProvider.notifier).react(message.id, emoji);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)) : null,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 32),
            
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Delete Message', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(message.id);
                },
              ),
            
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Copy Text', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard'), behavior: SnackBarBehavior.floating));
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to delete this message?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              ref.read(chatControllerProvider.notifier).delete(messageId);
              Navigator.pop(context);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAttachmentItem(Icons.image, 'Gallery', Colors.purple, _sendImage),
              _buildAttachmentItem(Icons.insert_drive_file, 'File', Colors.blue, _sendFile),
              _buildAttachmentItem(Icons.camera_alt, 'Camera', Colors.orange, () async {
                 final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                 if (image != null) {
                    ref.read(chatControllerProvider.notifier).sendMessage(
                      toUserId: widget.partner.id,
                      type: 'image',
                      file: File(image.path),
                    );
                    Navigator.pop(context);
                 }
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () {
            Navigator.pop(context);
            onTap();
          },
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatControllerProvider);
    final user = ref.watch(authControllerProvider).value;
    final avatarUrl = widget.partner.avatar != null ? ApiEndpoints.getImageUrl(widget.partner.avatar!) : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leadingWidth: 40,
        title: InkWell(
          onTap: () {
            context.push('${RouteName.publicProfile}/${widget.partner.id}');
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFF3F4F6),
                backgroundImage: avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
                child: avatarUrl.isEmpty ? Text(widget.partner.name[0].toUpperCase()) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.partner.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1F2937)),
                    ),
                    const Text(
                      'Online',
                      style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.grey), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (allMessages) {
                final chatMessages = allMessages.where((m) => 
                  m.fromUserId == widget.partner.id || m.toUserId == widget.partner.id
                ).toList();
                
                chatMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                if (chatMessages.isEmpty) {
                  return _buildEmptyChat();
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: chatMessages.length,
                  itemBuilder: (context, index) {
                    final msg = chatMessages[index];
                    final isMe = msg.fromUserId == user?.id;
                    
                    bool showDate = true;
                    if (index < chatMessages.length - 1) {
                      final olderMsg = chatMessages[index + 1];
                      if (_isSameDay(msg.createdAt, olderMsg.createdAt)) {
                        showDate = false;
                      }
                    }

                    bool showTail = true;
                    if (index > 0) {
                      final newerMsg = chatMessages[index - 1];
                      if (newerMsg.fromUserId == msg.fromUserId && _isSameDay(msg.createdAt, newerMsg.createdAt)) {
                        showTail = false;
                      }
                    }

                    return Column(
                      children: [
                        if (showDate) _buildDateSeparator(msg.createdAt),
                        GestureDetector(
                          onLongPress: () => _showOptions(msg, isMe),
                          child: _MessageBubble(
                            message: msg, 
                            isMe: isMe, 
                            showTail: showTail,
                            currentUserId: user?.id,
                            onReactionTap: (emoji) {
                              ref.read(chatControllerProvider.notifier).react(msg.id, emoji);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => _buildChatSkeleton(),
              error: (err, __) => Center(child: Text('Error: $err')),
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatSkeleton() {
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: 6,
      itemBuilder: (context, index) {
        final isMe = index % 2 == 0;
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              width: 150 + (index * 20).toDouble(),
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _formatDate(date),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'TODAY';
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) return 'YESTERDAY';
    return DateFormat('MMMM dd, yyyy').format(date).toUpperCase();
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            'No messages yet',
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Send a message to start the conversation',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.grey),
              onPressed: _showAttachmentMenu,
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 4,
                  minLines: 1,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;
  final bool showTail;
  final int? currentUserId;
  final Function(String)? onReactionTap;

  const _MessageBubble({
    required this.message, 
    required this.isMe, 
    required this.showTail,
    this.currentUserId,
    this.onReactionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: showTail ? 8 : 2),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primaryBlue : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : (showTail ? 0 : 16)),
                  bottomRight: Radius.circular(isMe ? (showTail ? 0 : 16) : 16),
                ),
                boxShadow: [
                  if (showTail)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (message.type == 'image' && message.filePath != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: ApiEndpoints.getImageUrl(message.filePath!),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              height: 150,
                              width: 200,
                              color: Colors.white,
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 150,
                            width: 200,
                            color: Colors.grey[100],
                            child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  
                  if (message.type == 'file' && message.filePath != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => launchUrl(Uri.parse(ApiEndpoints.getImageUrl(message.filePath!))),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.insert_drive_file, color: isMe ? Colors.white : AppTheme.primaryBlue),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  message.content,
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  if (message.type == 'text')
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isMe ? Colors.white : const Color(0xFF1F2937),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white.withOpacity(0.7) : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isMe) const SizedBox(width: 4),
                      if (isMe)
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            if (message.reactions.isNotEmpty)
              _buildReactions(),
          ],
        ),
      ),
    );
  }

  Widget _buildReactions() {
    return Transform.translate(
      offset: const Offset(0, -6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: message.reactions.map((r) {
            final isMine = r.userId == currentUserId;
            return GestureDetector(
              onTap: () => onReactionTap?.call(r.emoji),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: isMine ? AppTheme.primaryBlue.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(r.emoji, style: const TextStyle(fontSize: 12)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
