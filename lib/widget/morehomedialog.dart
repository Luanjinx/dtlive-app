import '../pages/contentbyid.dart';
import '../provider/bottombarprovider.dart';
import '../provider/homeprovider.dart';
import '../provider/sectiondataprovider.dart';
import '../model/sectiontypemodel.dart' as type;
import '../provider/videobyidprovider.dart';
import '../utils/adhelper.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/dimens.dart';
import '../utils/utils.dart';
import '../widget/myimage.dart';
import '../widget/mynetworkimg.dart';
import '../widget/mytext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

class MoreHomeDialog extends StatefulWidget {
  const MoreHomeDialog({super.key});

  @override
  State<MoreHomeDialog> createState() => _MoreHomeDialogState();
}

class _MoreHomeDialogState extends State<MoreHomeDialog> {
  late HomeProvider homeProvider;
  late BottombarProvider bottombarProvider;
  late SectionDataProvider sectionDataProvider;

  @override
  void initState() {
    super.initState();
    homeProvider = Provider.of<HomeProvider>(context, listen: false);
    bottombarProvider = Provider.of<BottombarProvider>(context, listen: false);
    sectionDataProvider = Provider.of<SectionDataProvider>(
      context,
      listen: false,
    );
  }

  Future<void> setSelectedTab(int tabPos) async {
    printLog("setSelectedTab tabPos ====> $tabPos");
    if (!mounted) return;
    homeProvider.setSelectedTab(tabPos);
    printLog(
      "setSelectedTab selectedIndex ====> ${homeProvider.selectedIndex}",
    );
    printLog(
      "setSelectedTab lastTabPosition ====> ${sectionDataProvider.lastTabPosition}",
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
    printLog("getTabData position ====> $position");
    sectionDataProvider.setLoading(true);
    await bottombarProvider.toggleVisibility(true);

    if (position == -1) {
      await setSelectedTab(-1);
      await sectionDataProvider.getSectionBanner("0", "1");
      await sectionDataProvider.getSectionList("0", "1", 1);
    } else {
      await setSelectedTab(position);
      await sectionDataProvider.getSectionBanner(
        sectionTypeList?[position].id ?? 0,
        "2",
      );
      await sectionDataProvider.getSectionList(
        sectionTypeList?[position].id ?? 0,
        "2",
        1,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Consumer<HomeProvider>(
        builder: (context, homeProvider, child) {
          return Container(
            width: MediaQuery.of(context).size.width,
            color: secondaryBgColor,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildTypes(),
                  const SizedBox(height: 18),
                  if (homeProvider.langaugeModel.result != null &&
                      (homeProvider.langaugeModel.result?.length ?? 0) > 0)
                    _buildTitleForDialog(
                      title: "popular_language",
                      isMultiLang: true,
                    ),
                  _buildPopularLanguage(),
                  _buildChannel(),
                  if (homeProvider.genresModel.result != null &&
                      (homeProvider.genresModel.result?.length ?? 0) > 0)
                    _buildTitleForDialog(
                      title: "popular_genres",
                      isMultiLang: true,
                    ),
                  _buildPopularGenres(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypes() {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        if (homeProvider.sectionTypeModel.result == null ||
            (homeProvider.sectionTypeModel.result?.length ?? 0) == 0) {
          return const SizedBox.shrink();
        }
        return Container(
          constraints: const BoxConstraints(maxHeight: 55),
          decoration: Utils.setBGWithBorder(
            appBgColor,
            transparent,
            Dimens.menuRadius,
            0,
          ),
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 0),
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          alignment: Alignment.topCenter,
          child: ListView.separated(
            itemCount: (homeProvider.sectionTypeModel.result?.length ?? 0),
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            separatorBuilder: (context, index) => Container(
              width: 1.5,
              margin: const EdgeInsets.fromLTRB(4, 10, 4, 10),
              decoration: Utils.setBackground(grayDark, 5),
            ),
            itemBuilder: (BuildContext context, int index) {
              return InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: () async {
                  printLog("index ===========> $index");

                  AdHelper.checkAndShowAds(
                    context: context,
                    buttonKey: "",
                    adType: Constant.interstialAdType,
                    alwaysShowAd: false,
                    showOnByClick: true,
                    onAdComplete: () async {
                      Utils.exitDialog(context);
                      await getTabData(
                        index,
                        homeProvider.sectionTypeModel.result,
                      );
                    },
                  );
                },
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                  child: MyText(
                    color: white,
                    multilanguage: false,
                    text:
                        (homeProvider.sectionTypeModel.result?[index].name
                            .toString() ??
                        ""),
                    fontsizeNormal: 12,
                    fontweight: FontWeight.w600,
                    fontsizeWeb: 14,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.center,
                    fontstyle: FontStyle.normal,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPopularLanguage() {
    if (homeProvider.langaugeModel.result != null &&
        (homeProvider.langaugeModel.result?.length ?? 0) > 0) {
      return Container(
        margin: const EdgeInsets.only(bottom: 18),
        width: MediaQuery.of(context).size.width,
        height: Dimens.heightLang,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          scrollDirection: Axis.horizontal,
          child: AlignedGridView.count(
            itemCount: homeProvider.langaugeModel.result?.length ?? 0,
            shrinkWrap: true,
            crossAxisCount: 1,
            crossAxisSpacing: Dimens.spaceBetweenLang,
            mainAxisSpacing: Dimens.spaceBetweenLang,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(left: 15, right: 15),
            scrollDirection: Axis.horizontal,
            itemBuilder: (BuildContext context, int index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(Dimens.heightLang / 2),
                clipBehavior: Clip.antiAliasWithSaveLayer,
                child: Container(
                  height: Dimens.heightLang,
                  width: Dimens.widthLang,
                  alignment: Alignment.center,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(Dimens.heightLang / 2),
                    focusColor: white,
                    onTap: () async {
                      printLog("Clicked on index ==> $index");
                      final videoByIDProvider = Provider.of<VideoByIDProvider>(
                        context,
                        listen: false,
                      );
                      Utils.exitDialog(context);
                      videoByIDProvider.setLoading(true);
                      if (!context.mounted) return;
                      Utils.pushWebPage(
                        context: context,
                        newChild: ContentByID(
                          homeProvider.langaugeModel.result?[index].id ?? 0,
                          homeProvider.langaugeModel.result?[index].name ?? "",
                          "ByLanguage",
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            Dimens.heightLang / 2,
                          ),
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          child: MyNetworkImage(
                            imageUrl:
                                homeProvider.langaugeModel.result?[index].image
                                    .toString() ??
                                "",
                            fit: BoxFit.fill,
                            height: Dimens.heightLang,
                            width: Dimens.widthLang,
                          ),
                        ),
                        Container(
                          height: Dimens.heightLang,
                          width: Dimens.widthLang,
                          alignment: Alignment.center,
                          decoration: Utils.setBGWithBorder(
                            transparent,
                            secondaryBgColor.withValues(alpha: 0.2),
                            Dimens.heightLang / 2,
                            2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildChannel() {
    if (homeProvider.channelModel.result != null &&
        (homeProvider.channelModel.result?.length ?? 0) > 0) {
      return Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.fromLTRB(0, 15, 0, 18),
        child: Column(children: [_buildChannelTitle(), _buildPopularChannel()]),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildPopularChannel() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: ((homeProvider.channelModel.result?.length ?? 0) < 13)
          ? (Dimens.heightChannelTotal)
          : (Dimens.heightChannelTotal * 2),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        scrollDirection: Axis.horizontal,
        child: AlignedGridView.count(
          itemCount: homeProvider.channelModel.result?.length ?? 0,
          shrinkWrap: true,
          crossAxisCount: ((homeProvider.channelModel.result?.length ?? 0) < 13)
              ? 1
              : 2,
          crossAxisSpacing: Dimens.spaceBetweenChannel,
          mainAxisSpacing: Dimens.spaceBetweenChannel,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 15, right: 15),
          scrollDirection: Axis.horizontal,
          itemBuilder: (BuildContext context, int index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(Dimens.cardRadiusMedium),
              clipBehavior: Clip.antiAliasWithSaveLayer,
              child: InkWell(
                borderRadius: BorderRadius.circular(Dimens.cardRadiusMedium),
                focusColor: white,
                onTap: () async {
                  final videoByIDProvider = Provider.of<VideoByIDProvider>(
                    context,
                    listen: false,
                  );
                  Utils.exitDialog(context);
                  videoByIDProvider.setLoading(true);
                  if (!context.mounted) return;
                  Utils.pushWebPage(
                    context: context,
                    newChild: ContentByID(
                      homeProvider.channelModel.result?[index].id ?? 0,
                      homeProvider.channelModel.result?[index].name ?? "",
                      "ByChannel",
                    ),
                  );
                },
                child: Container(
                  height: Dimens.heightChannel,
                  alignment: Alignment.center,
                  constraints: const BoxConstraints(minWidth: 80),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      Dimens.cardRadiusMedium,
                    ),
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: MyNetworkImage(
                      imageUrl:
                          homeProvider.channelModel.result?[index].landscapeImg
                              .toString() ??
                          "",
                      fit: BoxFit.fill,
                      width: Dimens.widthChannel,
                      height: Dimens.heightChannel,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChannelTitle() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      margin: const EdgeInsets.only(bottom: 11),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                alignment: Alignment.centerRight,
                height: 17,
                width: 17,
                margin: const EdgeInsets.only(right: 2),
                child: MyImage(imagePath: "ic_fire.png", fit: BoxFit.contain),
              ),
              Container(
                alignment: Alignment.centerLeft,
                child: MyText(
                  color: white,
                  text: "popular_channel",
                  textalign: TextAlign.start,
                  fontsizeNormal: 15,
                  fontweight: FontWeight.w600,
                  fontsizeWeb: 17,
                  multilanguage: true,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  fontstyle: FontStyle.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPopularGenres() {
    if (homeProvider.genresModel.result != null &&
        (homeProvider.genresModel.result?.length ?? 0) > 0) {
      return SizedBox(
        width: MediaQuery.of(context).size.width,
        height: Dimens.heightGen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          scrollDirection: Axis.horizontal,
          child: AlignedGridView.count(
            itemCount: homeProvider.genresModel.result?.length ?? 0,
            shrinkWrap: true,
            crossAxisCount: 1,
            crossAxisSpacing: Dimens.spaceBetweenCategory,
            mainAxisSpacing: Dimens.spaceBetweenCategory,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(left: 15, right: 15),
            scrollDirection: Axis.horizontal,
            itemBuilder: (BuildContext context, int index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(Dimens.heightGen / 2),
                clipBehavior: Clip.antiAliasWithSaveLayer,
                child: Container(
                  height: Dimens.heightGen,
                  width: Dimens.widthGen,
                  alignment: Alignment.center,
                  child: InkWell(
                    focusColor: white,
                    borderRadius: BorderRadius.circular(Dimens.heightGen / 2),
                    onTap: () async {
                      final videoByIDProvider = Provider.of<VideoByIDProvider>(
                        context,
                        listen: false,
                      );
                      Utils.exitDialog(context);
                      videoByIDProvider.setLoading(true);
                      if (!context.mounted) return;
                      Utils.pushWebPage(
                        context: context,
                        newChild: ContentByID(
                          homeProvider.genresModel.result?[index].id ?? 0,
                          homeProvider.genresModel.result?[index].name ?? "",
                          "ByCategory",
                        ),
                      );
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            Dimens.heightGen / 2,
                          ),
                          child: MyNetworkImage(
                            imageUrl:
                                homeProvider.genresModel.result?[index].image
                                    .toString() ??
                                "",
                            fit: BoxFit.fill,
                            height: Dimens.heightGen,
                            width: Dimens.widthGen,
                          ),
                        ),
                        Container(
                          height: Dimens.heightGen,
                          width: Dimens.widthGen,
                          alignment: Alignment.center,
                          decoration: Utils.setBGWithBorder(
                            transparent,
                            secondaryBgColor.withValues(alpha: 0.2),
                            Dimens.heightGen / 2,
                            2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildTitleForDialog({
    required String title,
    required bool isMultiLang,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 75),
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
      alignment: Alignment.centerLeft,
      child: MyText(
        color: white,
        text: title,
        multilanguage: isMultiLang,
        textalign: TextAlign.start,
        fontsizeNormal: 15,
        fontweight: FontWeight.w600,
        fontsizeWeb: 17,
        maxline: 1,
        overflow: TextOverflow.ellipsis,
        fontstyle: FontStyle.normal,
      ),
    );
  }
}
