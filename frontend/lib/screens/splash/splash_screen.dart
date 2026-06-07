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
  late final AnimationController _spinCtrl;
  late final AnimationController _enterCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _ringFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _textFade;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _loaderFade;

  String? _nextRoute;
  static const _minMs = 2000;

  @override
  void initState() {
    super.initState();

    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0.0, 0.28, curve: Curves.easeOut),
      ),
    );
    _ringFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0.22, 0.52, curve: Curves.easeOut),
      ),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _enterCtrl,
            curve: const Interval(0.42, 0.80, curve: Curves.easeOutCubic),
          ),
        );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0.42, 0.76, curve: Curves.easeOut),
      ),
    );
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0.58, 0.88, curve: Curves.easeOut),
      ),
    );
    _loaderFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0.76, 1.0, curve: Curves.easeOut),
      ),
    );

    _resolveWithMinDuration();
  }

  Future<void> _resolveWithMinDuration() async {
    await Future.wait([
      _computeNextRoute(),
      Future.delayed(const Duration(milliseconds: _minMs)),
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(_nextRoute!);
  }

  Future<void> _computeNextRoute() async {
    final auth = context.read<AuthProvider>();
    final onboardingDone = await OnboardingStorage.isDone();
    if (!mounted) return;
    if (!onboardingDone) {
      _nextRoute = AppRouter.onboarding;
      return;
    }
    await auth.bootstrap();
    if (!mounted) return;
    _nextRoute = auth.isAuthenticated
        ? (auth.isStaff ? AppRouter.adminHome : AppRouter.home)
        : AppRouter.login;
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _enterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF3730A3),
              AppColors.gradientStart,
              AppColors.gradientEnd,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SizedBox.expand(
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // ── Logo + spinning ring ────────────────────────
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: SizedBox(
                      // Outer SizedBox includes ring clearance
                      width: 260,
                      height: 260,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Spinning ring behind logo
                          FadeTransition(
                            opacity: _ringFade,
                            child: AnimatedBuilder(
                              animation: _spinCtrl,
                              builder: (_, w) => CustomPaint(
                                size: const Size(260, 260),
                                painter: _RingPainter(
                                  progress: _spinCtrl.value,
                                ),
                              ),
                            ),
                          ),

                          // Logo — using app_icon.png with built-in background
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(44),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.20),
                                  blurRadius: 32,
                                  offset: const Offset(0, 12),
                                ),
                                BoxShadow(
                                  color: AppColors.gradientEnd.withValues(
                                    alpha: 0.45,
                                  ),
                                  blurRadius: 56,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(44),
                              child: Image.asset(
                                'assets/app_icon.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // ── App name ──────────────────────────────────────
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: const Text(
                      'Labventory',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ── Subtitle ──────────────────────────────────────
                FadeTransition(
                  opacity: _subtitleFade,
                  child: Text(
                    'Sistem peminjaman inventaris\nlaboratorium kampus',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.55,
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // ── Loader ────────────────────────────────────────
                FadeTransition(
                  opacity: _loaderFade,
                  child: const _BouncingDots(),
                ),

                const SizedBox(height: 10),

                FadeTransition(
                  opacity: _loaderFade,
                  child: Text(
                    'Memuat...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.40),
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ring painter
// ─────────────────────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});
  final double progress;

  static final _trackPaint = Paint()
    ..color = const Color(0x18FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r1 = size.width / 2 - 5;
    final r2 = r1 - 18;
    final c = Offset(cx, cy);

    canvas.drawCircle(c, r1, _trackPaint);

    final outerRect = Rect.fromCircle(center: c, radius: r1);
    final outerPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.95),
        ],
      ).createShader(outerRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final a1 = progress * math.pi * 2 - math.pi / 2;
    const sweep1 = math.pi * 1.2;
    canvas.drawArc(outerRect, a1, sweep1, false, outerPaint);

    final dotX = cx + r1 * math.cos(a1 + sweep1);
    final dotY = cy + r1 * math.sin(a1 + sweep1);
    canvas.drawCircle(Offset(dotX, dotY), 4.5, Paint()..color = Colors.white);

    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final a2 = -progress * math.pi * 2 - math.pi / 2;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r2),
      a2,
      math.pi * 0.65,
      false,
      innerPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Bouncing dots
// ─────────────────────────────────────────────────────────────────────────────

class _BouncingDots extends StatefulWidget {
  const _BouncingDots();

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(3, (i) {
      final c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 580),
      );
      c.value = i / 3.0;
      c.repeat(reverse: true);
      return c;
    });
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrls[i],
          builder: (_, w) {
            final v = _ctrls[i].value;
            return Container(
              width: 8,
              height: 8 + v * 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.30 + v * 0.70),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          },
        );
      }),
    );
  }
}
