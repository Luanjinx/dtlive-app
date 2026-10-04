import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/color.dart';
import '../utils/constant.dart';
import '../utils/dimens.dart';
import '../utils/sharedpre.dart';
import '../utils/utils.dart';
import '../webpages/webcomman.dart';
import '../widget/myimage.dart';
import '../widget/mytext.dart';

class ContactUs extends StatefulWidget {
  final String? newPage, oldPage;
  const ContactUs({
    required this.newPage,
    required this.oldPage,
    super.key,
  });

  @override
  State<ContactUs> createState() => _ContactUsState();
}

class _ContactUsState extends State<ContactUs> {
  SharedPre sharedPre = SharedPre();
  String? mobileNumber, emailAddress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getData();
    });
  }

  Future<void> _getData() async {
    mobileNumber = await sharedPre.read(Constant.supportMobileKey);
    emailAddress = await sharedPre.read(Constant.supportEmailKey);
    printLog("_getData mobileNumber ==> $mobileNumber");
    printLog("_getData emailAddress ==> $emailAddress");

    Future.delayed(Duration.zero).then(
      (value) {
        if (!mounted) return;
        setState(() {});
      },
    );
  }

  void launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not launch $phoneUri';
    }
  }

  void launchEmail(String emailAddress) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw 'Could not launch $emailUri';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return WebComman(
        newPage: widget.newPage,
        oldPage: widget.oldPage,
        reqText: '',
        newChild: _buildWebPageUI(),
      );
    } else {
      return Scaffold(
        backgroundColor: appBgColor,
        body: SafeArea(
          child: _buildPageUI(),
        ),
      );
    }
  }

  Widget _buildWebPageUI() {
    return Container(
      padding: const EdgeInsets.all(0),
      width: MediaQuery.of(context).size.width,
      child:
          Dimens.isBigScreen(context) ? _buildWebRowUI() : _buildWebColumnUI(),
    );
  }

  Widget _buildWebRowUI() {
    return Column(
      children: [
        SizedBox(height: (Dimens.homeTabHeight + 20)),
        MyText(
          color: titleTextColor,
          text: "contact_customer_care",
          textalign: TextAlign.center,
          fontsizeNormal: 22,
          fontsizeWeb: 24,
          maxline: 1,
          multilanguage: true,
          overflow: TextOverflow.ellipsis,
          fontweight: FontWeight.w500,
          fontstyle: FontStyle.normal,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildTitleIconView(
                    title: "call",
                    iconName: "ic_calling",
                  ),
                  const SizedBox(height: 15),
                  _buildButton(
                    title: mobileNumber ?? "",
                    onClick: () {
                      launchPhone(mobileNumber ?? "");
                    },
                  ),
                  const SizedBox(height: 25),
                  MyText(
                    color: titleTextColor,
                    text: "or",
                    textalign: TextAlign.start,
                    fontsizeNormal: 16,
                    fontsizeWeb: 18,
                    maxline: 1,
                    multilanguage: true,
                    overflow: TextOverflow.ellipsis,
                    fontweight: FontWeight.w600,
                    fontstyle: FontStyle.normal,
                  ),
                  const SizedBox(height: 25),
                  _buildTitleIconView(
                    title: "write_to_us",
                    iconName: "ic_mail",
                  ),
                  const SizedBox(height: 15),
                  _buildButton(
                    title: emailAddress ?? "",
                    onClick: () {
                      launchEmail(emailAddress ?? "");
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildBottomImg(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWebColumnUI() {
    return Column(
      children: [
        SizedBox(height: (Dimens.homeTabHeight + 20)),
        MyText(
          color: titleTextColor,
          text: "contact_customer_care",
          textalign: TextAlign.center,
          fontsizeNormal: 22,
          fontsizeWeb: 24,
          maxline: 1,
          multilanguage: true,
          overflow: TextOverflow.ellipsis,
          fontweight: FontWeight.w500,
          fontstyle: FontStyle.normal,
        ),
        const SizedBox(height: 20),
        _buildTitleIconView(
          title: "call",
          iconName: "ic_calling",
        ),
        const SizedBox(height: 15),
        _buildButton(
          title: mobileNumber ?? "",
          onClick: () {
            launchPhone(mobileNumber ?? "");
          },
        ),
        const SizedBox(height: 25),
        MyText(
          color: titleTextColor,
          text: "or",
          textalign: TextAlign.start,
          fontsizeNormal: 16,
          fontsizeWeb: 18,
          maxline: 1,
          multilanguage: true,
          overflow: TextOverflow.ellipsis,
          fontweight: FontWeight.w600,
          fontstyle: FontStyle.normal,
        ),
        const SizedBox(height: 25),
        _buildTitleIconView(
          title: "write_to_us",
          iconName: "ic_mail",
        ),
        const SizedBox(height: 15),
        _buildButton(
          title: emailAddress ?? "",
          onClick: () {
            launchEmail(emailAddress ?? "");
          },
        ),
        const SizedBox(height: 20),
        _buildBottomImg(),
      ],
    );
  }

  Widget _buildPageUI() {
    return Container(
      padding: const EdgeInsets.all(0),
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: Dimens.isBigScreen(context) ? Dimens.homeTabHeight : null,
          ),
          if (!kIsWeb)
            Container(
              alignment: Alignment.centerRight,
              margin: const EdgeInsets.only(top: 30, right: 20, bottom: 20),
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                focusColor: gray.withValues(alpha: 0.5),
                onTap: () {
                  Utils.exitPage(context);
                },
                child: Container(
                  decoration:
                      Utils.setBackground(black.withValues(alpha: 0.5), 25),
                  padding: const EdgeInsets.all(5.0),
                  child: MyImage(
                    height: 20,
                    width: 20,
                    imagePath: "ic_close.png",
                    fit: BoxFit.contain,
                    color: white,
                  ),
                ),
              ),
            ),
          MyText(
            color: titleTextColor,
            text: "contact_customer_care",
            textalign: TextAlign.center,
            fontsizeNormal: 22,
            fontsizeWeb: 24,
            maxline: 1,
            multilanguage: true,
            overflow: TextOverflow.ellipsis,
            fontweight: FontWeight.w500,
            fontstyle: FontStyle.normal,
          ),
          const SizedBox(height: 20),
          _buildTitleIconView(
            title: "call",
            iconName: "ic_calling",
          ),
          const SizedBox(height: 15),
          _buildButton(
            title: mobileNumber ?? "",
            onClick: () {
              launchPhone(mobileNumber ?? "");
            },
          ),
          const SizedBox(height: 25),
          MyText(
            color: titleTextColor,
            text: "or",
            textalign: TextAlign.start,
            fontsizeNormal: 16,
            fontsizeWeb: 18,
            maxline: 1,
            multilanguage: true,
            overflow: TextOverflow.ellipsis,
            fontweight: FontWeight.w600,
            fontstyle: FontStyle.normal,
          ),
          const SizedBox(height: 25),
          _buildTitleIconView(
            title: "write_to_us",
            iconName: "ic_mail",
          ),
          const SizedBox(height: 15),
          _buildButton(
            title: emailAddress ?? "",
            onClick: () {
              launchEmail(emailAddress ?? "");
            },
          ),
          const SizedBox(height: 25),
          _buildBottomImg(),
        ],
      ),
    );
  }

  Widget _buildBottomImg() {
    if (kIsWeb) {
      final screens = WidgetsBinding.instance.platformDispatcher.displays;
      final screenHeight = screens.first.size.height;
      return Container(
        padding: EdgeInsets.fromLTRB(Dimens.isBigScreen(context) ? 50 : 20, 0,
            Dimens.isBigScreen(context) ? 50 : 20, 0),
        child: MyImage(
          imagePath: "ic_help.png",
          height: (screenHeight * 0.5),
          width: Dimens.isBigScreen(context)
              ? (MediaQuery.of(context).size.width * 0.5)
              : (MediaQuery.of(context).size.width * 0.7),
          fit: BoxFit.contain,
        ),
      );
    }
    return Expanded(
      child: Container(
        transform: Matrix4.translationValues(0, 25, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              appBgColor,
              appBgColor.withValues(alpha: 0.2),
              lightBlack.withValues(alpha: 0.2),
              lightBlack.withValues(alpha: 0.4),
            ],
          ),
          shape: BoxShape.rectangle,
        ),
        padding: const EdgeInsets.fromLTRB(50, 50, 50, 0),
        child: MyImage(
          imagePath: "ic_help.png",
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildTitleIconView({
    required String title,
    required String iconName,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        MyImage(
          imagePath: "$iconName.png",
          height: 23,
          width: 23,
          fit: BoxFit.contain,
          color: titleTextColor,
        ),
        const SizedBox(width: 10),
        MyText(
          color: titleTextColor,
          text: title,
          textalign: TextAlign.start,
          fontsizeNormal: 16,
          fontsizeWeb: 18,
          maxline: 1,
          multilanguage: true,
          overflow: TextOverflow.ellipsis,
          fontweight: FontWeight.w500,
          fontstyle: FontStyle.normal,
        ),
      ],
    );
  }

  Widget _buildButton({
    required String title,
    required Function()? onClick,
  }) {
    return FittedBox(
      child: InkWell(
        borderRadius: BorderRadius.circular(5),
        onTap: onClick,
        child: Container(
          height: 40,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          decoration: BoxDecoration(
            color: colorPrimary,
            borderRadius: BorderRadius.circular(5),
          ),
          alignment: Alignment.center,
          child: MyText(
            color: black,
            text: title,
            textalign: TextAlign.center,
            fontsizeNormal: 15,
            fontsizeWeb: 17,
            fontweight: FontWeight.w600,
            multilanguage: false,
            maxline: 1,
            overflow: TextOverflow.ellipsis,
            fontstyle: FontStyle.normal,
          ),
        ),
      ),
    );
  }
}
