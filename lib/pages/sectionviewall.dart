import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

import '../pages/contentbyid.dart';
import '../provider/sectionviewallprovider.dart';
import '../provider/videobyidprovider.dart';
import '../routes/routes_constant.dart';
import '../shimmer/shimmerutils.dart';
import '../utils/adhelper.dart';
import '../utils/constant.dart';
import '../utils/dimens.dart';
import '../utils/loadingoverlay.dart';
import '../utils/utils.dart';
import '../widget/nodata.dart';
import '../utils/color.dart';
import '../widget/mynetworkimg.dart';

class SectionViewAll extends StatefulWidget {
  final int sectionId, videoType;
  final String appBarTitle, screenLayout;
  const SectionViewAll({
    required this.appBarTitle,
    required this.screenLayout,
    required this.sectionId,
    required this.videoType,
    super.key,
  });

  @override
  State<SectionViewAll> createState() => SectionViewAllState();
}

class SectionViewAllState extends State<SectionViewAll> {
  Timer? _timer;
  late SectionViewAllProvider sectionViewAllProvider;
  final _scrollController = ScrollController();

  Future<void> _nestedScrollListener() async {
    if (!_scrollController.hasClients) return;
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange &&
        (sectionViewAllProvider.isMorePage ?? false)) {
      sectionViewAllProvider.setLoadMore(true);
      _fetchSectionDetails(sectionViewAllProvider.currentPage ?? 0);
    }
  }

  Future<void> _fetchSectionDetails(int? nextPage) async {
    printLog("_fetchSectionDetails nextPage  ========> $nextPage");
    printLog(
      "_fetchSectionDetails isMorePage  ======> ${sectionViewAllProvider.isMorePage}",
    );
    printLog(
      "_fetchSectionDetails currentPage ======> ${sectionViewAllProvider.currentPage}",
    );
    printLog(
      "_fetchSectionDetails totalPage   ======> ${sectionViewAllProvider.totalPage}",
    );

    await sectionViewAllProvider.getSectionDetails(
      widget.sectionId,
      (nextPage ?? 0) + 1,
    );
    printLog(
      "sectionDetailsList length ==> ${sectionViewAllProvider.sectionDetailList?.length}",
    );
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    if (!widget.screenLayout.contains("index")) {
      _scrollController.addListener(_nestedScrollListener);
    }
    sectionViewAllProvider = Provider.of<SectionViewAllProvider>(
      context,
      listen: false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
  }

  Future<void> _getData() async {
    // Always load the first page
    await _fetchSectionDetails(0);

    final isAutoLoadType =
        (widget.videoType == Constant.genresType ||
        widget.videoType == Constant.languageType ||
        widget.videoType == Constant.channelType);

    if (isAutoLoadType) {
      _timer = Timer.periodic(const Duration(milliseconds: 400), (timer) async {
        if (sectionViewAllProvider.isMorePage == true) {
          sectionViewAllProvider.setLoadMore(true);
          await _fetchSectionDetails(sectionViewAllProvider.currentPage ?? 0);
        } else {
          printLog("======== CANCELLED ========");
          timer.cancel();
        }
      });
    } else if (!widget.screenLayout.contains("index")) {
      Future.delayed(const Duration(milliseconds: 400)).then((value) async {
        if (sectionViewAllProvider.isMorePage == true) {
          sectionViewAllProvider.setLoadMore(true);
          await _fetchSectionDetails(sectionViewAllProvider.currentPage ?? 0);
        }
      });
    }
  }

  @override
  void dispose() {
    sectionViewAllProvider.clearProvider();
    _timer?.cancel();
    LoadingOverlay().hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      appBar: Utils.myAppBarWithBack(context, widget.appBarTitle, false),
      bottomNavigationBar: SmartBannerAd(isSpacing: true, bottomSpace: 10),
      body: SafeArea(child: _buildPage()),
    );
  }

  Widget _buildPage() {
    if (sectionViewAllProvider.loading && !sectionViewAllProvider.loadMore) {
      if (widget.videoType == Constant.genresType ||
          widget.videoType == Constant.languageType) {
        return SingleChildScrollView(
          child: ShimmerUtils.responsiveGrid2(
            context,
            Dimens.heightGen,
            Dimens.widthGen,
            3,
            14,
            12,
            12,
          ),
        );
      } else if (widget.videoType == Constant.channelType) {
        return SingleChildScrollView(
          child: ShimmerUtils.responsiveGrid2(
            context,
            Dimens.heightChannel,
            Dimens.widthChannel,
            4,
            14,
            12,
            12,
          ),
        );
      } else {
        return SingleChildScrollView(
          child: ShimmerUtils.responsiveGrid2(
            context,
            Dimens.heightPortOther,
            Dimens.widthPortOther,
            3,
            14,
            12,
            12,
          ),
        );
      }
    }
    if (sectionViewAllProvider.sectionDetailList != null &&
        (sectionViewAllProvider.sectionDetailList?.length ?? 0) > 0) {
      return RefreshIndicator(
        backgroundColor: white,
        color: complimentryColor,
        displacement: 80,
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 1500)).then((
            value,
          ) {
            sectionViewAllProvider.setLoading(true);
            Future.delayed(Duration.zero).then((value) {
              if (!mounted) return;
              setState(() {});
            });
            _getData();
          });
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              if (widget.videoType == Constant.genresType)
                _buildGenres()
              else if (widget.videoType == Constant.languageType)
                _buildLanguage()
              else if (widget.videoType == Constant.channelType)
                _buildChannelItem()
              else
                _buildVideoItem(),

              /* Pagination loader */
              Consumer<SectionViewAllProvider>(
                builder: (context, sectionViewAllProvider, child) {
                  if (sectionViewAllProvider.loadMore) {
                    return Container(
                      height: 80,
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.center,
                      child: Utils.pageLoader(),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ],
          ),
        ),
      );
    } else {
      return NoData(
        title: (widget.videoType == Constant.genresType)
            ? 'no_category_title'
            : ((widget.videoType == Constant.languageType)
                  ? 'no_language_title'
                  : ((widget.videoType == Constant.channelType)
                        ? 'no_channel_title'
                        : 'no_data')),
        subTitle: (widget.videoType == Constant.genresType)
            ? 'no_category_desc'
            : ((widget.videoType == Constant.languageType)
                  ? 'no_language_desc'
                  : ((widget.videoType == Constant.channelType)
                        ? 'no_channel_desc'
                        : 'no_video_show')),
      );
    }
  }

  Widget _buildVideoItem() {
    final bool isLandscape = widget.screenLayout.contains("landscape");
    final double cardRadius = Dimens.isBigScreen(context) ? 10.0 : 8.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: ResponsiveGridList(
        minItemWidth: isLandscape ? 160 : Dimens.widthPortOther,
        verticalGridSpacing: 14,
        horizontalGridSpacing: 12,
        minItemsPerRow: isLandscape ? 2 : 3,
        maxItemsPerRow: 8,
        listViewBuilderOptions: ListViewBuilderOptions(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
        ),
        children: List.generate(
          (sectionViewAllProvider.sectionDetailList?.length ?? 0),
          (position) {
            final item = sectionViewAllProvider.sectionDetailList?[position];
            final String imageUrl = isLandscape
                ? ((item?.landscape != null &&
                        item!.landscape!.isNotEmpty &&
                        !item.landscape!.contains('no_img'))
                    ? item.landscape!
                    : (item?.thumbnail ?? ""))
                : ((item?.thumbnail != null &&
                        item!.thumbnail!.isNotEmpty &&
                        !item.thumbnail!.contains('no_img'))
                    ? item.thumbnail!
                    : (item?.landscape ?? ""));

            return AspectRatio(
              aspectRatio: isLandscape
                  ? (16 / 9)
                  : (Dimens.widthPortOther / Dimens.heightPortOther),
              child: Container(
                decoration: BoxDecoration(
                  color: lightBlack,
                  borderRadius: BorderRadius.circular(cardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: black.withValues(alpha: 0.35),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(cardRadius),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(cardRadius),
                    onTap: () {
                      printLog("Clicked on position ==> $position");
                      Utils.openDetails(
                        context: context,
                        videoId: item?.id ?? 0,
                        subVideoType: item?.subVideoType ?? 0,
                        videoType: item?.videoType ?? 0,
                        typeId: item?.typeId ?? 0,
                        newPage: RoutesConstant.contentDetailsPage,
                        oldPage: "",
                        reqText: "",
                      );
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MyNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          height: double.infinity,
                          width: double.infinity,
                        ),
                        /* Rent / Premium Tag */
                        if ((item?.isPremium ?? 0) == 1 ||
                            (item?.isRent ?? 0) == 1)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Utils.buildRentPremiumTAG(
                              context: context,
                              isPremium: item?.isPremium ?? 0,
                              isRent: item?.isRent ?? 0,
                              rentPrice: item?.price ?? 0,
                            ),
                          ),
                      ],
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

  Widget _buildChannelItem() {
    final double cardRadius = Dimens.isBigScreen(context) ? 10.0 : 8.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: ResponsiveGridList(
        minItemWidth: Dimens.widthChannel,
        verticalGridSpacing: 14,
        horizontalGridSpacing: 12,
        minItemsPerRow: 4,
        maxItemsPerRow: 8,
        listViewBuilderOptions: ListViewBuilderOptions(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
        ),
        children: List.generate(
          (sectionViewAllProvider.sectionDetailList?.length ?? 0),
          (position) {
            final item = sectionViewAllProvider.sectionDetailList?[position];
            return Container(
              decoration: BoxDecoration(
                color: lightBlack,
                borderRadius: BorderRadius.circular(cardRadius),
                boxShadow: [
                  BoxShadow(
                    color: black.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(cardRadius),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  borderRadius: BorderRadius.circular(cardRadius),
                  focusColor: white,
                  onTap: () async {
                    printLog("Clicked on position ==> $position");
                    final videoByIDProvider = Provider.of<VideoByIDProvider>(
                      context,
                      listen: false,
                    );
                    videoByIDProvider.setLoading(true);
                    if (!mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return ContentByID(
                            item?.id ?? 0,
                            item?.name ?? "",
                            "ByChannel",
                          );
                        },
                      ),
                    );
                  },
                  child: AspectRatio(
                    aspectRatio: Dimens.widthChannel / Dimens.heightChannel,
                    child: MyNetworkImage(
                      imageUrl: item?.landscapeImg?.toString() ?? "",
                      fit: BoxFit.fill,
                      width: double.infinity,
                      height: double.infinity,
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

  Widget _buildLanguage() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: ResponsiveGridList(
        minItemWidth: Dimens.widthLangViewAll,
        verticalGridSpacing: 14,
        horizontalGridSpacing: 12,
        minItemsPerRow: 3,
        maxItemsPerRow: 8,
        listViewBuilderOptions: ListViewBuilderOptions(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
        ),
        children: List.generate(
          (sectionViewAllProvider.sectionDetailList?.length ?? 0),
          (position) {
            return Container(
              height: Dimens.heightLangViewAll,
              width: Dimens.widthLangViewAll,
              alignment: Alignment.center,
              child: InkWell(
                borderRadius: BorderRadius.circular(
                  Dimens.heightLangViewAll / 2,
                ),
                focusColor: white,
                onTap: () async {
                  printLog("Clicked on position ==> $position");
                  final videoByIDProvider = Provider.of<VideoByIDProvider>(
                    context,
                    listen: false,
                  );
                  videoByIDProvider.setLoading(true);
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return ContentByID(
                          sectionViewAllProvider
                                  .sectionDetailList?[position]
                                  .id ??
                              0,
                          sectionViewAllProvider
                                  .sectionDetailList?[position]
                                  .name ??
                              "",
                          "ByLanguage",
                        );
                      },
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    Dimens.heightLangViewAll / 2,
                  ),
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  child: MyNetworkImage(
                    imageUrl:
                        sectionViewAllProvider
                            .sectionDetailList?[position]
                            .image
                            .toString() ??
                        "",
                    fit: BoxFit.fill,
                    height: Dimens.heightLangViewAll,
                    width: Dimens.widthLangViewAll,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGenres() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: ResponsiveGridList(
        minItemWidth: Dimens.widthGen,
        verticalGridSpacing: 14,
        horizontalGridSpacing: 12,
        minItemsPerRow: 3,
        maxItemsPerRow: 8,
        listViewBuilderOptions: ListViewBuilderOptions(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
        ),
        children: List.generate(
          (sectionViewAllProvider.sectionDetailList?.length ?? 0),
          (position) {
            return Container(
              height: Dimens.heightGen,
              width: Dimens.widthGen,
              alignment: Alignment.center,
              child: InkWell(
                focusColor: white,
                borderRadius: BorderRadius.circular(8.0),
                onTap: () async {
                  printLog("Clicked on position ==> $position");
                  final videoByIDProvider = Provider.of<VideoByIDProvider>(
                    context,
                    listen: false,
                  );
                  videoByIDProvider.setLoading(true);
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return ContentByID(
                          sectionViewAllProvider
                                  .sectionDetailList?[position]
                                  .id ??
                              0,
                          sectionViewAllProvider
                                  .sectionDetailList?[position]
                                  .name ??
                              "",
                          "ByCategory",
                        );
                      },
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Dimens.widthGen / 2),
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  child: MyNetworkImage(
                    imageUrl:
                        sectionViewAllProvider
                            .sectionDetailList?[position]
                            .image
                            .toString() ??
                        "",
                    fit: BoxFit.fill,
                    height: Dimens.heightGen,
                    width: Dimens.widthGen,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
