import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import '../../utils/onboarding_storage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _particleCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Stagger the text entry after logo finishes
    _logoCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _textCtrl.forward();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    final auth = context.read<AuthProvider>();

    // Check onboarding FIRST, before bootstrap, so it always shows
    // on a fresh install regardless of whether a token exists.
    final onboardingDone = await OnboardingStorage.isDone();
    if (!mounted) return;

    if (!onboardingDone) {
      Navigator.of(context).pushReplacementNamed(AppRouter.onboarding);
      return;
    }

    // Onboarding already done — proceed with normal auth bootstrap.
    await auth.bootstrap();
    if (!mounted) return;

    final String next;
    if (auth.isAuthenticated) {
      next = auth.isStaff ? AppRouter.adminHome : AppRouter.home;
    } else {
      next = AppRouter.login;
    }
    Navigator.of(context).pushReplacementNamed(next);
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _particleCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Floating particles background
              AnimatedBuilder(
                animation: _particleCtrl,
                builder: (context, _) => CustomPaint(
                  painter: _ParticlePainter(progress: _particleCtrl.value),
                  child: const SizedBox.expand(),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Outer pulse ring
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (context, child) {
                        final scale = 1.0 + _pulseCtrl.value * 0.08;
                        return Container(
                          width: 130 * scale,
                          height: 130 * scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(
                              alpha: 0.07 * (1 - _pulseCtrl.value),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: child,
                        );
                      },
                      child: ScaleTransition(
                        scale: CurvedAnimation(
                          parent: _logoCtrl,
                          curve: Curves.elasticOut,
                        ),
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gradientStart.withValues(
                                  alpha: 0.40,
                                ),
                                blurRadius: 40,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Image.asset('assets/logo_transparant.png'),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Staggered text slides
                    SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _textCtrl,
                              curve: const Interval(
                                0.0,
                                0.6,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                          ),
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _textCtrl,
                          curve: const Interval(
                            0.0,
                            0.6,
                            curve: Curves.easeOut,
                          ),
                        ),
                        child: const Text(
                          'Labventory',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 0.4),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _textCtrl,
                              curve: const Interval(
                                0.2,
                                0.8,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                          ),
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _textCtrl,
                          curve: const Interval(
                            0.2,
                            0.8,
                            curve: Curves.easeOut,
                          ),
                        ),
                        child: const Text(
                          'Sistem peminjaman inventaris laboratorium kampus',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _textCtrl,
                        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                      ),
                      child: const _DotLoader(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Three-dot animated loader instead of a spinner
class _DotLoader extends StatefulWidget {
  const _DotLoader();
  @override
  State<_DotLoader> createState() => _DotLoaderState();
}

class _DotLoaderState extends State<_DotLoader> with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 3; i++) {
      final c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      // Stagger each dot
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) c.repeat(reverse: true);
      });
      _controllers.add(c);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (context, _) => Container(
            width: 8,
            height: 8 + _controllers[i].value * 6,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.5 + _controllers[i].value * 0.5,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

// Floating semi-transparent circles background
class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.progress});
  final double progress;

  static final _particles = List.generate(14, (i) {
    final rng = math.Random(i * 17 + 3);
    return _Particle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      r: 8 + rng.nextDouble() * 18,
      speed: 0.03 + rng.nextDouble() * 0.05,
      phase: rng.nextDouble(),
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in _particles) {
      final t = (progress + p.phase) % 1.0;
      final y = (p.y + t * p.speed) % 1.0;
      final x = p.x + math.sin((t + p.phase) * math.pi * 2) * 0.04;
      final alpha = 0.06 + math.sin(t * math.pi) * 0.06;
      paint.color = Colors.white.withValues(alpha: alpha.clamp(0, 1));
      canvas.drawCircle(Offset(x * size.width, y * size.height), p.r, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _Particle {
  const _Particle({
    required this.x,
    required this.y,
    required this.r,
    required this.speed,
    required this.phase,
  });
  final double x;
  final double y;
  final double r;
  final double speed;
  final double phase;
}
