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

    // 2500ms: Minimum splash duration reached, allow smooth exit
    _delayed(2500, () {
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
    } else if (intro != '1' || seen == '1') {
      _nextPage = const Bottombar();
    } else {
      _nextPage = has ? const Intro() : const Bottombar();
    }

    _dataDone = true;
    _tryNavigate();
  }

  void _tryNavigate() {
    if (!_animDone || !_dataDone || !mounted || _nextPage == null) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: _kNavFadeMs),
        pageBuilder: (context, animation, secondaryAnimation) => _nextPage!,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
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
    final size = MediaQuery.sizeOf(context);
    final bool isTablet = size.shortestSide >= 600 || size.width >= 600;

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
            child: _buildEqualizer(isTablet),
          ),

          // Fase 2: Clean Logo with Ambient Glow and Laser Sweep (adaptive for phone & tablet, matches web)
          Center(
            child: _buildStage(size, isTablet),
          ),
        ],
      ),
    );
  }

  // ── Fase 1: Equalizer ─────────────────────────────────────────────────
  Widget _buildEqualizer(bool isTablet) {
    final double barWidth = isTablet ? 5.0 : 3.8;
    final double barGap = isTablet ? 3.5 : 2.2;
    final double maxBarHeight = isTablet ? 72.0 : 52.0;
    final double minBarHeight = isTablet ? 14.0 : 10.0;

    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _eqFadeCtrl, curve: Curves.easeInOut),
      ),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.85).animate(
          CurvedAnimation(parent: _eqFadeCtrl, curve: Curves.easeInOut),
        ),
        child: SizedBox(
          height: isTablet ? 140 : 100,
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
                  final double h = (minBarHeight +
                          (maxBarHeight * centerFactor - minBarHeight) * wave)
                      .clamp(minBarHeight, maxBarHeight);

                  return Container(
                    width: barWidth,
                    height: h,
                    margin: EdgeInsets.symmetric(horizontal: barGap),
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

  // ── Fase 2: Clean Stage (Logo + Laser + Ambient Glow) ───────────────────
  Widget _buildStage(Size size, bool isTablet) {
    // Adaptive sizing: on tablets use proportional optimal bounds so it doesn't look too small or stretched
    final double logoW = isTablet
        ? (size.width * 0.42).clamp(320.0, 520.0)
        : (size.width * 0.66).clamp(180.0, 300.0);
    final double logoH = logoW * (308.0 / 1200.0); // exact 1200x308 aspect ratio

    return FadeTransition(
      opacity: CurvedAnimation(parent: _stageCtrl, curve: Curves.easeOut),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Radial Ambient Glow behind logo
          IgnorePointer(
            child: Container(
              width: logoW * 1.55,
              height: logoH * 2.6,
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
          ),

          // Nexstream Logo Image with bounded Laser Sweep
          SizedBox(
            width: logoW,
            height: logoH,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                MyImage(
                  imagePath: 'appicon.png',
                  width: logoW,
                  height: logoH,
                  fit: BoxFit.contain,
                ),
                _buildLaser(logoW, logoH, isTablet),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Fase 2: Neon Laser Scanner Beam ───────────────────────────────────
  Widget _buildLaser(double logoW, double logoH, bool isTablet) {
    final double beamWidth = isTablet ? 4.5 : 3.5;

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
          left: x,
          top: -logoH * 0.15,
          bottom: -logoH * 0.15,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Container(
              width: beamWidth,
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
}
