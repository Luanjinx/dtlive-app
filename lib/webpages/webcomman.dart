import 'package:dropdown_button2/dropdown_button2.dart';
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
  SharedPre sharePref = SharedPre();
  final JSHelper jsHelper = JSHelper();

  final ScrollController _mainScrollController = ScrollController();

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
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      floatingActionButton: (widget.newPage != RoutesConstant.clipsEpisodesPage)
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
          _buildAppBar(),
        ],
      ),
    );
  }

  /* AppBar */
  Widget _buildAppBar() {
    final bool isBig = Dimens.isBigScreen(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: MediaQuery.of(context).size.width,
      height: Dimens.homeTabHeight,
      padding: EdgeInsets.fromLTRB(isBig ? 28 : 16, 0, isBig ? 28 : 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _isNavScrolled
              ? [
                  appBgColor.withValues(alpha: 0.98),
                  appBgColor.withValues(alpha: 0.95),
                  appBgColor.withValues(alpha: 0.60),
                  transparent,
                ]
              : [
                  appBgColor.withValues(alpha: 0.75),
                  appBgColor.withValues(alpha: 0.40),
                  appBgColor.withValues(alpha: 0.10),
                  transparent,
                ],
          stops: const [0.0, 0.50, 0.80, 1.0],
        ),
        border: _isNavScrolled
            ? Border(
                bottom: BorderSide(
                  color: white.withValues(alpha: 0.07),
                  width: 1,
                ),
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /* Hamburger (mobile) */
          if (!isBig) _buildMobileMenuButton(),

          /* Logo or Back */
          if (currentPage == RoutesConstant.homePage)
            _buildLogoButton()
          else
            _buildBackButton(),

          /* Nav tabs (desktop only) */
          if (isBig)
            Expanded(child: tabTitle(homeProvider.sectionTypeModel.result))
          else
            const Expanded(child: SizedBox.shrink()),

          const SizedBox(width: 8),

          /* Search */
          if (currentPage != RoutesConstant.searchPage) _buildSearchButton(),

          const SizedBox(width: 6),
          _buildUserLogin(),
        ],
      ),
    );
  }

  Widget _buildMobileMenuButton() {
    return Container(
      constraints: const BoxConstraints(minWidth: 25),
      padding: const EdgeInsets.fromLTRB(0, 10, 12, 10),
      child: Consumer<HomeProvider>(
        builder: (context, homeProvider, child) {
          return DropdownButtonHideUnderline(
            child: DropdownButton2(
              isDense: true,
              isExpanded: true,
              customButton: MyImage(
                height: 30,
                imagePath: "ic_menu.png",
                fit: BoxFit.contain,
                color: white,
              ),
              items: _buildWebDropDownItems(),
              onChanged: (type.Result? value) async {
                if (value?.id == -1) {
                  await getTabData(-1, homeProvider.sectionTypeModel.result);
                  if (widget.newPage != RoutesConstant.homePage) {
                    if (!context.mounted) return;
                    context.go('/', extra: widget.newPage ?? "");
                  }
                } else if (value?.id == -2) {
                  printLog("<===============================>");
                  printLog("storePage oldPage ======> ${widget.oldPage}");
                  printLog("storePage newPage ======> ${widget.newPage}");
                  printLog("<===============================>");
                  if (!context.mounted) return;
                  context.go(
                    '/${RoutesConstant.storePage}',
                    extra: widget.newPage ?? "",
                  );
                } else {
                  final index = homeProvider.sectionTypeModel.result
                      ?.indexWhere((item) => item.id == value?.id);
                  printLog("<===============================>");
                  printLog("sectionType index ======> $index");
                  printLog("<===============================>");

                  if (index != null && index != -1 && index != -2) {
                    await getTabData(
                      index,
                      homeProvider.sectionTypeModel.result,
                    );
                  }
                  if (widget.newPage != RoutesConstant.homePage) {
                    if (!context.mounted) return;
                    context.go('/', extra: widget.newPage ?? "");
                  }
                }
              },
              dropdownStyleData: DropdownStyleData(
                width: MediaQuery.of(context).size.width * 0.55,
                useSafeArea: true,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: lightBlack,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: black.withValues(alpha: 0.50),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                elevation: 0,
              ),
              menuItemStyleData: const MenuItemStyleData(
                padding: EdgeInsets.symmetric(horizontal: 4),
              ),
              buttonStyleData: ButtonStyleData(
                decoration: BoxDecoration(color: transparent),
                overlayColor: WidgetStateProperty.all(transparent),
              ),
            ),
          );
        },
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
                padding: const EdgeInsets.fromLTRB(13, 15, 0, 15),
                separatorBuilder: (context, index) => const SizedBox(width: 5),
                itemBuilder: (BuildContext context, int index) {
                  final bool isActive =
                      widget.newPage == RoutesConstant.homePage &&
                      homeProvider.selectedIndex == index;

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
                          borderRadius: BorderRadius.circular(
                            Dimens.cardRadius,
                          ),
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
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            constraints: const BoxConstraints(maxHeight: 34),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? white
                                  : isHovered
                                  ? white.withValues(alpha: 0.08)
                                  : transparent,
                              borderRadius: BorderRadius.circular(
                                Dimens.cardRadius,
                              ),
                              border: (!isActive && isHovered)
                                  ? Border.all(
                                      color: white.withValues(alpha: 0.12),
                                      width: 1,
                                    )
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: MyText(
                              color: isActive ? black : white,
                              multilanguage: false,
                              text: index == 0
                                  ? "Home"
                                  : (sectionTypeList?[index - 1].name
                                            .toString() ??
                                        ""),
                              fontsizeNormal: 12,
                              fontweight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontsizeWeb: 14,
                              maxline: 1,
                              overflow: TextOverflow.ellipsis,
                              textalign: TextAlign.center,
                              fontstyle: FontStyle.normal,
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
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.fromLTRB(0, 15, 0, 15),
              child: InteractiveIcon(
                builder: (isHovered) {
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
                      borderRadius: BorderRadius.circular(Dimens.cardRadius),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        constraints: const BoxConstraints(minHeight: 34),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: widget.newPage == RoutesConstant.storePage
                              ? white
                              : isHovered
                              ? white.withValues(alpha: 0.08)
                              : transparent,
                          borderRadius: BorderRadius.circular(
                            Dimens.cardRadius,
                          ),
                          border:
                              (widget.newPage != RoutesConstant.storePage &&
                                  isHovered)
                              ? Border.all(
                                  color: white.withValues(alpha: 0.12),
                                  width: 1,
                                )
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Consumer<HomeProvider>(
                          builder: (context, homeProvider, child) {
                            return MyText(
                              color: widget.newPage == RoutesConstant.storePage
                                  ? black
                                  : white,
                              multilanguage: true,
                              text: "bottommenu4",
                              maxline: 1,
                              overflow: TextOverflow.ellipsis,
                              fontsizeNormal: 12,
                              fontweight:
                                  (widget.newPage == RoutesConstant.storePage)
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontsizeWeb: 14,
                              textalign: TextAlign.center,
                              fontstyle: FontStyle.normal,
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<DropdownMenuItem<type.Result>>? _buildWebDropDownItems() {
    final List<type.Result> typeDropDownList = [];

    // 1. Add static "Home" at first position
    typeDropDownList.add(
      type.Result()
        ..id =
            -1 // use unique ID for static item
        ..name = "Home",
    );

    // 2. Add API data in middle
    final apiData = homeProvider.sectionTypeModel.result ?? [];
    typeDropDownList.addAll(apiData);

    // 3. Add static "Store" at last position
    if ((rentMenuStatus != null && rentMenuStatus == "1") &&
        Constant.userIsKid == false) {
      typeDropDownList.add(
        type.Result()
          ..id =
              -2 // use unique ID for static item
          ..name = "Store",
      );
    }

    // 4. Build DropdownMenuItem list
    return typeDropDownList.map((type.Result value) {
      final bool isRentSelected =
          (value.id == -2 && widget.newPage == RoutesConstant.storePage);
      final bool isHomeSelected =
          (value.id == -1 &&
          widget.newPage != RoutesConstant.storePage &&
          homeProvider.selectedIndex == 0);
      final bool isOtherTabSelected =
          widget.newPage != RoutesConstant.storePage &&
          (homeProvider.selectedIndex != -1) &&
          (typeDropDownList[homeProvider.selectedIndex].id ?? 0) ==
              (value.id ?? 0) &&
          value.id != -1 &&
          value.id != -2;

      final bool isSelected =
          isHomeSelected || isRentSelected || isOtherTabSelected;

      return DropdownMenuItem<type.Result>(
        value: value,
        alignment: Alignment.center,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? white.withValues(alpha: 0.10) : transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.centerLeft,
          child: MyText(
            color: isSelected ? white : white.withValues(alpha: 0.75),
            multilanguage: false,
            text: value.name ?? "",
            fontsizeNormal: 13,
            fontweight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontsizeWeb: 14,
            maxline: 1,
            overflow: TextOverflow.ellipsis,
            textalign: TextAlign.start,
            fontstyle: FontStyle.normal,
          ),
        ),
      );
    }).toList();
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
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isHovered ? white.withValues(alpha: 0.08) : transparent,
            ),
            child: MyImage(
              imagePath: "ic_find.png",
              color: white.withValues(alpha: isHovered ? 1.0 : 0.80),
              fit: BoxFit.contain,
              width: 18,
              height: 18,
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
          physics: const AlwaysScrollableScrollPhysics(),
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
