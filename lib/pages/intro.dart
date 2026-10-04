import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../pages/bottombar.dart';
import '../provider/generalprovider.dart';
import '../utils/color.dart';
import '../widget/mynetworkimg.dart';
import '../widget/mytext.dart';
import '../utils/utils.dart';

class Intro extends StatefulWidget {
  const Intro({super.key});

  @override
  State<Intro> createState() => IntroState();
}

class IntroState extends State<Intro> {
  late GeneralProvider generalProvider;
  PageController pageController = PageController();
  final currentPageNotifier = ValueNotifier<int>(0);
  int position = 0;

  @override
  void initState() {
    super.initState();
    generalProvider = Provider.of<GeneralProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _fetchIntro();
    });
  }

  Future<void> _fetchIntro() async {
    await generalProvider.getIntroPages();
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (generalProvider.introScreenModel.result != null &&
              (generalProvider.introScreenModel.result?.length ?? 0) > 0)
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              color: black,
              alignment: Alignment.center,
              child: SafeArea(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Expanded(
                        flex: 6,
                        child: Padding(padding: EdgeInsets.all(18)),
                      ),
                      Expanded(
                        flex: 5,
                        child: Stack(
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.height * 0.5,
                            ),
                            Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                margin: const EdgeInsets.only(top: 0),
                                child: SmoothPageIndicator(
                                  controller: pageController,
                                  count:
                                      (generalProvider
                                          .introScreenModel
                                          .result
                                          ?.length ??
                                      0),
                                  axisDirection: Axis.horizontal,
                                  effect: const ExpandingDotsEffect(
                                    spacing: 6,
                                    radius: 5,
                                    dotWidth: 10,
                                    expansionFactor: 4,
                                    dotHeight: 10,
                                    dotColor: grayDark,
                                    activeDotColor: colorPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          PageView.builder(
            itemCount: (generalProvider.introScreenModel.result?.length ?? 0),
            controller: pageController,
            scrollDirection: Axis.horizontal,
            itemBuilder: (BuildContext context, int index) {
              return SafeArea(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(30),
                          child: MyNetworkImage(
                            imageUrl:
                                generalProvider
                                    .introScreenModel
                                    .result?[index]
                                    .image ??
                                "",
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.fromLTRB(25, 10, 25, 10),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              const SizedBox(height: 60),
                              MyText(
                                color: titleTextColor,
                                maxline: 4,
                                multilanguage: false,
                                overflow: TextOverflow.ellipsis,
                                text:
                                    generalProvider
                                        .introScreenModel
                                        .result?[index]
                                        .title ??
                                    "",
                                textalign: TextAlign.center,
                                fontsizeNormal: 20,
                                fontsizeWeb: 25,
                                fontweight: FontWeight.w600,
                                fontstyle: FontStyle.normal,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            onPageChanged: (index) {
              position = index;
              currentPageNotifier.value = index;
              printLog("position :==> $position");
              setState(() {});
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 80),
              child: InkWell(
                onTap: () {
                  printLog("nextPage pos :==> $position");
                  if (position ==
                      (generalProvider.introScreenModel.result?.length ?? 0) -
                          1) {
                    Utils.setFirstTime("1");
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const Bottombar();
                        },
                      ),
                    );
                  }
                  pageController.nextPage(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeIn,
                  );
                },
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 0,
                    maxHeight: 45,
                    minWidth: 0,
                    maxWidth: 170,
                  ),
                  padding: const EdgeInsets.all(12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorPrimaryDark,
                    borderRadius: BorderRadius.circular(5),
                    shape: BoxShape.rectangle,
                  ),
                  child: MyText(
                    color: white,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    multilanguage: true,
                    text:
                        (position ==
                            (generalProvider.introScreenModel.result?.length ??
                                    0) -
                                1)
                        ? "getstarted"
                        : "next",
                    textalign: TextAlign.center,
                    fontsizeNormal: 16,
                    fontsizeWeb: 18,
                    fontweight: FontWeight.w700,
                    fontstyle: FontStyle.normal,
                  ),
                ),
              ),
            ),
          ),
          (position !=
                  (generalProvider.introScreenModel.result?.length ?? 0) - 1)
              ? Align(
                  alignment: Alignment.bottomRight,
                  child: InkWell(
                    onTap: () {
                      printLog("pos :==> $position");
                      Utils.setFirstTime("1");
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return const Bottombar();
                          },
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(0, 0, 20, 20),
                      padding: const EdgeInsets.all(15),
                      child: MyText(
                        color: white,
                        maxline: 1,
                        overflow: TextOverflow.ellipsis,
                        text: "skip",
                        multilanguage: true,
                        textalign: TextAlign.center,
                        fontsizeNormal: 14,
                        fontsizeWeb: 16,
                        fontweight: FontWeight.w600,
                        fontstyle: FontStyle.normal,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
