import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../../core/config/frappe_config.dart';
import '../../../core/services/frappe_client.dart';
import '../../../core/utils/user_friendly_error.dart';

class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({super.key});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FrappeClient _client = FrappeClient();

  bool isSearching = false;
  String selectedClientId = '';
  String _searchQuery = '';
  String _currentUserId = '';
  bool _loadingClients = false;
  bool _loadingMessages = false;
  String? _errorMessage;

  List<Map<String, dynamic>> clients = [];
  final Map<String, List<Map<String, dynamic>>> chatHistories = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndClients();
  }

  Future<void> _loadCurrentUserAndClients() async {
    setState(() {
      _loadingClients = true;
      _errorMessage = null;
    });
    try {
      final currentUserResponse = await _client.get(
        '/api/method/frappe.auth.get_logged_user',
      );
      _currentUserId = currentUserResponse['message']?.toString() ?? '';

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
    if (text.isEmpty || selectedClientId.isEmpty) return;
    _sendMessage(text);
  }

  Future<void> _sendMessage(String text) async {
    final message = {
      'text': text,
      'isSentByUser': true,
      'timestamp': DateTime.now(),
    };
    setState(() {
      chatHistories.putIfAbsent(selectedClientId, () => []);
      chatHistories[selectedClientId]!.add(message);
    });

    _messageController.clear();

    try {
      await _client.post(
        '/api/resource/${FrappeConfig.chatMessageDoctype}',
        body: {
          'data': {
            FrappeConfig.chatMessageSenderField: _currentUserId,
            FrappeConfig.chatMessageReceiverField: selectedClientId,
            FrappeConfig.chatMessageBodyField: text,
            FrappeConfig.chatMessageTimestampField: DateTime.now()
                .toIso8601String(),
          },
        },
      );
    } catch (e) {
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

  Future<void> _loadMessages(String clientId) async {
    setState(() {
      _loadingMessages = true;
      _errorMessage = null;
    });
    try {
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
            FrappeConfig.chatMessageTimestampField,
          ]),
          'order_by': '${FrappeConfig.chatMessageTimestampField} asc',
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
            'timestamp':
                DateTime.tryParse(
                  item[FrappeConfig.chatMessageTimestampField]?.toString() ??
                      '',
                ) ??
                DateTime.now(),
          };
        }).toList();
      }
    } catch (e) {
      _errorMessage = UserFriendlyError.message(
        e,
        fallback: 'Unable to load messages right now.',
      );
    } finally {
      setState(() {
        _loadingMessages = false;
      });
    }
  }

  String _formatTimestamp(DateTime time) {
    return DateFormat('hh:mm a').format(time);
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
        final chat = chatHistories[client['id']];
        final lastMessage = chat != null && chat.isNotEmpty
            ? chat.last['text']
            : '';
        final timestamp = chat != null && chat.isNotEmpty
            ? _formatTimestamp(chat.last['timestamp'])
            : '';

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.deepPurple[100],
            backgroundImage:
                (client['avatar'] != null &&
                    client['avatar'].toString().isNotEmpty)
                ? NetworkImage(client['avatar'])
                : null,
            child:
                (client['avatar'] == null ||
                    client['avatar'].toString().isEmpty)
                ? Text(
                    client['name'].toString().isNotEmpty
                        ? client['name'].toString()[0].toUpperCase()
                        : '?',
                  )
                : null,
          ),
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
          onTap: () {
            setState(() {
              selectedClientId = client['id'];
              isSearching = false;
            });
            _loadMessages(client['id']);
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
          Expanded(
            child: Container(
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
    final messages = selectedClientId.isNotEmpty
        ? chatHistories[selectedClientId] ?? []
        : [];

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
                              _buildMessage(messages[index]),
                        ),
                ),
                _buildMessageInput(),
              ],
            ),
    );
  }
}
