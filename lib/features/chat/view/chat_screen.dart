import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({super.key});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool isSearching = false;
  String selectedClientId = '';
  String _searchQuery = '';

  final List<Map<String, dynamic>> clients = [
    {'id': 'user_1', 'name': 'Alice', 'avatar': '🧑‍💼'},
    {'id': 'user_2', 'name': 'Bob', 'avatar': '👨‍🔧'},
    {'id': 'user_3', 'name': 'Charlie', 'avatar': '👩‍🌾'},
  ];

  final Map<String, List<Map<String, dynamic>>> chatHistories = {
    'user_1': [
      {
        'text': 'Hi Alice! How can I help you with your taxes today?',
        'isSentByUser': false,
        'timestamp': DateTime.now().subtract(const Duration(minutes: 8)),
      },
      {
        'text': 'Yes, please help me with documents.',
        'isSentByUser': true,
        'timestamp': DateTime.now().subtract(const Duration(minutes: 7)),
      },
    ],
    'user_2': [
      {
        'text': 'Hello Bob, I see some receipts uploaded.',
        'isSentByUser': false,
        'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
      },
    ],
    'user_3': [
      {
        'text': 'Hi Charlie! Any updates on your expense list?',
        'isSentByUser': false,
        'timestamp': DateTime.now().subtract(const Duration(minutes: 3)),
      },
    ],
  };

  void _handleSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty || selectedClientId.isEmpty) return;

    setState(() {
      chatHistories[selectedClientId]!.add({
        'text': text,
        'isSentByUser': true,
        'timestamp': DateTime.now(),
      });
    });
    _messageController.clear();

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
            child: Text(client['avatar']),
          ),
          title: Text(client['name']),
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
                  child: ListView.builder(
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
