import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/showdetailsprovider.dart';
import '../provider/videodetailsprovider.dart';
import '../provider/viewallprovider.dart';
import '../routes/routes_constant.dart';
import '../shimmer/shimmerutils.dart';
import '../utils/constant.dart';
import '../utils/dimens.dart';
import '../utils/utils.dart';
import '../webpages/webcomman.dart';
import '../widget/mytext.dart';
import '../widget/nodata.dart';
import '../utils/color.dart';
import '../webwidget/web_hover_card.dart';

class WebViewAll extends StatefulWidget {
  final String appBarTitle;
  final String? newPage, oldPage;
  final dynamic reqText;
  final int videoId, subVideoType, videoType, typeId;
  const WebViewAll({
    required this.appBarTitle,
    required this.videoId,
    required this.subVideoType,
    required this.videoType,
    required this.typeId,
    required this.newPage,
    required this.oldPage,
    required this.reqText,
    super.key,
  });

  @override
  State<WebViewAll> createState() => WebViewAllState();
}

class WebViewAllState extends State<WebViewAll> {
  late ViewAllProvider viewAllProvider;

  @override
  void initState() {
    super.initState();
    viewAllProvider = Provider.of<ViewAllProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
  }

  Future<void> _getData() async {
    if (widget.appBarTitle == RoutesConstant.relatedContentPage) {
      viewAllProvider.relatedList?.clear();
      viewAllProvider.relatedList = [];
      await viewAllProvider.getRelatedContent(
        widget.typeId,
        widget.videoType,
        widget.videoId,
        widget.subVideoType,
        1,
      );
      Future.delayed(const Duration(milliseconds: 400)).then((value) async {
        if (viewAllProvider.isMorePage == true) {
          await viewAllProvider.getRelatedContent(
            widget.typeId,
            widget.videoType,
            widget.videoId,
            widget.subVideoType,
            2,
          );
        }
        if (!context.mounted) return;
        setState(() {});
      });
    } else if (widget.appBarTitle == RoutesConstant.continueWatchPage) {
      viewAllProvider.continueWatchList?.clear();
      viewAllProvider.continueWatchList = [];
      await viewAllProvider.getContinueWatching(1);
      Future.delayed(const Duration(milliseconds: 400)).then((value) async {
        if (viewAllProvider.isMorePage == true) {
          await viewAllProvider.getContinueWatching(2);
        }
        if (!context.mounted) return;
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    viewAllProvider.clearProvider();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WebComman(
      newChild: _buildPageUI(),
      newPage: widget.newPage,
      oldPage: widget.oldPage,
      reqText: {
        'itemid': widget.videoId,
        'videotype': widget.videoType,
        'subvideotype': widget.subVideoType,
        'typeid': widget.typeId,
      },
    );
  }

  Widget _buildPageUI() {
    return Column(
      children: [
        SizedBox(height: Dimens.homeTabHeight),
        _buildAppbar(),
        _setContentByType(),

        /* Pagination loader */
        Consumer<ViewAllProvider>(
          builder: (context, viewAllProvider, child) {
            if (viewAllProvider.loadMore) {
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

  Widget _buildAppbar() {
    if (widget.appBarTitle == "") {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.fromLTRB(35, 5, 35, 10),
        child: SizedBox(),
      );
    }
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.fromLTRB(35, 5, 35, 10),
      child: MyText(
        text: widget.appBarTitle,
        multilanguage: true,
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

  Widget _setContentByType() {
    switch (widget.appBarTitle) {
      case 'customer_also_watch':
        return _buildRelatedItem();
      case 'continuewatching':
        return _buildContinueWatchItem();
      default:
        return _buildRelatedItem();
    }
  }

  Widget _buildRelatedItem() {
    return Consumer<ViewAllProvider>(
      builder: (context, viewAllProvider, child) {
        if (viewAllProvider.loading && !viewAllProvider.loadMore) {
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
        if (viewAllProvider.relatedList == null ||
            (viewAllProvider.relatedList?.length ?? 0) == 0) {
          return const NoData(title: 'no_data', subTitle: 'no_video_show');
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Wrap(
            spacing: Dimens.isBigScreen(context) ? 12 : 8,
            runSpacing: Dimens.isBigScreen(context) ? 16 : 10,
            alignment: WrapAlignment.start,
            children: List.generate(
              (viewAllProvider.relatedList?.length ?? 0),
              (position) {
                return WebHoverCard(
                  cardW: Dimens.isBigScreen(context)
                      ? Dimens.widthPortOtherWeb
                      : Dimens.widthPortOther,
                  cardH: Dimens.isBigScreen(context)
                      ? Dimens.heightPortOtherWeb
                      : Dimens.heightPortOther,
                  borderRadius: Dimens.cardRadiusSmall,
                  imageUrl:
                      viewAllProvider.relatedList?[position].thumbnail
                          .toString() ??
                      "",
                  onTap: () async {
                    printLog("Clicked on position ==> $position");
                    final videoDetailsProvider =
                        Provider.of<VideoDetailsProvider>(
                          context,
                          listen: false,
                        );
                    final showDetailsProvider =
                        Provider.of<ShowDetailsProvider>(
                          context,
                          listen: false,
                        );
                    if ((viewAllProvider.relatedList?[position].videoType ??
                                0) ==
                            Constant.showContentType ||
                        (viewAllProvider.relatedList?[position].subVideoType ??
                                0) ==
                            Constant.showContentType) {
                      showDetailsProvider.setLoading(true);
                    } else {
                      videoDetailsProvider.setLoading(true);
                    }

                    if (!context.mounted) return;
                    Utils.openDetailsWithReplace(
                      context: context,
                      videoId: viewAllProvider.relatedList?[position].id ?? 0,
                      subVideoType:
                          viewAllProvider.relatedList?[position].subVideoType ??
                          0,
                      videoType:
                          viewAllProvider.relatedList?[position].videoType ?? 0,
                      typeId:
                          viewAllProvider.relatedList?[position].typeId ?? 0,
                      newPage: RoutesConstant.contentDetailsPage,
                      oldPage: "",
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

  Widget _buildContinueWatchItem() {
    return Consumer<ViewAllProvider>(
      builder: (context, viewAllProvider, child) {
        if (viewAllProvider.loading && !viewAllProvider.loadMore) {
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
        if (viewAllProvider.continueWatchList == null ||
            (viewAllProvider.continueWatchList?.length ?? 0) == 0) {
          return const NoData(title: 'no_video_show', subTitle: 'no_data');
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Wrap(
            spacing: Dimens.isBigScreen(context) ? 12 : 8,
            runSpacing: Dimens.isBigScreen(context) ? 16 : 10,
            alignment: WrapAlignment.start,
            children: List.generate(
              (viewAllProvider.continueWatchList?.length ?? 0),
              (position) {
                return WebHoverCard(
                  cardW: Dimens.isBigScreen(context)
                      ? Dimens.widthPortOtherWeb
                      : Dimens.widthPortOther,
                  cardH: Dimens.isBigScreen(context)
                      ? Dimens.heightPortOtherWeb
                      : Dimens.heightPortOther,
                  borderRadius: Dimens.cardRadiusSmall,
                  imageUrl:
                      viewAllProvider.continueWatchList?[position].thumbnail
                          .toString() ??
                      "",
                  onTap: () async {
                    printLog("Clicked on position ==> $position");
                    final videoDetailsProvider =
                        Provider.of<VideoDetailsProvider>(
                          context,
                          listen: false,
                        );
                    final showDetailsProvider =
                        Provider.of<ShowDetailsProvider>(
                          context,
                          listen: false,
                        );
                    // if (context.canPop()) {
                    //   context.pop(context);
                    // }
                    if ((viewAllProvider
                                    .continueWatchList?[position]
                                    .videoType ??
                                0) ==
                            5 ||
                        (viewAllProvider
                                    .continueWatchList?[position]
                                    .videoType ??
                                0) ==
                            6 ||
                        (viewAllProvider
                                    .continueWatchList?[position]
                                    .videoType ??
                                0) ==
                            7) {
                      if ((viewAllProvider
                                  .continueWatchList?[position]
                                  .subVideoType ??
                              0) ==
                          1) {
                        videoDetailsProvider.setLoading(true);
                        // if (!context.mounted) return;
                        // context.pushReplacementNamed(
                        //   RoutesConstant.contentDetailsPage,
                        //   extra: {
                        //     'newpage': widget.oldPage.toString(),
                        //     'videoid': (viewAllProvider
                        //                 .continueWatchList?[position].id ??
                        //             0)
                        //         .toString(),
                        //     'subvideotype': (viewAllProvider
                        //                 .continueWatchList?[position]
                        //                 .subVideoType ??
                        //             0)
                        //         .toString(),
                        //     'videotype': (viewAllProvider
                        //                 .continueWatchList?[position]
                        //                 .videoType ??
                        //             0)
                        //         .toString(),
                        //     'typeid': (viewAllProvider
                        //                 .continueWatchList?[position]
                        //                 .typeId ??
                        //             0)
                        //         .toString()
                        //   },
                        // );
                      } else if ((viewAllProvider
                                  .continueWatchList?[position]
                                  .subVideoType ??
                              0) ==
                          2) {
                        showDetailsProvider.setLoading(true);
                        // if (!context.mounted) return;
                        // context.pushReplacementNamed(
                        //   RoutesConstant.contentDetailsPage,
                        //   extra: {
                        //     'newpage': widget.oldPage.toString(),
                        //     'videoid': (viewAllProvider
                        //                 .continueWatchList?[position].id ??
                        //             0)
                        //         .toString(),
                        //     'subvideotype': (viewAllProvider
                        //                 .continueWatchList?[position]
                        //                 .subVideoType ??
                        //             0)
                        //         .toString(),
                        //     'videotype': (viewAllProvider
                        //                 .continueWatchList?[position]
                        //                 .videoType ??
                        //             0)
                        //         .toString(),
                        //     'typeid': (viewAllProvider
                        //                 .continueWatchList?[position]
                        //                 .typeId ??
                        //             0)
                        //         .toString()
                        //   },
                        // );
                      }
                    } else {
                      if ((viewAllProvider
                                  .continueWatchList?[position]
                                  .videoType ??
                              0) ==
                          1) {
                        videoDetailsProvider.setLoading(true);
                        // if (!context.mounted) return;
                        // context.pushReplacementNamed(
                        //   RoutesConstant.contentDetailsPage,
                        //   extra: {
                        //     'newpage': widget.oldPage.toString(),
                        //     'videoid': (viewAllProvider
                        //                 .continueWatchList?[position].id ??
                        //             0)
                        //         .toString(),
                        //     'subvideotype': (viewAllProvider
                        //                 .continueWatchList?[position]
                        //                 .subVideoType ??
                        //             0)
                        //         .toString(),
                        //     'videotype': (viewAllProvider
                        //                 .continueWatchList?[position]
                        //                 .videoType ??
                        //             0)
                        //         .toString(),
                        //     'typeid': (viewAllProvider
                        //                 .continueWatchList?[position]
                        //                 .typeId ??
                        //             0)
                        //         .toString()
                        //   },
                        // );
                      } else if ((viewAllProvider
                                  .continueWatchList?[position]
                                  .videoType ??
                              0) ==
                          2) {
                        showDetailsProvider.setLoading(true);
                        // if (!context.mounted) return;
                        // context.pushReplacementNamed(
                        //   RoutesConstant.contentDetailsPage,
                        //   extra: {
                        //     'newpage': widget.oldPage.toString(),
                        //     'videoid': (viewAllProvider
                        //                 .continueWatchList?[position].id ??
                        //             0)
                        //         .toString(),
                        //     'subvideotype': (viewAllProvider
                        //                 .continueWatchList?[position]
                        //                 .subVideoType ??
                        //             0)
                        //         .toString(),
                        //     'videotype': (viewAllProvider
                        //                 .continueWatchList?[position]
                        //                 .videoType ??
                        //             0)
                        //         .toString(),
                        //     'typeid': (viewAllProvider
                        //                 .continueWatchList?[position]
                        //                 .typeId ??
                        //             0)
                        //         .toString()
                        //   },
                        // );
                      }
                    }
                    if (!context.mounted) return;
                    Utils.openDetailsWithReplace(
                      context: context,
                      videoId:
                          viewAllProvider.continueWatchList?[position].id ?? 0,
                      subVideoType:
                          viewAllProvider
                              .continueWatchList?[position]
                              .subVideoType ??
                          0,
                      videoType:
                          viewAllProvider
                              .continueWatchList?[position]
                              .videoType ??
                          0,
                      typeId:
                          viewAllProvider.continueWatchList?[position].typeId ??
                          0,
                      newPage: RoutesConstant.contentDetailsPage,
                      oldPage: "",
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
