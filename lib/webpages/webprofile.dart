import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../provider/profileprovider.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/dimens.dart';
import '../utils/sharedpre.dart';
import '../utils/utils.dart';
import '../webpages/webcomman.dart';
import '../webwidget/interactive_icon.dart';
import '../widget/myimage.dart';
import '../widget/mytext.dart';

class WebProfile extends StatefulWidget {
  final String? newPage, oldPage;
  final dynamic reqText;
  const WebProfile({
    required this.newPage,
    required this.oldPage,
    required this.reqText,
    super.key,
  });

  @override
  State<WebProfile> createState() => WebProfileState();
}

class WebProfileState extends State<WebProfile> {
  SharedPre sharedPref = SharedPre();
  late ProfileProvider profileProvider;

  @override
  void initState() {
    super.initState();
    profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
  }

  Future<void> _getData() async {
    if (!mounted) return;
    profileProvider.getProfile(context);
    profileProvider.getDeviceSyncList();

    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return WebComman(
      newPage: widget.newPage,
      oldPage: widget.oldPage,
      reqText: '',
      newChild: _buildPage(),
    );
  }

  Widget _buildPage() {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width > 1080
                ? (MediaQuery.of(context).size.width * 0.5)
                : ((MediaQuery.of(context).size.width <= 1080 &&
                          (MediaQuery.of(context).size.width > 720))
                      ? (MediaQuery.of(context).size.width * 0.7)
                      : MediaQuery.of(context).size.width),
            margin: EdgeInsets.fromLTRB(
              Dimens.isBigScreen(context) ? 50 : 25,
              (Dimens.homeTabHeight + 30),
              Dimens.isBigScreen(context) ? 50 : 25,
              Dimens.isBigScreen(context) ? 50 : 25,
            ),
            padding: EdgeInsets.fromLTRB(
              Dimens.isBigScreen(context) ? 40 : 25,
              Dimens.isBigScreen(context) ? 40 : 25,
              Dimens.isBigScreen(context) ? 40 : 25,
              Dimens.isBigScreen(context) ? 40 : 25,
            ),
            alignment: Alignment.center,
            decoration: Utils.setBackground(
              lightBlack.withValues(alpha: 0.3),
              3,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /* AppIcon */
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(5),
                  child: MyImage(
                    height: Dimens.isBigScreen(context) ? 60 : 50,
                    imagePath: "appicon.png",
                    fit: BoxFit.contain,
                  ),
                ),

                /* Current Plan Details */
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 30, 0, 0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(5),
                    onTap: () async {
                      await Utils.openSubscription(
                        context: context,
                        oldPage: "",
                      );
                    },
                    child: MyText(
                      color: titleTextColor,
                      text:
                          (profileProvider.profileModel.result != null &&
                              (profileProvider.profileModel.result?.length ??
                                      0) >
                                  0)
                          ? (((profileProvider.profileModel.result?[0].isBuy ??
                                        0) ==
                                    1)
                                ? (profileProvider
                                          .profileModel
                                          .result?[0]
                                          .packageName ??
                                      "")
                                : "View All Plan")
                          : "View All Plan",
                      multilanguage: false,
                      textalign: TextAlign.center,
                      fontsizeNormal: 20,
                      fontsizeWeb: 23,
                      fontweight: FontWeight.w700,
                      maxline: 2,
                      overflow: TextOverflow.ellipsis,
                      fontstyle: FontStyle.normal,
                      withShaderMask: true,
                    ),
                  ),
                ),
                /* Plan Expire (in days) */
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                  child: MyText(
                    color: descTextColor,
                    text:
                        (profileProvider.profileModel.result != null &&
                            (profileProvider.profileModel.result?.length ?? 0) >
                                0)
                        ? (((profileProvider.profileModel.result?[0].isBuy ??
                                          0) ==
                                      1 &&
                                  (profileProvider
                                              .profileModel
                                              .result?[0]
                                              .expiryDate ??
                                          "")
                                      .isNotEmpty)
                              ? "Plan expires in ${Utils.remainTimeInDays((profileProvider.profileModel.result?[0].expiryDate ?? ""))} days"
                              : "Buy subscription & get more")
                        : "Buy subscription & get more",
                    multilanguage: false,
                    textalign: TextAlign.center,
                    fontsizeNormal: 12,
                    fontsizeWeb: 15,
                    fontweight: FontWeight.w400,
                    maxline: 2,
                    overflow: TextOverflow.ellipsis,
                    fontstyle: FontStyle.normal,
                    withShaderMask: false,
                  ),
                ),
                _buildLine(0, 18, 0, 18),

                /* Mobile Number / Email Address */
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                  child: MyText(
                    color: titleTextColor,
                    text:
                        (profileProvider.profileModel.result == null ||
                            (profileProvider.profileModel.result?.length ??
                                    0) ==
                                0)
                        ? "-"
                        : (Utils.convertToStar(
                            (profileProvider.profileModel.result?[0].type == 1)
                                ? (profileProvider
                                          .profileModel
                                          .result?[0]
                                          .mobileNumber ??
                                      "")
                                : ((profileProvider
                                                  .profileModel
                                                  .result?[0]
                                                  .email ??
                                              "")
                                          .isNotEmpty
                                      ? (profileProvider
                                                .profileModel
                                                .result?[0]
                                                .email ??
                                            "")
                                      : "-"),
                          )),
                    multilanguage: false,
                    textalign: TextAlign.center,
                    fontsizeNormal: 16,
                    fontsizeWeb: 18,
                    fontweight: FontWeight.w500,
                    maxline: 2,
                    overflow: TextOverflow.ellipsis,
                    fontstyle: FontStyle.normal,
                    withShaderMask: false,
                  ),
                ),
                if (profileProvider.profileModel.result != null &&
                    (profileProvider.profileModel.result?.length ?? 0) > 0)
                  Container(
                    margin: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                    child: MyText(
                      color: descTextColor,
                      text: (profileProvider.profileModel.result?[0].type == 1)
                          ? "registered_mobile_number"
                          : ((profileProvider.profileModel.result?[0].email ??
                                        "")
                                    .isNotEmpty
                                ? "registered_email"
                                : "dash_symbol"),
                      multilanguage: true,
                      textalign: TextAlign.center,
                      fontsizeNormal: 12,
                      fontsizeWeb: 15,
                      fontweight: FontWeight.w400,
                      maxline: 2,
                      overflow: TextOverflow.ellipsis,
                      fontstyle: FontStyle.normal,
                      withShaderMask: false,
                    ),
                  ),

                /* All Devices */
                _buildDeviceList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeviceList() {
    return Container(
      decoration: Utils.setBackground(secondaryBgColor, 10),
      margin: const EdgeInsets.fromLTRB(0, 30, 0, 0),
      padding: const EdgeInsets.fromLTRB(13, 15, 13, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(
            color: titleTextColor,
            text: "all_devices",
            multilanguage: true,
            textalign: TextAlign.center,
            fontsizeNormal: 15,
            fontsizeWeb: 17,
            fontweight: FontWeight.w600,
            maxline: 2,
            overflow: TextOverflow.ellipsis,
            fontstyle: FontStyle.normal,
            withShaderMask: false,
          ),
          const SizedBox(height: 15),
          AlignedGridView.count(
            shrinkWrap: true,
            crossAxisCount: 1,
            crossAxisSpacing: 27,
            mainAxisSpacing: 27,
            itemCount: (profileProvider.deviceSyncModel.result?.length ?? 0),
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int position) {
              return Material(
                type: MaterialType.transparency,
                child: _buildDeviceItem(position: position),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceItem({required int position}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        /* Device Icon */
        Container(
          height: 25,
          width: 25,
          alignment: Alignment.center,
          child: MyImage(
            imagePath: _setIconByType(position: position),
            fit: BoxFit.contain,
            color: defaultIconColor,
          ),
        ),
        const SizedBox(width: 15),

        /* Device Name */
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText(
                color: white,
                text:
                    profileProvider
                        .deviceSyncModel
                        .result?[position]
                        .deviceName ??
                    "-",
                multilanguage: false,
                textalign: TextAlign.start,
                fontsizeNormal: 12,
                fontsizeWeb: 15,
                fontweight: FontWeight.w600,
                maxline: 2,
                overflow: TextOverflow.ellipsis,
                fontstyle: FontStyle.normal,
                withShaderMask: false,
              ),
              const SizedBox(height: 5),
              MyText(
                color: descTextColor,
                text:
                    (profileProvider
                                .deviceSyncModel
                                .result?[position]
                                .createdAt !=
                            null &&
                        (profileProvider
                                    .deviceSyncModel
                                    .result?[position]
                                    .createdAt ??
                                "")
                            .isNotEmpty)
                    ? ("Last used : ${DateFormat("dd MMM, yyyy").format(DateTime.parse(profileProvider.deviceSyncModel.result?[position].createdAt ?? ""))}")
                    : "-",
                multilanguage: false,
                textalign: TextAlign.start,
                fontsizeNormal: 12,
                fontsizeWeb: 15,
                fontweight: FontWeight.w400,
                maxline: 2,
                overflow: TextOverflow.ellipsis,
                fontstyle: FontStyle.normal,
                withShaderMask: false,
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),

        /* Logout Button */
        InteractiveIcon(
          builder: (isHovered) {
            final bool canLogout = Constant.currentDeviceId !=
                (profileProvider.deviceSyncModel.result?[position].deviceId ??
                    "");
            return InkWell(
              borderRadius: BorderRadius.circular(5),
              onTap: () async {
                if (!canLogout) return;
                try {
                  await Utils.logoutFromApp(
                    context,
                    profileProvider.deviceSyncModel.result?[position].id ?? 0,
                    profileProvider
                            .deviceSyncModel
                            .result?[position]
                            .deviceType ??
                        0,
                    profileProvider
                            .deviceSyncModel
                            .result?[position]
                            .deviceToken ??
                        "",
                    profileProvider
                            .deviceSyncModel
                            .result?[position]
                            .deviceId ??
                        "",
                  );
                } on Exception catch (e) {
                  printLog("logoutFromApp Exception =====> $e");
                }
                _getData();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 32,
                alignment: Alignment.center,
                decoration: canLogout
                    ? BoxDecoration(
                        color: isHovered
                            ? white.withValues(alpha: 0.15)
                            : grayDark.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(5),
                      )
                    : Utils.setBGWithBorder(
                        transparent,
                        grayDark.withValues(alpha: 0.2),
                        5,
                        0.7,
                      ),
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                child: MyText(
                  color: canLogout ? white : descTextColor,
                  text: canLogout ? "log_out" : "this_device",
                  multilanguage: true,
                  textalign: TextAlign.start,
                  fontsizeNormal: 13,
                  fontsizeWeb: 15,
                  fontweight: FontWeight.w600,
                  maxline: 2,
                  overflow: TextOverflow.ellipsis,
                  fontstyle: FontStyle.normal,
                  withShaderMask: false,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLine(
    double leftMargin,
    double topMargin,
    double rightMargin,
    double bottomMargin,
  ) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 0.7,
      margin: EdgeInsets.fromLTRB(
        leftMargin,
        topMargin,
        rightMargin,
        bottomMargin,
      ),
      decoration: Utils.setBackground(gray.withValues(alpha: 0.3), 0.7),
    );
  }

  String _setIconByType({required int position}) {
    String icon = "";
    if (profileProvider.deviceSyncModel.result?[position].deviceType == 2) {
      icon = "ic_iphone.png";
    } else if (profileProvider.deviceSyncModel.result?[position].deviceType ==
        3) {
      icon = "ic_web.png";
    } else if (profileProvider.deviceSyncModel.result?[position].deviceType ==
        4) {
      icon = "ic_tv.png";
    } else {
      icon = "ic_phone.png";
    }
    return icon;
  }
}
