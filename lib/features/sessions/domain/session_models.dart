class ClassSessionInfo {
  const ClassSessionInfo({
    required this.pin,
    required this.name,
    required this.studentCount,
  });

  factory ClassSessionInfo.fromJson(Map<String, dynamic> json) {
    return ClassSessionInfo(
      pin: json['pin'] as String,
      name: json['name'] as String,
      studentCount: (json['studentCount'] as num?)?.toInt() ?? 0,
    );
  }

  final String pin;
  final String name;
  final int studentCount;
}

/// Estudiante visto desde el panel del docente.
class SessionStudentInfo {
  const SessionStudentInfo({
    required this.id,
    required this.alias,
    required this.avatar,
    required this.joinedAt,
  });

  factory SessionStudentInfo.fromJson(Map<String, dynamic> json) {
    return SessionStudentInfo(
      id: json['id'] as String,
      alias: json['alias'] as String,
      avatar: json['avatar'] as String,
      joinedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['joinedAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  final String id;
  final String alias;
  final String avatar;
  final DateTime joinedAt;
}

class StudentSession {
  const StudentSession({
    required this.token,
    required this.studentId,
    required this.alias,
    required this.avatar,
    required this.sessionPin,
    required this.sessionName,
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
    );
  }

  final String token;
  final String studentId;
  final String alias;
  final String avatar;
  final String sessionPin;
  final String sessionName;
}
