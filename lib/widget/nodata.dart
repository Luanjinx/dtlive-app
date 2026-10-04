import '../utils/color.dart';
import '../utils/dimens.dart';
import '../widget/myimage.dart';
import '../widget/mytext.dart';
import 'package:flutter/material.dart';

class NoData extends StatelessWidget {
  final String? title, subTitle;
  const NoData({super.key, required this.title, required this.subTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: transparent,
        borderRadius: BorderRadius.circular(12),
        shape: BoxShape.rectangle,
      ),
      padding: const EdgeInsets.fromLTRB(30, 15, 30, 15),
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
      constraints: const BoxConstraints(minHeight: 0, minWidth: 0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MyImage(height: 150, fit: BoxFit.contain, imagePath: "nodata.png"),
            const SizedBox(height: 20),
            (title ?? "") != ""
                ? MyText(
                    color: titleTextColor,
                    text: title ?? "",
                    fontsizeNormal: 16,
                    fontsizeWeb: 18,
                    maxline: 5,
                    multilanguage: true,
                    overflow: TextOverflow.ellipsis,
                    fontweight: FontWeight.w600,
                    textalign: TextAlign.center,
                    fontstyle: FontStyle.normal,
                  )
                : const SizedBox.shrink(),
            const SizedBox(height: 8),
            (subTitle ?? "") != ""
                ? MyText(
                    color: descTextColor,
                    text: subTitle ?? "",
                    fontsizeNormal: 14,
                    fontsizeWeb: 16,
                    maxline: 20,
                    multilanguage: true,
                    overflow: TextOverflow.ellipsis,
                    fontweight: FontWeight.w500,
                    textalign: TextAlign.center,
                    fontstyle: FontStyle.normal,
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
