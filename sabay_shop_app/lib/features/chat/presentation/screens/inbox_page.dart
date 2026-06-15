import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sabay_shop_app/core/router/route_name.dart';
import 'package:sabay_shop_app/features/chat/domain/entities/message_entity.dart';
import 'package:sabay_shop_app/features/chat/presentation/controllers/chat_controller.dart';
import 'package:sabay_shop_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:sabay_shop_app/features/auth/domain/entities/user_entity.dart';
import 'package:sabay_shop_app/core/network/api_endpoints.dart';
import 'package:sabay_shop_app/features/chat/presentation/screens/chat_detail_page.dart';
import 'package:intl/intl.dart';
import 'package:sabay_shop_app/core/theme/app_theme.dart';

class InboxPage extends ConsumerWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final messagesAsync = ref.watch(chatControllerProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FD),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              title: const Text('MESSAGES', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                      child: const Icon(Icons.chat_bubble_outline, size: 80, color: AppTheme.primaryBlue),
                    ),
                    const SizedBox(height: 32),
                    const Text('Sign in to view messages', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF1F2937))),
                    const SizedBox(height: 12),
                    const Text(
                      'Log in to chat with buyers and sellers about products.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500, height: 1.5),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          context.push(RouteName.login);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('LOGIN / REGISTER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
            title: const Text(
              'Messages',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 24,
                color: Color(0xFF1F2937),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.grey),
                onPressed: () {},
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(chatControllerProvider);
              await ref.read(chatControllerProvider.future);
            },
            child: messagesAsync.when(
              skipLoadingOnRefresh: false,
              data: (messages) {
                final conversations = _groupMessages(messages, user.id);

                if (conversations.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: conversations.length,
                  separatorBuilder: (_, __) => Padding(
                    padding: const EdgeInsets.only(left: 80),
                    child: Divider(color: Colors.grey.withOpacity(0.1), height: 1),
                  ),
                  itemBuilder: (context, index) {
                    final conv = conversations[index];
                    return _ConversationTile(conversation: conv, currentUserId: user.id);
                  },
                );
              },
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: 8,
                itemBuilder: (context, index) => _buildConversationSkeleton(),
              ),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        );
      },
      loading: () => _InboxSkeleton(),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildConversationSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(width: 56, height: 56, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 120, height: 14, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: double.infinity, height: 12, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline, size: 64, color: AppTheme.primaryBlue),
          ),
          const SizedBox(height: 24),
          const Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start chatting with sellers to buy items',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  List<_Conversation> _groupMessages(List<MessageEntity> messages, int currentUserId) {
    final Map<int, _Conversation> groups = {};
    for (final msg in messages) {
      final partnerId = msg.fromUserId == currentUserId ? msg.toUserId : msg.fromUserId;
      if (!groups.containsKey(partnerId)) {
        final partner = msg.fromUserId == currentUserId ? msg.toUser : msg.fromUser;
        if (partner == null) continue;
        groups[partnerId] = _Conversation(partner: partner, messages: []);
      }
      groups[partnerId]!.messages.add(msg);
    }
    final list = groups.values.toList();
    // Sort by latest message
    list.sort((a, b) {
      if (a.messages.isEmpty || b.messages.isEmpty) return 0;
      return b.messages.first.createdAt.compareTo(a.messages.first.createdAt);
    });
    return list;
  }
}

class _ConversationTile extends StatelessWidget {
  final _Conversation conversation;
  final int currentUserId;

  const _ConversationTile({required this.conversation, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    if (conversation.messages.isEmpty) return const SizedBox.shrink();
    final lastMsg = conversation.messages.first;
    final partner = conversation.partner;
    final unreadCount = conversation.messages.where((m) => !m.isRead && m.toUserId == currentUserId).length;
    final avatarUrl = partner.avatar != null ? ApiEndpoints.getImageUrl(partner.avatar!) : '';
    final partnerInitial = partner.name.isNotEmpty ? partner.name[0].toUpperCase() : '?';

    return InkWell(
      onTap: () => context.push(RouteName.chatDetail, extra: partner),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: avatarUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: avatarUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: const Color(0xFFF3F4F6)),
                            errorWidget: (context, url, error) => Center(
                              child: Text(partnerInitial,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primaryBlue)),
                            ),
                          )
                        : Center(
                            child: Text(partnerInitial,
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primaryBlue)),
                          ),
                  ),
                ),
                // Online status indicator (mock)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        partner.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        _formatDate(lastMsg.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: unreadCount > 0 ? AppTheme.primaryBlue : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (lastMsg.fromUserId == currentUserId)
                         Icon(
                           lastMsg.isRead ? Icons.done_all : Icons.done,
                           size: 14,
                           color: lastMsg.isRead ? Colors.blue : Colors.grey,
                         ),
                      if (lastMsg.fromUserId == currentUserId)
                        const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          lastMsg.type == 'text' ? lastMsg.content : '[${lastMsg.type.toUpperCase()}]',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: unreadCount > 0 ? FontWeight.w900 : FontWeight.normal,
                            color: unreadCount > 0 ? Colors.black87 : Colors.grey[500],
                          ),
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
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
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('dd/MM/yy').format(date);
    }
  }
}

class _Conversation {
  final UserEntity partner;
  final List<MessageEntity> messages;
  _Conversation({required this.partner, required this.messages});
}

class _InboxSkeleton extends StatelessWidget {
  const _InboxSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(width: 120, height: 24, color: Colors.white),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: 8,
        itemBuilder: (context, index) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(width: 56, height: 56, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 150, height: 16, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(width: double.infinity, height: 14, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
