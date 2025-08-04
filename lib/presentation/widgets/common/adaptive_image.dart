import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A widget that can display both network images and local file images
class AdaptiveImage extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const AdaptiveImage({
    Key? key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultErrorWidget = errorWidget ?? Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Icon(
        Icons.image_not_supported,
        color: Colors.grey,
      ),
    );

    final defaultPlaceholder = placeholder ?? Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );

    Widget imageWidget;

    if (_isNetworkUrl(imagePath)) {
      // Network image
      imageWidget = CachedNetworkImage(
        imageUrl: imagePath,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => defaultPlaceholder,
        errorWidget: (context, url, error) => defaultErrorWidget,
      );
    } else {
      // Local file image
      imageWidget = Image.file(
        File(imagePath),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => defaultErrorWidget,
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  /// Check if a path is a network URL or local file path
  bool _isNetworkUrl(String path) {
    return path.startsWith('http://') || 
           path.startsWith('https://') || 
           path.startsWith('gs://') ||
           path.startsWith('ftp://');
  }
}

/// Extension to provide easy access to adaptive image display
extension AdaptiveImageExtension on String {
  Widget toAdaptiveImage({
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    BorderRadius? borderRadius,
  }) {
    return AdaptiveImage(
      imagePath: this,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
      borderRadius: borderRadius,
    );
  }
}
