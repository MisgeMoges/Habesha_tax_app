import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/config/frappe_config.dart';
import '../../../core/services/frappe_client.dart';
import '../../../core/services/frappe_realtime_service.dart';
import '../../../core/utils/user_friendly_error.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';

class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({super.key});

  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FrappeClient _client = FrappeClient();
  final FrappeRealtimeService _realtimeService = FrappeRealtimeService();

  bool isSearching = false;
  String selectedClientId = '';
  String _searchQuery = '';
  String _currentUserId = '';
  bool _loadingClients = false;
  bool _loadingMessages = false;
  String? _errorMessage;
  Timer? _pollTimer;
  StreamSubscription<Map<String, dynamic>>? _realtimeSubscription;

  String? _pendingAttachmentUrl;
  String? _pendingAttachmentName;
  final Map<String, DateTime> _lastSeenBySender = {};
  Map<String, int> _unreadBySender = {};
  final Map<String, Map<String, dynamic>> _latestMessageByClient = {};

  List<Map<String, dynamic>> clients = [];
  final Map<String, List<Map<String, dynamic>>> chatHistories = {};

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _currentUserId = authState.user.email.trim();
    }
    _connectRealtime();
    _loadCurrentUserAndClients();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _realtimeSubscription?.cancel();
    _realtimeService.dispose();
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _connectRealtime() {
    if (_currentUserId.isEmpty) return;
    if (_realtimeService.isConnected) return;

    _realtimeService.connect(userEmail: _currentUserId);
    _realtimeSubscription?.cancel();
    _realtimeSubscription = _realtimeService.events.listen((_) {
      _pollUnreadAndOpenConversation();
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _pollUnreadAndOpenConversation();
    });
  }

  Future<void> _pollUnreadAndOpenConversation() async {
    if (_currentUserId.isEmpty) return;
    await _refreshUnreadCount();
    if (selectedClientId.isNotEmpty) {
      await _loadMessages(selectedClientId, showLoader: false);
    }
  }

  Future<void> _loadCurrentUserAndClients() async {
    setState(() {
      _loadingClients = true;
      _errorMessage = null;
    });
    try {
      if (_currentUserId.isEmpty) {
        throw Exception('User not authenticated');
      }
      // final response = await _client.get(
      //   '/api/method/habesha_tax.habesha_tax.doctype.chat_message.chat_message.get_clients',
      // );

      // final data = response['message'];

      // if (data is List) {
      //   clients = data.map((item) {
      //     return {
      //       "id": item["client"],
      //       "name": item["client"],
      //       "email": item["client"],
      //       "avatar": null,
      //     };
      //   }).toList();
      // }

      final response = await _client.get(
        '/api/resource/${FrappeConfig.userDoctype}',
        queryParameters: {
          'fields': jsonEncode([
            FrappeConfig.userIdField,
            FrappeConfig.userFirstNameField,
            FrappeConfig.userLastNameField,
            FrappeConfig.userEmailField,
          ]),
          'filters': jsonEncode([
            ['enabled', '=', 1],
          ]),
          'limit_page_length': '200',
        },
      );

      final data = response['data'];
      if (data is List) {
        clients = data
            .map(
              (item) => {
                'id': item[FrappeConfig.userIdField]?.toString() ?? '',
                'name':
                    '${item[FrappeConfig.userFirstNameField] ?? ''} ${item[FrappeConfig.userLastNameField] ?? ''}'
                        .trim(),
                'email': item[FrappeConfig.userEmailField]?.toString() ?? '',
                'avatar': null,
              },
            )
            .where((client) => client['id'] != _currentUserId)
            .toList();
      }

      await _refreshUnreadCount();
    } catch (e) {
      _errorMessage = UserFriendlyError.message(
        e,
        fallback: 'Unable to load chats right now.',
      );
    } finally {
      setState(() {
        _loadingClients = false;
      });
    }
  }

  void _handleSend() {
    final text = _messageController.text.trim();
    if ((text.isEmpty && _pendingAttachmentUrl == null) ||
        selectedClientId.isEmpty) {
      return;
    }

    final displayText = _pendingAttachmentName == null
        ? text
        : text.isEmpty
        ? '📎 $_pendingAttachmentName'
        : '$text\n📎 $_pendingAttachmentName';
    final payloadText = _pendingAttachmentUrl == null
        ? text
        : text.isEmpty
        ? 'Attachment: $_pendingAttachmentUrl'
        : '$text\nAttachment: $_pendingAttachmentUrl';
    _sendMessage(displayText: displayText, payloadText: payloadText);
  }

  Future<void> _sendMessage({
    required String displayText,
    required String payloadText,
  }) async {
    if (_currentUserId.isEmpty) {
      setState(() {
        _errorMessage = 'User not authenticated.';
      });
      return;
    }

    final message = {
      'text': displayText,
      'isSentByUser': true,
      'timestamp': DateTime.now(),
    };
    setState(() {
      chatHistories.putIfAbsent(selectedClientId, () => []);
      chatHistories[selectedClientId]!.add(message);
      _latestMessageByClient[selectedClientId] = {
        'text': displayText,
        'timestamp': message['timestamp'],
      };
    });

    _messageController.clear();
    final attachmentUrl = _pendingAttachmentUrl;
    final attachmentName = _pendingAttachmentName;
    setState(() {
      _pendingAttachmentUrl = null;
      _pendingAttachmentName = null;
    });

    try {
      await _client.post(
        '/api/method/habesha_tax.habesha_tax.doctype.chat_message.chat_message.send_message',
        body: {
          "receiver": selectedClientId,
          "message": payloadText,
          "sender": _currentUserId,
        },
      );
      // await _client.post(
      //   '/api/resource/${FrappeConfig.chatMessageDoctype}',
      //   body: {
      //     'data': {
      //       FrappeConfig.chatMessageSenderField: _currentUserId,
      //       FrappeConfig.chatMessageReceiverField: selectedClientId,
      //       FrappeConfig.chatMessageBodyField: payloadText,
      //       FrappeConfig.chatMessageTimestampField: DateTime.now()
      //           .toIso8601String(),
      //     },
      //   },
      // );
      await _loadMessages(selectedClientId, showLoader: false);
      await _refreshUnreadCount();
    } catch (e) {
      if (attachmentUrl != null && attachmentName != null) {
        setState(() {
          _pendingAttachmentUrl = attachmentUrl;
          _pendingAttachmentName = attachmentName;
        });
      }
      setState(() {
        _errorMessage = UserFriendlyError.message(
          e,
          fallback: 'Unable to send message right now. Please try again.',
        );
      });
    }

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _loadMessages(String clientId, {bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loadingMessages = true;
        _errorMessage = null;
      });
    }
    try {
      // final response = await _client.get(
      //   '/api/method/habesha_tax.habesha_tax.doctype.chat_message.chat_message.get_messages',
      //   queryParameters: {
      //     "client": "misganmoges@gmail.com",
      //     "user": _currentUserId,
      //   },
      // );

      // final data = response['message'];

      // if (data is List) {
      //   chatHistories[clientId] = data.map((item) {
      //     final sender = item['sender']?.toString() ?? '';

      //     return {
      //       'text': item['message'] ?? '',
      //       'isSentByUser': sender == _currentUserId,
      //       'timestamp':
      //           DateTime.tryParse(item['timestamp'] ?? '') ?? DateTime.now(),
      //     };
      //   }).toList();
      final response = await _client.get(
        '/api/resource/${FrappeConfig.chatMessageDoctype}',
        queryParameters: {
          'filters': jsonEncode([
            [
              FrappeConfig.chatMessageSenderField,
              'in',
              [_currentUserId, clientId],
            ],
            [
              FrappeConfig.chatMessageReceiverField,
              'in',
              [_currentUserId, clientId],
            ],
          ]),
          'fields': jsonEncode([
            'name',
            FrappeConfig.chatMessageSenderField,
            FrappeConfig.chatMessageReceiverField,
            FrappeConfig.chatMessageBodyField,
            FrappeConfig.chatMessageCreationIsoField,
            FrappeConfig.chatMessageTimestampField,
            FrappeConfig.chatMessageCreatedAtField,
          ]),
          'order_by': '${FrappeConfig.chatMessageCreatedAtField} asc',
          'limit_page_length': '200',
        },
      );

      final data = response['data'];
      if (data is List) {
        chatHistories[clientId] = data.map((item) {
          final sender =
              item[FrappeConfig.chatMessageSenderField]?.toString() ?? '';
          return {
            'text': item[FrappeConfig.chatMessageBodyField]?.toString() ?? '',
            'isSentByUser': sender == _currentUserId,
            'timestamp': _parseServerChatTime(item),
          };
        }).toList();
        final history = chatHistories[clientId];
        if (history != null && history.isNotEmpty) {
          final lastMessage = history.last;
          _latestMessageByClient[clientId] = {
            'text': lastMessage['text']?.toString() ?? '',
            'timestamp': lastMessage['timestamp'],
          };
        }
        await _markConversationAsRead(clientId);
        await _refreshUnreadCount();
      }
    } catch (e) {
      _errorMessage = UserFriendlyError.message(
        e,
        fallback: 'Unable to load messages right now.',
      );
    } finally {
      if (showLoader) {
        setState(() {
          _loadingMessages = false;
        });
      }
    }
  }

  void _scrollToLatest({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  Future<void> _markConversationAsRead(String clientId) async {
    final history = chatHistories[clientId] ?? const [];
    DateTime? latestIncoming;
    for (final msg in history) {
      if (msg['isSentByUser'] == false && msg['timestamp'] is DateTime) {
        final ts = msg['timestamp'] as DateTime;
        if (latestIncoming == null || ts.isAfter(latestIncoming)) {
          latestIncoming = ts;
        }
      }
    }
    if (latestIncoming != null) {
      _lastSeenBySender[clientId] = latestIncoming;
    }

    // Prefer a bulk server method to mark unread messages as read.
    // Fallback to per-row resource updates when method is unavailable.
    try {
      if (_currentUserId.isEmpty) return;
      var markedWithBulkMethod = false;
      try {
        await _client.post(
          '/api/method/habesha_tax.habesha_tax.doctype.chat_message.chat_message.mark_messages_as_read',
          body: {'sender': clientId, 'receiver': _currentUserId},
        );
        markedWithBulkMethod = true;
      } catch (_) {
        markedWithBulkMethod = false;
      }

      if (!markedWithBulkMethod) {
        final resp = await _client.get(
          '/api/resource/${FrappeConfig.chatMessageDoctype}',
          queryParameters: {
            'filters': jsonEncode([
              [FrappeConfig.chatMessageSenderField, '=', clientId],
              [FrappeConfig.chatMessageReceiverField, '=', _currentUserId],
              ['is_read', '=', 0],
            ]),
            'fields': jsonEncode(['name']),
            'limit_page_length': '500',
          },
        );
        final data = resp['data'];
        if (data is List) {
          for (final row in data) {
            final name = row['name']?.toString();
            if (name == null || name.isEmpty) continue;
            try {
              await _client.put(
                '/api/resource/${FrappeConfig.chatMessageDoctype}/$name',
                body: {'is_read': 1},
              );
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _refreshUnreadCount() async {
    try {
      // Only fetch messages that are still unread on the server
      final unreadResponse = await _client.get(
        '/api/resource/${FrappeConfig.chatMessageDoctype}',
        queryParameters: {
          'filters': jsonEncode([
            [FrappeConfig.chatMessageReceiverField, '=', _currentUserId],
            ['is_read', '=', 0],
          ]),
          'fields': jsonEncode([
            FrappeConfig.chatMessageSenderField,
            FrappeConfig.chatMessageCreatedAtField,
            FrappeConfig.chatMessageTimestampField,
          ]),
          'order_by': '${FrappeConfig.chatMessageCreatedAtField} desc',
          'limit_page_length': '500',
        },
      );

      final previewResponse = await _client.get(
        '/api/resource/${FrappeConfig.chatMessageDoctype}',
        queryParameters: {
          'or_filters': jsonEncode([
            [FrappeConfig.chatMessageSenderField, '=', _currentUserId],
            [FrappeConfig.chatMessageReceiverField, '=', _currentUserId],
          ]),
          'fields': jsonEncode([
            FrappeConfig.chatMessageSenderField,
            FrappeConfig.chatMessageReceiverField,
            FrappeConfig.chatMessageBodyField,
            FrappeConfig.chatMessageCreatedAtField,
            FrappeConfig.chatMessageTimestampField,
          ]),
          'order_by': '${FrappeConfig.chatMessageCreatedAtField} desc',
          'limit_page_length': '500',
        },
      );

      final data = unreadResponse['data'];
      if (data is! List) return;

      final previewData = previewResponse['data'];
      final latestMessageByClient = <String, Map<String, dynamic>>{};
      if (previewData is List) {
        for (final row in previewData) {
          final item = Map<String, dynamic>.from(row as Map);
          final sender =
              item[FrappeConfig.chatMessageSenderField]?.toString() ?? '';
          final receiver =
              item[FrappeConfig.chatMessageReceiverField]?.toString() ?? '';
          final partnerId = sender == _currentUserId ? receiver : sender;
          if (partnerId.isEmpty || partnerId == _currentUserId) continue;
          if (latestMessageByClient.containsKey(partnerId)) continue;

          latestMessageByClient[partnerId] = {
            'text': item[FrappeConfig.chatMessageBodyField]?.toString() ?? '',
            'timestamp': _parseServerChatTime(item),
          };
        }
      }

      // Server indicates unread via `is_read` field, so simply count rows per sender
      var unread = 0;
      final unreadBySender = <String, int>{};
      for (final row in data) {
        final item = Map<String, dynamic>.from(row as Map);
        final sender =
            item[FrappeConfig.chatMessageSenderField]?.toString() ?? '';
        if (sender.isEmpty || sender == _currentUserId) continue;
        unread += 1;
        unreadBySender[sender] = (unreadBySender[sender] ?? 0) + 1;
      }

      AdminChatScreen.unreadCountNotifier.value = unread;
      if (mounted) {
        setState(() {
          _unreadBySender = unreadBySender;
          _latestMessageByClient
            ..clear()
            ..addAll(latestMessageByClient);
        });
      }
    } catch (_) {}
  }

  Widget _buildClientAvatar(Map<String, dynamic> client, int unreadCount) {
    final avatar = CircleAvatar(
      backgroundColor: Colors.deepPurple[100],
      backgroundImage:
          (client['avatar'] != null && client['avatar'].toString().isNotEmpty)
          ? NetworkImage(client['avatar'])
          : null,
      child: (client['avatar'] == null || client['avatar'].toString().isEmpty)
          ? Text(
              client['name'].toString().isNotEmpty
                  ? client['name'].toString()[0].toUpperCase()
                  : '?',
            )
          : null,
    );

    if (unreadCount <= 0) return avatar;

    final badgeText = unreadCount > 99 ? '99+' : '$unreadCount';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 16),
            child: Text(
              badgeText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      final path = result?.files.single.path;
      if (path == null || path.isEmpty) return;

      final file = File(path);
      final response = await _client.uploadFile(file: file);
      final fileUrl =
          response['message']?['file_url']?.toString() ??
          response['file_url']?.toString();

      if (fileUrl == null || fileUrl.trim().isEmpty) {
        _showSnack('Unable to attach file right now.');
        return;
      }

      setState(() {
        _pendingAttachmentUrl = fileUrl;
        _pendingAttachmentName =
            result?.files.single.name ?? file.path.split('/').last;
      });
    } catch (e) {
      _showSnack(
        UserFriendlyError.message(
          e,
          fallback: 'Unable to attach file right now.',
        ),
      );
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatTimestamp(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  DateTime _parseServerChatTime(Map<String, dynamic> item) {
    DateTime? parseServerTime(String value) {
      final raw = value.trim();
      if (raw.isEmpty) return null;

      final normalized = raw.replaceFirst(' ', 'T');
      final parsed = DateTime.tryParse(normalized);
      if (parsed == null) return null;

      // If server includes timezone/UTC info, convert to device local time.
      // If timezone is missing, keep parsed local value as-is.
      return parsed.isUtc ? parsed.toLocal() : parsed;
    }

    final creationIso = parseServerTime(
      item[FrappeConfig.chatMessageCreationIsoField]?.toString() ?? '',
    );
    if (creationIso != null) return creationIso;

    final createdAt = parseServerTime(
      item[FrappeConfig.chatMessageCreatedAtField]?.toString() ?? '',
    );
    if (createdAt != null) return createdAt;

    final legacyTimestamp = parseServerTime(
      item[FrappeConfig.chatMessageTimestampField]?.toString() ?? '',
    );
    if (legacyTimestamp != null) return legacyTimestamp;

    return DateTime.now();
  }

  String _formatConversationTimestamp(DateTime time) {
    final now = DateTime.now();
    if (_isSameDay(now, time)) {
      return _formatTimestamp(time);
    }

    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(time.year, time.month, time.day);
    final difference = today.difference(target).inDays;

    if (difference == 1) {
      return 'Yesterday';
    }
    if (difference < 7) {
      return DateFormat('EEE').format(time);
    }
    return DateFormat('MMM d').format(time);
  }

  String _formatDayHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = today.difference(target).inDays;

    if (difference == 0) {
      return 'Today';
    }
    if (difference == 1) {
      return 'Yesterday';
    }
    return DateFormat('EEEE, MMM d, yyyy').format(date);
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  Widget _buildDateSeparator(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Expanded(child: Divider(indent: 16, endIndent: 12)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _formatDayHeader(date),
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Expanded(child: Divider(indent: 12, endIndent: 16)),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final isUser = msg['isSentByUser'];
    final text = msg['text'];
    final timestamp = msg['timestamp'];

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF8A56E8) : Colors.grey.shade300,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(timestamp),
              style: TextStyle(
                color: isUser ? Colors.white70 : Colors.black54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedMessage(List<Map<String, dynamic>> messages, int index) {
    final message = messages[index];
    final timestamp = message['timestamp'];
    final currentTimestamp = timestamp is DateTime ? timestamp : DateTime.now();
    final previousTimestamp = index > 0
        ? messages[index - 1]['timestamp']
        : null;
    final previousDate = previousTimestamp is DateTime
        ? previousTimestamp
        : null;
    final shouldShowDateSeparator =
        previousDate == null || !_isSameDay(previousDate, currentTimestamp);

    return Column(
      children: [
        if (shouldShowDateSeparator) _buildDateSeparator(currentTimestamp),
        _buildMessage(message),
      ],
    );
  }

  Widget _buildClientList() {
    final filtered = clients
        .where(
          (client) =>
              client['name'].toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    if (_loadingClients) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final client = filtered[index];
        final clientId = client['id']?.toString() ?? '';
        final unreadCount = _unreadBySender[clientId] ?? 0;
        final latestMessage = _latestMessageByClient[clientId];
        final lastMessage = latestMessage?['text']?.toString() ?? '';
        final latestTimestamp = latestMessage?['timestamp'];
        final timestamp = latestTimestamp is DateTime
            ? _formatConversationTimestamp(latestTimestamp)
            : '';

        return ListTile(
          leading: _buildClientAvatar(client, unreadCount),
          title: Text(
            client['name'].toString().isEmpty
                ? client['email']
                : client['name'],
          ),
          subtitle: Text(
            lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            timestamp,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          onTap: () async {
            setState(() {
              selectedClientId = client['id'];
              isSearching = false;
            });
            await _loadMessages(client['id']);
            _scrollToLatest(animated: false);
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.deepPurple,
      elevation: 0,
      leading: selectedClientId.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                setState(() {
                  selectedClientId = '';
                });
              },
            )
          : null,
      title: isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Search user...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white),
              ),
              style: const TextStyle(color: Colors.white),
            )
          : Text(
              selectedClientId.isEmpty
                  ? 'Chats'
                  : clients.firstWhere(
                      (c) => c['id'] == selectedClientId,
                    )['name'],
              style: TextStyle(color: Colors.white),
            ),
      actions: [
        IconButton(
          icon: Icon(
            isSearching ? Icons.close : Icons.search,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              isSearching = !isSearching;
              _searchQuery = '';
              _searchController.clear();
            });
          },
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Attach file',
            onPressed: selectedClientId.isEmpty ? null : _pickAttachment,
            icon: const Icon(Icons.attach_file),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_pendingAttachmentName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '📎 $_pendingAttachmentName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 18,
                          onPressed: () {
                            setState(() {
                              _pendingAttachmentUrl = null;
                              _pendingAttachmentName = null;
                            });
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 40,
                      maxHeight: 120,
                    ),
                    child: Scrollbar(
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF8A56E8),
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _handleSend,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> messages = selectedClientId.isNotEmpty
        ? List<Map<String, dynamic>>.from(
            chatHistories[selectedClientId] ?? const <Map<String, dynamic>>[],
          )
        : const <Map<String, dynamic>>[];

    return Scaffold(
      appBar: _buildAppBar(),
      body: selectedClientId.isEmpty
          ? _buildClientList()
          : Column(
              children: [
                Expanded(
                  child: _loadingMessages
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemCount: messages.length,
                          itemBuilder: (context, index) =>
                              _buildGroupedMessage(messages, index),
                        ),
                ),
                _buildMessageInput(),
              ],
            ),
    );
  }
}
