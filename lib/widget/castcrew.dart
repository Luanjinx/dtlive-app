import '../model/contentdetailmodel.dart';
import '../pages/contentbyid.dart';
import '../provider/videobyidprovider.dart';
import '../routes/routes_constant.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/dimens.dart';
import '../utils/utils.dart';
import '../webwidget/leftright_scroll_on_hover.dart';
import '../widget/mytext.dart';
import '../widget/myusernetworkimg.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../webwidget/interactive_icon.dart';

class CastCrew extends StatefulWidget {
  final String? newPage;
  final List<Cast>? castList;
  const CastCrew({required this.castList, required this.newPage, super.key});

  @override
  State<CastCrew> createState() => _CastCrewState();
}

class _CastCrewState extends State<CastCrew> {
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
    return Column(
      children: [
        if (widget.castList == null || (widget.castList?.isEmpty ?? true))
          SizedBox.shrink()
        else ...[
          SizedBox(height: Dimens.isBigScreen(context) ? 30 : 20),
          Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(
              left: Dimens.isBigScreen(context) ? 0 : 10,
              right: Dimens.isBigScreen(context) ? 0 : 10,
            ),
            child: MyText(
              color: titleTextColor,
              text: "castandcrew",
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
          Container(
            width: MediaQuery.of(context).size.width,
            height: 0.5,
            color: grayDark,
            margin: EdgeInsets.fromLTRB(
              Dimens.isBigScreen(context) ? 0 : 10,
              5,
              Dimens.isBigScreen(context) ? 0 : 10,
              18,
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: (Dimens.isBigScreen(context)
                ? (Dimens.heightCastWeb + 28)
                : (Dimens.heightCast + 25)),
            child: _buildList(),
          ),
          SizedBox(height: 15),
        ],
      ],
    );
  }

  Widget _buildList() {
    final bool bigScreen = Dimens.isBigScreen(context);
    final double cardW = bigScreen ? Dimens.widthCastWeb : Dimens.widthCast;
    final double cardH = bigScreen ? Dimens.heightCastWeb : Dimens.heightCast;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: bigScreen ? 0 : 10),
      scrollDirection: Axis.horizontal,
      physics: const AlwaysScrollableScrollPhysics(),
      child: LeftRightScrollOnHover(
        scrollController: relatedScrollController,
        itemCount: widget.castList?.length ?? 0,
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
          itemCount: widget.castList?.length ?? 0,
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (context, position) => SizedBox(
            width: bigScreen
                ? Dimens.spaceBetweenCardsWeb
                : Dimens.spaceBetweenCards,
          ),
          itemBuilder: (BuildContext context, int position) {
            return InteractiveIcon(
              builder: (isHovered) => GestureDetector(
                onTap: () async {
                  printLog("Item Clicked! => $position");
                  final videoByIDProvider = Provider.of<VideoByIDProvider>(
                    context,
                    listen: false,
                  );
                  videoByIDProvider.setLoading(true);
                  if (!mounted) return;
                  if (kIsWeb || Constant.isTV) {
                    context.go(
                      "/${RoutesConstant.videoByCastPage}/${widget.castList?[position].id ?? 0}",
                      extra: {
                        'newpage': widget.newPage.toString(),
                        'itemid': (widget.castList?[position].id ?? 0)
                            .toString(),
                        'title': widget.castList?[position].name ?? '',
                        'layouttype': 'ByCast',
                      },
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return ContentByID(
                            widget.castList?[position].id ?? 0,
                            widget.castList?[position].name ?? "",
                            'ByCast',
                          );
                        },
                      ),
                    );
                  }
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: cardW,
                        height: cardH,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            bigScreen
                                ? Dimens.cardRadiusMedium
                                : Dimens.cardRadius,
                          ),
                          border: Border.all(
                            color: isHovered
                                ? colorPrimary.withValues(alpha: 0.55)
                                : transparent,
                            width: 2,
                          ),
                          boxShadow: isHovered
                              ? [
                                  BoxShadow(
                                    color: colorPrimary.withValues(alpha: 0.25),
                                    blurRadius: 14,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            bigScreen
                                ? Dimens.cardRadiusMedium
                                : Dimens.cardRadius,
                          ),
                          child: Transform.scale(
                            scale: isHovered ? 1.05 : 1.0,
                            child: MyUserNetworkImage(
                              imageUrl: widget.castList?[position].image ?? "",
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: cardW,
                        child: MyText(
                          color: isHovered ? colorPrimary : titleTextColor,
                          multilanguage: false,
                          text: widget.castList?[position].name ?? "",
                          fontstyle: FontStyle.normal,
                          maxline: 1,
                          fontsizeNormal: 12,
                          fontsizeWeb: 14,
                          fontweight: FontWeight.w500,
                          overflow: TextOverflow.ellipsis,
                          textalign: TextAlign.center,
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
  }
}
