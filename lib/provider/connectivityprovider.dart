import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../pages/nointernet.dart';
import '../utils/utils.dart';
import 'package:flutter/services.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity connectivity = Connectivity();

  List<ConnectivityResult> connectivityResults = [ConnectivityResult.none];
  bool isOnline = true;

  Timer? _offlineTimer;

  /// Initialize connectivity & start listening
  Future<void> initConnectivity(BuildContext context) async {
    try {
      final results = await connectivity.checkConnectivity();
      if (context.mounted) {
        await _handleStatus(context, results);
      }
    } on PlatformException catch (e) {
      printLog("Couldn't check connectivity status: $e");
    }

    connectivity.onConnectivityChanged.listen((results) {
      if (context.mounted) {
        _handleStatus(context, results);
      }
    });
  }

  /// Handle changes from connectivity_plus
  Future<void> _handleStatus(
      BuildContext context, List<ConnectivityResult> results) async {
    connectivityResults = results;

    final hasConnection = results.any((r) =>
        (r == ConnectivityResult.mobile) ||
        (r == ConnectivityResult.wifi) ||
        (r == ConnectivityResult.ethernet));

    // --- ONLINE ---
    if (hasConnection) {
      _offlineTimer?.cancel();
      printLog('_handleStatus isOnline ==> $isOnline');
      if (!isOnline) {
        isOnline = true;
        printLog(
            '_handleStatus Back online: ${results.map((e) => e.name).join(", ")}');
        notifyListeners();
      }
      return;
    }

    // --- OFFLINE (schedule delay) ---
    _offlineTimer?.cancel();
    _offlineTimer = Timer(const Duration(seconds: 3), () {
      if (isOnline) {
        isOnline = false;
        printLog('Went offline');
        notifyListeners();
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => const NoInternet()),
          (Route<dynamic> route) => false,
        ).then(
          (value) {
            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => const NoInternet()),
            );
          },
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
