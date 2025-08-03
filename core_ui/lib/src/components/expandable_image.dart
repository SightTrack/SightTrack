import 'dart:io';
import 'package:flutter/material.dart';

class ExpandableImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const ExpandableImage({
    super.key,
    required this.imageUrl,
    this.width = double.infinity,
    this.height = 250,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showExpandedImage(context),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(12.0),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: fit,
          ),
        ),
      ),
    );
  }

  void _showExpandedImage(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Tooltip(
                    message: 'Close',
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black54,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ExpandableLocalImage extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;

  const ExpandableLocalImage({
    super.key,
    required this.imagePath,
    this.width = double.infinity,
    this.height = 250,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _showExpandedImage(context),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Image.file(
          File(imagePath),
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ??
                Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
          },
        ),
      ),
    );
  }

  void _showExpandedImage(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Image not available',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.7),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ExpandableNetworkImage extends StatelessWidget {
  final Future<String> imageUrlFuture;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const ExpandableNetworkImage({
    super.key,
    required this.imageUrlFuture,
    this.width = double.infinity,
    this.height = 250,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: imageUrlFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ??
              Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: borderRadius ?? BorderRadius.circular(12.0),
                ),
                child: const Center(
                  child: Icon(Icons.image, size: 80, color: Colors.grey),
                ),
              );
        } else if (snapshot.hasError || snapshot.data == null) {
          return errorWidget ??
              Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: borderRadius ?? BorderRadius.circular(12.0),
                ),
                child: const Center(
                  child: Icon(Icons.image, size: 80, color: Colors.grey),
                ),
              );
        } else {
          return ExpandableImage(
            imageUrl: snapshot.data!,
            width: width,
            height: height,
            fit: fit,
            borderRadius: borderRadius,
          );
        }
      },
    );
  }
}
