import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../provider/findprovider.dart';
import '../routes/routes_constant.dart';
import '../shimmer/shimmerutils.dart';
import '../utils/adhelper.dart';
import '../utils/color.dart';
import '../utils/dimens.dart';
import '../utils/loadingoverlay.dart';
import '../utils/utils.dart';
import '../widget/myimage.dart';
import '../widget/mynetworkimg.dart';
import '../widget/mytext.dart';
import '../widget/nodata.dart';

class Find extends StatefulWidget {
  final String viewFrom;
  const Find({super.key, required this.viewFrom});

  @override
  State<Find> createState() => FindState();
}

class FindState extends State<Find> {
  late FindProvider findProvider;
  final SpeechToText _speechToText = SpeechToText();
  final nestedScrollController = ScrollController();
  final searchController = TextEditingController();

  /* Pagination START *********** */
  Future<void> _nestedScrollListener() async {
    if (!nestedScrollController.hasClients) return;
    if (nestedScrollController.offset >=
            nestedScrollController.position.maxScrollExtent &&
        !nestedScrollController.position.outOfRange &&
        (findProvider.isMorePage ?? false)) {
      findProvider.setLoadMore(true);
      _fetchNewPageData(findProvider.currentPage ?? 0);
    }
  }

  Future<void> _fetchNewPageData(int? nextPage) async {
    printLog("_fetchNewPageData nextPage  ========> $nextPage");
    printLog(
      "_fetchNewPageData isMorePage  ======> ${findProvider.isMorePage}",
    );
    printLog(
      "_fetchNewPageData currentPage ======> ${findProvider.currentPage}",
    );
    printLog("_fetchNewPageData totalPage   ======> ${findProvider.totalPage}");

    await findProvider.getSearchContent(
      searchController.text.toString(),
      (nextPage ?? 0) + 1,
    );
    printLog(
      "searchDataList length ==> ${findProvider.searchDataList?.length}",
    );
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }
  /* ************* Pagination END */

  @override
  void initState() {
    super.initState();
    nestedScrollController.addListener(_nestedScrollListener);
    findProvider = Provider.of<FindProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
    _initSpeech();
  }

  Future<void> _getData() async {
    await findProvider.getSearchContent("", 1);
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  /* Search Data by Type START *********** */
  Future<void> getTabData() async {
    if (!mounted) return;
    if (nestedScrollController.hasClients) {
      await nestedScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.linear,
      );
    }

    findProvider.setSearchLoading(true);
    await findProvider.clearSearchData();
    if (searchController.text.toString().isEmpty) {
      await findProvider.getSearchContent("", 1);
      return;
    }
    printLog("searchController ====> ${searchController.text}");
    await findProvider.getSearchContent(searchController.text.toString(), 1);
  }
  /* ************* Search Data by Type END */

  /* Speech To Text START *********** */
  void _initSpeech() async {
    bool? speechEnabled = await _speechToText.initialize();
    printLog("speechEnabled =============> $speechEnabled");
    findProvider.setSpeechStatus(speechEnabled);
  }

  void _startListening() async {
    printLog("<============== _startListening ==============>");
    await findProvider.setSpeechListening(true);
    await _speechToText.listen(onResult: _onSpeechResult);
    Future.delayed(const Duration(seconds: 10), () {
      if (findProvider.isListening &&
          searchController.text.toString().isEmpty) {
        if (!mounted) return;
        Utils.showSnackbar(context, "info", "speechnotavailable", true);
        _stopListening();
      }
    });
  }

  void _stopListening() async {
    printLog("<============== _stopListening ==============>");
    await _speechToText.stop();
    findProvider.setSpeechLastWord("");
    await findProvider.setSpeechListening(false);
  }

  void _onSpeechResult(SpeechRecognitionResult result) async {
    printLog("<============== _onSpeechResult ==============>");
    printLog("recognizedWords ========> ${result.recognizedWords}");
    findProvider.setSpeechLastWord(result.recognizedWords);
    printLog("_lastWords =============> ${findProvider.lastWords}");
    if (findProvider.lastWords.isNotEmpty) {
      searchController.text = findProvider.lastWords.toString();
      await findProvider.setSpeechListening(false);
      if (!mounted) return;
      getTabData();
    }
  }
  /* *********** Speech To Text END */

  @override
  void dispose() {
    super.dispose();
    _stopListening();
    searchController.dispose();
    findProvider.clearProvider();
    LoadingOverlay().hide();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: appBgColor,
      body: SafeArea(
        child: Consumer<FindProvider>(
          builder: (context, findProvider, child) {
            return Stack(
              alignment: Alignment.topCenter,
              children: [
                _buildSearchData(),
                /* Type List */
                _buildPage(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPage() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            appBgColor,
            appBgColor.withValues(alpha: 0.9),
            appBgColor.withValues(alpha: 0.8),
            appBgColor.withValues(alpha: 0.7),
            appBgColor.withValues(alpha: 0.6),
            appBgColor.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Column(
        children: [
          _buildSearchBox(),
          Container(
            alignment: Alignment.centerLeft,
            margin: const EdgeInsets.fromLTRB(20, 10, 20, 5),
            child: MyText(
              color: titleTextColor,
              text: "people_search_for",
              multilanguage: true,
              textalign: TextAlign.start,
              fontsizeNormal: 15,
              fontweight: FontWeight.w600,
              fontsizeWeb: 17,
              maxline: 1,
              overflow: TextOverflow.ellipsis,
              fontstyle: FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  /* Search View */
  Widget _buildSearchBox() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 55,
      margin: const EdgeInsets.fromLTRB(20, 5, 20, 5),
      decoration: Utils.setBackground(white, 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: () {
              if (widget.viewFrom == RoutesConstant.homePage) {
                Utils.exitPage(context);
              }
            },
            child: Container(
              width: 42,
              height: MediaQuery.of(context).size.width,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(14),
              child: MyImage(
                imagePath: (widget.viewFrom == RoutesConstant.homePage)
                    ? "back.png"
                    : "ic_find.png",
                color: defaultIconColor,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: TextField(
                onSubmitted: (value) async {
                  printLog("value ====> $value");
                  if (value.isNotEmpty) {
                    // if (!mounted) return;
                    // getTabData();
                  }
                },
                onChanged: (value) async {
                  if (!mounted) return;
                  getTabData();
                },
                textInputAction: TextInputAction.done,
                obscureText: false,
                controller: searchController,
                keyboardType: TextInputType.text,
                maxLines: 1,
                style: GoogleFonts.inter(
                  textStyle: const TextStyle(
                    color: black,
                    fontSize: 16,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  filled: true,
                  fillColor: transparent,
                  hintStyle: TextStyle(
                    color: descTextColor,
                    fontSize: 15,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.w500,
                  ),
                  hintText: Locales.string(context, "search_here"),
                ),
              ),
            ),
          ),
          if (searchController.text.toString().isNotEmpty)
            InkWell(
              borderRadius: BorderRadius.circular(5),
              onTap: () async {
                printLog("Click on Clear!");
                searchController.clear();
                getTabData();
              },
              child: Container(
                width: 42,
                padding: const EdgeInsets.all(13),
                alignment: Alignment.center,
                child: MyImage(
                  imagePath: "ic_close.png",
                  color: defaultIconColor,
                  fit: BoxFit.contain,
                ),
              ),
            )
          else
            InkWell(
              borderRadius: BorderRadius.circular(5),
              onTap: () async {
                printLog("Click on Microphone!");
                if (!findProvider.isListening) {
                  _startListening();
                }
              },
              child: findProvider.isListening
                  ? AvatarGlow(
                      glowColor: colorPrimary,
                      glowShape: BoxShape.circle,
                      duration: const Duration(milliseconds: 2000),
                      repeat: true,
                      glowCount: 3,
                      child: Material(
                        elevation: 5,
                        color: transparent,
                        shape: const CircleBorder(),
                        child: Container(
                          width: 42,
                          padding: const EdgeInsets.all(15),
                          color: transparent,
                          alignment: Alignment.center,
                          child: MyImage(
                            imagePath: "ic_voice.png",
                            color: defaultIconColor,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      width: 42,
                      padding: const EdgeInsets.all(15),
                      alignment: Alignment.center,
                      child: MyImage(
                        imagePath: "ic_voice.png",
                        color: defaultIconColor,
                        fit: BoxFit.contain,
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  /* Search Data */
  Widget _buildSearchData() {
    if (findProvider.loadingSearch && !findProvider.loadMore) {
      return ShimmerUtils.buildFindShimmer(context);
    }
    if (findProvider.searchDataList == null ||
        (findProvider.searchDataList?.length ?? 0) == 0) {
      return const NoData(title: 'no_search_title', subTitle: 'no_search_desc');
    }
    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: const BoxConstraints.expand(),
      padding: const EdgeInsets.fromLTRB(0, 105, 0, 0),
      child: RefreshIndicator(
        backgroundColor: white,
        color: complimentryColor,
        displacement: 80,
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 1500)).then((
            value,
          ) {
            if (!mounted) return;
            _getData();
            getTabData();
          });
        },
        child: SingleChildScrollView(
          controller: nestedScrollController,
          padding: const EdgeInsets.fromLTRB(3, 8, 3, 15),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              /* Banner Ad */
              SmartBannerAd(isSpacing: true, bottomSpace: 10),
              StaggeredGrid.count(
                crossAxisCount: 6, // Keep this Fix
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                children: Utils.buildGroupedTiles(
                  dataCount: findProvider.searchDataList?.length ?? 0,
                  contentItem: _buildVideoContent,
                ),
              ),
              /* Pagination loader */
              if (findProvider.loadMore)
                Container(
                  height: 80,
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.center,
                  child: Utils.pageLoader(),
                )
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoContent({required int position}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Dimens.cardRadiusMedium),
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimens.cardRadiusMedium),
        onTap: () {
          printLog("Clicked on position ==> $position");
          Utils.openDetails(
            context: context,
            videoId: findProvider.searchDataList?[position].id ?? 0,
            subVideoType:
                findProvider.searchDataList?[position].subVideoType ?? 0,
            videoType: findProvider.searchDataList?[position].videoType ?? 0,
            typeId: findProvider.searchDataList?[position].typeId ?? 0,
            newPage:
                ((findProvider.searchDataList?[position].subVideoType ?? 0) ==
                        2 ||
                    (findProvider.searchDataList?[position].videoType ?? 0) ==
                        2)
                ? RoutesConstant.contentDetailsPage
                : RoutesConstant.contentDetailsPage,
            oldPage: '',
            reqText: '',
          );
        },
        child: Stack(
          alignment: AlignmentDirectional.topEnd,
          children: [
            Container(
              alignment: Alignment.center,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Dimens.cardRadius),
                clipBehavior: Clip.antiAliasWithSaveLayer,
                child: MyNetworkImage(
                  imageUrl:
                      findProvider.searchDataList?[position].thumbnail
                          .toString() ??
                      "",
                  fit: BoxFit.cover,
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 0,
              child: Utils.buildRentPremiumTAG(
                context: context,
                isPremium:
                    findProvider.searchDataList?[position].isPremium ?? 0,
                isRent: findProvider.searchDataList?[position].isRent ?? 0,
                rentPrice: findProvider.searchDataList?[position].price ?? 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
