import 'package:flutter/material.dart';

class BottombarProvider extends ChangeNotifier {
  int bottomNavIndex = 0;
  bool isShowBottombar = true;

  Future toggleVisibility(bool isShowBottombar) async {
    this.isShowBottombar = isShowBottombar;
    notifyListeners();
  }

  Future setBottomNavIndex(int index) async {
    bottomNavIndex = index;
    notifyListeners();
  }

  void clearProvider() {
    isShowBottombar = true;
    bottomNavIndex = 0;
  }
}
