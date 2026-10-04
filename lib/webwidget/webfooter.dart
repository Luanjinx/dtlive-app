import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../model/sectiontypemodel.dart' as type;
import '../provider/generalprovider.dart';
import '../provider/homeprovider.dart';
import '../provider/sectiondataprovider.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/dimens.dart';
import '../utils/sharedpre.dart';
import '../web_js/js_helper.dart';
import '../webwidget/interactive_icon.dart';
import '../widget/myimage.dart';
import '../utils/utils.dart';
import '../widget/mynetworkimg.dart';
import '../widget/mytext.dart';
import '../webwidget/interactive_text.dart';

class WebFooter extends StatefulWidget {
  final String? newPage, oldPage;
  final dynamic reqText;
  final Function() onTypeClick;
  const WebFooter({
    super.key,
    required this.newPage,
    required this.oldPage,
    required this.reqText,
    required this.onTypeClick,
  });

  @override
  State<WebFooter> createState() => _WebFooterState();
}

class _WebFooterState extends State<WebFooter> {
  final JSHelper _jsHelper = JSHelper();
  SharedPre sharedPref = SharedPre();
  late GeneralProvider generalProvider;
  late HomeProvider homeProvider;
  late SectionDataProvider sectionDataProvider;

  @override
  void initState() {
    super.initState();
    sectionDataProvider = Provider.of<SectionDataProvider>(
      context,
      listen: false,
    );
    generalProvider = Provider.of<GeneralProvider>(context, listen: false);
    homeProvider = Provider.of<HomeProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
  }

  Future<void> _redirectToUrl(String loadingUrl, bool openInNew) async {
    printLog("loadingUrl -----------> $loadingUrl");
    printLog("openInNew ------------> $openInNew");

    try {
      // Determine the target
      final String target = openInNew ? '_blank' : '_self';

      // Call the helper
      // Ensure _jsHelper.callOpenTab returns a Future<String> as we defined earlier
      final String dataFromJS = await _jsHelper.callOpenTab(loadingUrl, target);

      printLog("dataFromJS -----------> $dataFromJS");

      if (dataFromJS == "Blocked") {
        printLog("Warning: Popup was blocked by the browser.");
        // Optional: Show a SnackBar or Dialog to the user here
      }
    } catch (e) {
      printLog("Error during JS redirection: $e");
    }
  }

  Future<void> _getData() async {
    await generalProvider.getPages();
    await generalProvider.getSocialLinks();

    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> setSelectedTab(int tabPos) async {
    if (!mounted) return;
    homeProvider.setSelectedTab(tabPos);

    printLog("getTabData position ====> $tabPos");
    printLog(
      "getTabData lastTabPosition ====> ${sectionDataProvider.lastTabPosition}",
    );
    if (sectionDataProvider.lastTabPosition == tabPos) {
      return;
    } else {
      sectionDataProvider.setTabPosition(tabPos);
    }
  }

  Future<void> getTabData(
    int position,
    List<type.Result>? sectionTypeList,
  ) async {
    sectionDataProvider.setLoading(true);
    if (position == -1) {
      await setSelectedTab(0);
      sectionDataProvider.getSectionBanner("0", "1");
      sectionDataProvider.getSectionList("0", "1", 1);
    } else {
      await setSelectedTab(position + 1);
      sectionDataProvider.getSectionBanner(
        sectionTypeList?[position].id ?? 0,
        "2",
      );
      sectionDataProvider.getSectionList(
        sectionTypeList?[position].id ?? 0,
        "2",
        1,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /* Gradient divider */
        Container(
          height: 1,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                white.withValues(alpha: 0),
                white.withValues(alpha: 0.5),
                white.withValues(alpha: 0.5),
                white.withValues(alpha: 0),
              ],
              stops: [0.0, 0.25, 0.75, 1.0],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
            (MediaQuery.of(context).size.width > 1200) ? 110 : 45,
            (MediaQuery.of(context).size.width > 1200) ? 60 : 30,
            (MediaQuery.of(context).size.width > 1200) ? 110 : 45,
            (MediaQuery.of(context).size.width > 1200) ? 60 : 30,
          ),
          decoration: BoxDecoration(color: lightBlack),
          child: (MediaQuery.of(context).size.width < 800)
              ? _buildColumnFooter()
              : _buildRowFooter(),
        ),
        /* Gradient divider */
        Container(
          height: 1,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                white.withValues(alpha: 0),
                white.withValues(alpha: 0.5),
                white.withValues(alpha: 0.5),
                white.withValues(alpha: 0),
              ],
              stops: [0.0, 0.25, 0.75, 1.0],
            ),
          ),
        ),
        /* Copyright bar */
        Container(
          height: 75,
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width > 1200 ? 110 : 45,
          ),
          color: lightBlack,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: MyText(
                  color: descTextColor.withValues(alpha: 0.70),
                  multilanguage: false,
                  text: "© ${Constant.appName}. All Rights Reserved.",
                  fontweight: FontWeight.w400,
                  fontsizeWeb: 14,
                  fontsizeNormal: 12,
                  textalign: TextAlign.start,
                  fontstyle: FontStyle.normal,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  letterSpacing: 0.3,
                ),
              ),
              Opacity(
                opacity: 0.20,
                child: MyImage(
                  imagePath: "appicon.png",
                  height: 25,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRowFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /* App Icon & Desc. */
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 60,
                alignment: Alignment.centerLeft,
                child: MyImage(fit: BoxFit.contain, imagePath: "appicon.png"),
              ),
              const SizedBox(height: 15),
              Consumer<GeneralProvider>(
                builder: (context, generalProvider, child) {
                  return MyText(
                    color: descTextColor,
                    multilanguage: false,
                    text: generalProvider.appDescription ?? "",
                    fontweight: FontWeight.w300,
                    fontsizeWeb: 14,
                    fontsizeNormal: 14,
                    textalign: TextAlign.start,
                    fontstyle: FontStyle.normal,
                    maxline: 50,
                    overflow: TextOverflow.ellipsis,
                    letterSpacing: 0.5,
                  );
                },
              ),
              /* Contact With us */
              const SizedBox(height: 40),
              _buildSocialLink(),
            ],
          ),
        ),
        const SizedBox(width: 30),

        /* Quick Links */
        Expanded(child: _buildPages()),
        const SizedBox(width: 8),

        /* Types */
        Expanded(flex: 2, child: _buildTypes()),
        const SizedBox(width: 30),

        /* Available On */
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /* Available On */
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 3,
                      height: 13,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: colorPrimary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Flexible(
                      child: MyText(
                        color: white.withValues(alpha: 0.90),
                        multilanguage: true,
                        text: "download_app_for_streaming",
                        fontweight: FontWeight.w600,
                        fontsizeWeb: 14,
                        fontsizeNormal: 12,
                        textalign: TextAlign.start,
                        fontstyle: FontStyle.normal,
                        maxline: 2,
                        overflow: TextOverflow.ellipsis,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              /* Store Icons */
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () {
                    _redirectToUrl(Constant.androidAppUrl, true);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: InteractiveIcon(
                    builder: (isHovered) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: (MediaQuery.of(context).size.width > 1200)
                            ? Dimens.heightStoreBtn
                            : 45,
                        width: (MediaQuery.of(context).size.width > 1200)
                            ? 180
                            : 140,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isHovered
                                ? white.withValues(alpha: 0.30)
                                : transparent,
                            width: 1.5,
                          ),
                        ),
                        child: MyImage(
                          imagePath: "playstore.png",
                          fit: BoxFit.contain,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () {
                    _redirectToUrl(Constant.iosAppUrl, true);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: InteractiveIcon(
                    builder: (isHovered) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: (MediaQuery.of(context).size.width > 1200)
                            ? Dimens.heightStoreBtn
                            : 45,
                        width: (MediaQuery.of(context).size.width > 1200)
                            ? 180
                            : 140,
                        padding: const EdgeInsets.all(4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isHovered
                                ? white.withValues(alpha: 0.30)
                                : transparent,
                            width: 1.5,
                          ),
                        ),
                        child: MyImage(
                          imagePath: "applestore.png",
                          fit: BoxFit.contain,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColumnFooter() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /* App Icon & Desc. */
        Container(
          width: 120,
          height: 60,
          alignment: Alignment.centerLeft,
          child: MyImage(fit: BoxFit.contain, imagePath: "appicon.png"),
        ),
        const SizedBox(height: 8),
        Consumer<GeneralProvider>(
          builder: (context, generalProvider, child) {
            return MyText(
              color: descTextColor,
              multilanguage: false,
              text: generalProvider.appDescription ?? "",
              fontweight: FontWeight.w300,
              fontsizeWeb: 14,
              fontsizeNormal: 14,
              textalign: TextAlign.start,
              fontstyle: FontStyle.normal,
              maxline: 50,
              overflow: TextOverflow.ellipsis,
              letterSpacing: 0.5,
            );
          },
        ),
        const SizedBox(height: 30),

        /* Social Icons */
        _buildSocialLink(),
        const SizedBox(height: 30),

        /* Types */
        _buildTypes(),

        /* Quick Links */
        const SizedBox(height: 30),
        _buildPages(),

        /* Available On */
        const SizedBox(height: 30),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /* Available On */
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 3,
                    height: 13,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: colorPrimary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Flexible(
                    child: MyText(
                      color: white.withValues(alpha: 0.90),
                      multilanguage: false,
                      text: "DOWNLOAD THE APP FOR STREAMING",
                      fontweight: FontWeight.w600,
                      fontsizeWeb: 14,
                      fontsizeNormal: 12,
                      textalign: TextAlign.start,
                      fontstyle: FontStyle.normal,
                      maxline: 2,
                      overflow: TextOverflow.ellipsis,
                      letterSpacing: 1.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            /* Store Icons */
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () {
                  _redirectToUrl(Constant.androidAppUrl, true);
                },
                borderRadius: BorderRadius.circular(8),
                child: InteractiveIcon(
                  builder: (isHovered) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: (MediaQuery.of(context).size.width > 1200)
                          ? Dimens.heightStoreBtn
                          : 45,
                      width: (MediaQuery.of(context).size.width > 1200)
                          ? 180
                          : 140,
                      padding: const EdgeInsets.all(4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isHovered
                              ? colorPrimary.withValues(alpha: 0.60)
                              : transparent,
                          width: 1.5,
                        ),
                        boxShadow: isHovered
                            ? [
                                BoxShadow(
                                  color: colorPrimary.withValues(alpha: 0.20),
                                  blurRadius: 12,
                                  spreadRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: MyImage(
                        imagePath: "playstore.png",
                        fit: BoxFit.contain,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () {
                  _redirectToUrl(Constant.iosAppUrl, true);
                },
                borderRadius: BorderRadius.circular(8),
                child: InteractiveIcon(
                  builder: (isHovered) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: (MediaQuery.of(context).size.width > 1200)
                          ? Dimens.heightStoreBtn
                          : 45,
                      width: (MediaQuery.of(context).size.width > 1200)
                          ? 180
                          : 140,
                      padding: const EdgeInsets.all(4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isHovered
                              ? colorPrimary.withValues(alpha: 0.60)
                              : transparent,
                          width: 1.5,
                        ),
                        boxShadow: isHovered
                            ? [
                                BoxShadow(
                                  color: colorPrimary.withValues(alpha: 0.20),
                                  blurRadius: 12,
                                  spreadRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: MyImage(
                        imagePath: "applestore.png",
                        fit: BoxFit.contain,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPages() {
    if (generalProvider.loading) {
      return const SizedBox.shrink();
    } else {
      if (generalProvider.pagesModel.status == 200 &&
          generalProvider.pagesModel.result != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 3,
                    height: 13,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: colorPrimary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  MyText(
                    color: white.withValues(alpha: 0.90),
                    multilanguage: true,
                    text: "help",
                    fontweight: FontWeight.w600,
                    fontsizeWeb: 14,
                    fontsizeNormal: 12,
                    textalign: TextAlign.start,
                    fontstyle: FontStyle.normal,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    letterSpacing: 1.8,
                  ),
                ],
              ),
            ),
            AlignedGridView.count(
              shrinkWrap: true,
              crossAxisCount: 1,
              crossAxisSpacing: 10,
              mainAxisSpacing: 20,
              itemCount: (generalProvider.pagesModel.result?.length ?? 0),
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (BuildContext context, int position) {
                return _buildPageItem(
                  pageName:
                      generalProvider.pagesModel.result?[position].title ?? "",
                  onClick: () {
                    _redirectToUrl(
                      generalProvider.pagesModel.result?[position].url ?? "",
                      false,
                    );
                  },
                );
              },
            ),
          ],
        );
      } else {
        return const SizedBox.shrink();
      }
    }
  }

  Widget _buildPageItem({
    required String pageName,
    required Function() onClick,
  }) {
    return InkWell(
      onTap: onClick,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 3,
            width: 3,
            decoration: BoxDecoration(
              color: descTextColor.withValues(alpha: 0.60),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 10),
          Flexible(
            child: InteractiveText(
              multilanguage: false,
              activeColor: white,
              inctiveColor: descTextColor,
              text: pageName,
              maxline: 2,
              textalign: TextAlign.start,
              fontstyle: FontStyle.normal,
              fontsizeWeb: 15,
              fontweight: FontWeight.w400,
              overflow: TextOverflow.ellipsis,
              withShaderMask: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypes() {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        if (generalProvider.loading) {
          return const SizedBox.shrink();
        } else {
          if (homeProvider.sectionTypeModel.status == 200 &&
              homeProvider.sectionTypeModel.result != null &&
              (homeProvider.sectionTypeModel.result?.length ?? 0) > 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 3,
                        height: 13,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: colorPrimary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      MyText(
                        color: white.withValues(alpha: 0.90),
                        multilanguage: true,
                        text: "browse_categories",
                        fontweight: FontWeight.w600,
                        fontsizeWeb: 14,
                        fontsizeNormal: 12,
                        textalign: TextAlign.start,
                        fontstyle: FontStyle.normal,
                        maxline: 1,
                        overflow: TextOverflow.ellipsis,
                        letterSpacing: 1.8,
                      ),
                    ],
                  ),
                ),
                AlignedGridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 20,
                  itemCount:
                      (homeProvider.sectionTypeModel.result?.length ?? 0),
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int position) {
                    return _buildTypesItem(
                      pageName:
                          homeProvider
                              .sectionTypeModel
                              .result?[position]
                              .name ??
                          "",
                      onClick: () async {
                        printLog("position ========> $position");
                        printLog("oldPage =========> ${widget.oldPage}");
                        printLog("newPage =========> ${widget.newPage}");
                        await getTabData(
                          (position),
                          homeProvider.sectionTypeModel.result,
                        );
                        if (kIsWeb && widget.oldPage != widget.newPage) {
                          if (!context.mounted) return;
                          context.go("/", extra: widget.newPage ?? "");
                        }
                        widget.onTypeClick();
                      },
                    );
                  },
                ),
              ],
            );
          } else {
            return const SizedBox.shrink();
          }
        }
      },
    );
  }

  Widget _buildTypesItem({
    required String pageName,
    required Function() onClick,
  }) {
    return InkWell(
      onTap: onClick,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 3,
            width: 3,
            decoration: BoxDecoration(
              color: descTextColor.withValues(alpha: 0.60),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 10),
          Flexible(
            child: InteractiveText(
              multilanguage: false,
              activeColor: white,
              inctiveColor: descTextColor,
              text: pageName,
              maxline: 2,
              textalign: TextAlign.start,
              fontstyle: FontStyle.normal,
              fontsizeWeb: 15,
              fontweight: FontWeight.w400,
              overflow: TextOverflow.ellipsis,
              withShaderMask: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLink() {
    if (generalProvider.loading) {
      return const SizedBox.shrink();
    } else {
      if (generalProvider.socialLinkModel.status == 200 &&
          generalProvider.socialLinkModel.result != null) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 3,
                    height: 13,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: colorPrimary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  MyText(
                    color: white.withValues(alpha: 0.90),
                    multilanguage: false,
                    text: "CONNECT WITH US!",
                    fontweight: FontWeight.w600,
                    fontsizeWeb: 14,
                    fontsizeNormal: 12,
                    textalign: TextAlign.start,
                    fontstyle: FontStyle.normal,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    letterSpacing: 1.8,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: Dimens.heightSocialBtn,
              child: ListView.separated(
                itemCount:
                    (generalProvider.socialLinkModel.result?.length ?? 0),
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                scrollDirection: Axis.horizontal,
                separatorBuilder: (context, index) => SizedBox(width: 15),
                itemBuilder: (BuildContext context, int position) {
                  return _buildSocialIcon(
                    iconUrl:
                        generalProvider
                            .socialLinkModel
                            .result?[position]
                            .image ??
                        "",
                    onClick: () {
                      _redirectToUrl(
                        generalProvider.socialLinkModel.result?[position].url ??
                            "",
                        true,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      } else {
        return const SizedBox.shrink();
      }
    }
  }

  Widget _buildSocialIcon({
    required String iconUrl,
    required Function() onClick,
  }) {
    return SizedBox(
      height: Dimens.heightSocialBtn,
      width: Dimens.widthSocialBtn,
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimens.heightSocialBtn),
        onTap: onClick,
        child: InteractiveIcon(
          builder: (isHovered) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: Dimens.heightSocialBtn,
              width: Dimens.widthSocialBtn,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isHovered
                    ? white.withValues(alpha: 0.10)
                    : white.withValues(alpha: 0.05),
                border: Border.all(
                  color: isHovered
                      ? white.withValues(alpha: 0.25)
                      : white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(10),
              child: MyNetworkImage(imageUrl: iconUrl, fit: BoxFit.contain),
            );
          },
        ),
      ),
    );
  }
}
