import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import '../provider/generalprovider.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/loadingoverlay.dart';
import '../utils/sharedpre.dart';
import '../webwidget/interactive_icon.dart';
import '../webwidget/webfooter.dart';
import '../widget/myimage.dart';
import '../widget/mytext.dart';
import '../utils/utils.dart';

class WebActiveTV extends StatefulWidget {
  final String? newPage, oldPage;
  final dynamic reqText;
  const WebActiveTV({
    required this.newPage,
    required this.oldPage,
    required this.reqText,
    super.key,
  });

  @override
  State<WebActiveTV> createState() => WebActiveTVState();
}

class WebActiveTVState extends State<WebActiveTV> {
  SharedPre sharePref = SharedPre();
  final pinPutController = TextEditingController();
  final ScrollController _mainScrollController = ScrollController();

  bool get _isDesktop => MediaQuery.of(context).size.width >= 800;
  double get _sw => MediaQuery.of(context).size.width;
  double get _sh => MediaQuery.of(context).size.height;

  double _formWidth() {
    if (_sw >= 1400) return _sw * 0.40;
    if (_sw >= 1080) return _sw * 0.45;
    if (_sw >= 800) return _sw * 0.50;
    return _sw;
  }

  double _pinCellSize(int count, double gap) {
    final double available = _formWidth() - 64 - (gap * (count - 1));
    return (available / count).clamp(44.0, 68.0);
  }

  Future<void> _scrollListener() async {
    if (_mainScrollController.offset >=
            _mainScrollController.position.maxScrollExtent &&
        !_mainScrollController.position.outOfRange) {
      setState(() {});
    }
    if (_mainScrollController.offset <=
            _mainScrollController.position.minScrollExtent &&
        !_mainScrollController.position.outOfRange) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _mainScrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    FocusManager.instance.primaryFocus?.unfocus();
    pinPutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      body: _isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(flex: 55, child: _buildLeftPanel()),
        SizedBox(width: _formWidth(), child: _buildRightPanel()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      controller: _mainScrollController,
      child: Column(
        children: [
          _buildRightPanel(),
          if (kIsWeb)
            WebFooter(
              newPage: widget.newPage,
              oldPage: widget.oldPage,
              reqText: '',
              onTypeClick: () {
                _mainScrollController.animateTo(
                  0,
                  duration: const Duration(seconds: 1),
                  curve: Curves.fastOutSlowIn,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return SizedBox(
      height: _sh,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MyImage(
            imagePath: "login_bg_land.png",
            fit: BoxFit.cover,
            width: double.infinity,
            height: _sh,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  black.withValues(alpha: 0.82),
                  black.withValues(alpha: 0.58),
                  black.withValues(alpha: 0.72),
                ],
                stops: const [0.0, 0.50, 1.0],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 40, 40, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  height: 48,
                  child: MyImage(fit: BoxFit.contain, imagePath: "appicon.png"),
                ),
                const Spacer(),
                MyText(
                  color: white,
                  text: "stream_live",
                  multilanguage: true,
                  fontsizeNormal: 34,
                  fontsizeWeb: 40,
                  fontweight: FontWeight.w800,
                  maxline: 1,
                  overflow: TextOverflow.clip,
                  textalign: TextAlign.start,
                  fontstyle: FontStyle.normal,
                ),
                MyText(
                  color: colorPrimary,
                  text: "scale_fast",
                  multilanguage: true,
                  fontsizeNormal: 34,
                  fontsizeWeb: 40,
                  fontweight: FontWeight.w800,
                  maxline: 1,
                  overflow: TextOverflow.clip,
                  textalign: TextAlign.start,
                  fontstyle: FontStyle.normal,
                ),
                const SizedBox(height: 14),
                MyText(
                  color: white.withValues(alpha: 0.60),
                  text: "auth_tagline_desc",
                  multilanguage: true,
                  fontsizeNormal: 12,
                  fontsizeWeb: 14,
                  fontweight: FontWeight.w400,
                  maxline: 3,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.start,
                  fontstyle: FontStyle.normal,
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _featureChip("feature_video", Icons.video_library_outlined),
                    _featureChip("feature_livestream", Icons.live_tv_rounded),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    _statItem("stat_value_24_7", "stat_uptime"),
                    _statDivider(),
                    _statItem("stat_value_hd", "stat_quality"),
                    _statDivider(),
                    _statItem("stat_value_infinity", "stat_streams"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureChip(String key, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: black.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: white.withValues(alpha: 0.20), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colorPrimary, size: 13),
          const SizedBox(width: 6),
          MyText(
            color: white.withValues(alpha: 0.85),
            text: key,
            multilanguage: true,
            fontsizeNormal: 11,
            fontsizeWeb: 12,
            fontweight: FontWeight.w500,
            maxline: 1,
            overflow: TextOverflow.ellipsis,
            textalign: TextAlign.start,
            fontstyle: FontStyle.normal,
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String key) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          MyText(
            color: colorPrimary,
            text: value,
            multilanguage: true,
            fontsizeNormal: 22,
            fontsizeWeb: 22,
            fontweight: FontWeight.w800,
            maxline: 1,
            overflow: TextOverflow.ellipsis,
            textalign: TextAlign.start,
            fontstyle: FontStyle.normal,
          ),
          const SizedBox(height: 2),
          MyText(
            color: white.withValues(alpha: 0.45),
            text: key,
            multilanguage: true,
            fontsizeNormal: 10,
            fontsizeWeb: 10,
            fontweight: FontWeight.w500,
            maxline: 1,
            overflow: TextOverflow.ellipsis,
            textalign: TextAlign.start,
            fontstyle: FontStyle.normal,
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: white.withValues(alpha: 0.14),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      height: _isDesktop ? _sh : null,
      color: authPanelBgColor,
      child: SingleChildScrollView(
        controller: _isDesktop ? null : _mainScrollController,
        padding: EdgeInsets.symmetric(
          horizontal: _isDesktop ? 48 : 24,
          vertical: _isDesktop ? 0 : 32,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: _isDesktop ? _sh : 0),
          child: IntrinsicHeight(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isDesktop) ...[
                  Center(
                    child: SizedBox(
                      width: 110,
                      height: 44,
                      child: MyImage(
                        fit: BoxFit.contain,
                        imagePath: "appicon.png",
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
                if (_isDesktop)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 32, bottom: 24),
                      child: _buildCloseButton(),
                    ),
                  ),
                _buildPageUI(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return InteractiveIcon(
      builder: (isHovered) {
        return InkWell(
          onTap: () {
            if (context.canPop()) context.pop();
          },
          borderRadius: BorderRadius.circular(20),
          focusColor: transparent,
          hoverColor: transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isHovered
                  ? white.withValues(alpha: 0.12)
                  : white.withValues(alpha: 0.06),
              border: Border.all(
                color: white.withValues(alpha: isHovered ? 0.22 : 0.10),
                width: 1,
              ),
            ),
            child: const Icon(Icons.close_rounded, color: white, size: 16),
          ),
        );
      },
    );
  }

  Widget _buildPageUI() {
    final double cell = _pinCellSize(4, 12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        /* App name + badge */
        Center(
          child: Column(
            children: [
              MyText(
                color: colorPrimary,
                text: Constant.appName,
                multilanguage: false,
                fontsizeNormal: 20,
                fontsizeWeb: 22,
                fontweight: FontWeight.w700,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
                textalign: TextAlign.center,
                fontstyle: FontStyle.normal,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: colorPrimary.withValues(alpha: 0.55),
                    width: 1,
                  ),
                ),
                child: MyText(
                  color: colorPrimary,
                  text: "app_tagline",
                  multilanguage: true,
                  fontsizeNormal: 9,
                  fontsizeWeb: 10,
                  fontweight: FontWeight.w600,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.center,
                  fontstyle: FontStyle.normal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        /* TV icon separator */
        Row(
          children: [
            Expanded(
              child: Container(height: 1, color: white.withValues(alpha: 0.08)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.tv_rounded, color: colorPrimary, size: 18),
            ),
            Expanded(
              child: Container(height: 1, color: white.withValues(alpha: 0.08)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        MyText(
          color: white,
          text: "verify_tvcode",
          multilanguage: true,
          fontsizeNormal: 20,
          fontsizeWeb: 22,
          fontweight: FontWeight.w700,
          maxline: 1,
          overflow: TextOverflow.ellipsis,
          textalign: TextAlign.start,
          fontstyle: FontStyle.normal,
        ),
        const SizedBox(height: 4),
        MyText(
          color: descTextColor,
          text: "tvcode_desc",
          fontsizeNormal: 12,
          fontsizeWeb: 13,
          fontweight: FontWeight.w400,
          maxline: 2,
          overflow: TextOverflow.ellipsis,
          textalign: TextAlign.start,
          multilanguage: true,
          fontstyle: FontStyle.normal,
        ),
        const SizedBox(height: 24),
        MyText(
          color: descTextColor,
          text: "tv_code_label",
          multilanguage: true,
          fontsizeNormal: 10,
          fontsizeWeb: 11,
          fontweight: FontWeight.w600,
          maxline: 1,
          overflow: TextOverflow.ellipsis,
          textalign: TextAlign.start,
          fontstyle: FontStyle.normal,
        ),
        const SizedBox(height: 10),
        Pinput(
          length: 4,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          controller: pinPutController,
          mainAxisAlignment: MainAxisAlignment.center,
          separatorBuilder: (i) => const SizedBox(width: 12),
          defaultPinTheme: PinTheme(
            width: cell,
            height: cell,
            decoration: BoxDecoration(
              color: white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: white.withValues(alpha: 0.10),
                width: 1,
              ),
            ),
            textStyle: kIsWeb
                ? TextStyle(
                    color: white,
                    fontSize: cell * 0.38,
                    fontWeight: FontWeight.w800,
                  )
                : GoogleFonts.inter(
                    color: white,
                    fontSize: cell * 0.38,
                    fontWeight: FontWeight.w800,
                  ),
          ),
          focusedPinTheme: PinTheme(
            width: cell,
            height: cell,
            decoration: BoxDecoration(
              color: colorPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorPrimary, width: 1.5),
            ),
            textStyle: kIsWeb
                ? TextStyle(
                    color: white,
                    fontSize: cell * 0.38,
                    fontWeight: FontWeight.w800,
                  )
                : GoogleFonts.inter(
                    color: white,
                    fontSize: cell * 0.38,
                    fontWeight: FontWeight.w800,
                  ),
          ),
          submittedPinTheme: PinTheme(
            width: cell,
            height: cell,
            decoration: BoxDecoration(
              color: colorPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorPrimary.withValues(alpha: 0.45),
                width: 1,
              ),
            ),
            textStyle: kIsWeb
                ? TextStyle(
                    color: white,
                    fontSize: cell * 0.38,
                    fontWeight: FontWeight.w800,
                  )
                : GoogleFonts.inter(
                    color: white,
                    fontSize: cell * 0.38,
                    fontWeight: FontWeight.w800,
                  ),
          ),
        ),
        const SizedBox(height: 28),
        InteractiveIcon(
          builder: (isHovered) {
            return InkWell(
              onTap: () {
                printLog("Clicked sms Code =====> ${pinPutController.text}");
                if (pinPutController.text.toString().isEmpty) {
                  Utils.showSnackbar(context, "info", "enter_tv_code", true);
                } else {
                  _checkAndLogin();
                }
              },
              focusColor: transparent,
              hoverColor: transparent,
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: isHovered
                      ? colorPrimary.withValues(alpha: 0.88)
                      : colorPrimary,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: MyText(
                  color: appBgColor,
                  text: "confirm",
                  fontsizeNormal: 15,
                  fontsizeWeb: 15,
                  multilanguage: true,
                  fontweight: FontWeight.w700,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.center,
                  fontstyle: FontStyle.normal,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _checkAndLogin() async {
    printLog("click on Submit mobile => ${pinPutController.text}");
    var generalProvider = Provider.of<GeneralProvider>(context, listen: false);
    LoadingOverlay().show(context);
    await generalProvider.loginWithTV(pinPutController.text.toString());

    if (!generalProvider.loading) {
      if (generalProvider.loginTVModel.status == 200) {
        printLog('Login Successfull!');
        if (!mounted) return;
        LoadingOverlay().hide();
        Utils.showToast("${generalProvider.loginTVModel.message}");
        if (context.canPop()) {
          context.pop();
        }
      } else {
        if (!mounted) return;
        LoadingOverlay().hide();
        Utils.showToast("${generalProvider.loginTVModel.message}");
      }
    }
  }
}
