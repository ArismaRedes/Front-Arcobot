import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum RealtimeConnectionStatus { disconnected, connecting, connected }

class RealtimeEvent {
  const RealtimeEvent({required this.type, this.data});

  factory RealtimeEvent.fromRaw(dynamic raw) {
    if (raw is! String) {
      throw const FormatException('Realtime payload must be text');
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> || decoded['type'] is! String) {
      throw const FormatException('Invalid realtime event');
    }
    return RealtimeEvent(
        type: decoded['type'] as String, data: decoded['data']);
  }

  final String type;
  final dynamic data;
}

typedef RealtimeTicketProvider = Future<Uri> Function();

/// Cliente WebSocket reutilizable: obtiene tickets cortos, reconecta con
/// backoff y expone eventos tipados sin conocer ningún módulo de negocio.
class RealtimeClient {
  RealtimeClient({
    required RealtimeTicketProvider ticketProvider,
    this.maxReconnectDelay = const Duration(seconds: 15),
  }) : _ticketProvider = ticketProvider;

  final RealtimeTicketProvider _ticketProvider;
  final Duration maxReconnectDelay;
  final _events = StreamController<RealtimeEvent>.broadcast(sync: true);
  final _statuses =
      StreamController<RealtimeConnectionStatus>.broadcast(sync: true);

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSubscription;
  Timer? _reconnectTimer;
  var _status = RealtimeConnectionStatus.disconnected;
  var _generation = 0;
  var _reconnectAttempt = 0;
  var _running = false;
  var _disposed = false;

  Stream<RealtimeEvent> get events => _events.stream;
  Stream<RealtimeConnectionStatus> get statuses => _statuses.stream;
  RealtimeConnectionStatus get status => _status;

  void _setStatus(RealtimeConnectionStatus next) {
    if (_status == next || _disposed) {
      return;
    }
    _status = next;
    _statuses.add(next);
  }

  void start() {
    if (_disposed || _running) {
      return;
    }
    _running = true;
    _generation += 1;
    unawaited(_connect(_generation));
  }

  Future<void> _connect(int generation) async {
    if (!_running || _disposed || generation != _generation) {
      return;
    }
    _setStatus(RealtimeConnectionStatus.connecting);
    WebSocketChannel? channel;
    try {
      final uri = await _ticketProvider();
      if (!_running || _disposed || generation != _generation) {
        return;
      }
      channel = WebSocketChannel.connect(uri);
      await channel.ready;
      if (!_running || _disposed || generation != _generation) {
        await channel.sink.close();
        return;
      }
      _channel = channel;
      _reconnectAttempt = 0;
      _setStatus(RealtimeConnectionStatus.connected);
      _channelSubscription = channel.stream.listen(
        (raw) {
          try {
            _events.add(RealtimeEvent.fromRaw(raw));
          } catch (error) {
            debugPrint('Evento realtime inválido: $error');
          }
        },
        onError: (Object error) {
          debugPrint('WebSocket realtime falló: $error');
          _handleDisconnected(generation, channel!);
        },
        onDone: () => _handleDisconnected(generation, channel!),
        cancelOnError: true,
      );
    } catch (error) {
      debugPrint('No se pudo conectar realtime: $error');
      if (channel != null) {
        await channel.sink.close();
      }
      _scheduleReconnect(generation);
    }
  }

  void _handleDisconnected(int generation, WebSocketChannel channel) {
    if (_channel != channel) {
      return;
    }
    _channel = null;
    _channelSubscription = null;
    _setStatus(RealtimeConnectionStatus.disconnected);
    _scheduleReconnect(generation);
  }

  void _scheduleReconnect(int generation) {
    if (!_running || _disposed || generation != _generation) {
      return;
    }
    _setStatus(RealtimeConnectionStatus.disconnected);
    _reconnectTimer?.cancel();
    _reconnectAttempt += 1;
    final exponent = math.min(_reconnectAttempt - 1, 3);
    final milliseconds = math.min(
      2000 * (1 << exponent),
      maxReconnectDelay.inMilliseconds,
    );
    _reconnectTimer = Timer(Duration(milliseconds: milliseconds), () {
      _reconnectTimer = null;
      unawaited(_connect(generation));
    });
  }

  Future<void> stop() async {
    _running = false;
    _generation += 1;
    _reconnectAttempt = 0;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _channelSubscription?.cancel();
    _channelSubscription = null;
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      await channel.sink.close();
    }
    _setStatus(RealtimeConnectionStatus.disconnected);
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    await stop();
    _disposed = true;
    await _events.close();
    await _statuses.close();
  }
}
