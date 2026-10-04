import '../utils/color.dart';
import '../utils/dimens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:google_fonts/google_fonts.dart';

// ignore: must_be_immutable
class MyText extends StatelessWidget {
  String text;
  double? fontsizeNormal, fontsizeWeb, letterSpacing, decorationThickness;
  dynamic maxline, fontstyle, fontweight, textalign, multilanguage;
  Color? color;
  Color? decorationColor;
  TextDecoration? decoration;
  dynamic overflow;
  bool? withShaderMask;
  bool? isShadowText;

  MyText({
    super.key,
    required this.color,
    required this.text,
    this.fontsizeNormal,
    this.fontsizeWeb,
    this.letterSpacing,
    this.maxline,
    this.multilanguage,
    this.overflow,
    this.textalign,
    this.fontweight,
    this.fontstyle,
    this.withShaderMask,
    this.isShadowText,
    this.decoration,
    this.decorationColor,
    this.decorationThickness,
  });

  @override
  Widget build(BuildContext context) {
    if (multilanguage == true) {
      if (withShaderMask != null && withShaderMask == true) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colorPrimary, colorPrimaryDark],
              tileMode: TileMode.mirror,
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height));
          },
          child: LocaleText(
            text,
            textAlign: textalign,
            overflow: overflow,
            maxLines: maxline,
            style: kIsWeb
                ? TextStyle(
                    fontSize: Dimens.isBigScreen(context)
                        ? fontsizeWeb
                        : fontsizeNormal,
                    fontStyle: fontstyle,
                    color: color,
                    fontWeight: fontweight,
                    letterSpacing: letterSpacing,
                    decoration: decoration,
                    decorationColor: decorationColor,
                    decorationThickness: decorationThickness,
                    shadows: [
                      if (isShadowText == true)
                        const Shadow(
                          color: black,
                          offset: Offset(0.8, 0.8),
                          blurRadius: 4,
                        ),
                    ],
                  )
                : GoogleFonts.inter(
                    fontSize: Dimens.isBigScreen(context)
                        ? fontsizeWeb
                        : fontsizeNormal,
                    fontStyle: fontstyle,
                    color: color,
                    fontWeight: fontweight,
                    letterSpacing: letterSpacing,
                    decoration: decoration,
                    decorationColor: decorationColor,
                    decorationThickness: decorationThickness,
                    shadows: [
                      if (isShadowText == true)
                        const Shadow(
                          color: black,
                          offset: Offset(0.8, 0.8),
                          blurRadius: 4,
                        ),
                    ],
                  ),
          ),
        );
      } else {
        return LocaleText(
          text,
          textAlign: textalign,
          overflow: overflow,
          maxLines: maxline,
          style: kIsWeb
              ? TextStyle(
                  fontSize: Dimens.isBigScreen(context)
                      ? fontsizeWeb
                      : fontsizeNormal,
                  fontStyle: fontstyle,
                  color: color,
                  fontWeight: fontweight,
                  letterSpacing: letterSpacing,
                  decoration: decoration,
                  decorationColor: decorationColor,
                  decorationThickness: decorationThickness,
                  shadows: [
                    if (isShadowText == true)
                      const Shadow(
                        color: black,
                        offset: Offset(0.8, 0.8),
                        blurRadius: 4,
                      ),
                  ],
                )
              : GoogleFonts.inter(
                  fontSize: Dimens.isBigScreen(context)
                      ? fontsizeWeb
                      : fontsizeNormal,
                  fontStyle: fontstyle,
                  color: color,
                  fontWeight: fontweight,
                  letterSpacing: letterSpacing,
                  decoration: decoration,
                  decorationColor: decorationColor,
                  decorationThickness: decorationThickness,
                  shadows: [
                    if (isShadowText == true)
                      const Shadow(
                        color: black,
                        offset: Offset(0.8, 0.8),
                        blurRadius: 4,
                      ),
                  ],
                ),
        );
      }
    } else {
      if (withShaderMask != null && withShaderMask == true) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colorPrimary, colorPrimaryDark],
              tileMode: TileMode.mirror,
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height));
          },
          child: Text(
            text,
            textAlign: textalign,
            overflow: overflow,
            maxLines: maxline,
            style: kIsWeb
                ? TextStyle(
                    fontSize: Dimens.isBigScreen(context)
                        ? fontsizeWeb
                        : fontsizeNormal,
                    fontStyle: fontstyle,
                    color: color,
                    fontWeight: fontweight,
                    letterSpacing: letterSpacing,
                    decoration: decoration,
                    decorationColor: decorationColor,
                    decorationThickness: decorationThickness,
                    shadows: [
                      if (isShadowText == true)
                        const Shadow(
                          color: black,
                          offset: Offset(0.8, 0.8),
                          blurRadius: 4,
                        ),
                    ],
                  )
                : GoogleFonts.inter(
                    fontSize: Dimens.isBigScreen(context)
                        ? fontsizeWeb
                        : fontsizeNormal,
                    fontStyle: fontstyle,
                    color: color,
                    fontWeight: fontweight,
                    letterSpacing: letterSpacing,
                    decoration: decoration,
                    decorationColor: decorationColor,
                    decorationThickness: decorationThickness,
                    shadows: [
                      if (isShadowText == true)
                        const Shadow(
                          color: black,
                          offset: Offset(0.8, 0.8),
                          blurRadius: 4,
                        ),
                    ],
                  ),
          ),
        );
      } else {
        return Text(
          text,
          textAlign: textalign,
          overflow: overflow,
          maxLines: maxline,
          style: kIsWeb
              ? TextStyle(
                  fontSize: Dimens.isBigScreen(context)
                      ? fontsizeWeb
                      : fontsizeNormal,
                  fontStyle: fontstyle,
                  color: color,
                  fontWeight: fontweight,
                  letterSpacing: letterSpacing,
                  decoration: decoration,
                  decorationColor: decorationColor,
                  decorationThickness: decorationThickness,
                  shadows: [
                    if (isShadowText == true)
                      const Shadow(
                        color: black,
                        offset: Offset(0.8, 0.8),
                        blurRadius: 4,
                      ),
                  ],
                )
              : GoogleFonts.inter(
                  fontSize: Dimens.isBigScreen(context)
                      ? fontsizeWeb
                      : fontsizeNormal,
                  fontStyle: fontstyle,
                  color: color,
                  fontWeight: fontweight,
                  letterSpacing: letterSpacing,
                  decoration: decoration,
                  decorationColor: decorationColor,
                  decorationThickness: decorationThickness,
                  shadows: [
                    if (isShadowText == true)
                      const Shadow(
                        color: black,
                        offset: Offset(0.8, 0.8),
                        blurRadius: 4,
                      ),
                  ],
                ),
        );
      }
    }
  }
}
