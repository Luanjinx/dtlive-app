import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../pages/mydownloads.dart';
import '../provider/connectivityprovider.dart';
import '../routes/routes_constant.dart';
import '../utils/color.dart';
import '../utils/utils.dart';
import '../widget/myimage.dart';
import '../widget/mytext.dart';

class NoInternet extends StatefulWidget {
  const NoInternet({super.key});

  @override
  State<NoInternet> createState() => NoInternetState();
}

class NoInternetState extends State<NoInternet> {
  Timer? _timer;
  late ConnectivityProvider connectivityProvider;

  @override
  void initState() {
    super.initState();
    connectivityProvider = Provider.of<ConnectivityProvider>(
      context,
      listen: false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setTimer();
    });
  }

  Future<void> _setTimer() async {
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (connectivityProvider.isOnline) {
        printLog("======== CANCELLED ========");
        timer.cancel();
        if (!mounted) return;
        Utils.redirectToMainPage(context: context);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      extendBody: true,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              colorPrimary.withValues(alpha: 0.3),
              colorPrimary.withValues(alpha: 0.2),
              colorPrimary.withValues(alpha: 0.1),
              appBgColor.withValues(alpha: 0.1),
              appBgColor,
            ],
          ),
          borderRadius: BorderRadius.circular(0),
          shape: BoxShape.rectangle,
        ),
        child: SafeArea(
          child: Consumer<ConnectivityProvider>(
            builder: (context, connectivityProvider, child) {
              return _buildPage();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPage() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!connectivityProvider.isOnline)
              Container(
                alignment: Alignment.center,
                child: MyImage(
                  height: 150,
                  fit: BoxFit.contain,
                  imagePath: "ic_no_internet.png",
                ),
              ),
            const SizedBox(height: 25),
            MyText(
              color: titleTextColor,
              text: connectivityProvider.isOnline
                  ? "internet_gain_title"
                  : "no_internet",
              fontsizeNormal: 20,
              fontsizeWeb: 22,
              maxline: 5,
              multilanguage: true,
              overflow: TextOverflow.ellipsis,
              fontweight: FontWeight.w600,
              textalign: TextAlign.center,
              fontstyle: FontStyle.normal,
            ),
            const SizedBox(height: 5),
            MyText(
              color: descTextColor,
              text: connectivityProvider.isOnline
                  ? "internet_gain_desc"
                  : "no_internet_desc",
              fontsizeNormal: 13,
              fontsizeWeb: 15,
              maxline: 5,
              multilanguage: true,
              overflow: TextOverflow.ellipsis,
              fontweight: FontWeight.w400,
              textalign: TextAlign.center,
              fontstyle: FontStyle.normal,
            ),
            /* Login Button */
            const SizedBox(height: 40),
            _buildRetryBtn(),
            const SizedBox(height: 20),
            _buildDownloadBtn(),
          ],
        ),
      ),
    );
  }

  Widget _buildRetryBtn() {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        if (connectivityProvider.isOnline) {
          if (!mounted) return;
          Utils.redirectToMainPage(context: context);
        }
      },
      child: Container(
        height: 45,
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width * 0.5,
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        decoration: Utils.setGradientBGWithCenter(
          colorPrimary,
          colorPrimary.withValues(alpha: 0.6),
          colorPrimary.withValues(alpha: 0.4),
          8,
        ),
        child: MyText(
          color: white,
          text: connectivityProvider.isOnline ? "goto_home" : "retry",
          fontsizeNormal: 15,
          fontsizeWeb: 17,
          maxline: 5,
          multilanguage: true,
          overflow: TextOverflow.ellipsis,
          fontweight: FontWeight.w600,
          textalign: TextAlign.center,
          fontstyle: FontStyle.normal,
        ),
      ),
    );
  }

  Widget _buildDownloadBtn() {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return const MyDownloads(viewFrom: RoutesConstant.homePage);
            },
          ),
        );
      },
      child: FittedBox(
        child: Container(
          height: 45,
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width * 0.5,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: MyText(
            color: titleTextColor,
            text: "open_download",
            fontsizeNormal: 15,
            fontsizeWeb: 17,
            maxline: 5,
            multilanguage: true,
            overflow: TextOverflow.ellipsis,
            fontweight: FontWeight.w600,
            textalign: TextAlign.center,
            fontstyle: FontStyle.normal,
          ),
        ),
      ),
    );
  }
}
