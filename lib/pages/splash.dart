import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../pages/bottombar.dart';
import '../pages/intro.dart';
import '../provider/connectivityprovider.dart';
import '../provider/generalprovider.dart';
import '../provider/homeprovider.dart';
import '../routes/routes_constant.dart';
import '../webpages/webhome.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/utils.dart';
import '../widget/myimage.dart';
import '../widget/mytext.dart';
import '../utils/sharedpre.dart';

const _kNavFadeMs = 500;

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with TickerProviderStateMixin {
  // ── Providers ──────────────────────────────────────────────────────────
  late GeneralProvider _gen;
  late ConnectivityProvider _conn;
  late HomeProvider _home;
  final SharedPre _prefs = SharedPre();

  // ── Phase 1: Equalizer Controllers ────────────────────────────────────
  late AnimationController _eqCtrl; // continuous audio oscillation
  late AnimationController _eqFadeCtrl; // fade-out & scale down at 800ms

  // ── Phase 2: Stage & Laser Controllers ────────────────────────────────
  late AnimationController _stageCtrl; // reveals stage at 950ms
  late AnimationController _laserCtrl; // sweeps across logo

  // ── Phase 3 & 4: Radar, Taglines & Subtitle Controllers ───────────────
  late AnimationController _radarCtrl; // concentric expanding pulse rings
  late AnimationController _tag1Ctrl; // Line 1: Stream Everything.
  late AnimationController _tag2Ctrl; // Line 2: Miss Nothing.
  late AnimationController _subCtrl; // Subtitle: Unlimited Entertainment Awaits

  // ── Navigation Gate ───────────────────────────────────────────────────
  bool _animDone = false;
  bool _dataDone = false;
  Widget? _nextPage;

  @override
  void initState() {
    super.initState();
    _gen = Provider.of<GeneralProvider>(context, listen: false);
    _home = Provider.of<HomeProvider>(context, listen: false);
    _conn = Provider.of<ConnectivityProvider>(context, listen: false);

    _initControllers();
    _startTimeline();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _initControllers() {
    // Phase 1: Equalizer continuous wave loop (1000ms cycle)
    _eqCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Phase 1 -> 2: Equalizer fade-out (350ms duration)
    _eqFadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    // Phase 2: Stage reveal fade-in (450ms duration)
    _stageCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    // Phase 2: Laser horizontal sweep (850ms duration)
    _laserCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    // Phase 3 & 4: Radar concentric rings (2800ms repeating loop)
    _radarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // Phase 3: Tagline 1 reveal (600ms duration)
    _tag1Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Phase 4: Tagline 2 reveal (600ms duration)
    _tag2Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Phase 4: Subtitle reveal (600ms duration)
    _subCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  void _startTimeline() {
    // 0ms: Equalizer starts dancing immediately
    _eqCtrl.repeat();

    // 800ms: Equalizer fades out
    _delayed(800, () {
      _eqFadeCtrl.forward();
    });

    // 950ms: Stage reveals, laser sweeps across logo
    _delayed(950, () {
      _stageCtrl.forward();
      _laserCtrl.forward();
    });

    // 1500ms: Radar rings pulse, Tagline 1 appears
    _delayed(1500, () {
      _radarCtrl.repeat();
      _tag1Ctrl.forward();
    });

    // 2000ms: Tagline 2 appears
    _delayed(2000, () {
      _tag2Ctrl.forward();
    });

    // 2400ms: Subtitle appears
    _delayed(2400, () {
      _subCtrl.forward();
    });

    // 3400ms: Minimum splash duration reached, allow smooth exit
    _delayed(3400, () {
      _animDone = true;
      _tryNavigate();
    });
  }

  void _delayed(int ms, VoidCallback callback) {
    Future.delayed(Duration(milliseconds: ms), () {
      if (mounted) callback();
    });
  }

  // ── Data Loading ───────────────────────────────────────────────────────
  Future<void> _fetchData() async {
    if (_conn.isOnline) await _gen.getGeneralsetting(context);
    if (!mounted) return;
    _resolveNextPage();
  }

  Future<void> _resolveNextPage() async {
    if (!mounted) return;
    await _home.setLoading(true);

    final intro = await Utils.configByStatus(
      status: Constant.introScreenStatus,
    );
    final seen = await _prefs.read('seen') ?? '0';
    final has = _gen.introScreenModel.result?.isNotEmpty ?? false;

    if (kIsWeb || Constant.isTV) {
      _nextPage = const WebHome(
        newPage: RoutesConstant.homePage,
        oldPage: RoutesConstant.homePage,
        reqText: '',
      );
    } else if (intro != '1') {
      _nextPage = const Bottombar();
    } else if (seen == '1') {
      _nextPage = const Bottombar();
    } else {
      _nextPage = has ? const Intro() : const Bottombar();
    }

    _dataDone = true;
    _tryNavigate();
  }

  // Gate: both data and minimum splash animation sequence must be complete
  void _tryNavigate() {
    if (!_animDone || !_dataDone || !mounted || _nextPage == null) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => _nextPage!,
        transitionDuration: const Duration(milliseconds: _kNavFadeMs),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _eqCtrl.dispose();
    _eqFadeCtrl.dispose();
    _stageCtrl.dispose();
    _laserCtrl.dispose();
    _radarCtrl.dispose();
    _tag1Ctrl.dispose();
    _tag2Ctrl.dispose();
    _subCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: appBgColor,
      body: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          // Ambient Dark Vignette Background
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.9,
                colors: [
                  const Color(0xFF0A1923).withValues(alpha: 0.65),
                  appBgColor,
                ],
                stops: const [0.0, 0.70],
              ),
            ),
          ),

          // Fase 1: Audio Equalizer / Soundwave (centered)
          Center(
            child: _buildEqualizer(),
          ),

          // Fase 2, 3, 4: Stage Container with Radar, Logo, Laser, and Taglines
          Center(
            child: _buildStage(size),
          ),

          // Version label at bottom
          Positioned(
            bottom: size.height * 0.03,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.22,
              child: MyText(
                text: 'v${Constant.appVersion.isNotEmpty ? Constant.appVersion : "2.1.0"}',
                color: titleTextColor,
                fontsizeNormal: 10,
                fontsizeWeb: 11,
                fontweight: FontWeight.w400,
                letterSpacing: 1.6,
                maxline: 1,
                multilanguage: false,
                overflow: TextOverflow.ellipsis,
                textalign: TextAlign.center,
                fontstyle: FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Fase 1: Equalizer ─────────────────────────────────────────────────
  Widget _buildEqualizer() {
    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _eqFadeCtrl, curve: Curves.easeInOut),
      ),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.85).animate(
          CurvedAnimation(parent: _eqFadeCtrl, curve: Curves.easeInOut),
        ),
        child: SizedBox(
          height: 100,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(21, (index) {
              return AnimatedBuilder(
                animation: _eqCtrl,
                builder: (context, child) {
                  final double t = _eqCtrl.value * 2 * math.pi;
                  // Center bars are taller, edge bars shorter
                  final double dist = (index - 10).abs() / 10.0;
                  final double centerFactor = 1.0 - (dist * 0.42);
                  final double freq = 1.2 + (index % 4) * 0.35;
                  final double phase = index * 0.65;
                  final double wave = 0.5 + 0.5 * math.sin(t * freq + phase);
                  final double h =
                      (10.0 + (48.0 * centerFactor - 10.0) * wave).clamp(8.0, 52.0);

                  return Container(
                    width: 3.8,
                    height: h,
                    margin: const EdgeInsets.symmetric(horizontal: 2.2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF00E5FF),
                          Color(0xFF10B981),
                          Color(0xFFBAFA34),
                        ],
                        stops: [0.0, 0.55, 1.0],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ),
    );
  }

  // ── Fase 2, 3, 4: Stage ────────────────────────────────────────────────
  Widget _buildStage(Size size) {
    final double logoW = (size.width * 0.64).clamp(180.0, 270.0);
    final double logoH = logoW * 0.32;

    return FadeTransition(
      opacity: CurvedAnimation(parent: _stageCtrl, curve: Curves.easeOut),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo Area with Ambient Glow, Radar Rings, and Laser Scanner
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Radial Ambient Glow
              Container(
                width: logoW * 1.45,
                height: logoH * 2.2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00E5FF).withValues(alpha: 0.18),
                      const Color(0xFFBAFA34).withValues(alpha: 0.12),
                      transparent,
                    ],
                    stops: const [0.0, 0.45, 0.72],
                  ),
                ),
              ),

              // Fase 3: Concentric Radar Rings
              SizedBox(
                width: logoW * 1.5,
                height: logoW * 1.5,
                child: AnimatedBuilder(
                  animation: _radarCtrl,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _RadarPainter(progress: _radarCtrl.value),
                    );
                  },
                ),
              ),

              // Nexstream Logo Image
              SizedBox(
                width: logoW,
                height: logoH,
                child: MyImage(
                  imagePath: 'appicon.png',
                  width: logoW,
                  fit: BoxFit.contain,
                ),
              ),

              // Fase 2: Neon Laser Sweep Scanner
              _buildLaser(logoW, logoH),
            ],
          ),

          SizedBox(height: (size.height * 0.04).clamp(18.0, 32.0)),

          // Fase 3 & 4: Taglines & Subtitle
          _buildTaglines(size),
        ],
      ),
    );
  }

  // ── Fase 2: Neon Laser Scanner Beam ───────────────────────────────────
  Widget _buildLaser(double logoW, double logoH) {
    return AnimatedBuilder(
      animation: _laserCtrl,
      builder: (context, child) {
        if (_laserCtrl.value == 0.0 || _laserCtrl.value == 1.0) {
          return const SizedBox.shrink();
        }
        final double x = -0.15 * logoW + (1.30 * logoW) * _laserCtrl.value;
        final double opacity = (_laserCtrl.value < 0.10)
            ? (_laserCtrl.value / 0.10)
            : (_laserCtrl.value > 0.88)
                ? ((1.0 - _laserCtrl.value) / 0.12).clamp(0.0, 1.0)
                : 1.0;

        return Positioned(
          left: (logoW * 0.25) + x - (logoW * 0.25),
          top: -10,
          bottom: -10,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Container(
              width: 3.5,
              decoration: BoxDecoration(
                color: const Color(0xFFBAFA34),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  const BoxShadow(
                    color: Color(0xFFBAFA34),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.85),
                    blurRadius: 22,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Fase 3 & 4: Taglines ──────────────────────────────────────────────
  Widget _buildTaglines(Size size) {
    final double fs = (size.width * 0.065).clamp(20.0, 30.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Line 1: Stream Everything.
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.35),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: _tag1Ctrl, curve: Curves.easeOutCubic)),
          child: FadeTransition(
            opacity: _tag1Ctrl,
            child: _buildRichTagline('Stream ', 'Everything.', fs),
          ),
        ),
        const SizedBox(height: 4),

        // Line 2: Miss Nothing.
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.35),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: _tag2Ctrl, curve: Curves.easeOutCubic)),
          child: FadeTransition(
            opacity: _tag2Ctrl,
            child: _buildRichTagline('Miss ', 'Nothing.', fs),
          ),
        ),
        const SizedBox(height: 14),

        // Subtitle: UNLIMITED ENTERTAINMENT AWAITS
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.40),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: _subCtrl, curve: Curves.easeOutCubic)),
          child: FadeTransition(
            opacity: _subCtrl,
            child: Text(
              'UNLIMITED ENTERTAINMENT AWAITS',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF8FA0B5).withValues(alpha: 0.85),
                fontSize: (size.width * 0.026).clamp(10.0, 12.5),
                fontWeight: FontWeight.w600,
                letterSpacing: 2.6,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRichTagline(String plain, String neon, double fontSize) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          height: 1.25,
        ),
        children: [
          TextSpan(
            text: plain,
            style: const TextStyle(color: white),
          ),
          TextSpan(
            text: neon,
            style: TextStyle(
              color: const Color(0xFFBAFA34),
              shadows: [
                Shadow(
                  color: const Color(0xFFBAFA34).withValues(alpha: 0.65),
                  blurRadius: 18,
                ),
                Shadow(
                  color: const Color(0xFFBAFA34).withValues(alpha: 0.25),
                  blurRadius: 36,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fase 3 & 4: Concentric Radar Rings Painter
// ─────────────────────────────────────────────────────────────────────────────
class _RadarPainter extends CustomPainter {
  final double progress; // 0.0 -> 1.0 loop
  _RadarPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.70;

    for (int i = 0; i < 3; i++) {
      final double p = (progress + (i * 0.333)) % 1.0;
      final double currentRadius = maxRadius * (0.22 + 0.78 * p);
      final double alpha = (1.0 - p).clamp(0.0, 0.75);

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Color.lerp(
          const Color(0xFF00E5FF),
          const Color(0xFFBAFA34),
          p,
        )!.withValues(alpha: alpha);

      canvas.drawCircle(center, currentRadius, paint);
    }
  }

  @override
  bool shouldRepaint(_RadarPainter oldDelegate) => oldDelegate.progress != progress;
}
