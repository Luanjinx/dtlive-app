import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:web/web.dart';

import '../utils/utils.dart';

@JS('window.jsOpenTab')
external JSPromise<JSString> jsOpenTab(JSString url, JSString target);

@JS('hideRecaptchaBadge')
external void _hideRecaptchaBadge();

class JSHelper {
  Future<String> callOpenTab(String url, String target) async {
    try {
      final JSString result = await jsOpenTab(url.toJS, target.toJS).toDart;
      return result.toDart;
    } catch (e) {
      return "Blocked";
    }
  }

  void setupWebVisibility(BuildContext context) {
    document.addEventListener(
      'visibilitychange',
      ((Event _) {
        // 4. Use document.hidden directly from package:web
        final isHidden = document.hidden;
        printLog("👀 Web Visibility changed: hidden => $isHidden");

        if (isHidden) {
        } else {}
      }).toJS, // This replaces allowInterop
    );
  }

  void setupRightClickBlock() {
    document.addEventListener(
      'contextmenu',
      (Event event) {
        event.preventDefault();
      }.toJS,
    );
  }

  void goBack() {
    window.history.back();
  }

  Future<void> callBrowserFullscreen(bool isFullscreen) async {
    if (isFullscreen) {
      final element = document.documentElement;
      if (element != null) {
        try {
          await element.requestFullscreen().toDart;
        } catch (e) {
          printLog("requestFullscreen failed: $e");
        }
      }
      try {
        await window.screen.orientation.lock('landscape').toDart;
        printLog("screen.orientation.lock('landscape') succeeded");
      } catch (e) {
        printLog("screen.orientation.lock('landscape') failed or not supported: $e");
      }
    } else {
      try {
        window.screen.orientation.unlock();
      } catch (e) {
        printLog("screen.orientation.unlock failed: $e");
      }
      if (document.fullscreenElement != null) {
        try {
          await document.exitFullscreen().toDart;
        } catch (e) {
          printLog("exitFullscreen failed: $e");
        }
      }
    }
  }

  void hideRecaptcha() {
    _hideRecaptchaBadge();
  }
}
