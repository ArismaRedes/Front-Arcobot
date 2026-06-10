import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sonidos de feedback cortos. Cada uno espera un asset en
/// `assets/audio/sfx/{nombre}.mp3` (ej. `tap.mp3`).
enum ArcoSfx { tap, success, error, join, celebrate }

final arcoAudioProvider = Provider<ArcoAudio>((ref) {
  final audio = ArcoAudio();
  ref.onDispose(audio.dispose);
  return audio;
});

/// Reproductor central de audio para la UI de niños.
///
/// Requisito (Architecture.md): cada acción tiene sonido y las narraciones
/// guían al niño paso a paso. Si un asset todavía no existe, el servicio
/// falla en silencio (y para `tap` usa el clic del sistema), de modo que la
/// app funciona igual mientras se graban los audios.
class ArcoAudio {
  ArcoAudio()
      : _sfxPlayer = AudioPlayer(playerId: 'arco-sfx'),
        _voicePlayer = AudioPlayer(playerId: 'arco-voice') {
    _sfxPlayer.setReleaseMode(ReleaseMode.stop);
    _voicePlayer.setReleaseMode(ReleaseMode.stop);
  }

  final AudioPlayer _sfxPlayer;
  final AudioPlayer _voicePlayer;
  final Set<String> _missingAssets = {};

  Future<void> _playAsset(AudioPlayer player, String assetKey) async {
    if (_missingAssets.contains(assetKey)) {
      return;
    }
    try {
      await player.stop();
      await player.play(AssetSource(assetKey));
    } catch (error) {
      // En web el navegador bloquea el audio hasta el primer gesto del
      // usuario (autoplay policy); ese fallo es temporal, no significa que
      // el asset falte. Solo en nativo cacheamos el asset como ausente.
      if (!kIsWeb) {
        _missingAssets.add(assetKey);
      }
      debugPrint('Audio no disponible ($assetKey): $error');
    }
  }

  /// Efecto de sonido corto (tap, éxito, error...).
  Future<void> sfx(ArcoSfx sound) async {
    final assetKey = 'audio/sfx/${sound.name}.mp3';
    if (_missingAssets.contains(assetKey) && sound == ArcoSfx.tap) {
      unawaited(SystemSound.play(SystemSoundType.click));
      return;
    }
    await _playAsset(_sfxPlayer, assetKey);
  }

  /// Narración de voz que guía al niño. `name` sin extensión,
  /// ej. `narrate('escribe_codigo')` → `assets/audio/voice/escribe_codigo.mp3`.
  Future<void> narrate(String name) async {
    await _playAsset(_voicePlayer, 'audio/voice/$name.mp3');
  }

  Future<void> stopNarration() async {
    try {
      await _voicePlayer.stop();
    } catch (_) {
      // Sin audio activo: nada que detener.
    }
  }

  void dispose() {
    _sfxPlayer.dispose();
    _voicePlayer.dispose();
  }
}
