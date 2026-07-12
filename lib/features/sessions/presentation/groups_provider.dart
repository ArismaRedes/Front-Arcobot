import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/features/sessions/data/group_repository.dart';
import 'package:front_arcobot/features/sessions/domain/report_models.dart';

/// Grupos (cursos) del docente. Invalidar tras crear/renombrar/borrar.
final groupsProvider = FutureProvider<List<GroupInfo>>((ref) {
  return ref.watch(groupRepositoryProvider).listGroups();
});

/// Historial de clases de un grupo, con reportes.
final groupSessionsProvider = FutureProvider.autoDispose
    .family<List<GroupSessionSummary>, String>((ref, groupId) {
  return ref.watch(groupRepositoryProvider).listGroupSessions(groupId);
});
