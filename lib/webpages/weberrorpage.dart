import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils/color.dart';
import '../utils/utils.dart';
import '../widget/myimage.dart';
import '../widget/mytext.dart';

class WebErrorPage extends StatelessWidget {
  const WebErrorPage(this.error, {super.key});
  final Exception error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      appBar: AppBar(
        backgroundColor: appBgColor,
        title: MyText(
          multilanguage: false,
          color: redColor,
          text: "404 Page Not Found!",
          maxline: 2,
          textalign: TextAlign.center,
          fontstyle: FontStyle.normal,
          fontsizeNormal: 22,
          fontsizeWeb: 24,
          overflow: TextOverflow.ellipsis,
          fontweight: FontWeight.w600,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MyImage(height: 230, fit: BoxFit.contain, imagePath: "ic_404.png"),
            const SizedBox(height: 20),
            SelectableText(error.toString()),
            MyText(
              multilanguage: false,
              color: white,
              text: error.toString(),
              maxline: 10,
              textalign: TextAlign.center,
              fontstyle: FontStyle.normal,
              fontsizeNormal: 18,
              fontsizeWeb: 20,
              overflow: TextOverflow.ellipsis,
              fontweight: FontWeight.w500,
            ),
            InkWell(
              onTap: () {
                context.go('/');
              },
              child: FittedBox(
                child: Container(
                  height: 35,
                  padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                  decoration: Utils.setBackground(colorPrimaryDark, 5),
                  alignment: Alignment.center,
                  child: MyText(
                    multilanguage: true,
                    color: white,
                    text: "go_to_home",
                    maxline: 1,
                    textalign: TextAlign.center,
                    fontstyle: FontStyle.normal,
                    fontsizeNormal: 18,
                    fontsizeWeb: 20,
                    overflow: TextOverflow.ellipsis,
                    fontweight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
