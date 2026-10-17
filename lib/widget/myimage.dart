import '../utils/color.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class MyImage extends StatelessWidget {
  double? height;
  double? width;
  String? imagePath;
  Color? color;
  dynamic fit;
  bool? withShaderMask;

  MyImage({
    super.key,
    this.width,
    this.height,
    required this.imagePath,
    this.color,
    this.fit,
    this.withShaderMask,
  });

  @override
  Widget build(BuildContext context) {
    if (withShaderMask != null && withShaderMask == true) {
      return ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colorPrimaryDark, colorPrimary],
          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height));
        },
        child: Image.asset(
          "assets/images/$imagePath",
          height: height,
          color: color,
          width: width,
          fit: fit,
          errorBuilder: (context, url, error) {
            return Container(
              width: width,
              height: height,
              color: transparent,
            );
          },
        ),
      );
    } else {
      return Image.asset(
        "assets/images/$imagePath",
        height: height,
        color: color,
        width: width,
        fit: fit,
        errorBuilder: (context, url, error) {
          return Container(
            width: width,
            height: height,
            color: transparent,
          );
        },
      );
    }
  }
}
