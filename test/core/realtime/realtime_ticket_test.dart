import 'package:flutter_test/flutter_test.dart';
import 'package:front_arcobot/core/realtime/realtime_ticket.dart';

void main() {
  test('builds a secure websocket URI with only the short ticket', () {
    final ticket = RealtimeTicket(
      ticket: 'single-use-ticket',
      expiresAt: DateTime.utc(2026, 7, 9),
      websocketPath: '/api/v1/realtime/connect',
    );

    final uri = ticket.toWebSocketUri('https://api.arcobot.example');

    expect(uri.scheme, 'wss');
    expect(uri.path, '/api/v1/realtime/connect');
    expect(uri.queryParameters, {'ticket': 'single-use-ticket'});
    expect(uri.toString(), isNot(contains('access_token')));
  });

  test('uses ws for local http development', () {
    final ticket = RealtimeTicket(
      ticket: 'dev-ticket',
      expiresAt: DateTime.utc(2026, 7, 9),
      websocketPath: '/api/v1/realtime/connect',
    );

    expect(ticket.toWebSocketUri('http://localhost:3000').scheme, 'ws');
  });
}
