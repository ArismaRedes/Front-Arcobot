import 'package:front_arcobot/features/simulator/domain/board_model.dart';
import 'package:front_arcobot/features/tracks/domain/track_models.dart';

Heading _headingFromName(String? name) {
  return Heading.values.firstWhere(
    (value) => value.name == name,
    orElse: () => Heading.up,
  );
}

Cell _cellFromJson(Map<String, dynamic>? json) {
  return Cell(
    ((json?['col']) as num?)?.toInt() ?? 0,
    ((json?['row']) as num?)?.toInt() ?? 0,
  );
}

/// "Ojo en la pantalla": réplica de lo que el niño ve en su simulador,
/// reportada por su app y renderizada en el monitor del docente.
class StudentLiveState {
  const StudentLiveState({
    required this.phase,
    required this.program,
    required this.robotCell,
    required this.robotHeading,
    required this.start,
    required this.startHeading,
    required this.goal,
    required this.obstacles,
    this.activeStep,
  });

  static StudentLiveState? tryParse(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      return null;
    }
    try {
      final robot = raw['robot'] as Map<String, dynamic>?;
      final board = raw['board'] as Map<String, dynamic>? ?? const {};
      final program = <RobotCommand>[
        for (final name in raw['program'] as List<dynamic>? ?? const [])
          RobotCommand.values.firstWhere(
            (command) => command.name == name,
            orElse: () => RobotCommand.forward,
          ),
      ];
      return StudentLiveState(
        phase: raw['phase'] as String? ?? 'editing',
        program: program,
        activeStep: (raw['activeStep'] as num?)?.toInt(),
        robotCell: _cellFromJson(robot),
        robotHeading: _headingFromName(robot?['heading'] as String?),
        start: _cellFromJson(board['start'] as Map<String, dynamic>?),
        startHeading: _headingFromName(board['startHeading'] as String?),
        goal: _cellFromJson(board['goal'] as Map<String, dynamic>?),
        obstacles: {
          for (final item in board['obstacles'] as List<dynamic>? ?? const [])
            _cellFromJson(item as Map<String, dynamic>?),
        },
      );
    } catch (_) {
      // Snapshot corrupto o de una versión vieja de la app: lo ignoramos.
      return null;
    }
  }

  final String phase;
  final List<RobotCommand> program;
  final int? activeStep;
  final Cell robotCell;
  final Heading robotHeading;
  final Cell start;
  final Heading startHeading;
  final Cell goal;
  final Set<Cell> obstacles;
}

class ClassSessionInfo {
  const ClassSessionInfo({
    required this.pin,
    required this.name,
    required this.studentCount,
    this.trackCount = 0,
    this.gameMode = 'cards',
  });

  factory ClassSessionInfo.fromJson(Map<String, dynamic> json) {
    return ClassSessionInfo(
      pin: json['pin'] as String,
      name: json['name'] as String,
      studentCount: (json['studentCount'] as num?)?.toInt() ?? 0,
      trackCount: (json['trackCount'] as num?)?.toInt() ?? 0,
      gameMode: json['gameMode'] as String? ?? 'cards',
    );
  }

  final String pin;
  final String name;
  final int studentCount;
  final int trackCount;

  /// Editor definido por el docente: 'cards' (tarjetas) o 'blocks' (Scratch).
  final String gameMode;
}

/// Última jugada reportada por el simulador del estudiante.
enum StudentOutcome { playing, success, blocked }

StudentOutcome? _outcomeFromName(String? name) {
  for (final value in StudentOutcome.values) {
    if (value.name == name) {
      return value;
    }
  }
  return null;
}

/// Estudiante visto desde el panel del docente, con su actividad en vivo.
class SessionStudentInfo {
  const SessionStudentInfo({
    required this.id,
    required this.alias,
    required this.avatar,
    required this.joinedAt,
    this.attempts = 0,
    this.successes = 0,
    this.lastTrack,
    this.lastOutcome,
    this.lastCards,
    this.lastActivityAt,
    this.live,
  });

  factory SessionStudentInfo.fromJson(Map<String, dynamic> json) {
    final lastActivity = (json['lastActivityAt'] as num?)?.toInt();
    return SessionStudentInfo(
      live: StudentLiveState.tryParse(json['liveState']),
      id: json['id'] as String,
      alias: json['alias'] as String,
      avatar: json['avatar'] as String,
      joinedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['joinedAt'] as num?)?.toInt() ?? 0,
      ),
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      successes: (json['successes'] as num?)?.toInt() ?? 0,
      lastTrack: json['lastTrack'] as String?,
      lastOutcome: _outcomeFromName(json['lastOutcome'] as String?),
      lastCards: (json['lastCards'] as num?)?.toInt(),
      lastActivityAt: lastActivity == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastActivity),
    );
  }

  final String id;
  final String alias;
  final String avatar;
  final DateTime joinedAt;
  final int attempts;
  final int successes;
  final String? lastTrack;
  final StudentOutcome? lastOutcome;
  final int? lastCards;
  final DateTime? lastActivityAt;

  /// Pantalla en vivo del estudiante (null si aún no reporta snapshot).
  final StudentLiveState? live;
}

class StudentSession {
  const StudentSession({
    required this.token,
    required this.studentId,
    required this.alias,
    required this.avatar,
    required this.sessionPin,
    required this.sessionName,
    this.gameMode = 'cards',
    this.tracks = const [],
  });

  factory StudentSession.fromJson(Map<String, dynamic> json) {
    final session = json['session'] as Map<String, dynamic>? ?? const {};
    return StudentSession(
      token: json['studentToken'] as String,
      studentId: json['studentId'] as String,
      alias: json['alias'] as String,
      avatar: json['avatar'] as String,
      sessionPin: session['pin'] as String? ?? '',
      sessionName: session['name'] as String? ?? '',
      gameMode: session['gameMode'] as String? ?? 'cards',
    );
  }

  final String token;
  final String studentId;
  final String alias;
  final String avatar;
  final String sessionPin;
  final String sessionName;

  /// Editor definido por el docente: 'cards' o 'blocks' (Scratch).
  final String gameMode;

  /// Pistas asignadas por el docente (vacío = usar las de demostración).
  final List<TrackInfo> tracks;

  StudentSession withTracks(List<TrackInfo> tracks) {
    return StudentSession(
      token: token,
      studentId: studentId,
      alias: alias,
      avatar: avatar,
      sessionPin: sessionPin,
      sessionName: sessionName,
      gameMode: gameMode,
      tracks: tracks,
    );
  }
}
