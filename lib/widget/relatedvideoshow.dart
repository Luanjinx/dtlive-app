import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../model/relatedcontentmodel.dart';
import '../pages/viewall.dart';
import '../provider/viewallprovider.dart';
import '../routes/routes_constant.dart';
import '../utils/color.dart';
import '../utils/utils.dart';
import '../utils/constant.dart';
import '../utils/dimens.dart';
import '../webwidget/leftright_scroll_on_hover.dart';
import '../webwidget/web_hover_card.dart';
import '../widget/myimage.dart';
import '../widget/mytext.dart';

class RelatedVideoShow extends StatefulWidget {
  final int videoId, subVideoType, videoType, typeId;
  final String? newPage, oldPage;
  final dynamic reqText;
  final List<Result>? relatedDataList;
  const RelatedVideoShow({
    required this.relatedDataList,
    required this.newPage,
    required this.oldPage,
    required this.reqText,
    required this.videoId,
    required this.subVideoType,
    required this.videoType,
    required this.typeId,
    super.key,
  });

  @override
  State<RelatedVideoShow> createState() => _RelatedVideoShowState();
}

class _RelatedVideoShowState extends State<RelatedVideoShow> {
  final relatedScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    relatedScrollController.dispose();
    printLog("dispose");
  }

  @override
  Widget build(BuildContext context) {
    final bool bigScreen = Dimens.isBigScreen(context);
    if (widget.relatedDataList != null &&
        (widget.relatedDataList?.length ?? 0) > 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 25),
          _buildTitleViewAll(),
          Container(
            width: MediaQuery.of(context).size.width,
            height: 0.5,
            margin: EdgeInsets.fromLTRB(
              bigScreen ? 0 : 10,
              5,
              bigScreen ? 0 : 10,
              18,
            ),
            color: grayDark,
          ),
          /* video_type =>  1-video,  2-show,  3-language,  4-category */
          /* screen_layout =>  landscape, potrait, square */
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height:
                (Dimens.isBigScreen(context)
                    ? Dimens.heightPortWeb
                    : Dimens.heightPort) +
                20,
            child: _buildList(widget.relatedDataList),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildTitleViewAll() {
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(
        left: Dimens.isBigScreen(context) ? 0 : 10,
        right: Dimens.isBigScreen(context) ? 0 : 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.centerLeft,
              child: MyText(
                color: titleTextColor,
                text: "customer_also_watch",
                multilanguage: true,
                textalign: TextAlign.start,
                fontsizeNormal: 17,
                fontsizeWeb: 19,
                fontweight: FontWeight.w500,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
                fontstyle: FontStyle.normal,
              ),
            ),
          ),
          InkWell(
            onTap: () async {
              final viewAllProvider = Provider.of<ViewAllProvider>(
                context,
                listen: false,
              );
              viewAllProvider.setLoading(true);
              if (!mounted) return;
              if (kIsWeb || Constant.isTV) {
                context.go(
                  (widget.subVideoType != 0)
                      ? "/${RoutesConstant.relatedContentPage}/${widget.videoId}/${widget.typeId}/${widget.videoType}/${widget.subVideoType}"
                      : "/${RoutesConstant.relatedContentPage}/${widget.videoId}/${widget.typeId}/${widget.videoType}",
                  extra: {
                    'newpage': widget.oldPage.toString(),
                    'title': RoutesConstant.relatedContentPage,
                    'itemid': widget.videoId.toString(),
                    'subvideotype': widget.subVideoType.toString(),
                    'videotype': widget.videoType.toString(),
                    'typeid': widget.typeId.toString(),
                  },
                );
              } else {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return ViewAll(
                        appBarTitle: RoutesConstant.relatedContentPage,
                        videoId: widget.videoId,
                        subVideoType: widget.subVideoType,
                        videoType: widget.videoType,
                        typeId: widget.typeId,
                      );
                    },
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(3),
            child: Container(
              alignment: Alignment.centerRight,
              height: 25,
              padding: const EdgeInsets.all(6),
              child: MyImage(imagePath: "ic_viewall.png", fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Result>? relatedDataList) {
    final bool bigScreen = Dimens.isBigScreen(context);
    final double cardW = bigScreen ? Dimens.widthPortWeb : Dimens.widthPort;
    final double cardH = bigScreen ? Dimens.heightPortWeb : Dimens.heightPort;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const AlwaysScrollableScrollPhysics(),
      child: LeftRightScrollOnHover(
        scrollController: relatedScrollController,
        itemCount: relatedDataList?.length ?? 0,
        itemSpacing: bigScreen
            ? Dimens.spaceBetweenCardsWeb
            : Dimens.spaceBetweenCards,
        itemWidth: cardW,
        height: cardH + 20,
        onLeftTap: () {
          Utils.scrollContentView(
            context: context,
            forward: false,
            scrollController: relatedScrollController,
          );
        },
        onRightTap: () {
          Utils.scrollContentView(
            context: context,
            forward: true,
            scrollController: relatedScrollController,
          );
        },
        child: ListView.separated(
          controller: relatedScrollController,
          itemCount: relatedDataList?.length ?? 0,
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          separatorBuilder: (context, index) => SizedBox(
            width: bigScreen
                ? Dimens.spaceBetweenCardsWeb
                : Dimens.spaceBetweenCards,
          ),
          itemBuilder: (BuildContext context, int index) {
            return WebHoverCard(
              cardW: cardW,
              cardH: cardH,
              borderRadius: bigScreen
                  ? Dimens.cardRadiusMedium
                  : Dimens.cardRadius,
              imageUrl: relatedDataList?[index].thumbnail.toString() ?? "",
              onTap: () async {
                printLog("Clicked on index ==> $index");
                if (!mounted) return;
                Utils.openDetailsWithReplace(
                  context: context,
                  videoId: relatedDataList?[index].id ?? 0,
                  subVideoType: relatedDataList?[index].subVideoType ?? 0,
                  videoType: relatedDataList?[index].videoType ?? 0,
                  typeId: relatedDataList?[index].typeId ?? 0,
                  newPage: RoutesConstant.contentDetailsPage,
                  oldPage: widget.newPage ?? "",
                  reqText: '',
                );
              },
              overlay: (relatedDataList?[index].isTitle == 1)
                  ? Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(6, 20, 6, 7),
                        decoration: Utils.setGradTTBBGWithCenter(
                          transparent,
                          appBgColor.withValues(alpha: 0.1),
                          appBgColor,
                          0,
                        ),
                        child: MyText(
                          color: white,
                          multilanguage: false,
                          text: relatedDataList?[index].name.toString() ?? "",
                          fontsizeNormal: 13,
                          fontweight: FontWeight.w600,
                          fontsizeWeb: 15,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          textalign: TextAlign.start,
                          fontstyle: FontStyle.normal,
                        ),
                      ),
                    )
                  : null,
            );
          },
        ),
      ),
    );
  }
}
