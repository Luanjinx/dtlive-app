import '../utils/color.dart';
import '../utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class InstamojoPG extends StatefulWidget {
  final String? paymentId;
  final String? paymentUrl;

  const InstamojoPG({
    super.key,
    required this.paymentId,
    required this.paymentUrl,
  });

  @override
  State<InstamojoPG> createState() => _InstamojoPGState();
}

class _InstamojoPGState extends State<InstamojoPG> {
  InAppWebViewController? webViewController;
  String finalPaymentId = "";

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        printLog("finalPaymentId =========> $finalPaymentId");
        if (Navigator.canPop(context)) {
          if (finalPaymentId != "") {
            Navigator.pop(context, true);
          } else {
            Navigator.pop(context, false);
          }
        }
      },
      child: Scaffold(
        backgroundColor: appBgColor,
        appBar: Utils.myAppBarWithBack(context, "Instamojo", false),
        body: SafeArea(
          child: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.paymentUrl ?? "")),
            onWebViewCreated: (controller) async {
              webViewController = controller;
            },
            onLoadStart: (controller, url) async {},
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              return NavigationActionPolicy.ALLOW;
            },
            onLoadStop: (controller, url) async {
              printLog("onLoadStop url =========> $url");
              if (url.toString().contains('instamojo.com/order/status')) {
                finalPaymentId = widget.paymentId ?? "";
                printLog(
                    "onLoadStop finalPaymentId =========> $finalPaymentId");
                Navigator.pop(context, true);
              } else {
                finalPaymentId = "";
              }
            },
            onProgressChanged: (controller, progress) {},
            onUpdateVisitedHistory: (controller, url, isReload) {
              printLog("onUpdateVisitedHistory url =========> $url");
            },
            onConsoleMessage: (controller, consoleMessage) {},
          ),
        ),
      ),
    );
  }
}
