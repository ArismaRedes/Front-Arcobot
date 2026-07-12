import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/features/sessions/data/session_repository.dart';
import 'package:front_arcobot/features/tracks/data/track_repository.dart';
import 'package:front_arcobot/features/tracks/domain/track_models.dart';

final tracksProvider =
    StateNotifierProvider<TracksController, AsyncValue<List<TrackInfo>>>(
  (ref) => TracksController(ref.watch(trackRepositoryProvider)),
);

class TracksController extends StateNotifier<AsyncValue<List<TrackInfo>>> {
  TracksController(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  final TrackRepository _repository;

  static String friendlyError(Object error) {
    if (error is SessionRepositoryException) {
      switch (error.code) {
        case 'NETWORK':
          return 'Sin conexión con el servidor. Revisa internet.';
        case 'TRACK_NOT_FOUND':
          return 'Esa pista ya no existe.';
        case 'TRACK_LIMIT_REACHED':
          return 'Alcanzaste el límite de pistas guardadas.';
        case 'AUTH_MISSING_TOKEN':
          return 'Tu sesión expiró. Inicia sesión nuevamente.';
      }
    }
    return 'Algo salió mal. Intenta de nuevo.';
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final tracks = await _repository.listTracks();
      if (mounted) {
        state = AsyncValue.data(tracks);
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  /// Crea o actualiza según venga con id vacío o no. Devuelve null si ok,
  /// o el mensaje de error para mostrar en el editor.
  Future<String?> save(TrackInfo track) async {
    try {
      final saved = track.id.isEmpty
          ? await _repository.createTrack(track)
          : await _repository.updateTrack(track);
      final current = [...?state.valueOrNull];
      final index = current.indexWhere((item) => item.id == saved.id);
      if (index >= 0) {
        current[index] = saved;
      } else {
        current.add(saved);
      }
      if (mounted) {
        state = AsyncValue.data(current);
      }
      return null;
    } catch (error) {
      return friendlyError(error);
    }
  }

  Future<String?> delete(String id) async {
    try {
      await _repository.deleteTrack(id);
      if (mounted) {
        state = AsyncValue.data(
          [...?state.valueOrNull]..removeWhere((item) => item.id == id),
        );
      }
      return null;
    } catch (error) {
      return friendlyError(error);
    }
  }
}
