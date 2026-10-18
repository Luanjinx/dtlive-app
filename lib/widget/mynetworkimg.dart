import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

import '../utils/color.dart';

// ignore: must_be_immutable
class MyNetworkImage extends StatefulWidget {
  String imageUrl;
  double? height, width;
  dynamic fit;

  MyNetworkImage({
    super.key,
    required this.imageUrl,
    required this.fit,
    this.height,
    this.width,
  });

  @override
  State<MyNetworkImage> createState() => _MyNetworkImageState();
}

class _MyNetworkImageState extends State<MyNetworkImage> {
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
    try {
      final String cleanUrl = _resolveUrl(widget.imageUrl);
      if (cleanUrl.isNotEmpty && !cleanUrl.contains('no_img')) {
        final image = NetworkImage(cleanUrl);
        await precacheImage(image, context, onError: (e, s) {});
      }
    } catch (_) {}
  }

  String _resolveUrl(String url) {
    String clean = url.trim();
    if (kIsWeb) {
      if (Uri.base.scheme == 'https' && clean.startsWith('http://')) {
        clean = 'https://${clean.substring(7)}';
      }
    }
    return clean;
  }

  Widget _buildShimmerPlaceholder() {
    return Shimmer(
      duration: const Duration(milliseconds: 800),
      interval: const Duration(milliseconds: 800),
      color: shimmerColor,
      colorOpacity: 0.3,
      enabled: true,
      direction: const ShimmerDirection.fromLTRB(),
      child: Container(
        width: widget.width,
        height: widget.height,
        color: shimmerItemColor,
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: shimmerItemColor,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: gray.withValues(alpha: 0.4),
        size: ((widget.width ?? 0) > 0 && (widget.width ?? 0) < 50) ? 16 : 26,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String cleanUrl = _resolveUrl(widget.imageUrl);
    if (cleanUrl.isEmpty || cleanUrl.contains('no_img')) {
      return _buildErrorWidget();
    }
    if (kIsWeb) {
      return SizedBox(
        height: widget.height,
        width: widget.width,
        child: Image.network(
          cleanUrl,
          fit: widget.fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return _buildShimmerPlaceholder();
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget();
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
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 200),
        imageBuilder: (context, imageProvider) => Container(
          decoration: BoxDecoration(
            image: DecorationImage(image: imageProvider, fit: widget.fit),
          ),
        ),
        placeholder: (context, url) {
          return _buildShimmerPlaceholder();
        },
        errorWidget: (context, url, error) {
          return _buildErrorWidget();
        },
      ),
    );
  }
}
