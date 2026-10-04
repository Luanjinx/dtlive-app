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
    sectionDataProvider.setLoading(true);
    await sectionDataProvider.getSectionBanner("0", "1");
    await sectionDataProvider.getSectionList("0", "1", 1);
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
          return Visibility(
            visible: bottombarProvider.isShowBottombar,
            maintainAnimation: true,
            maintainState: true,
            child: AnimatedOpacity(
              opacity: bottombarProvider.isShowBottombar ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              child: BottomAppBar(
                elevation: 0,
                color: secondaryBgColor,
                padding: EdgeInsets.zero,
                shadowColor: black.withValues(alpha: 0.8),
                child: BottomNavigationBar(
                  elevation: 0,
                  showSelectedLabels: false,
                  showUnselectedLabels: false,
                  currentIndex: bottombarProvider.bottomNavIndex,
                  backgroundColor: secondaryBgColor,
                  landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
                  type: BottomNavigationBarType.fixed,
                  items: [
                    BottomNavigationBarItem(
                      label: "",
                      activeIcon: _buildBottomNavIcon(
                        title: "bottommenu1",
                        isTitleMultilang: true,
                        iconName: 'ic_home',
                        iconColor: colorPrimary,
                      ),
                      icon: _buildBottomNavIcon(
                        title: "bottommenu1",
                        isTitleMultilang: true,
                        iconName: 'ic_home',
                        iconColor: defaultIconColor,
                      ),
                    ),
                    BottomNavigationBarItem(
                      label: "",
                      activeIcon: _buildBottomNavIcon(
                        title: "bottommenu2",
                        isTitleMultilang: true,
                        iconName: 'ic_find',
                        iconColor: colorPrimary,
                      ),
                      icon: _buildBottomNavIcon(
                        title: "bottommenu2",
                        isTitleMultilang: true,
                        iconName: 'ic_find',
                        iconColor: defaultIconColor,
                      ),
                    ),
                    if (Constant.userIsKid == false)
                      BottomNavigationBarItem(
                        label: "",
                        activeIcon: _buildBottomNavIcon(
                          title: "bottommenu3",
                          isTitleMultilang: true,
                          iconName: 'ic_clips',
                          iconColor: colorPrimary,
                        ),
                        icon: _buildBottomNavIcon(
                          title: "bottommenu3",
                          isTitleMultilang: true,
                          iconName: 'ic_clips',
                          iconColor: defaultIconColor,
                        ),
                      ),
                    if ((rentMenuStatus != null && rentMenuStatus == "1") &&
                        Constant.userIsKid == false)
                      BottomNavigationBarItem(
                        label: "",
                        activeIcon: _buildBottomNavIcon(
                          title: "bottommenu4",
                          isTitleMultilang: true,
                          iconName: 'ic_store',
                          iconColor: colorPrimary,
                        ),
                        icon: _buildBottomNavIcon(
                          title: "bottommenu4",
                          isTitleMultilang: true,
                          iconName: 'ic_store',
                          iconColor: defaultIconColor,
                        ),
                      ),
                    BottomNavigationBarItem(
                      label: "",
                      activeIcon: _buildBottomNavProfileIcon(
                        iconColor: colorPrimary,
                      ),
                      icon: _buildBottomNavProfileIcon(
                        iconColor: defaultIconColor,
                      ),
                    ),
                  ],
                  onTap: _onItemTapped,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavIcon({
    required String title,
    required bool isTitleMultilang,
    required String iconName,
    required Color? iconColor,
  }) {
    return Align(
      alignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            alignment: Alignment.center,
            child: MyImage(
              imagePath: "$iconName.png",
              width: 18,
              height: 18,
              color: iconColor,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            alignment: Alignment.center,
            child: MyText(
              color: iconColor,
              multilanguage: isTitleMultilang,
              text: title,
              fontsizeNormal: 12,
              fontsizeWeb: 14,
              fontweight: FontWeight.w500,
              maxline: 1,
              overflow: TextOverflow.ellipsis,
              textalign: TextAlign.center,
              fontstyle: FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavProfileIcon({required Color? iconColor}) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        if (profileProvider.profileModel.result != null &&
            (profileProvider.profileModel.result?.length ?? 0) > 0) {
          return Align(
            alignment: Alignment.center,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  alignment: Alignment.center,
                  child: (Constant.userIsKid == true)
                      ? ClipRRect(
                          borderRadius: BorderRadiusGeometry.circular(10),
                          child: MyImage(
                            imagePath: 'kids.png',
                            fit: BoxFit.cover,
                            width: 18,
                            height: 18,
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadiusGeometry.circular(10),
                          child: MyUserNetworkImage(
                            imageUrl:
                                profileProvider.profileModel.result?[0].image ??
                                "",
                            fit: BoxFit.cover,
                            width: 18,
                            height: 18,
                          ),
                        ),
                ),
                const SizedBox(height: 2),
                Container(
                  alignment: Alignment.center,
                  child: MyText(
                    color: iconColor,
                    multilanguage: true,
                    text: "bottommenu5",
                    fontsizeNormal: 12,
                    fontsizeWeb: 14,
                    fontweight: FontWeight.w500,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.center,
                    fontstyle: FontStyle.normal,
                  ),
                ),
              ],
            ),
          );
        } else {
          return _buildBottomNavIcon(
            title: "bottommenu5",
            isTitleMultilang: true,
            iconName: 'ic_stuff',
            iconColor: iconColor,
          );
        }
      },
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
