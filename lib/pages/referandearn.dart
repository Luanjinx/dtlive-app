import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/bi.dart';
import 'package:iconify_flutter/icons/eva.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:provider/provider.dart';

import '../provider/profileprovider.dart';
import '../routes/routes_constant.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/dimens.dart';
import '../utils/utils.dart';
import '../webpages/webcomman.dart';
import '../widget/myimage.dart';
import '../widget/mytext.dart';

class ReferEarn extends StatefulWidget {
  const ReferEarn({super.key});

  @override
  State<ReferEarn> createState() => _ReferEarnState();
}

class _ReferEarnState extends State<ReferEarn> {
  late ProfileProvider profileProvider;

  @override
  void initState() {
    super.initState();
    profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (Constant.userID == null) return;
    await profileProvider.getProfile(context);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return WebComman(
        newPage: RoutesConstant.referEarnPage,
        oldPage: RoutesConstant.homePage,
        reqText: '',
        newChild: _buildBody(),
      );
    }
    return Scaffold(backgroundColor: appBgColor, body: _buildBody());
  }

  Widget _buildBody() {
    return Consumer<ProfileProvider>(
      builder: (context, profileProv, _) {
        if (profileProv.loading) {
          return Center(child: Utils.pageLoader());
        }
        final resultList = profileProv.profileModel.result;
        final code = (resultList != null && resultList.isNotEmpty)
            ? (resultList[0].referenceCode ?? "")
            : "";
        return Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: .center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorPrimary.withValues(alpha: 0.8),
                            colorPrimary,
                            colorPrimary,
                            colorPrimary.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: SafeArea(
                        child: SizedBox(
                          width: (Dimens.isWeb(context))
                              ? (MediaQuery.of(context).size.width * 0.5)
                              : (Dimens.isTablet(context)
                                    ? (MediaQuery.of(context).size.width * 0.7)
                                    : MediaQuery.of(context).size.width),
                          child: Column(
                            children: [
                              if (kIsWeb)
                                SizedBox(height: Dimens.homeTabHeight + 30)
                              else
                                SizedBox(height: kToolbarHeight),
                              _buildIllustration(context),
                              const SizedBox(height: 16),
                              _buildDescription(),
                              const SizedBox(height: 22),
                              _buildCodeCard(code),
                              const SizedBox(height: 26),
                              _buildSocialShareSection(code),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    _buildHowItWorks(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            if (!kIsWeb) SafeArea(child: _buildTopBar(context)),
          ],
        );
      },
    );
  }

  /* ── Top bar ─────────────────────────────────────────────── */
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 20, 0),
      child: IconButton(
        onPressed: () => Utils.exitPage(context),
        icon: const Icon(Icons.arrow_back_rounded, color: black, size: 24),
      ),
    );
  }

  /* ── Title + gift illustration ───────────────────────────── */
  Widget _buildIllustration(BuildContext context) {
    final bool bigScreen = Dimens.isBigScreen(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          MyText(
            color: black,
            text: "refer_your_friends_and_earn",
            multilanguage: true,
            fontsizeNormal: 28,
            fontsizeWeb: 30,
            fontweight: FontWeight.w600,
            maxline: 2,
            overflow: TextOverflow.ellipsis,
            textalign: TextAlign.center,
            fontstyle: FontStyle.normal,
          ),
          const SizedBox(height: 22),
          MyImage(
            imagePath: "ic_gift.png",
            height: bigScreen ? 200.0 : 175.0,
            width: bigScreen ? 200.0 : 175.0,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  /* ── Description ─────────────────────────────────────────── */
  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.center,
      child: MyText(
        color: black,
        text: "invite_friends_get_reward",
        multilanguage: true,
        fontsizeNormal: 16,
        fontsizeWeb: 18,
        fontweight: FontWeight.w600,
        maxline: 2,
        overflow: TextOverflow.ellipsis,
        textalign: TextAlign.center,
        fontstyle: FontStyle.normal,
      ),
    );
  }

  /* ── Referral code card ──────────────────────────────────── */
  Widget _buildCodeCard(String code) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _DashedBorderBox(
        borderColor: black,
        borderRadius: 16,
        strokeWidth: 1,
        dashLength: 4,
        gapLength: 4,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                /* Code section */
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MyText(
                          color: gray,
                          text: "your_referral_code",
                          multilanguage: true,
                          fontsizeNormal: 12,
                          fontsizeWeb: 13,
                          fontweight: FontWeight.w500,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          textalign: TextAlign.start,
                          fontstyle: FontStyle.normal,
                        ),
                        const SizedBox(height: 6),
                        MyText(
                          color: black,
                          text: code.isNotEmpty ? code : "----",
                          multilanguage: false,
                          fontsizeNormal: 22,
                          fontsizeWeb: 24,
                          fontweight: FontWeight.w600,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          textalign: TextAlign.start,
                          fontstyle: FontStyle.normal,
                        ),
                      ],
                    ),
                  ),
                ),

                /* Divider */
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  color: gray.withValues(alpha: 0.7),
                ),

                /* Copy button */
                InkWell(
                  onTap: code.isNotEmpty
                      ? () {
                          Clipboard.setData(ClipboardData(text: code));
                          Utils.showSnackbar(
                            context,
                            "success",
                            "copied_success",
                            true,
                          );
                        }
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    child: MyText(
                      color: black,
                      text: "copy_code",
                      multilanguage: true,
                      fontsizeNormal: 14,
                      fontsizeWeb: 16,
                      fontweight: FontWeight.w600,
                      maxline: 2,
                      overflow: TextOverflow.ellipsis,
                      textalign: TextAlign.center,
                      fontstyle: FontStyle.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /* ── Social share section ────────────────────────────────── */
  Widget _buildSocialShareSection(String code) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          MyText(
            color: black,
            text: "share_referral_code_via",
            multilanguage: true,
            fontsizeNormal: 15,
            fontsizeWeb: 17,
            fontweight: FontWeight.w600,
            maxline: 1,
            overflow: TextOverflow.ellipsis,
            textalign: TextAlign.center,
            fontstyle: FontStyle.normal,
          ),
          Container(
            transform: Matrix4.translationValues(0, 25, 0),
            child: Row(
              children: [
                Expanded(
                  child: _buildSocialButton(
                    imagePath: "ic_insta.png",
                    onTap: () =>
                        Utils.referCode(context: context, referralCode: code),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _buildSocialButton(
                    imagePath: "ic_fb.png",
                    onTap: () =>
                        Utils.referCode(context: context, referralCode: code),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _buildSocialButton(
                    imagePath: "ic_ws.png",
                    onTap: () async {
                      if (!mounted) return;
                      Utils.referCode(context: context, referralCode: code);
                    },
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _buildSocialButton(
                    imagePath: "ic_tele.png",
                    onTap: () =>
                        Utils.referCode(context: context, referralCode: code),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _buildSocialButton(
                    imagePath: "ic_linkedin.png",
                    onTap: () =>
                        Utils.referCode(context: context, referralCode: code),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      highlightColor: transparent,
      child: Container(
        height: 50,
        width: 50,
        alignment: Alignment.center,
        child: MyImage(imagePath: imagePath),
      ),
    );
  }

  /* ── How it works (dark card with dashed border) ─────────── */
  Widget _buildHowItWorks() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(top: 25),
      width: (Dimens.isWeb(context))
          ? (MediaQuery.of(context).size.width * 0.5)
          : (Dimens.isTablet(context)
                ? (MediaQuery.of(context).size.width * 0.7)
                : MediaQuery.of(context).size.width),
      child: _DashedBorderBox(
        borderColor: colorPrimary,
        borderRadius: 10,
        strokeWidth: 1,
        dashLength: 2,
        gapLength: 2,
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: secondaryBgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepsItem(
                icon: Eva.share_fill,
                title: "share_code_step",
                isMultilang: true,
              ),
              _buildStepConnector(
                icon: "ic_refer_1",
                alignment: Alignment.centerLeft,
              ),
              _buildStepsItem(
                icon: Mdi.user_add,
                title: "friend_signup_step",
                isMultilang: true,
              ),
              _buildStepConnector(
                icon: "ic_refer_2",
                alignment: Alignment.centerRight,
              ),
              _buildStepsItem(
                icon: Bi.stars,
                title: "earn_rewards_step",
                isMultilang: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepConnector({
    required String icon,
    AlignmentGeometry? alignment,
  }) {
    return Container(
      width: 44,
      alignment: alignment,
      padding: EdgeInsets.fromLTRB(2, 5, 2, 3),
      child: MyImage(
        width: 20,
        height: 30,
        imagePath: "$icon.png",
        fit: BoxFit.contain,
        color: colorPrimary,
      ),
    );
  }

  Widget _buildStepsItem({
    required String icon,
    required String title,
    required bool isMultilang,
  }) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorPrimary.withValues(alpha: 0.2),
                  colorPrimary.withValues(alpha: 0.2),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(44),
              boxShadow: [
                BoxShadow(
                  color: black.withValues(alpha: 0.5),
                  blurRadius: 18,
                  spreadRadius: 0,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Iconify(icon, size: 21, color: white),
          ),
          SizedBox(width: 10),
          Expanded(
            child: MyText(
              text: title,
              multilanguage: isMultilang,
              fontsizeNormal: 14,
              fontsizeWeb: 16,
              color: titleTextColor,
              fontstyle: FontStyle.normal,
              fontweight: FontWeight.w500,
              maxline: 5,
              overflow: TextOverflow.ellipsis,
              textalign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }
}

/* ── Dashed border painter ───────────────────────────────── */
class _DashedBorderBox extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final double borderRadius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  const _DashedBorderBox({
    required this.child,
    required this.borderColor,
    required this.borderRadius,
    this.strokeWidth = 1.5,
    this.dashLength = 8,
    this.gapLength = 6,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(
        color: borderColor,
        borderRadius: borderRadius,
        strokeWidth: strokeWidth,
        dashLength: dashLength,
        gapLength: gapLength,
      ),
      child: child,
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double borderRadius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  const _DashedRectPainter({
    required this.color,
    required this.borderRadius,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      double distance = 0;
      while (distance < metric.length) {
        final start = distance;
        final end = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(start, end), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter old) =>
      old.color != color ||
      old.borderRadius != borderRadius ||
      old.dashLength != dashLength ||
      old.gapLength != gapLength;
}
