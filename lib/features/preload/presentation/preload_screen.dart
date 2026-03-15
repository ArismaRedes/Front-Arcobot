import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/config/app_assets.dart';
import 'package:front_arcobot/core/widgets/app_illustration.dart';
import 'package:front_arcobot/features/auth/presentation/auth_provider.dart';
import 'package:front_arcobot/features/auth/presentation/auth_state.dart';
import 'package:front_arcobot/features/auth/presentation/login_screen.dart';
import 'package:front_arcobot/features/dashboard/presentation/dashboard_screen.dart';
import 'package:front_arcobot/features/superadmin/presentation/superadmin_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class PreloadScreen extends ConsumerStatefulWidget {
  const PreloadScreen({super.key});

  static const routePath = '/preload';

  @override
  ConsumerState<PreloadScreen> createState() => _PreloadScreenState();
}

class _PreloadScreenState extends ConsumerState<PreloadScreen>
    with SingleTickerProviderStateMixin {
  bool _minDelayDone = false;
  bool _navigated = false;
  bool _lottieCompleted = false;
  bool _lottieFallbackShown = false;
  static const _preloadMinDuration = Duration(milliseconds: 2500);
  late final AnimationController _lottieController;

  Future<LottieComposition?> _dotLottieDecoder(List<int> bytes) async {
    return LottieComposition.decodeZip(
      bytes,
      filePicker: (files) {
        final animationFile = files.where((file) {
          final name = file.name.toLowerCase();
          return name.endsWith('.json') &&
              name.contains('animations/') &&
              !name.endsWith('manifest.json');
        });
        if (animationFile.isNotEmpty) {
          return animationFile.first;
        }

        final nonManifestJson = files.where((file) {
          final name = file.name.toLowerCase();
          return name.endsWith('.json') && !name.endsWith('manifest.json');
        });
        if (nonManifestJson.isNotEmpty) {
          return nonManifestJson.first;
        }

        final anyJson = files.where((file) => file.name.endsWith('.json'));
        return anyJson.isNotEmpty ? anyJson.first : null;
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _lottieController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _lottieCompleted = true;
        _tryNavigate();
      }
    });
    Future<void>.delayed(_preloadMinDuration, () {
      if (!mounted) {
        return;
      }
      _minDelayDone = true;
      _tryNavigate();
    });
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  void _onLottieLoaded(LottieComposition composition) {
    _lottieController
      ..duration = composition.duration
      ..reset()
      ..forward();
  }

  void _tryNavigate() {
    if (!mounted || _navigated || !_minDelayDone) {
      return;
    }

    if (!_lottieCompleted && !_lottieFallbackShown) {
      return;
    }

    final authState = ref.read(authControllerProvider);
    if (authState.status == AuthStatus.unknown ||
        authState.status == AuthStatus.loading) {
      return;
    }

    _navigated = true;
    if (authState.status == AuthStatus.authenticated) {
      context.go(
        authState.isSuperadmin
            ? SuperadminScreen.routePath
            : DashboardScreen.routePath,
      );
      return;
    }
    context.go(LoginScreen.routePath);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (_, __) {
      _tryNavigate();
    });

    final theme = Theme.of(context);
    final lottieSize = MediaQuery.sizeOf(context).width.clamp(240.0, 360.0);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF9FCFF), Color(0xFFEFF6FA)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: lottieSize,
                  height: lottieSize,
                  child: Lottie.asset(
                    AppAssets.preloadLottie,
                    fit: BoxFit.contain,
                    repeat: false,
                    animate: false,
                    controller: _lottieController,
                    decoder: _dotLottieDecoder,
                    onLoaded: _onLottieLoaded,
                    errorBuilder: (_, __, ___) {
                      if (!_lottieFallbackShown) {
                        _lottieFallbackShown = true;
                        _lottieCompleted = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _tryNavigate();
                        });
                      }
                      return AppIllustration(
                        assetPath: AppAssets.mascotSvg,
                        height: lottieSize,
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cargando...',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0B6E5E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
