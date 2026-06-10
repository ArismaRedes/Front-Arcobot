import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/audio/arco_audio.dart';
import 'package:front_arcobot/core/theme/design_tokens.dart';
import 'package:front_arcobot/core/widgets/arco_avatar.dart';
import 'package:front_arcobot/core/widgets/kid_error_banner.dart';
import 'package:front_arcobot/features/sessions/presentation/student_home_screen.dart';
import 'package:front_arcobot/features/sessions/presentation/student_session_provider.dart';
import 'package:go_router/go_router.dart';

class StudentJoinScreen extends ConsumerStatefulWidget {
  const StudentJoinScreen({required this.pin, super.key});

  static const routePath = '/class/:pin/join';

  static String pathFor(String pin) => '/class/$pin/join';

  final String pin;

  @override
  ConsumerState<StudentJoinScreen> createState() => _StudentJoinScreenState();
}

class _StudentJoinScreenState extends ConsumerState<StudentJoinScreen> {
  late final TextEditingController _aliasController;
  String _selectedAvatar = ArcoAvatars.ids.first;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    _aliasController = TextEditingController();
    _aliasController.addListener(() {
      if (_inlineError != null && _aliasController.text.isNotEmpty) {
        setState(() => _inlineError = null);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(arcoAudioProvider).narrate('elige_tu_nombre');
    });
  }

  @override
  void dispose() {
    _aliasController.dispose();
    super.dispose();
  }

  void _selectAvatar(String avatarId) {
    ref.read(arcoAudioProvider).sfx(ArcoSfx.tap);
    HapticFeedback.selectionClick();
    setState(() => _selectedAvatar = avatarId);
  }

  Future<void> _join() async {
    final alias = _aliasController.text.trim();
    if (alias.length < 2) {
      ref.read(arcoAudioProvider).sfx(ArcoSfx.error);
      HapticFeedback.mediumImpact();
      setState(() => _inlineError = 'Escribe tu nombre para entrar');
      return;
    }

    setState(() => _inlineError = null);
    final joined = await ref.read(studentSessionProvider.notifier).join(
          pin: widget.pin,
          alias: alias,
          avatar: _selectedAvatar,
        );

    if (!mounted) {
      return;
    }

    if (joined) {
      ref.read(arcoAudioProvider).sfx(ArcoSfx.celebrate);
      HapticFeedback.lightImpact();
      context.go(StudentHomeScreen.routePath);
    } else {
      ref.read(arcoAudioProvider).sfx(ArcoSfx.error);
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(studentSessionProvider);
    final joining = sessionState.isLoading;
    final remoteError = sessionState.hasError
        ? StudentSessionController.friendlyError(sessionState.error!)
        : null;
    final errorMessage = _inlineError ?? remoteError;
    final compact = MediaQuery.sizeOf(context).width < 440;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.92, -0.64),
            end: Alignment(0.92, 0.64),
            colors: ArcobotKidColors.screenGradient,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(compact ? 16 : 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFF4F3F8)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 32,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: joining
                                ? null
                                : () => Navigator.of(context).maybePop().then(
                                      (popped) {
                                        if (!popped && context.mounted) {
                                          context.go('/login');
                                        }
                                      },
                                    ),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: ArcobotKidColors.textSecondary,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Clase $_formattedPin',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: ArcobotKidColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '¿Quién eres?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ArcobotKidColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Elige tu personaje y escribe tu nombre',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ArcobotKidColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          for (final avatarId in ArcoAvatars.ids)
                            GestureDetector(
                              onTap: joining
                                  ? null
                                  : () => _selectAvatar(avatarId),
                              child: ArcoAvatar(
                                avatarId: avatarId,
                                size: 64,
                                selected: avatarId == _selectedAvatar,
                              ),
                            ),
                        ],
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        child: errorMessage == null
                            ? const SizedBox(width: double.infinity)
                            : Padding(
                                padding: const EdgeInsets.only(top: 18),
                                child: KidErrorBanner(message: errorMessage),
                              ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _aliasController,
                        enabled: !joining,
                        textAlign: TextAlign.center,
                        textInputAction: TextInputAction.done,
                        autocorrect: false,
                        style: const TextStyle(
                          color: ArcobotKidColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Tu nombre',
                          hintStyle: const TextStyle(
                            color: Color(0xFF9DA9BF),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F8FF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E8FF),
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E8FF),
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: ArcobotKidColors.action,
                              width: 2.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[\p{L}\p{N} ]', unicode: true),
                          ),
                          LengthLimitingTextInputFormatter(14),
                        ],
                        onSubmitted: (_) => _join(),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 58,
                        child: FilledButton(
                          onPressed: joining ? null : _join,
                          style: FilledButton.styleFrom(
                            backgroundColor: ArcobotKidColors.action,
                            disabledBackgroundColor:
                                ArcobotKidColors.action.withValues(alpha: 0.6),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: joining
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('¡A jugar!'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _formattedPin {
    final pin = widget.pin;
    if (pin.length == 6) {
      return '${pin.substring(0, 3)} ${pin.substring(3)}';
    }
    return pin;
  }
}
