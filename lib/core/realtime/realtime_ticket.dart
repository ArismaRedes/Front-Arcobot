class RealtimeTicket {
  const RealtimeTicket({
    required this.ticket,
    required this.expiresAt,
    required this.websocketPath,
  });

  factory RealtimeTicket.fromJson(Map<String, dynamic> json) {
    return RealtimeTicket(
      ticket: json['ticket'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      websocketPath: json['websocketPath'] as String,
    );
  }

  final String ticket;
  final DateTime expiresAt;
  final String websocketPath;

  Uri toWebSocketUri(String apiBaseUrl) {
    final base = Uri.parse(apiBaseUrl);
    return base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: websocketPath,
      queryParameters: {'ticket': ticket},
    );
  }
}
