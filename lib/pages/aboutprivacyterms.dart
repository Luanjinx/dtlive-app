import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../utils/adhelper.dart';
import '../utils/color.dart';
import '../utils/loadingoverlay.dart';
import '../utils/sharedpre.dart';
import '../utils/utils.dart';

class AboutPrivacyTerms extends StatefulWidget {
  final String appBarTitle, loadURL;

  const AboutPrivacyTerms({
    super.key,
    required this.appBarTitle,
    required this.loadURL,
  });

  @override
  State<AboutPrivacyTerms> createState() => _AboutPrivacyTermsState();
}

class _AboutPrivacyTermsState extends State<AboutPrivacyTerms> {
  var loadingPercentage = 0;
  InAppWebViewController? webViewController;
  PullToRefreshController? pullToRefreshController;
  SharedPre sharedPref = SharedPre();

  @override
  void initState() {
    super.initState();
    printLog("loadURL ========> ${widget.loadURL}");
    pullToRefreshController =
        (kIsWeb) ||
            ![
              TargetPlatform.iOS,
              TargetPlatform.android,
            ].contains(defaultTargetPlatform)
        ? null
        : PullToRefreshController(
            settings: PullToRefreshSettings(color: complimentryColor),
            onRefresh: () async {
              InAppWebViewController.clearAllCache();
              if (defaultTargetPlatform == TargetPlatform.android) {
                webViewController?.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS ||
                  defaultTargetPlatform == TargetPlatform.macOS) {
                webViewController?.loadUrl(
                  urlRequest: URLRequest(
                    url: await webViewController?.getUrl(),
                  ),
                );
              }
            },
          );
  }

  @override
  void dispose() {
    super.dispose();
    LoadingOverlay().hide();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: appBgColor,
        body: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
            minWidth: MediaQuery.of(context).size.width,
          ),
          child: setWebView(),
        ),
      );
    } else {
      return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: appBgColor,
        appBar: Utils.myAppBarWithBack(context, widget.appBarTitle, false),
        bottomNavigationBar: SmartBannerAd(isSpacing: true, bottomSpace: 10),
        body: setWebView(),
      );
    }
  }

  Widget setWebView() {
    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(widget.loadURL)),
          initialSettings: InAppWebViewSettings(
            supportZoom: true,
            javaScriptEnabled: true,
            disableHorizontalScroll: true,
            useShouldOverrideUrlLoading: true,
            disableVerticalScroll: false,
          ),
          pullToRefreshController: pullToRefreshController,
          onLoadStart: (controller, url) async {
            setState(() {
              loadingPercentage = 0;
            });
          },
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            return NavigationActionPolicy.ALLOW;
          },
          onLoadStop: (controller, url) async {
            setState(() {
              loadingPercentage = 100;
            });
          },
          onProgressChanged: (controller, progress) {
            setState(() {
              loadingPercentage = progress;
            });
          },
          onUpdateVisitedHistory: (controller, url, isReload) {
            printLog("onUpdateVisitedHistory url =========> $url");
          },
          onConsoleMessage: (controller, consoleMessage) {
            printLog("consoleMessage =========> $consoleMessage");
          },
        ),
        if (loadingPercentage < 100)
          LinearProgressIndicator(
            color: complimentryColor,
            backgroundColor: appBgColor,
            value: loadingPercentage / 100.0,
          ),
      ],
    );
  }
}
