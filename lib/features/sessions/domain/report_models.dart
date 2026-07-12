/// Premio de una categoría del reporte (analíticas generadas por backend).
class ReportAward {
  const ReportAward({
    required this.studentId,
    required this.alias,
    required this.avatar,
    required this.value,
    this.detail,
  });

  factory ReportAward.fromJson(Map<String, dynamic> json) {
    return ReportAward(
      studentId: json['studentId'] as String,
      alias: json['alias'] as String,
      avatar: json['avatar'] as String,
      value: (json['value'] as num).toDouble(),
      detail: json['detail'] as String?,
    );
  }

  final String studentId;
  final String alias;
  final String avatar;
  final double value;
  final String? detail;
}

class ReportStudentSummary {
  const ReportStudentSummary({
    required this.studentId,
    required this.alias,
    required this.avatar,
    required this.attempts,
    required this.successes,
    this.bestMs,
    this.avgCards,
  });

  factory ReportStudentSummary.fromJson(Map<String, dynamic> json) {
    return ReportStudentSummary(
      studentId: json['studentId'] as String,
      alias: json['alias'] as String,
      avatar: json['avatar'] as String,
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      successes: (json['successes'] as num?)?.toInt() ?? 0,
      bestMs: (json['bestMs'] as num?)?.toInt(),
      avgCards: (json['avgCards'] as num?)?.toDouble(),
    );
  }

  final String studentId;
  final String alias;
  final String avatar;
  final int attempts;
  final int successes;
  final int? bestMs;
  final double? avgCards;
}

class SessionReportStats {
  const SessionReportStats({
    required this.students,
    required this.attempts,
    required this.successes,
    required this.successRate,
    this.topSolver,
    this.fastest,
    this.mostPersistent,
    this.mostEfficient,
    this.perStudent = const [],
  });

  factory SessionReportStats.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map<String, dynamic>? ?? const {};
    final awards = json['awards'] as Map<String, dynamic>? ?? const {};
    ReportAward? award(String key) {
      final raw = awards[key];
      return raw is Map<String, dynamic> ? ReportAward.fromJson(raw) : null;
    }

    return SessionReportStats(
      students: (totals['students'] as num?)?.toInt() ?? 0,
      attempts: (totals['attempts'] as num?)?.toInt() ?? 0,
      successes: (totals['successes'] as num?)?.toInt() ?? 0,
      successRate: (totals['successRate'] as num?)?.toDouble() ?? 0,
      topSolver: award('topSolver'),
      fastest: award('fastest'),
      mostPersistent: award('mostPersistent'),
      mostEfficient: award('mostEfficient'),
      perStudent: [
        for (final item in json['perStudent'] as List<dynamic>? ?? const [])
          ReportStudentSummary.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  final int students;
  final int attempts;
  final int successes;
  final double successRate;
  final ReportAward? topSolver;
  final ReportAward? fastest;
  final ReportAward? mostPersistent;
  final ReportAward? mostEfficient;
  final List<ReportStudentSummary> perStudent;

  bool get hasAwards =>
      topSolver != null ||
      fastest != null ||
      mostPersistent != null ||
      mostEfficient != null;
}

/// Grupo persistente del docente (curso, ej. "2°B").
class GroupInfo {
  const GroupInfo({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory GroupInfo.fromJson(Map<String, dynamic> json) {
    return GroupInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  final String id;
  final String name;
  final DateTime createdAt;
}

/// Clase del historial de un grupo, con su reporte si ya terminó.
class GroupSessionSummary {
  const GroupSessionSummary({
    required this.id,
    required this.pin,
    required this.name,
    required this.createdAt,
    required this.studentCount,
    this.endedAt,
    this.report,
  });

  factory GroupSessionSummary.fromJson(Map<String, dynamic> json) {
    final endedAt = (json['endedAt'] as num?)?.toInt();
    final report = json['report'];
    return GroupSessionSummary(
      id: json['id'] as String,
      pin: json['pin'] as String,
      name: json['name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as num?)?.toInt() ?? 0,
      ),
      studentCount: (json['studentCount'] as num?)?.toInt() ?? 0,
      endedAt:
          endedAt == null ? null : DateTime.fromMillisecondsSinceEpoch(endedAt),
      report: report is Map<String, dynamic>
          ? SessionReportStats.fromJson(report)
          : null,
    );
  }

  final String id;
  final String pin;
  final String name;
  final DateTime createdAt;
  final int studentCount;
  final DateTime? endedAt;
  final SessionReportStats? report;
}
