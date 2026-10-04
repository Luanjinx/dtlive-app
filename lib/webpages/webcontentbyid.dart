import 'dart:async';

import 'package:flutter_locales/flutter_locales.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

import '../routes/routes_constant.dart';
import '../shimmer/shimmerutils.dart';
import '../utils/dimens.dart';
import '../utils/utils.dart';
import '../webpages/webcomman.dart';
import '../widget/mytext.dart';
import '../widget/nodata.dart';
import '../provider/videobyidprovider.dart';
import '../utils/color.dart';
import '../widget/mynetworkimg.dart';
import '../webwidget/web_hover_card.dart';

class WebVideosByID extends StatefulWidget {
  final String? newPage, oldPage;
  final dynamic reqText;
  final String appBarTitle, layoutType;
  final int itemID;
  const WebVideosByID(
    this.itemID,
    this.appBarTitle,
    this.layoutType, {
    super.key,
    required this.newPage,
    required this.oldPage,
    required this.reqText,
  });

  @override
  State<WebVideosByID> createState() => WebVideosByIDState();
}

class WebVideosByIDState extends State<WebVideosByID> {
  late VideoByIDProvider videoByIDProvider;

  @override
  void initState() {
    super.initState();
    videoByIDProvider = Provider.of<VideoByIDProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
  }

  Future<void> _getData() async {
    if (widget.layoutType == RoutesConstant.videoByCatPage) {
      await videoByIDProvider.getVideoByCategory(widget.itemID, 1);
    } else if (widget.layoutType == RoutesConstant.videoByLanguagePage) {
      await videoByIDProvider.getVideoByLanguage(widget.itemID, 1);
    } else if (widget.layoutType == RoutesConstant.videoByChannelPage) {
      await videoByIDProvider.getVideoByChannel(widget.itemID, 1);
    } else if (widget.layoutType == RoutesConstant.videoByCastPage) {
      await videoByIDProvider.getCastDetails(widget.itemID);
      await videoByIDProvider.getVideoByCast(widget.itemID, 1);
    }
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    videoByIDProvider.clearProvider();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WebComman(
      newChild: _buildPageUI(),
      newPage: widget.newPage,
      oldPage: widget.oldPage,
      reqText: '',
    );
  }

  Widget _buildPageUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: Dimens.homeTabHeight),
        _buildAppbar(),
        _buildCastDetails(),
        _buildContentItem(),
        /* Pagination loader */
        Consumer<VideoByIDProvider>(
          builder: (context, videoByIDProvider, child) {
            if (videoByIDProvider.loadMore) {
              return ShimmerUtils.responsiveGrid(
                context,
                Dimens.isBigScreen(context)
                    ? Dimens.heightPortOtherWeb
                    : Dimens.heightPortOther,
                Dimens.isBigScreen(context)
                    ? Dimens.widthPortOtherWeb
                    : Dimens.widthPortOther,
                2,
                10,
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
      ],
    );
  }

  Widget _buildCastDetails() {
    return Consumer<VideoByIDProvider>(
      builder: (context, videoByIDProvider, child) {
        if (widget.layoutType == RoutesConstant.videoByCastPage &&
            videoByIDProvider.castDetailModel.status == 200 &&
            videoByIDProvider.castDetailModel.result != null &&
            (videoByIDProvider.castDetailModel.result?.length ?? 0) > 0) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(45),
                  child: MyNetworkImage(
                    imageUrl:
                        videoByIDProvider.castDetailModel.result?[0].image
                            .toString() ??
                        "",
                    fit: BoxFit.cover,
                    height: 90,
                    width: 90,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: MediaQuery.of(context).size.width,
                  constraints: const BoxConstraints(minHeight: 0),
                  alignment: Alignment.centerLeft,
                  child: ExpandableText(
                    videoByIDProvider.castDetailModel.status == 200
                        ? videoByIDProvider.castDetailModel.result != null
                              ? (videoByIDProvider
                                        .castDetailModel
                                        .result?[0]
                                        .personalInfo
                                        .toString() ??
                                    "-")
                              : "-"
                        : "-",
                    expandText: Locales.string(context, "more"),
                    collapseText: Locales.string(context, "less"),
                    maxLines: 10,
                    linkColor: descTextColor,
                    textAlign: TextAlign.start,
                    expandOnTextTap: true,
                    collapseOnTextTap: true,
                    style: const TextStyle(
                      letterSpacing: 0.5,
                      wordSpacing: 0.2,
                      fontSize: 14,
                      fontStyle: FontStyle.normal,
                      color: descTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildAppbar() {
    if (widget.appBarTitle == "" &&
        widget.layoutType != RoutesConstant.videoByCastPage) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.fromLTRB(35, 5, 35, 10),
        child: SizedBox(),
      );
    }
    if (widget.layoutType == RoutesConstant.videoByCastPage &&
        videoByIDProvider.castDetailModel.status == 200 &&
        videoByIDProvider.castDetailModel.result != null &&
        (videoByIDProvider.castDetailModel.result?.length ?? 0) > 0) {
      return Consumer<VideoByIDProvider>(
        builder: (context, videoByIDProvider, child) {
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.fromLTRB(35, 5, 35, 10),
            child: MyText(
              text: videoByIDProvider.castDetailModel.result?[0].name ?? "",
              multilanguage: false,
              color: colorPrimary,
              fontsizeNormal: 20,
              fontsizeWeb: 25,
              maxline: 1,
              fontweight: FontWeight.w600,
              fontstyle: FontStyle.normal,
              textalign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      );
    }
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.fromLTRB(35, 5, 35, 10),
      child: MyText(
        text: widget.appBarTitle,
        multilanguage: false,
        color: colorPrimary,
        fontsizeNormal: 20,
        fontsizeWeb: 25,
        maxline: 1,
        fontweight: FontWeight.w600,
        fontstyle: FontStyle.normal,
        textalign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildContentItem() {
    return Consumer<VideoByIDProvider>(
      builder: (context, videoByIDProvider, child) {
        if (videoByIDProvider.loading && !videoByIDProvider.loadMore) {
          return ShimmerUtils.responsiveGrid(
            context,
            Dimens.isBigScreen(context)
                ? Dimens.heightPortOtherWeb
                : Dimens.heightPortOther,
            Dimens.isBigScreen(context)
                ? Dimens.widthPortOtherWeb
                : Dimens.widthPortOther,
            2,
            Dimens.isBigScreen(context) ? 40 : 20,
          );
        }
        if (videoByIDProvider.contentList == null ||
            (videoByIDProvider.contentList?.length ?? 0) == 0) {
          return NoData(
            title: (widget.layoutType == RoutesConstant.videoByCatPage)
                ? 'no_category_data_title'
                : ((widget.layoutType == RoutesConstant.videoByLanguagePage)
                      ? 'no_language_data_title'
                      : 'no_cast_data_title'),
            subTitle: (widget.layoutType == RoutesConstant.videoByCatPage)
                ? 'no_category_data_desc'
                : ((widget.layoutType == RoutesConstant.videoByLanguagePage)
                      ? 'no_language_data_desc'
                      : 'no_cast_data_desc'),
          );
        }
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: ResponsiveGridList(
            minItemWidth: Dimens.isBigScreen(context)
                ? Dimens.widthPortOtherWeb
                : Dimens.widthPortOther,
            verticalGridSpacing: 5,
            horizontalGridSpacing: 5,
            minItemsPerRow: 2,
            maxItemsPerRow: 15,
            listViewBuilderOptions: ListViewBuilderOptions(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
            ),
            children: List.generate(
              (videoByIDProvider.contentList?.length ?? 0),
              (position) {
                return WebHoverCard(
                  cardW: Dimens.isBigScreen(context)
                      ? Dimens.widthPortOtherWeb
                      : Dimens.widthPortOther,
                  cardH: Dimens.isBigScreen(context)
                      ? Dimens.heightPortOtherWeb
                      : Dimens.heightPortOther,
                  borderRadius: Dimens.cardRadiusMedium,
                  imageUrl: videoByIDProvider
                          .contentList?[position]
                          .thumbnail
                          .toString() ??
                      "",
                  onTap: () {
                    printLog("Clicked on position ==> $position");
                    Utils.openDetails(
                      context: context,
                      videoId:
                          videoByIDProvider.contentList?[position].id ?? 0,
                      subVideoType:
                          videoByIDProvider
                              .contentList?[position]
                              .subVideoType ??
                          0,
                      videoType:
                          videoByIDProvider
                              .contentList?[position]
                              .videoType ??
                          0,
                      typeId:
                          videoByIDProvider.contentList?[position].typeId ?? 0,
                      newPage: RoutesConstant.contentDetailsPage,
                      oldPage: widget.newPage ?? "",
                      reqText: "",
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
