import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../provider/findprovider.dart';
import '../provider/generalprovider.dart';
import '../provider/homeprovider.dart';
import '../provider/profileprovider.dart';
import '../model/sectiontypemodel.dart' as type;
import '../provider/purchaselistprovider.dart';
import '../provider/rentstoreprovider.dart';
import '../provider/sectiondataprovider.dart';
import '../provider/sectionviewallprovider.dart';
import '../provider/subhistoryprovider.dart';
import '../provider/videobyidprovider.dart';
import '../provider/viewallprovider.dart';
import '../provider/watchlistprovider.dart';
import '../pushservice/pushnotificationservice.dart';
import '../routes/routes_constant.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/dimens.dart';
import '../utils/sharedpre.dart';
import '../utils/utils.dart';
import '../web_js/js_helper.dart';
import '../webwidget/interactive_icon.dart';
import '../webwidget/webarrowkeyscroll.dart';
import '../webwidget/webfooter.dart';
import '../widget/myimage.dart';
import '../widget/mynetworkimg.dart';
import '../widget/mytext.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';

class WebComman extends StatefulWidget {
  final String? newPage, oldPage;
  final dynamic reqText;
  final Widget newChild;
  const WebComman({
    required this.newChild,
    required this.newPage,
    required this.oldPage,
    required this.reqText,
    super.key,
  });

  @override
  State<WebComman> createState() => _WebCommanState();
}

class _WebCommanState extends State<WebComman> with RouteAware {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  SharedPre sharePref = SharedPre();
  final JSHelper jsHelper = JSHelper();

  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _mobileTabScrollController = ScrollController();

  late SectionDataProvider sectionDataProvider;
  late RentStoreProvider rentStoreProvider;
  late VideoByIDProvider videoByIDProvider;
  late ProfileProvider profileProvider;
  late HomeProvider homeProvider;
  late FindProvider findProvider;
  late SectionViewAllProvider sectionViewAllProvider;
  late ViewAllProvider viewAllProvider;
  late WatchlistProvider watchlistProvider;
  late PurchaselistProvider purchaselistProvider;
  late GeneralProvider generalProvider;
  late SubHistoryProvider subHistoryProvider;

  String? currentPage, rentMenuStatus;
  dynamic reqText;
  bool _isNavScrolled = false;

  void _scrollUp() {
    if (!_mainScrollController.hasClients) return;
    _mainScrollController.animateTo(
      _mainScrollController.position.minScrollExtent,
      duration: const Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _scrollDown() {
    if (!_mainScrollController.hasClients) return;
    _mainScrollController.animateTo(
      _mainScrollController.position.maxScrollExtent,
      duration: const Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  Future<void> _scrollListener() async {
    final bool wasScrolled = _isNavScrolled;
    final bool nowScrolled = _mainScrollController.offset > 10;
    if (wasScrolled != nowScrolled) {
      setState(() => _isNavScrolled = nowScrolled);
    }
    if (_mainScrollController.offset >=
            _mainScrollController.position.maxScrollExtent &&
        !_mainScrollController.position.outOfRange) {
      setState(() {});
    }
    if (_mainScrollController.offset <=
            _mainScrollController.position.minScrollExtent &&
        !_mainScrollController.position.outOfRange) {
      setState(() {});
    }
    /* Home Sections */
    if (_mainScrollController.offset >=
            _mainScrollController.position.maxScrollExtent &&
        !_mainScrollController.position.outOfRange &&
        (sectionDataProvider.isMorePage ?? false) &&
        widget.newPage == RoutesConstant.homePage) {
      sectionDataProvider.setLoadMore(true);
      _fetchSectionData(sectionDataProvider.currentPage ?? 0);
    }

    /* Rent Store */
    if (_mainScrollController.offset >=
            _mainScrollController.position.maxScrollExtent &&
        !_mainScrollController.position.outOfRange &&
        (rentStoreProvider.isMorePage ?? false) &&
        widget.newPage == RoutesConstant.storePage) {
      rentStoreProvider.setLoadMore(true);
      _fetchRentNewData(rentStoreProvider.currentPage ?? 0);
    }

    /* Content By Id */
    if (_mainScrollController.offset >=
            _mainScrollController.position.maxScrollExtent &&
        !_mainScrollController.position.outOfRange &&
        (videoByIDProvider.isMorePage ?? false) &&
        (widget.newPage == RoutesConstant.videoByCatPage ||
            widget.newPage == RoutesConstant.videoByChannelPage ||
            widget.newPage == RoutesConstant.videoByLanguagePage)) {
      videoByIDProvider.setLoadMore(true);
      _fetchNewContentById(videoByIDProvider.currentPage ?? 0);
    }

    /* Content By Section */
    if (_mainScrollController.offset >=
            _mainScrollController.position.maxScrollExtent &&
        !_mainScrollController.position.outOfRange &&
        (sectionViewAllProvider.isMorePage ?? false) &&
        widget.newPage == RoutesConstant.sectionDetailsPage) {
      sectionViewAllProvider.setLoadMore(true);
      _fetchSectionDetails(sectionViewAllProvider.currentPage ?? 0);
    }

    /* Content By Search */
    if (_mainScrollController.offset >=
            _mainScrollController.position.maxScrollExtent &&
        !_mainScrollController.position.outOfRange &&
        (findProvider.isMorePage ?? false) &&
        widget.newPage == RoutesConstant.searchPage) {
      findProvider.setLoadMore(true);
      _fetchNewSearchData(findProvider.currentPage ?? 0);
    }

    /* Related Content */
    if (_mainScrollController.offset >=
            _mainScrollController.position.maxScrollExtent &&
        !_mainScrollController.position.outOfRange &&
        (viewAllProvider.isMorePage ?? false) &&
        widget.newPage == RoutesConstant.relatedContentPage) {
      viewAllProvider.setLoadMore(true);
      _fetchRelatedContent(viewAllProvider.currentPage ?? 0);
    }

    /* Continue Watching */
    if (_mainScrollController.offset >=
            _mainScrollController.position.maxScrollExtent &&
        !_mainScrollController.position.outOfRange &&
        (viewAllProvider.isMorePage ?? false) &&
        widget.newPage == RoutesConstant.continueWatchPage) {
      viewAllProvider.setLoadMore(true);
      _fetchContinueWatch(viewAllProvider.currentPage ?? 0);
    }

    /* Watchlist */
    if (_mainScrollController.offset >=
            _mainScrollController.position.maxScrollExtent &&
        !_mainScrollController.position.outOfRange &&
        (watchlistProvider.isMorePage ?? false) &&
        widget.newPage == RoutesConstant.myWatchlistPage) {
      watchlistProvider.setLoadMore(true);
      _fetchWatchlist(watchlistProvider.currentPage ?? 0);
    }

    /* User Rent ContentList */
    if (_mainScrollController.offset >=
            _mainScrollController.position.maxScrollExtent &&
        !_mainScrollController.position.outOfRange &&
        (purchaselistProvider.isMorePage ?? false) &&
        widget.newPage == RoutesConstant.rentPurchasePage) {
      purchaselistProvider.setLoadMore(true);
      _fetchUserRentContentList(purchaselistProvider.currentPage ?? 0);
    }

    /* Subscription History */
    if (_mainScrollController.offset >=
            _mainScrollController.position.maxScrollExtent &&
        !_mainScrollController.position.outOfRange &&
        (subHistoryProvider.isMorePage ?? false) &&
        widget.newPage == RoutesConstant.subsHistoryPage) {
      subHistoryProvider.setLoadMore(true);
      _fetchSubsHistoryData(subHistoryProvider.currentPage ?? 0);
    }
  }

  Future<void> _fetchSectionData(int? nextPage) async {
    printLog(
      "_fetchSectionData selectedIndex ====> ${homeProvider.selectedIndex}",
    );
    printLog("_fetchSectionData nextPage  ========> $nextPage");
    printLog(
      "_fetchSectionData isMorePage  ======> ${sectionDataProvider.isMorePage}",
    );
    printLog(
      "_fetchSectionData currentPage ======> ${sectionDataProvider.currentPage}",
    );
    printLog(
      "_fetchSectionData totalPage   ======> ${sectionDataProvider.totalPage}",
    );

    await sectionDataProvider.getSectionList(
      (homeProvider.selectedIndex == -1 || homeProvider.selectedIndex == 0)
          ? 0
          : (homeProvider
                    .sectionTypeModel
                    .result?[homeProvider.selectedIndex]
                    .id ??
                0),
      (homeProvider.selectedIndex == -1 || homeProvider.selectedIndex == 0)
          ? "1"
          : "2",
      (nextPage ?? 0) + 1,
    );
    printLog(
      "sectionList length ==> ${sectionDataProvider.sectionList?.length}",
    );
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _fetchRentNewData(int? nextPage) async {
    printLog("_fetchRentNewData nextPage  ========> $nextPage");
    printLog(
      "_fetchRentNewData isMorePage  ======> ${rentStoreProvider.isMorePage}",
    );
    printLog(
      "_fetchRentNewData currentPage ======> ${rentStoreProvider.currentPage}",
    );
    printLog(
      "_fetchRentNewData totalPage   ======> ${rentStoreProvider.totalPage}",
    );

    await rentStoreProvider.getRentContentList(
      rentStoreProvider
              .sectionTypeList?[rentStoreProvider.selectedIndex]
              .type ??
          0,
      (nextPage ?? 0) + 1,
    );
    printLog(
      "rentDataList length ==> ${rentStoreProvider.rentDataList?.length}",
    );
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _fetchNewContentById(int? nextPage) async {
    printLog("_fetchNewContentById nextPage  ========> $nextPage");
    printLog(
      "_fetchNewContentById isMorePage  ======> ${videoByIDProvider.isMorePage}",
    );
    printLog(
      "_fetchNewContentById currentPage ======> ${videoByIDProvider.currentPage}",
    );
    printLog(
      "_fetchNewContentById totalPage   ======> ${videoByIDProvider.totalPage}",
    );

    if (widget.newPage == RoutesConstant.videoByCatPage) {
      printLog(
        "_fetchNewContentById currentCatId ======> ${videoByIDProvider.currentCatId}",
      );
      await videoByIDProvider.getVideoByCategory(
        videoByIDProvider.currentCatId,
        (nextPage ?? 0) + 1,
      );
    } else if (widget.newPage == RoutesConstant.videoByLanguagePage) {
      printLog(
        "_fetchNewContentById currentLangId =====> ${videoByIDProvider.currentLangId}",
      );
      await videoByIDProvider.getVideoByLanguage(
        videoByIDProvider.currentLangId,
        (nextPage ?? 0) + 1,
      );
    } else {
      printLog(
        "_fetchNewContentById currentChannelId ==> ${videoByIDProvider.currentChannelId}",
      );
      await videoByIDProvider.getVideoByChannel(
        videoByIDProvider.currentChannelId,
        (nextPage ?? 0) + 1,
      );
    }
    printLog("contentList length ==> ${videoByIDProvider.contentList?.length}");
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
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
      widget.reqText,
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

  Future<void> _fetchNewSearchData(int? nextPage) async {
    printLog("_fetchNewSearchData nextPage  ========> $nextPage");
    printLog(
      "_fetchNewSearchData isMorePage  ======> ${findProvider.isMorePage}",
    );
    printLog(
      "_fetchNewSearchData currentPage ======> ${findProvider.currentPage}",
    );
    printLog(
      "_fetchNewSearchData totalPage   ======> ${findProvider.totalPage}",
    );

    await findProvider.getSearchContent(widget.reqText, (nextPage ?? 0) + 1);
    printLog(
      "searchDataList length ==> ${findProvider.searchDataList?.length}",
    );
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _fetchRelatedContent(int? nextPage) async {
    printLog("_fetchRelatedContent nextPage  ========> $nextPage");
    printLog(
      "_fetchRelatedContent isMorePage  ======> ${viewAllProvider.isMorePage}",
    );
    printLog(
      "_fetchRelatedContent currentPage ======> ${viewAllProvider.currentPage}",
    );
    printLog(
      "_fetchRelatedContent totalPage   ======> ${viewAllProvider.totalPage}",
    );
    printLog("_fetchRelatedContent newPage  ========> ${widget.newPage}");
    printLog("_fetchRelatedContent reqText  ========> ${widget.reqText}");

    if (widget.reqText is Map<String, dynamic>) {
      final extraData = widget.reqText as Map<String, dynamic>;
      final itemID = extraData['itemid'] as int;
      final subVideoType = extraData['subvideotype'] as int;
      final videoType = extraData['videotype'] as int;
      final typeId = extraData['typeid'] as int;
      await viewAllProvider.getRelatedContent(
        typeId,
        videoType,
        itemID,
        subVideoType,
        (nextPage ?? 0) + 1,
      );
    }
    printLog(
      "_fetchRelatedContent length ==> ${viewAllProvider.relatedList?.length}",
    );
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _fetchContinueWatch(int? nextPage) async {
    printLog("_fetchContinueWatch nextPage  ========> $nextPage");
    printLog(
      "_fetchContinueWatch isMorePage  ======> ${viewAllProvider.isMorePage}",
    );
    printLog(
      "_fetchContinueWatch currentPage ======> ${viewAllProvider.currentPage}",
    );
    printLog(
      "_fetchContinueWatch totalPage   ======> ${viewAllProvider.totalPage}",
    );
    printLog("_fetchContinueWatch newPage  ========> ${widget.newPage}");
    printLog("_fetchContinueWatch reqText  ========> ${widget.reqText}");

    await viewAllProvider.getContinueWatching((nextPage ?? 0) + 1);
    printLog(
      "_fetchContinueWatch length ==> ${viewAllProvider.continueWatchList?.length}",
    );
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _fetchWatchlist(int? nextPage) async {
    printLog("_fetchWatchlist nextPage  ========> $nextPage");
    printLog(
      "_fetchWatchlist isMorePage  ======> ${watchlistProvider.isMorePage}",
    );
    printLog(
      "_fetchWatchlist currentPage ======> ${watchlistProvider.currentPage}",
    );
    printLog(
      "_fetchWatchlist totalPage   ======> ${watchlistProvider.totalPage}",
    );

    await watchlistProvider.getWatchlist((nextPage ?? 0) + 1);
    printLog(
      "_fetchWatchlist length ==> ${watchlistProvider.watchlistDataList?.length}",
    );
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _fetchUserRentContentList(int? nextPage) async {
    printLog("_fetchUserRentContentList nextPage  ========> $nextPage");
    printLog(
      "_fetchUserRentContentList isMorePage  ======> ${purchaselistProvider.isMorePage}",
    );
    printLog(
      "_fetchUserRentContentList currentPage ======> ${purchaselistProvider.currentPage}",
    );
    printLog(
      "_fetchUserRentContentList totalPage   ======> ${purchaselistProvider.totalPage}",
    );

    await purchaselistProvider.getUserRentVideoList((nextPage ?? 0) + 1);
    printLog(
      "_fetchUserRentContentList length ==> ${purchaselistProvider.contentList?.length}",
    );
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _fetchSubsHistoryData(int? nextPage) async {
    printLog("_fetchSubsHistoryData nextPage =========> $nextPage");
    printLog(
      "_fetchSubsHistoryData isMorePage =======> ${subHistoryProvider.isMorePage}",
    );
    printLog(
      "_fetchSubsHistoryData currentPage ======> ${subHistoryProvider.currentPage}",
    );
    printLog(
      "_fetchSubsHistoryData totalPage ========> ${subHistoryProvider.totalPage}",
    );

    await subHistoryProvider.getSubscriptionList((nextPage ?? 0) + 1);
    printLog(
      "historyDataList length ==> ${subHistoryProvider.historyDataList?.length}",
    );
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    super.didChangeDependencies();
  }

  @override
  void didPopNext() {
    printLog("didPopNext");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
    super.didPopNext();
  }

  @override
  void initState() {
    super.initState();
    currentPage = widget.newPage;
    reqText = widget.reqText;
    generalProvider = Provider.of<GeneralProvider>(context, listen: false);
    sectionDataProvider = Provider.of<SectionDataProvider>(
      context,
      listen: false,
    );
    rentStoreProvider = Provider.of<RentStoreProvider>(context, listen: false);
    videoByIDProvider = Provider.of<VideoByIDProvider>(context, listen: false);
    findProvider = Provider.of<FindProvider>(context, listen: false);
    sectionViewAllProvider = Provider.of<SectionViewAllProvider>(
      context,
      listen: false,
    );
    viewAllProvider = Provider.of<ViewAllProvider>(context, listen: false);
    watchlistProvider = Provider.of<WatchlistProvider>(context, listen: false);
    purchaselistProvider = Provider.of<PurchaselistProvider>(
      context,
      listen: false,
    );
    homeProvider = Provider.of<HomeProvider>(context, listen: false);
    profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    subHistoryProvider = Provider.of<SubHistoryProvider>(
      context,
      listen: false,
    );
    _mainScrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();

      if (kIsWeb) {
        PushNotificationService().requestNotificationPermission();
      }
    });
  }

  Future<void> _getData() async {
    Constant.userID = await sharePref.read("userid");
    printLog('userID =========> ${Constant.userID}');
    /* Get Profile */
    if (Constant.userID != null) {
      if (!mounted) return;
      profileProvider.getProfile(context).then((_) async {
        if (mounted) profileProvider.notifyProvider();
      });
    }

    if (mounted) {
      generalProvider.getGeneralsetting(context).then((_) async {
        rentMenuStatus = await Utils.configByStatus(
          status: Constant.rentStatus,
        );
        printLog('_getData rentMenuStatus ==> $rentMenuStatus');
        printLog('_getData userIsKid =======> ${Constant.userIsKid}');
        if (mounted) setState(() {});
      });
    }

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
    await sectionDataProvider.clearOldData();
    sectionDataProvider.setLoading(true);
    final bool isDefaultTab = position == -1;
    final String tabId = isDefaultTab
        ? "0"
        : (sectionTypeList?[position].id ?? 0).toString();
    final String type = isDefaultTab ? "1" : "2";

    await setSelectedTab(isDefaultTab ? 0 : position + 1);

    await Future.wait([
      sectionDataProvider.getSectionBanner(tabId, type),
      sectionDataProvider.getSectionList(tabId, type, 1),
    ]);
  }

  void _scrollToCurrentMobileTab(int index) {
    if (!_mobileTabScrollController.hasClients) return;
    _mobileTabScrollController.animateTo(
      (index * 85.0).clamp(
        0.0,
        _mobileTabScrollController.position.maxScrollExtent,
      ),
      curve: Curves.easeInOut,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _mobileTabScrollController.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isBig = Dimens.isBigScreen(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: !isBig ? _buildMobileDrawer() : null,
      backgroundColor: appBgColor,
      floatingActionButton: (isBig && widget.newPage != RoutesConstant.clipsEpisodesPage)
          ? FloatingActionButton.small(
              backgroundColor: colorAccent,
              shape: const CircleBorder(),
              elevation: 4,
              onPressed: () {
                printLog("Offset =========> ${_mainScrollController.offset}");
                if (_mainScrollController.offset <=
                        _mainScrollController.position.minScrollExtent &&
                    !_mainScrollController.position.outOfRange) {
                  _scrollDown();
                } else {
                  _scrollUp();
                }
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  (_mainScrollController.hasClients &&
                          _mainScrollController.offset >=
                              _mainScrollController.position.maxScrollExtent &&
                          !_mainScrollController.position.outOfRange)
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: appBgColor,
                  size: 20,
                  key: ValueKey(
                    _mainScrollController.hasClients &&
                        _mainScrollController.offset >=
                            _mainScrollController.position.maxScrollExtent,
                  ),
                ),
              ),
            )
          : null,
      body: Stack(
        children: [
          _buildPage(),
          /* AppBar */
          RepaintBoundary(
            child: _buildAppBar(),
          ),
        ],
      ),
    );
  }

  /* AppBar */
  Widget _buildAppBar() {
    final bool isBig = Dimens.isBigScreen(context);

    return Consumer2<SectionDataProvider, HomeProvider>(
      builder: (context, sectionDataProvider, homeProvider, child) {
        final bool isHomePage = currentPage == RoutesConstant.homePage;
        final bool hasTypes = homeProvider.sectionTypeModel.status == 200 &&
            (homeProvider.sectionTypeModel.result?.isNotEmpty ?? false);
        final bool hasHeroBanner = isHomePage &&
            sectionDataProvider.sectionBannerModel.status == 200 &&
            (sectionDataProvider.sectionBannerModel.result?.isNotEmpty ??
                false);

        final bool isTransparentHeader =
            isBig && isHomePage && hasHeroBanner && !_isNavScrolled;

        final double appBarHeight = (!isBig && isHomePage && hasTypes)
            ? (56.0 + 42.0)
            : Dimens.homeTabHeight;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: MediaQuery.of(context).size.width,
          height: appBarHeight,
          padding: EdgeInsets.fromLTRB(isBig ? 28 : 16, 0, isBig ? 28 : 16, 0),
          decoration: BoxDecoration(
            color: isTransparentHeader ? transparent : appBgColor,
            gradient: isTransparentHeader
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      appBgColor.withValues(alpha: 0.85),
                      appBgColor.withValues(alpha: 0.50),
                      appBgColor.withValues(alpha: 0.15),
                      transparent,
                    ],
                    stops: const [0.0, 0.40, 0.75, 1.0],
                  )
                : null,
            border: !isTransparentHeader
                ? Border(
                    bottom: BorderSide(
                      color: white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  )
                : null,
            boxShadow: !isTransparentHeader
                ? [
                    BoxShadow(
                      color: black.withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: isBig
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (currentPage == RoutesConstant.homePage)
                      _buildLogoButton()
                    else
                      _buildBackButton(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: tabTitle(homeProvider.sectionTypeModel.result),
                    ),
                    const SizedBox(width: 8),
                    if (currentPage != RoutesConstant.searchPage)
                      _buildSearchButton(),
                    const SizedBox(width: 6),
                    _buildUserLogin(),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 56,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (currentPage == RoutesConstant.homePage)
                            _buildMobileMenuButton(),
                          if (currentPage == RoutesConstant.homePage)
                            _buildLogoButton()
                          else
                            _buildBackButton(),
                          const Expanded(child: SizedBox.shrink()),
                          if (currentPage != RoutesConstant.searchPage)
                            _buildSearchButton(),
                          const SizedBox(width: 6),
                          _buildUserLogin(),
                        ],
                      ),
                    ),
                    if (isHomePage && hasTypes)
                      SizedBox(
                        height: 42,
                        child: _buildMobileCategoryPills(
                          homeProvider.sectionTypeModel.result,
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildMobileCategoryPills(List<type.Result>? sectionTypeList) {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        final list = sectionTypeList ?? [];
        final int itemCount = 1 + list.length; // 1 for "Home" + all categories

        return ListView.separated(
          controller: _mobileTabScrollController,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 6),
          itemCount: itemCount,
          separatorBuilder: (context, index) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final bool isHomeTab = index == 0;
            final bool isSelected = isHomeTab
                ? (homeProvider.selectedIndex <= 0)
                : (homeProvider.selectedIndex == index);

            final String title = isHomeTab
                ? "Home"
                : (list[index - 1].name?.toString() ?? "");

            return InkWell(
              borderRadius: BorderRadius.circular(20),
              splashColor: transparent,
              highlightColor: transparent,
              onTap: () async {
                if (isSelected) return;
                _scrollToCurrentMobileTab(index);
                await getTabData(
                  isHomeTab ? -1 : (index - 1),
                  sectionTypeList,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 14 : 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? colorPrimary : transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: !isSelected
                      ? Border.all(
                          color: white.withValues(alpha: 0.15),
                          width: 1,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: MyText(
                  color: isSelected ? black : white.withValues(alpha: 0.90),
                  text: title,
                  multilanguage: false,
                  fontsizeNormal: 13,
                  fontsizeWeb: 14,
                  fontweight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.center,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMobileMenuButton() {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 12, 8),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: MyImage(
              height: 20,
              width: 20,
              imagePath: "ic_menu.png",
              fit: BoxFit.contain,
              color: white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoButton() {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        focusColor: white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          await getTabData(-1, homeProvider.sectionTypeModel.result);
        },
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: MyImage(
            width: Dimens.appIconSizeWeb,
            height: Dimens.appIconSizeWeb,
            imagePath: "appicon.png",
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 12, 0),
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () {
            printLog("reqText ======> ${widget.reqText}");
            printLog("oldPage ======> ${widget.oldPage}");
            if (context.canPop()) {
              context.pop();
            } else {
              if (kIsWeb) {
                jsHelper.goBack();
              } else {
                Navigator.of(context).maybePop();
              }
            }
          },
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(8),
            child: MyImage(fit: BoxFit.contain, imagePath: "back_web.png"),
          ),
        ),
      ),
    );
  }

  Widget tabTitle(List<type.Result>? sectionTypeList) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Consumer<HomeProvider>(
            builder: (context, homeProvider, child) {
              return ListView.separated(
                itemCount: (sectionTypeList?.length ?? 0) + 1,
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (BuildContext context, int index) {
                  final bool isActive =
                      widget.newPage == RoutesConstant.homePage &&
                      homeProvider.selectedIndex == index;

                  final String title = index == 0
                      ? "Home"
                      : (sectionTypeList?[index - 1].name?.toString() ?? "");

                  return InteractiveIcon(
                    builder: (isHovered) {
                      return Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          autofocus: false,
                          focusColor: transparent,
                          hoverColor: transparent,
                          splashColor: transparent,
                          highlightColor: transparent,
                          onTap: () async {
                            printLog("<===============================>");
                            printLog("HOME index ======> $index");
                            printLog("HOME oldPage ====> ${widget.oldPage}");
                            printLog("HOME newPage ====> ${widget.newPage}");
                            printLog("<===============================>");
                            if (index == 0) {
                              await getTabData(
                                -1,
                                homeProvider.sectionTypeModel.result,
                              );
                            } else {
                              await getTabData(
                                (index - 1),
                                homeProvider.sectionTypeModel.result,
                              );
                            }
                            if (widget.newPage != RoutesConstant.homePage) {
                              if (!context.mounted) return;
                              context.go('/', extra: widget.newPage ?? "");
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: IntrinsicWidth(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    title,
                                    style: GoogleFonts.inter(
                                      color: isActive
                                          ? white
                                          : (isHovered
                                              ? white
                                              : white.withValues(alpha: 0.70)),
                                      fontSize: 15,
                                      fontWeight: isActive
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      letterSpacing: 0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeInOut,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? colorPrimary
                                          : transparent,
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: isActive
                                          ? [
                                              BoxShadow(
                                                color: colorPrimary.withValues(
                                                  alpha: 0.50,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          /* Store */
          if ((rentMenuStatus != null && rentMenuStatus == "1") &&
              Constant.userIsKid == false) ...[
            const SizedBox(width: 6),
            InteractiveIcon(
              builder: (isHovered) {
                final bool isStoreActive =
                    widget.newPage == RoutesConstant.storePage;
                return Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    focusColor: transparent,
                    hoverColor: transparent,
                    splashColor: transparent,
                    highlightColor: transparent,
                    onTap: () async {
                      printLog("newPage ======> ${widget.newPage}");
                      if (!mounted) return;
                      context.go(
                        '/${RoutesConstant.storePage}',
                        extra: widget.newPage ?? "",
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: IntrinsicWidth(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            MyText(
                              color: isStoreActive
                                  ? white
                                  : (isHovered
                                      ? white
                                      : white.withValues(alpha: 0.70)),
                              multilanguage: true,
                              text: "bottommenu4",
                              maxline: 1,
                              overflow: TextOverflow.ellipsis,
                              fontsizeNormal: 14,
                              fontweight: isStoreActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontsizeWeb: 15,
                              textalign: TextAlign.center,
                              fontstyle: FontStyle.normal,
                            ),
                            const SizedBox(height: 6),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              height: 3,
                              decoration: BoxDecoration(
                                color: isStoreActive
                                    ? colorPrimary
                                    : transparent,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: isStoreActive
                                    ? [
                                        BoxShadow(
                                          color: colorPrimary.withValues(
                                            alpha: 0.50,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                    : null,
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
          ],
        ],
      ),
    );
  }

  Widget _buildMobileDrawer() {
    final List<type.Result> sectionTypes =
        homeProvider.sectionTypeModel.result ?? [];

    return Drawer(
      backgroundColor: appBgColor,
      surfaceTintColor: transparent,
      width: (MediaQuery.of(context).size.width * 0.82).clamp(270.0, 320.0),
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header: App Logo + Name + Close Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: MyImage(
                      width: 36,
                      height: 36,
                      imagePath: "appicon.png",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      Constant.appName,
                      style: GoogleFonts.inter(
                        color: white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: white,
                      size: 22,
                    ),
                    splashRadius: 20,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // User Info / Login Banner Card
            _buildDrawerUserCard(),

            // Navigation Items List
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                children: [
                  // Home item
                  _buildDrawerNavItem(
                    icon: Icons.home_rounded,
                    title: "Home",
                    isActive: widget.newPage == RoutesConstant.homePage &&
                        homeProvider.selectedIndex == 0,
                    onTap: () async {
                      Navigator.of(context).pop();
                      await getTabData(-1, homeProvider.sectionTypeModel.result);
                      if (widget.newPage != RoutesConstant.homePage) {
                        if (!mounted) return;
                        context.go('/', extra: widget.newPage ?? "");
                      }
                    },
                  ),

                  // Dynamic Section Types (e.g. Movies, Series, Anime, etc.)
                  for (int i = 0; i < sectionTypes.length; i++) ...[
                    _buildDrawerNavItem(
                      icon: _getCategoryIcon(sectionTypes[i].name ?? ""),
                      title: sectionTypes[i].name ?? "",
                      isActive: widget.newPage == RoutesConstant.homePage &&
                          homeProvider.selectedIndex == (i + 1),
                      onTap: () async {
                        Navigator.of(context).pop();
                        await getTabData(
                          i,
                          homeProvider.sectionTypeModel.result,
                        );
                        if (widget.newPage != RoutesConstant.homePage) {
                          if (!mounted) return;
                          context.go('/', extra: widget.newPage ?? "");
                        }
                      },
                    ),
                  ],

                  // Clips / Shorts (if not kid)
                  if (Constant.userIsKid == false)
                    _buildDrawerNavItem(
                      icon: Icons.play_circle_outline_rounded,
                      title: "Shorts",
                      isActive: widget.newPage == RoutesConstant.clipsEpisodesPage,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go(
                          '/${RoutesConstant.clipsEpisodesPage}',
                          extra: widget.newPage ?? "",
                        );
                      },
                    ),

                  // Store (if enabled)
                  if ((rentMenuStatus != null && rentMenuStatus == "1") &&
                      Constant.userIsKid == false)
                    _buildDrawerNavItem(
                      icon: Icons.storefront_rounded,
                      title: "Store",
                      isActive: widget.newPage == RoutesConstant.storePage,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go(
                          '/${RoutesConstant.storePage}',
                          extra: widget.newPage ?? "",
                        );
                      },
                    ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: Colors.white12, height: 1),
                  ),

                  // Search
                  _buildDrawerNavItem(
                    icon: Icons.search_rounded,
                    title: "Search",
                    isActive: widget.newPage == RoutesConstant.searchPage,
                    onTap: () {
                      Navigator.of(context).pop();
                      findProvider.setSearchLoading(true);
                      context.go(
                        '/${RoutesConstant.searchPage}',
                        extra: widget.newPage ?? "",
                      );
                    },
                  ),

                  // My Space / Profile (if logged in)
                  if (Constant.userID != null) ...[
                    _buildDrawerNavItem(
                      icon: Icons.person_rounded,
                      title: "My Space",
                      isActive: widget.newPage == RoutesConstant.mySpacePage,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go(
                          "/${RoutesConstant.mySpacePage}",
                          extra: widget.newPage ?? "",
                        );
                      },
                    ),
                    _buildDrawerNavItem(
                      icon: Icons.bookmark_border_rounded,
                      title: "Watchlist",
                      isActive: widget.newPage == RoutesConstant.myWatchlistPage,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go(
                          "/${RoutesConstant.myWatchlistPage}",
                          extra: widget.newPage ?? "",
                        );
                      },
                    ),
                  ],

                  // Subscribe plan
                  _buildDrawerNavItem(
                    icon: Icons.workspace_premium_rounded,
                    title: "Berlangganan",
                    isActive: widget.newPage == RoutesConstant.subscriptionPage,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(
                        '/${RoutesConstant.subscriptionPage}',
                        extra: widget.newPage ?? "",
                      );
                    },
                  ),

                  // Settings
                  _buildDrawerNavItem(
                    icon: Icons.settings_rounded,
                    title: "Settings",
                    isActive: widget.newPage == RoutesConstant.settingsPage,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(
                        '/${RoutesConstant.settingsPage}',
                        extra: widget.newPage ?? "",
                      );
                    },
                  ),
                ],
              ),
            ),

            // Footer version info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              alignment: Alignment.centerLeft,
              child: Text(
                "v${Constant.appVersion}",
                style: GoogleFonts.inter(
                  color: white.withValues(alpha: 0.35),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerUserCard() {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        if (Constant.userID != null) {
          final profileResult = profileProvider.profileModel.result;
          final userName = (profileResult != null && profileResult.isNotEmpty)
              ? (profileResult[0].fullName ?? profileResult[0].userName ?? "User")
              : "User";
          final userEmail = (profileResult != null && profileResult.isNotEmpty)
              ? (profileResult[0].email ?? "")
              : "";
          final userImage = (profileResult != null && profileResult.isNotEmpty)
              ? (profileResult[0].image ?? "")
              : "";

          return InkWell(
            onTap: () {
              Navigator.of(context).pop();
              context.go(
                "/${RoutesConstant.mySpacePage}",
                extra: widget.newPage ?? "",
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: lightBlack,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: (Constant.userIsKid == true)
                        ? MyImage(
                            imagePath: "kids.png",
                            fit: BoxFit.cover,
                            height: 40,
                            width: 40,
                          )
                        : MyNetworkImage(
                            imageUrl: userImage,
                            fit: BoxFit.cover,
                            height: 40,
                            width: 40,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: GoogleFonts.inter(
                            color: white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (userEmail.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            userEmail,
                            style: GoogleFonts.inter(
                              color: white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: white.withValues(alpha: 0.4),
                    size: 14,
                  ),
                ],
              ),
            ),
          );
        } else {
          return Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: lightBlack,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Selamat Datang!",
                        style: GoogleFonts.inter(
                          color: white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Masuk untuk akses penuh",
                        style: GoogleFonts.inter(
                          color: white.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () async {
                    Navigator.of(context).pop();
                    await Utils.openLogin(
                      context: context,
                      newPage: RoutesConstant.loginSocialPage,
                    );
                    _getData();
                    if (!mounted) return;
                    setState(() {});
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Login",
                      style: GoogleFonts.inter(
                        color: appBgColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildDrawerNavItem({
    required IconData icon,
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? colorPrimary.withValues(alpha: 0.15) : transparent,
        borderRadius: BorderRadius.circular(10),
        border: isActive
            ? Border.all(color: colorPrimary.withValues(alpha: 0.5), width: 1)
            : null,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Icon(
          icon,
          size: 20,
          color: isActive ? colorPrimary : white.withValues(alpha: 0.75),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: isActive ? colorPrimary : white,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains("movie") || lower.contains("film")) {
      return Icons.movie_outlined;
    } else if (lower.contains("series") ||
        lower.contains("show") ||
        lower.contains("drama")) {
      return Icons.tv_rounded;
    } else if (lower.contains("anime") ||
        lower.contains("cartoon") ||
        lower.contains("animasi")) {
      return Icons.auto_awesome_rounded;
    } else if (lower.contains("clip") || lower.contains("short")) {
      return Icons.play_circle_outline_rounded;
    } else if (lower.contains("live") || lower.contains("stream")) {
      return Icons.live_tv_rounded;
    } else if (lower.contains("music") || lower.contains("audio")) {
      return Icons.music_note_rounded;
    }
    return Icons.video_library_outlined;
  }

  Widget _buildUserLogin() {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        if (Constant.userID != null) {
          return InteractiveIcon(
            builder: (isHovered) {
              return InkWell(
                onTap: () {
                  if (!mounted) return;
                  context.go(
                    "/${RoutesConstant.mySpacePage}",
                    extra: widget.newPage ?? "",
                  );
                },
                borderRadius: BorderRadius.circular(Dimens.widthHomeUser),
                focusColor: transparent,
                hoverColor: transparent,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isHovered
                          ? white.withValues(alpha: 0.70)
                          : white.withValues(alpha: 0.20),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Dimens.widthHomeUser),
                    child: (Constant.userIsKid == true)
                        ? MyImage(
                            imagePath: "kids.png",
                            fit: BoxFit.cover,
                            height: Dimens.heightHomeUser,
                            width: Dimens.widthHomeUser,
                          )
                        : MyNetworkImage(
                            imageUrl:
                                (profileProvider.profileModel.status == 200 &&
                                    profileProvider.profileModel.result != null)
                                ? (((profileProvider
                                                  .profileModel
                                                  .result
                                                  ?.length ??
                                              0) >
                                          0)
                                      ? (profileProvider
                                                .profileModel
                                                .result?[0]
                                                .image ??
                                            "")
                                      : "")
                                : "",
                            fit: BoxFit.cover,
                            height: Dimens.heightHomeUser,
                            width: Dimens.widthHomeUser,
                          ),
                  ),
                ),
              );
            },
          );
        } else {
          return InteractiveIcon(
            builder: (isHovered) {
              return InkWell(
                onTap: () async {
                  if (!mounted) return;
                  await Utils.openLogin(
                    context: context,
                    newPage: RoutesConstant.loginSocialPage,
                  );
                  _getData();
                  if (!mounted) return;
                  setState(() {});
                },
                borderRadius: BorderRadius.circular(20),
                focusColor: transparent,
                hoverColor: transparent,
                child: Container(
                  height: 36,
                  constraints: const BoxConstraints(minWidth: 80),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isHovered
                        ? colorPrimary
                        : colorPrimary.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(Dimens.cardRadius),
                    boxShadow: isHovered
                        ? [
                            BoxShadow(
                              color: colorPrimary.withValues(alpha: 0.30),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: MyText(
                    multilanguage: true,
                    color: appBgColor,
                    text: "login",
                    maxline: 1,
                    textalign: TextAlign.center,
                    fontstyle: FontStyle.normal,
                    fontsizeNormal: 13,
                    fontsizeWeb: 13,
                    overflow: TextOverflow.ellipsis,
                    fontweight: FontWeight.w700,
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }

  /* Search button */
  Widget _buildSearchButton() {
    final bool isBig = Dimens.isBigScreen(context);
    final double sw = MediaQuery.of(context).size.width;
    final bool isWideDesktop = isBig && sw >= 1150;

    return InteractiveIcon(
      builder: (isHovered) {
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          focusColor: transparent,
          hoverColor: transparent,
          splashColor: transparent,
          onTap: () async {
            findProvider.setSearchLoading(true);
            if (!mounted) return;
            context.go(
              '/${RoutesConstant.searchPage}',
              extra: widget.newPage ?? "",
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            height: 38,
            width: isWideDesktop ? 260 : 38,
            padding: EdgeInsets.symmetric(
              horizontal: isWideDesktop ? 12 : 8,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isHovered
                  ? white.withValues(alpha: 0.12)
                  : white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isHovered
                    ? colorPrimary.withValues(alpha: 0.45)
                    : white.withValues(alpha: 0.10),
                width: 1,
              ),
            ),
            child: isWideDesktop
                ? Row(
                    children: [
                      MyImage(
                        imagePath: "ic_find.png",
                        color: white.withValues(alpha: isHovered ? 1.0 : 0.65),
                        fit: BoxFit.contain,
                        width: 15,
                        height: 15,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Cari film, serial...",
                          style: GoogleFonts.inter(
                            color: white.withValues(
                              alpha: isHovered ? 0.90 : 0.50,
                            ),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: white.withValues(alpha: 0.15),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          "/",
                          style: GoogleFonts.inter(
                            color: white.withValues(alpha: 0.60),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: MyImage(
                      imagePath: "ic_find.png",
                      color: white.withValues(alpha: isHovered ? 1.0 : 0.80),
                      fit: BoxFit.contain,
                      width: 18,
                      height: 18,
                    ),
                  ),
          ),
        );
      },
    );
  }

  /* Details */
  Widget _buildPage() {
    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: const BoxConstraints.expand(),
      child: WebArrowKeyScroll(
        scrollController: _mainScrollController,
        childToScroll: SingleChildScrollView(
          controller: _mainScrollController,
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              /* Post */
              widget.newChild,
              /* Web Footer */
              const SizedBox(height: 20),
              if (widget.newPage != RoutesConstant.clipsEpisodesPage)
                WebFooter(
                  newPage: widget.newPage,
                  oldPage: widget.oldPage,
                  reqText: '',
                  onTypeClick: () {
                    _scrollUp();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
