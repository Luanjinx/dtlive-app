import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import '../utils/loadingoverlay.dart';
import '../provider/generalprovider.dart';
import '../utils/color.dart';
import '../utils/sharedpre.dart';
import '../widget/myimage.dart';
import '../widget/mytext.dart';
import '../utils/utils.dart';

class ActiveTV extends StatefulWidget {
  final String? newPage, oldPage;
  final dynamic reqText;
  const ActiveTV({
    required this.newPage,
    required this.oldPage,
    required this.reqText,
    super.key,
  });

  @override
  State<ActiveTV> createState() => ActiveTVState();
}

class ActiveTVState extends State<ActiveTV> {
  SharedPre sharePref = SharedPre();
  final pinPutController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    FocusManager.instance.primaryFocus?.unfocus();
    pinPutController.dispose();
    LoadingOverlay().hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      body: SafeArea(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          margin: const EdgeInsets.all(25),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: () {
                      Utils.exitPage(context);
                    },
                    child: Container(
                      width: 35,
                      height: 35,
                      alignment: Alignment.centerLeft,
                      child: MyImage(
                        fit: BoxFit.fill,
                        imagePath: "backwith_bg.png",
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                MyText(
                  color: titleTextColor,
                  text: "verify_tvcode",
                  fontsizeNormal: 22,
                  multilanguage: true,
                  fontweight: FontWeight.bold,
                  maxline: 2,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.center,
                  fontstyle: FontStyle.normal,
                ),
                const SizedBox(height: 8),
                MyText(
                  color: descTextColor,
                  text: "tvcode_desc",
                  fontsizeNormal: 15,
                  fontweight: FontWeight.w500,
                  maxline: 3,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.center,
                  multilanguage: true,
                  fontstyle: FontStyle.normal,
                ),
                const SizedBox(height: 40),

                /* Enter TV pin */
                Pinput(
                  length: 4,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  controller: pinPutController,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  defaultPinTheme: PinTheme(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      border: Border.all(color: colorPrimary, width: 0.7),
                      shape: BoxShape.rectangle,
                      color: edtShadowColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    textStyle: GoogleFonts.inter(
                      color: white,
                      fontSize: 16,
                      fontStyle: FontStyle.normal,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                /* Confirm Button */
                InkWell(
                  borderRadius: BorderRadius.circular(26),
                  onTap: () {
                    printLog(
                      "Clicked sms Code =====> ${pinPutController.text}",
                    );
                    if (pinPutController.text.toString().isEmpty) {
                      Utils.showSnackbar(
                        context,
                        "info",
                        "enter_tv_code",
                        true,
                      );
                    } else {
                      _checkAndLogin();
                    }
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [colorPrimary, colorPrimaryDark],
                        begin: FractionalOffset(0.0, 0.0),
                        end: FractionalOffset(1.0, 0.0),
                        stops: [0.0, 1.0],
                        tileMode: TileMode.clamp,
                      ),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    alignment: Alignment.center,
                    child: MyText(
                      color: white,
                      text: "confirm",
                      fontsizeNormal: 17,
                      multilanguage: true,
                      fontweight: FontWeight.w700,
                      maxline: 1,
                      overflow: TextOverflow.ellipsis,
                      textalign: TextAlign.center,
                      fontstyle: FontStyle.normal,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkAndLogin() async {
    printLog("click on Submit mobile => ${pinPutController.text}");
    var generalProvider = Provider.of<GeneralProvider>(context, listen: false);
    LoadingOverlay().show(context);
    await generalProvider.loginWithTV(pinPutController.text.toString());

    if (!generalProvider.loading) {
      if (generalProvider.loginTVModel.status == 200) {
        printLog('Login Successfull!');
        if (!mounted) return;
        LoadingOverlay().hide();
        Utils.showSnackbar(context, "success", "tv_login_success", true);
        Utils.exitPage(context);
      } else {
        if (!mounted) return;
        LoadingOverlay().hide();
        Utils.showSnackbar(
          context,
          "fail",
          "${generalProvider.loginTVModel.message}",
          false,
        );
      }
    }
  }
}
