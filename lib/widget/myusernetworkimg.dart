import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widget/myimage.dart';

// ignore: must_be_immutable
class MyUserNetworkImage extends StatefulWidget {
  String imageUrl;
  double? height, width;
  dynamic fit;

  MyUserNetworkImage({
    super.key,
    required this.imageUrl,
    required this.fit,
    this.height,
    this.width,
  });

  @override
  State<MyUserNetworkImage> createState() => _MyUserNetworkImageState();
}

class _MyUserNetworkImageState extends State<MyUserNetworkImage> {
  bool _isPrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (kIsWeb && !_isPrecached) {
      _precacheImage();
      _isPrecached = true;
    }
  }

  Future<void> _precacheImage() async {
    final image = NetworkImage(widget.imageUrl);
    await precacheImage(image, context);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.contains('no_img')) {
      return MyImage(
        width: widget.width,
        height: widget.height,
        imagePath: "no_image_land.png",
        fit: BoxFit.cover,
      );
    }

    if (kIsWeb) {
      return SizedBox(
        height: widget.height,
        width: widget.width,
        child: Image.network(
          widget.imageUrl,
          fit: widget.fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return MyImage(
              width: widget.width,
              height: widget.height,
              imagePath: widget.imageUrl.contains('land_')
                  ? "no_image_land.png"
                  : "no_image_port.png",
              fit: BoxFit.cover,
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return MyImage(
              width: widget.width,
              height: widget.height,
              imagePath: widget.imageUrl.contains('land_')
                  ? "no_image_land.png"
                  : "no_image_port.png",
              fit: BoxFit.cover,
            );
          },
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: CachedNetworkImage(
        imageUrl: widget.imageUrl,
        fit: widget.fit,
        imageBuilder: (context, imageProvider) => Container(
          decoration: BoxDecoration(
            image: DecorationImage(image: imageProvider, fit: widget.fit),
          ),
        ),
        placeholder: (context, url) {
          return MyImage(
            width: widget.width,
            height: widget.height,
            imagePath: widget.imageUrl.contains('land_')
                ? "no_image_land.png"
                : "no_image_port.png",
            fit: BoxFit.cover,
          );
        },
        errorWidget: (context, url, error) {
          return MyImage(
            width: widget.width,
            height: widget.height,
            imagePath: widget.imageUrl.contains('land_')
                ? "no_image_land.png"
                : "no_image_port.png",
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }
}
