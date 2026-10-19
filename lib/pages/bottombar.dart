import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../pages/rentstore.dart';
import '../pages/clips.dart';
import '../main.dart';
import '../pages/find.dart';
import '../pages/home.dart';
import '../pages/myspace.dart';
import '../pages/nointernet.dart';
import '../provider/bottombarprovider.dart';
import '../provider/connectivityprovider.dart';
import '../provider/generalprovider.dart';
import '../provider/homeprovider.dart';
import '../provider/profileprovider.dart';
import '../provider/sectiondataprovider.dart';
import '../routes/routes_constant.dart';
import '../utils/adhelper.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/loadingoverlay.dart';
import '../utils/sharedpre.dart';
import '../utils/utils.dart';
import '../widget/myimage.dart';
import '../widget/mytext.dart';
import '../widget/myusernetworkimg.dart';

class Bottombar extends StatefulWidget {
  const Bottombar({super.key});

  @override
  State<Bottombar> createState() => BottombarState();
}

class BottombarState extends State<Bottombar> with RouteAware {
  late SectionDataProvider sectionDataProvider;
  late ConnectivityProvider connectivityProvider;
  late GeneralProvider generalProvider;
  late HomeProvider homeProvider;
  late BottombarProvider bottombarProvider;
  SharedPre sharedPre = SharedPre();
  String? rentMenuStatus, downloadStatus;
  DateTime? currentBackPressTime;

  List<Widget> widgetOptions = <Widget>[];

  /* Notification CLICK START ************** */
  void _handleNotificationOpened(OSNotificationClickEvent result) {
    /* id, video_type, type_id */

    printLog(
      "_handleNotificationOpened additionalData ===> ${result.notification.additionalData.toString()}",
    );
    printLog(
      "_handleNotificationOpened video_id =========> ${result.notification.additionalData?['id']}",
    );
    printLog(
      "_handleNotificationOpened sub_video_type ===> ${result.notification.additionalData?['sub_video_type']}",
    );
    printLog(
      "_handleNotificationOpened video_type =======> ${result.notification.additionalData?['video_type']}",
    );
    printLog(
      "_handleNotificationOpened type_id ==========> ${result.notification.additionalData?['type_id']}",
    );

    if (result.notification.additionalData?['id'] != null &&
        result.notification.additionalData?['sub_video_type'] != null &&
        result.notification.additionalData?['video_type'] != null &&
        result.notification.additionalData?['type_id'] != null) {
      String? videoID =
          result.notification.additionalData?['id'].toString() ?? "";
      String? subVideoType =
          result.notification.additionalData?['sub_video_type'].toString() ??
          "";
      String? videoType =
          result.notification.additionalData?['video_type'].toString() ?? "";
      String? typeID =
          result.notification.additionalData?['type_id'].toString() ?? "";
      printLog("videoID =======> $videoID");
      printLog("subVideoType ==> $subVideoType");
      printLog("videoType =====> $videoType");
      printLog("typeID ========> $typeID");

      Utils.openDetails(
        context: context,
        videoId: int.parse(videoID),
        subVideoType: int.parse(subVideoType),
        videoType: int.parse(videoType),
        typeId: int.parse(typeID),
        newPage: (int.parse(videoType) == Constant.shortsContentType)
            ? RoutesConstant.clipsEpisodesPage
            : RoutesConstant.contentDetailsPage,
        oldPage: '',
        reqText: '',
      );
    }
  }
  /* **************** Notification CLICK END */

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    super.didChangeDependencies();
  }

  @override
  void didPopNext() {
    printLog(
      "didPopNext bottomNavIndex ===> ${bottombarProvider.bottomNavIndex}",
    );
    super.didPopNext();
  }

  @override
  void initState() {
    super.initState();
    homeProvider = Provider.of<HomeProvider>(context, listen: false);
    bottombarProvider = Provider.of<BottombarProvider>(context, listen: false);
    printLog(
      "initState bottomNavIndex ===> ${bottombarProvider.bottomNavIndex}",
    );
    generalProvider = Provider.of<GeneralProvider>(context, listen: false);
    connectivityProvider = Provider.of<ConnectivityProvider>(
      context,
      listen: false,
    );
    sectionDataProvider = Provider.of<SectionDataProvider>(
      context,
      listen: false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      printLog("initState isOnline ===> ${connectivityProvider.isOnline}");
      _getData();
      /* Check Internet Connection */
      connectivityProvider.connectivity.onConnectivityChanged.listen((results) {
        printLog('connectivityResult length =====> ${results.length}');
        if (results.isNotEmpty) {
          printLog('connectivityResult name =======> ${results[0].name}');
          final hasConnection = results.any(
            (r) =>
                (r == ConnectivityResult.mobile) ||
                (r == ConnectivityResult.wifi) ||
                (r == ConnectivityResult.ethernet),
          );

          // --- OFFLINE ---
          if (!hasConnection) {
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => const NoInternet(),
              ),
              (Route<dynamic> route) => false,
            ).then((value) {
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => const NoInternet(),
                ),
              );
            });
            return;
          }
        } else {
          printLog('connectivityResult =======> None');
        }
      });
    });
  }

  Future<void> _getData() async {
    printLog("_getData isOnline ===> ${connectivityProvider.isOnline}");
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    if (connectivityProvider.isOnline) {
      if (!mounted) return;
      await generalProvider.getGeneralsetting(context);

      /* On Notification Click */
      if (!kIsWeb) {
        OneSignal.Notifications.addClickListener(_handleNotificationOpened);
      }

      rentMenuStatus = await Utils.configByStatus(status: Constant.rentStatus);
      downloadStatus = await Utils.configByStatus(
        status: Constant.downloadStatus,
      );
      printLog('_getData rentMenuStatus ==> $rentMenuStatus');
      printLog('_getData downloadStatus ==> $downloadStatus');
      printLog('_getData userIsKid =======> ${Constant.userIsKid}');

      widgetOptions = <Widget>[];
      widgetOptions = <Widget>[
        const Home(pageName: ""),
        const Find(viewFrom: ""),
        if (Constant.userIsKid == false)
          const Clips(clipId: 0, openFrom: "bottom"),
        if (rentMenuStatus != null &&
            rentMenuStatus == "1" &&
            Constant.userIsKid == false)
          const RentStore(),
        const MySpace(),
      ];
      printLog('_getData widgetOptions ===> ${widgetOptions.length}');

      if (!mounted) return;
      if (Constant.userID != null) {
        await profileProvider.getProfile(context);
      } else {
        Utils.updatePremium("0");
        Utils.loadAds(context);
      }
    }

    if (!mounted) return;
    setState(() {});
  }

  void _onItemTapped(int index) async {
    AdHelper.checkAndShowAds(
      context: context,
      buttonKey: "",
      adType: Constant.interstialAdType,
      alwaysShowAd: false,
      showOnByClick: true,
      onAdComplete: () async {
        if (index == 0) {
          getHomeTabData();
        }
        if (!mounted) return;
        await bottombarProvider.setBottomNavIndex(index);
        printLog("bottomNavIndex ===> ${bottombarProvider.bottomNavIndex}");
        printLog("widget length ====> ${widgetOptions.length}");
      },
    );
  }

  Future<void> getHomeTabData() async {
    homeProvider.setSelectedTab(-1);
    await sectionDataProvider.clearOldData();
    sectionDataProvider.setLoading(true);
    await Future.wait([
      sectionDataProvider.getSectionBanner("0", "1"),
      sectionDataProvider.getSectionList("0", "1", 1),
    ]);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    LoadingOverlay().hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        onBackPressed(didPop);
      },
      child: _buildOnlinePage(),
    );
  }

  Widget _buildOnlinePage() {
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Consumer<BottombarProvider>(
        builder: (context, bottombarProvider, child) {
          return (widgetOptions.isEmpty)
              ? const SizedBox.shrink()
              : Center(child: widgetOptions[bottombarProvider.bottomNavIndex]);
        },
      ),
      bottomNavigationBar: Consumer<BottombarProvider>(
        builder: (context, bottombarProvider, child) {
          final double bottomInset = MediaQuery.of(context).padding.bottom;
          final double leftInset = MediaQuery.of(context).padding.left;
          final double rightInset = MediaQuery.of(context).padding.right;

          int navIndex = 0;
          final List<Widget> navItems = [];

          // 0: Home
          final int homeIdx = navIndex++;
          navItems.add(_buildNavItem(
            index: homeIdx,
            currentIndex: bottombarProvider.bottomNavIndex,
            title: "bottommenu1",
            isTitleMultilang: true,
            iconName: 'ic_home',
          ));

          // 1: Find
          final int findIdx = navIndex++;
          navItems.add(_buildNavItem(
            index: findIdx,
            currentIndex: bottombarProvider.bottomNavIndex,
            title: "bottommenu2",
            isTitleMultilang: true,
            iconName: 'ic_find',
          ));

          // 2: Clips (if not kid)
          if (Constant.userIsKid == false) {
            final int clipsIdx = navIndex++;
            navItems.add(_buildNavItem(
              index: clipsIdx,
              currentIndex: bottombarProvider.bottomNavIndex,
              title: "bottommenu3",
              isTitleMultilang: true,
              iconName: 'ic_clips',
            ));
          }

          // 3: Store (if active and not kid)
          if ((rentMenuStatus != null && rentMenuStatus == "1") &&
              Constant.userIsKid == false) {
            final int storeIdx = navIndex++;
            navItems.add(_buildNavItem(
              index: storeIdx,
              currentIndex: bottombarProvider.bottomNavIndex,
              title: "bottommenu4",
              isTitleMultilang: true,
              iconName: 'ic_store',
            ));
          }

          // Last: Profile / MySpace
          final int profileIdx = navIndex++;
          navItems.add(_buildProfileNavItem(
            index: profileIdx,
            currentIndex: bottombarProvider.bottomNavIndex,
          ));

          return Visibility(
            visible: bottombarProvider.isShowBottombar,
            maintainAnimation: true,
            maintainState: true,
            child: AnimatedOpacity(
              opacity: bottombarProvider.isShowBottombar ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              child: IgnorePointer(
                ignoring: !bottombarProvider.isShowBottombar,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Container(
                      height: 50,
                      margin: EdgeInsets.only(
                        left: 20 + leftInset,
                        right: 20 + rightInset,
                        bottom: bottomInset > 0 ? bottomInset + 12 : 24,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xF216181F),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: white.withValues(alpha: 0.10),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: black.withValues(alpha: 0.50),
                            blurRadius: 16,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: navItems,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required int currentIndex,
    required String title,
    required bool isTitleMultilang,
    required String iconName,
  }) {
    final bool isSelected = currentIndex == index;
    final Color itemColor =
        isSelected ? colorPrimary : const Color(0xFF8E9299);

    return Expanded(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          splashColor: transparent,
          highlightColor: transparent,
          onTap: () => _onItemTapped(index),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                MyImage(
                  imagePath: "$iconName.png",
                  width: 17,
                  height: 17,
                  color: itemColor,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 2),
                MyText(
                  color: itemColor,
                  multilanguage: isTitleMultilang,
                  text: title,
                  fontsizeNormal: 10,
                  fontsizeWeb: 11,
                  fontweight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.center,
                  fontstyle: FontStyle.normal,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileNavItem({
    required int index,
    required int currentIndex,
  }) {
    final bool isSelected = currentIndex == index;
    final Color itemColor =
        isSelected ? colorPrimary : const Color(0xFF8E9299);

    return Expanded(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          splashColor: transparent,
          highlightColor: transparent,
          onTap: () => _onItemTapped(index),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Consumer<ProfileProvider>(
              builder: (context, profileProvider, child) {
                final bool hasProfile =
                    profileProvider.profileModel.result != null &&
                    (profileProvider.profileModel.result?.length ?? 0) > 0;
                final String userImage = hasProfile
                    ? (profileProvider.profileModel.result?[0].image ?? "")
                    : "";

                Widget profileIconWidget;
                if (Constant.userIsKid == true) {
                  profileIconWidget = ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: MyImage(
                      imagePath: 'kids.png',
                      fit: BoxFit.cover,
                      width: 17,
                      height: 17,
                    ),
                  );
                } else if (hasProfile && userImage.isNotEmpty) {
                  profileIconWidget = ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Container(
                      decoration: BoxDecoration(
                        border: isSelected
                            ? Border.all(color: colorPrimary, width: 1.2)
                            : null,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: MyUserNetworkImage(
                        imageUrl: userImage,
                        fit: BoxFit.cover,
                        width: 17,
                        height: 17,
                      ),
                    ),
                  );
                } else {
                  profileIconWidget = MyImage(
                    imagePath: 'ic_stuff.png',
                    fit: BoxFit.contain,
                    width: 17,
                    height: 17,
                    color: itemColor,
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    profileIconWidget,
                    const SizedBox(height: 2),
                    MyText(
                      color: itemColor,
                      multilanguage: true,
                      text: "bottommenu5",
                      fontsizeNormal: 10,
                      fontsizeWeb: 11,
                      fontweight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      maxline: 1,
                      overflow: TextOverflow.ellipsis,
                      textalign: TextAlign.center,
                      fontstyle: FontStyle.normal,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> onBackPressed(bool didPop) async {
    if (didPop) return;
    if (bottombarProvider.bottomNavIndex == 0) {
      DateTime now = DateTime.now();
      if (currentBackPressTime == null ||
          now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
        currentBackPressTime = now;
        Utils.showSnackbar(context, "", "exit_warning", true);
        return;
      }
      SystemNavigator.pop();
    } else {
      _onItemTapped(0);
    }
  }
}
