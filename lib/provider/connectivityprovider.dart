import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../pages/nointernet.dart';
import '../utils/utils.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity connectivity = Connectivity();

  List<ConnectivityResult> connectivityResults = [ConnectivityResult.none];
  bool isOnline = true;

  Timer? _offlineTimer;

  /// Initialize connectivity & start listening.
  /// No BuildContext stored — navigation uses the top-level navigatorKey.
  Future<void> initConnectivity() async {
    try {
      final results = await connectivity.checkConnectivity();
      await _handleStatus(results);
    } on PlatformException catch (e) {
      printLog("Couldn't check connectivity status: $e");
    }

    connectivity.onConnectivityChanged.listen((results) {
      _handleStatus(results);
    });
  }

  Future<void> _handleStatus(List<ConnectivityResult> results) async {
    connectivityResults = results;

    final bool hasConnection = results.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet,
    );

    // --- ONLINE ---
    if (hasConnection) {
      _offlineTimer?.cancel();
      printLog('_handleStatus isOnline ==> $isOnline');
      if (!isOnline) {
        isOnline = true;
        printLog(
          '_handleStatus Back online: ${results.map((e) => e.name).join(", ")}',
        );
        notifyListeners();
      }
      return;
    }

    // --- OFFLINE (3s delay to avoid false triggers) ---
    _offlineTimer?.cancel();
    _offlineTimer = Timer(const Duration(seconds: 3), () {
      if (isOnline) {
        isOnline = false;
        printLog('Went offline');
        notifyListeners();

        final NavigatorState? navigator = navigatorKey.currentState;
        if (navigator == null) return;

        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const NoInternet()),
          (Route<dynamic> route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _offlineTimer?.cancel();
    super.dispose();
  }
}
