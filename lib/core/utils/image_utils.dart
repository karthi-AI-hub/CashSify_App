import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ImageUtils {
  static final customCacheManager = CacheManager(
    Config(
      'customCacheKey',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
      repo: JsonCacheInfoRepository(databaseName: 'imageCache'),
      fileService: HttpFileService(),
    ),
  );

  static Widget cachedNetworkImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheManager: customCacheManager,
      placeholder: (context, url) => placeholder ?? const Center(child: CircularProgressIndicator()),
      errorWidget: (context, url, error) => errorWidget ?? const Icon(Icons.error),
    );
  }

  static Future<void> preloadImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      await customCacheManager.getSingleFile(url);
    }
  }

  static Future<void> clearImageCache() async {
    await customCacheManager.emptyCache();
  }

  static Widget assetImage({
    required String assetPath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => 
        errorWidget ?? const Icon(Icons.error),
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return placeholder ?? const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  static Widget animationAsset({
    required String assetPath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? errorWidget,
  }) {
    return Image.asset(
      'assets/animations/$assetPath',
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => 
        errorWidget ?? const Icon(Icons.error),
    );
  }
} 