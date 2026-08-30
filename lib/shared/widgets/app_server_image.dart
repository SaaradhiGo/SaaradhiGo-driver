import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Displays an image URL returned by the API (avatar, rc_doc, license_doc).
///
/// IMPORTANT: private documents come back as S3 presigned URLs and public
/// assets as plain URLs — both expire after ~15 minutes
/// (AWS_QUERYSTRING_EXPIRE=900). Never persist or cache these URLs long-term:
/// always re-fetch the owning entity to get fresh URLs instead of reusing old
/// ones. This widget only caches the decoded bytes for the session via
/// [CachedNetworkImage]; it does not extend URL validity.
class AppServerImage extends StatelessWidget {
  const AppServerImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  final String url;
  final BoxFit fit;
  final PlaceholderWidgetBuilder? placeholder;
  final LoadingErrorWidgetBuilder? errorWidget;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder:
          placeholder ??
          (context, url) => const ColoredBox(
            color: AppColors.surfaceContainerHigh,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
      errorWidget:
          errorWidget ??
          (context, url, error) => const ColoredBox(
            color: AppColors.surfaceContainerHigh,
            child: Icon(
              Icons.broken_image_outlined,
              color: AppColors.onSurfaceVariant,
            ),
          ),
    );
  }
}
