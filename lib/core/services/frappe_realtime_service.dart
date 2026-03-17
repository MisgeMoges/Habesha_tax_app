import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/frappe_config.dart';

class FrappeRealtimeService {
  io.Socket? _socket;
  final StreamController<Map<String, dynamic>> _eventsController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _eventsController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect({required String userEmail}) {
    if (_socket != null) return;

    final options = io.OptionBuilder()
        .setPath(FrappeConfig.socketPath)
        .setTransports(['websocket'])
        .setQuery({'user': userEmail})
        .enableReconnection()
        .setReconnectionDelay(1000)
        .setReconnectionDelayMax(5000)
        .disableAutoConnect()
        .build();

    _socket = io.io(FrappeConfig.baseUrl, options);

    _socket!.on(FrappeConfig.chatRealtimeEvent, (data) {
      if (data is Map) {
        _eventsController.add(Map<String, dynamic>.from(data));
      } else {
        _eventsController.add(<String, dynamic>{'data': data});
      }
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _eventsController.close();
  }
}
