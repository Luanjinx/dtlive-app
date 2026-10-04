import '../provider/connectivityprovider.dart';
import '../provider/playerprovider.dart';
import '../utils/color.dart';
import '../utils/dimens.dart';
import '../utils/utils.dart';
import '../widget/mytext.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CannotWatch extends StatefulWidget {
  const CannotWatch({super.key});

  @override
  State<CannotWatch> createState() => CannotWatchState();
}

class CannotWatchState extends State<CannotWatch> {
  late ConnectivityProvider connectivityProvider;
  late PlayerProvider playerProvider;

  @override
  void initState() {
    super.initState();
    connectivityProvider =
        Provider.of<ConnectivityProvider>(context, listen: false);
    playerProvider = Provider.of<PlayerProvider>(context, listen: false);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (kIsWeb) {
          if (context.canPop()) {
            context.pop(false);
          }
        } else {
          if (Navigator.canPop(context)) {
            Navigator.pop(context, false);
          }
        }
      },
      child: Scaffold(
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
            child: _buildPage(),
          ),
        ),
      ),
    );
  }

  Widget _buildPage() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Container(
          width: MediaQuery.of(context).size.width > 1080
              ? (MediaQuery.of(context).size.width * 0.35)
              : ((MediaQuery.of(context).size.width <= 1080 &&
                      (MediaQuery.of(context).size.width > 720))
                  ? (MediaQuery.of(context).size.width * 0.5)
                  : MediaQuery.of(context).size.width),
          margin: EdgeInsets.fromLTRB(
            Dimens.isBigScreen(context) ? 70 : 15,
            Dimens.isBigScreen(context) ? 70 : 15,
            Dimens.isBigScreen(context) ? 70 : 15,
            Dimens.isBigScreen(context) ? 70 : 15,
          ),
          alignment: Alignment.center,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MyText(
                color: titleTextColor,
                text: "device_limit_reached_title",
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
                text: "device_limit_reached_desc",
                fontsizeNormal: 14,
                fontsizeWeb: 16,
                maxline: 25,
                multilanguage: true,
                overflow: TextOverflow.ellipsis,
                fontweight: FontWeight.w400,
                textalign: TextAlign.center,
                fontstyle: FontStyle.normal,
              ),
              /* Devices Watching */
              _buildDevices(),
              /* Retry Button */
              const SizedBox(height: 40),
              _buildRetryBtn(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDevices() {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        if (playerProvider.deviceSyncModel.result != null &&
            (playerProvider.deviceSyncModel.result?.length ?? 0) > 0) {
          return Container(
            margin: const EdgeInsets.fromLTRB(0, 15, 0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  child: MyText(
                    color: titleTextColor,
                    text: "screen_",
                    fontsizeNormal: 15,
                    fontsizeWeb: 17,
                    maxline: 1,
                    multilanguage: true,
                    overflow: TextOverflow.ellipsis,
                    fontweight: FontWeight.w500,
                    textalign: TextAlign.start,
                    fontstyle: FontStyle.normal,
                  ),
                ),
                const SizedBox(height: 5),
                AlignedGridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 1,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                  itemCount:
                      (playerProvider.deviceSyncModel.result?.length ?? 0),
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int position) {
                    return MyText(
                      color: titleTextColor,
                      text: playerProvider
                              .deviceSyncModel.result?[position].deviceName ??
                          "",
                      fontsizeNormal: 15,
                      fontsizeWeb: 17,
                      maxline: 1,
                      multilanguage: false,
                      overflow: TextOverflow.ellipsis,
                      fontweight: FontWeight.w700,
                      textalign: TextAlign.start,
                      fontstyle: FontStyle.normal,
                    );
                  },
                ),
              ],
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildRetryBtn() {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        /* ******* Check Device Sync ******* */
        if (connectivityProvider.isOnline && !playerProvider.loading) {
          Utils.showToast(Locales.string(context, "checking"));
          await playerProvider.addRemoveDevice(1);
          if (playerProvider.isDeviceAdded) {
            if (mounted) {
              if (kIsWeb) {
                if (context.canPop()) {
                  context.pop(true);
                }
              } else {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context, true);
                }
              }
            }
          } else {
            Utils.showToast(playerProvider.deviceSyncModel.message ?? "");
          }
        }
        /* ************** */
      },
      child: Container(
        height: 45,
        constraints:
            BoxConstraints(minWidth: MediaQuery.of(context).size.width * 0.5),
        alignment: Alignment.center,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        decoration: Utils.setGradientBGWithCenter(
            colorPrimary,
            colorPrimary.withValues(alpha: 0.6),
            colorPrimary.withValues(alpha: 0.4),
            8),
        child: MyText(
          color: white,
          text: "retry",
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
}
