import 'package:front_arcobot/features/simulator/domain/board_model.dart';

Heading _headingFromName(String? name) {
  return Heading.values.firstWhere(
    (value) => value.name == name,
    orElse: () => Heading.up,
  );
}

Cell _cellFromJson(Map<String, dynamic> json) {
  return Cell(
    (json['col'] as num?)?.toInt() ?? 0,
    (json['row'] as num?)?.toInt() ?? 0,
  );
}

Map<String, int> _cellToJson(Cell cell) => {'col': cell.col, 'row': cell.row};

/// Pista creada por el docente en el editor. Es la versión persistida de
/// [BoardLevel]: se guarda en backend y la juegan los niños de la sesión.
class TrackInfo {
  const TrackInfo({
    required this.id,
    required this.name,
    required this.start,
    required this.startHeading,
    required this.goal,
    required this.obstacles,
    this.updatedAt,
  });

  factory TrackInfo.fromJson(Map<String, dynamic> json) {
    final obstacles = (json['obstacles'] as List<dynamic>? ?? const [])
        .map((item) => _cellFromJson(item as Map<String, dynamic>))
        .toSet();
    return TrackInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      start: _cellFromJson(json['start'] as Map<String, dynamic>),
      startHeading: _headingFromName(json['startHeading'] as String?),
      goal: _cellFromJson(json['goal'] as Map<String, dynamic>),
      obstacles: obstacles,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  final String id;
  final String name;
  final Cell start;
  final Heading startHeading;
  final Cell goal;
  final Set<Cell> obstacles;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'start': _cellToJson(start),
      'startHeading': startHeading.name,
      'goal': _cellToJson(goal),
      'obstacles': obstacles.map(_cellToJson).toList(),
    };
  }

  BoardLevel toBoardLevel() {
    return BoardLevel(
      name: name,
      start: start,
      startHeading: startHeading,
      goal: goal,
      obstacles: obstacles,
    );
  }
}
