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

const _lime = colorPrimary; // #BAFA34
const _cyan = colorPrimaryDark;
const _purple = complimentryColor; // #792BEC
const _red = colorAccent; // #EC2B4E
const _orange = warningBG;

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

  // ── Background (starts at 0ms) ─────────────────────────────────────────
  late AnimationController _bgCtrl; // 600ms one-shot
  late Animation<double> _bgFade;

  // ── Glow blobs (all loop forever) ──────────────────────────────────────
  late AnimationController _orbitCtrl; // 9000ms
  late AnimationController _pulse1; // 2400ms
  late AnimationController _pulse2; // 3000ms
  late AnimationController _pulse3; // 3600ms
  late Animation<double> _orbitAngle;
  late Animation<double> _p1s, _p1o;
  late Animation<double> _p2s, _p2o;
  late Animation<double> _p3s, _p3o;

  // ── Icon reveal (starts at 300ms, 700ms duration) ──────────────────────
  // opacity 0→1 + scale 0.88→1.0 — NO setState, pure controller
  late AnimationController _iconCtrl;
  late Animation<double> _iconOpacity;
  late Animation<double> _iconScale;

  // ── Shine sweep — fully controller-driven, no bool flag ────────────────
  // _shineOpCtrl fades the shine band in/out (no setState needed)
  // _shineProgCtrl sweeps the position left→right
  late AnimationController _shineOpCtrl; // 150ms one-shot (fade in)
  late AnimationController _shineProgCtrl; // 450ms one-shot (sweep)
  late AnimationController _shineOutCtrl; // 150ms one-shot (fade out)
  late Animation<double> _shineOpacity;
  late Animation<double> _shineProg;

  // ── Separator (starts at 1000ms, 550ms duration) ───────────────────────
  late AnimationController _sepCtrl;
  late Animation<double> _sepFade;
  late Animation<double> _sepLineScale;

  // ── Separator dot ring (loop, starts at 1200ms) ────────────────────────
  late AnimationController _dotRingCtrl;
  late Animation<double> _dotRingScale;
  late Animation<double> _dotRingOpacity;

  // ── Tagline (starts at 1200ms, 750ms duration) ────────────────────────
  late AnimationController _tagCtrl;
  late Animation<double> _tagOpacity;
  late Animation<Offset> _tagSlide;

  // ── Subtitle (starts at 1900ms, 550ms duration) ───────────────────────
  late AnimationController _subCtrl;
  late Animation<double> _subOpacity;

  // ── Late elements: stripe + dots + bar (starts at 2000ms, 450ms) ──────
  late AnimationController _lateCtrl;
  late Animation<double> _lateFade;

  // ── Dots bounce + colour wave (loop) ──────────────────────────────────
  late AnimationController _dotsCtrl; // 1100ms loop
  late AnimationController _waveCtrl; // 2000ms loop

  // ── Bottom progress strip shimmer (loop) ──────────────────────────────
  late AnimationController _stripCtrl; // 1800ms loop

  // ── Logo geometry — plain fields, no setState ─────────────────────────
  // AnimatedBuilder reads these on every tick, so no rebuild needed.
  Size _logoSize = Size.zero;
  Offset _logoOffset = Offset.zero;
  final GlobalKey _logoKey = GlobalKey();

  // ── Navigation ─────────────────────────────────────────────────────────
  bool _animDone = false;
  bool _dataDone = false;
  Widget? _nextPage;

  // ──────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _gen = Provider.of<GeneralProvider>(context, listen: false);
    _home = Provider.of<HomeProvider>(context, listen: false);
    _conn = Provider.of<ConnectivityProvider>(context, listen: false);

    _createControllers();
    _startSequence();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readLogoGeometry();
      _fetchData();
    });
  }

  // Reads logo rect without setState — AnimatedBuilder picks it up on next tick
  void _readLogoGeometry() {
    final box = _logoKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    _logoSize = box.size;
    _logoOffset = box.localToGlobal(Offset.zero);
  }

  // ── Controller factory ────────────────────────────────────────────────
  void _createControllers() {
    // Background
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bgFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _bgCtrl, curve: Curves.easeOut));

    // Orbit
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
    );
    _orbitAngle = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(parent: _orbitCtrl, curve: Curves.linear));

    _pulse1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _p1s = Tween<double>(
      begin: .80,
      end: 1.24,
    ).animate(CurvedAnimation(parent: _pulse1, curve: Curves.easeInOut));
    _p1o = Tween<double>(
      begin: .17,
      end: .52,
    ).animate(CurvedAnimation(parent: _pulse1, curve: Curves.easeInOut));

    _pulse2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _p2s = Tween<double>(
      begin: .86,
      end: 1.30,
    ).animate(CurvedAnimation(parent: _pulse2, curve: Curves.easeInOut));
    _p2o = Tween<double>(
      begin: .13,
      end: .46,
    ).animate(CurvedAnimation(parent: _pulse2, curve: Curves.easeInOut));

    _pulse3 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    _p3s = Tween<double>(
      begin: .76,
      end: 1.20,
    ).animate(CurvedAnimation(parent: _pulse3, curve: Curves.easeInOut));
    _p3o = Tween<double>(
      begin: .11,
      end: .40,
    ).animate(CurvedAnimation(parent: _pulse3, curve: Curves.easeInOut));

    // Icon
    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _iconOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _iconCtrl,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );
    _iconScale = Tween<double>(begin: .88, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconCtrl,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Shine — 3 separate controllers, no bool flag
    _shineOpCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _shineOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _shineOpCtrl, curve: Curves.easeIn));

    _shineProgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shineProg = Tween<double>(
      begin: -.38,
      end: 1.38,
    ).animate(CurvedAnimation(parent: _shineProgCtrl, curve: Curves.easeInOut));

    _shineOutCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    // Separator
    _sepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _sepFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _sepCtrl, curve: Curves.easeOut));
    _sepLineScale = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _sepCtrl, curve: Curves.easeOut));

    // Dot ring (loop)
    _dotRingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _dotRingScale = Tween<double>(
      begin: 1.0,
      end: 2.6,
    ).animate(CurvedAnimation(parent: _dotRingCtrl, curve: Curves.easeOut));
    _dotRingOpacity = Tween<double>(
      begin: .70,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _dotRingCtrl, curve: Curves.easeOut));

    // Tagline
    _tagCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _tagOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _tagCtrl, curve: Curves.easeOut));
    _tagSlide = Tween<Offset>(
      begin: const Offset(0, .14),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _tagCtrl, curve: Curves.easeOutCubic));

    // Subtitle
    _subCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _subOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _subCtrl, curve: Curves.easeOut));

    // Late elements
    _lateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _lateFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _lateCtrl, curve: Curves.easeOut));

    // Dots + wave
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Strip
    _stripCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  // ── Sequence — all via Future.delayed, zero setState ─────────────────
  void _startSequence() {
    // 0 ms — BG + blobs
    _bgCtrl.forward();
    _orbitCtrl.repeat();
    _pulse1.repeat(reverse: true);
    _pulse2.repeat(reverse: true);
    _pulse3.repeat(reverse: true);
    _dotsCtrl.repeat();
    _waveCtrl.repeat();
    _stripCtrl.repeat();

    // 300 ms — icon fades + scales in
    _at(300, _iconCtrl.forward);

    // 600 ms — shine fade-in, then sweep, then fade-out
    // All chained via whenComplete — no setState, no bool
    _at(600, () {
      _shineOpCtrl.forward().whenComplete(() {
        _shineProgCtrl.forward().whenComplete(() {
          _shineOutCtrl.forward();
        });
      });
    });

    // 1 000 ms — separator lines sweep in
    _at(1000, () {
      _sepCtrl.forward();
      _dotRingCtrl.repeat();
    });

    // 1 200 ms — tagline slides up
    _at(1200, _tagCtrl.forward);

    // 1 900 ms — subtitle fades in
    _at(1900, _subCtrl.forward);

    // 2 000 ms — stripe + dots + bar
    _at(2000, _lateCtrl.forward);

    // 3 500 ms — minimum splash duration, mark animation complete
    // This guarantees ALL animations finish before navigation fires
    _at(3500, () {
      _animDone = true;
      _tryNavigate();
    });
  }

  void _at(int ms, VoidCallback fn) {
    Future.delayed(Duration(milliseconds: ms), () {
      if (mounted) fn();
    });
  }

  // ── Data ──────────────────────────────────────────────────────────────
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

  // Gate: both flags AND minimum splash time must pass
  void _tryNavigate() {
    if (!_animDone || !_dataDone || !mounted || _nextPage == null) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => _nextPage!,
        transitionDuration: const Duration(milliseconds: _kNavFadeMs),
        transitionsBuilder: (_, a, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _orbitCtrl.dispose();
    _pulse1.dispose();
    _pulse2.dispose();
    _pulse3.dispose();
    _iconCtrl.dispose();
    _shineOpCtrl.dispose();
    _shineProgCtrl.dispose();
    _shineOutCtrl.dispose();
    _sepCtrl.dispose();
    _dotRingCtrl.dispose();
    _tagCtrl.dispose();
    _subCtrl.dispose();
    _lateCtrl.dispose();
    _dotsCtrl.dispose();
    _waveCtrl.dispose();
    _stripCtrl.dispose();
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
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _bgCtrl,
          _orbitCtrl,
          _pulse1,
          _pulse2,
          _pulse3,
          _iconCtrl,
          _shineOpCtrl,
          _shineProgCtrl,
          _shineOutCtrl,
          _sepCtrl,
          _dotRingCtrl,
          _tagCtrl,
          _subCtrl,
          _lateCtrl,
          _dotsCtrl,
          _waveCtrl,
          _stripCtrl,
        ]),
        builder: (_, _) {
          // Refresh logo geometry on every frame (no setState needed)
          _readLogoGeometry();

          // Resolved shine opacity = fade-in value × fade-out value
          final shineAlpha =
              _shineOpacity.value * (1.0 - _shineOutCtrl.value).clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1 — Background
              _buildBg(),

              // 2 — Rotating glow blobs
              _buildBlobs(size),

              // 3 — Shine overlay (always in tree, opacity drives visibility)
              if (_logoSize != Size.zero && shineAlpha > 0.0)
                _buildShine(shineAlpha),

              // 4 — Content column
              _buildContent(size),

              // 5 — Top brand stripe
              Positioned(top: 0, left: 0, right: 0, child: _buildStripe()),

              // 6 — Bottom progress strip
              Positioned(bottom: 0, left: 0, right: 0, child: _buildStripe()),

              // 7 — Version label
              Positioned(
                bottom: size.height * .022,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _lateFade.value.clamp(0, 1),
                  child: MyText(
                    text: 'v1.0.0',
                    color: titleTextColor.withValues(alpha: .16),
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
          );
        },
      ),
    );
  }

  // ── Background ──────────────────────────────────────────────────────────
  Widget _buildBg() => Opacity(
    opacity: _bgFade.value,
    child: Container(color: appBgColor),
  );

  // ── Glow blobs ──────────────────────────────────────────────────────────
  Widget _buildBlobs(Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.36;
    final a = _orbitAngle.value;
    final b3 = Color.lerp(_cyan, _orange, _pulse1.value)!;

    return Opacity(
      opacity: _bgFade.value,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _blob(
            cx + r * math.cos(a),
            cy + r * .40 * math.sin(a),
            size.width * .80,
            _lime,
            _p1s.value,
            _p1o.value,
          ),
          _blob(
            cx + r * math.cos(a + 2.094),
            cy + r * .40 * math.sin(a + 2.094),
            size.width * .72,
            _purple,
            _p2s.value,
            _p2o.value,
          ),
          _blob(
            cx + r * math.cos(a + 4.189),
            cy + r * .40 * math.sin(a + 4.189),
            size.width * .66,
            b3,
            _p3s.value,
            _p3o.value,
          ),
          // Dark radial vignette — keeps centre readable
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: .86,
                colors: [
                  transparent,
                  black.withValues(alpha: 0.80),
                  black.withValues(alpha: 0.97),
                ],
                stops: [.24, .60, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(
    double cx,
    double cy,
    double sz,
    Color color,
    double scale,
    double opacity,
  ) {
    final s = sz * scale;
    return Positioned(
      left: cx - s / 2,
      top: cy - s / 2,
      width: s,
      height: s,
      child: Opacity(
        opacity: opacity,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: .50),
                color.withValues(alpha: .13),
                transparent, // [TASK-1]
              ],
              stops: const [0.0, .45, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  // ── Shine sweep — opacity driven, no bool ──────────────────────────────
  Widget _buildShine(double opacity) => Positioned(
    left: _logoOffset.dx,
    top: _logoOffset.dy,
    width: _logoSize.width,
    height: _logoSize.height,
    child: ClipRect(
      child: Opacity(
        opacity: opacity.clamp(0, 1),
        child: CustomPaint(painter: _ShinePainter(progress: _shineProg.value)),
      ),
    ),
  );

  // ── Brand stripe ────────────────────────────────────────────────────────
  Widget _buildStripe() => Opacity(
    opacity: _lateFade.value.clamp(0, 1),
    child: Container(
      height: 2,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [transparent, _lime, _cyan, transparent], // [TASK-1]
          stops: [0.0, .38, .62, 1.0],
        ),
      ),
    ),
  );

  // ── Content column ──────────────────────────────────────────────────────
  Widget _buildContent(Size size) {
    final logoW = size.width * 0.62;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── App Icon — opacity + scale, no jumps, no burst ─────────
        Opacity(
          opacity: _iconOpacity.value.clamp(0, 1),
          child: Transform.scale(
            scale: _iconScale.value,
            child: SizedBox(
              key: _logoKey,
              width: logoW,
              child: MyImage(
                imagePath: (kIsWeb || Constant.isTV)
                    ? 'appicon.png'
                    : 'appicon.png',
                width: logoW,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        SizedBox(height: size.height * .052),

        // ── Separator ──────────────────────────────────────────────
        Opacity(
          opacity: _sepFade.value.clamp(0, 1),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Left line — sweeps from centre outward
              Transform.scale(
                scaleX: _sepLineScale.value,
                alignment: Alignment.centerRight,
                child: Container(
                  width: size.width * .22,
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [transparent, _lime], // [TASK-1]
                    ),
                  ),
                ),
              ),

              // Pulsing dot with expanding ring
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Expanding ring
                      Transform.scale(
                        scale: _dotRingScale.value,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _lime.withValues(
                                alpha: _dotRingOpacity.value.clamp(0, 1),
                              ),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      // Solid lime dot
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _lime,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Right line
              Transform.scale(
                scaleX: _sepLineScale.value,
                alignment: Alignment.centerLeft,
                child: Container(
                  width: size.width * .22,
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_lime, transparent], // [TASK-1]
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: size.height * .030),

        // ── Tagline ────────────────────────────────────────────────
        FadeTransition(
          opacity: _tagOpacity,
          child: SlideTransition(
            position: _tagSlide,
            child: _buildTagline(size),
          ),
        ),

        SizedBox(height: size.height * .018),

        // ── Subtitle ───────────────────────────────────────────────
        FadeTransition(
          opacity: _subOpacity,
          child: MyText(
            text: 'Unlimited Entertainment Awaits',
            color: titleTextColor.withValues(alpha: .36),
            fontsizeNormal: 11,
            fontsizeWeb: 12,
            fontweight: FontWeight.w400,
            letterSpacing: 3.0,
            maxline: 1,
            multilanguage: false,
            overflow: TextOverflow.ellipsis,
            textalign: TextAlign.center,
            fontstyle: FontStyle.normal,
          ),
        ),

        SizedBox(height: size.height * .060),

        // ── Loading dots ───────────────────────────────────────────
        Opacity(opacity: _lateFade.value.clamp(0, 1), child: _buildDots()),
      ],
    );
  }

  // ── Tagline ─────────────────────────────────────────────────────────────
  Widget _buildTagline(Size size) {
    final fs = size.width * .062;
    return Column(
      children: [
        _tagLine('Stream ', 'Everything.', fs),
        _tagLine('Miss ', 'Nothing.', fs),
      ],
    );
  }

  Widget _tagLine(String plain, String grad, double fontSize) => RichText(
    textAlign: TextAlign.center,
    text: TextSpan(
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: -.3,
        height: 1.22,
      ),
      children: [
        TextSpan(
          text: plain,
          style: const TextStyle(color: white), // [TASK-1]
        ),
        WidgetSpan(
          child: ShaderMask(
            shaderCallback: (b) =>
                const LinearGradient(colors: [_lime, _cyan]).createShader(b),
            child: Text(
              grad,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                letterSpacing: -.3,
                height: 1.22,
                color: white, // [TASK-1]
              ),
            ),
          ),
        ),
      ],
    ),
  );

  // ── Colour-cycling bounce dots ──────────────────────────────────────────
  Widget _buildDots() {
    const phases = [.00, .20, .40, .60, .80];
    const palette = [_lime, _cyan, _purple, _red, _orange];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        return AnimatedBuilder(
          animation: Listenable.merge([_dotsCtrl, _waveCtrl]),
          builder: (_, _) {
            final t = math.sin(((_dotsCtrl.value + phases[i]) % 1.0) * math.pi);
            final ct = (_waveCtrl.value + i * .20) % 1.0;
            final ci = (ct * palette.length).floor();
            final cf = ct * palette.length - ci;
            final col = Color.lerp(
              palette[ci % palette.length],
              palette[(ci + 1) % palette.length],
              cf,
            )!;
            return Container(
              width: 8,
              height: 8 + 13.0 * t,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: col.withValues(alpha: .42 + .58 * t),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          },
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shine painter — diagonal light band sweeping left → right
// ─────────────────────────────────────────────────────────────────────────────
class _ShinePainter extends CustomPainter {
  final double progress; // -0.38 → 1.38
  const _ShinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const bw = 0.26;
    final cx = size.width * progress;
    final skew = size.height * 0.36;

    final path = Path()
      ..moveTo(cx - size.width * bw / 2 - skew, 0)
      ..lineTo(cx + size.width * bw / 2 - skew, 0)
      ..lineTo(cx + size.width * bw / 2 + skew, size.height)
      ..lineTo(cx - size.width * bw / 2 + skew, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader =
            LinearGradient(
              colors: [
                white.withValues(alpha: 0), // [TASK-1]
                white.withValues(alpha: 0.40), // [TASK-1]
                white.withValues(alpha: 0.60), // [TASK-1]
                white.withValues(alpha: 0.40), // [TASK-1]
                white.withValues(alpha: 0), // [TASK-1]
              ],
              stops: const [0.0, .35, .50, .65, 1.0],
            ).createShader(
              Rect.fromLTWH(
                cx - size.width * bw / 2,
                0,
                size.width * bw,
                size.height,
              ),
            ),
    );
  }

  @override
  bool shouldRepaint(_ShinePainter o) => o.progress != progress;
}
