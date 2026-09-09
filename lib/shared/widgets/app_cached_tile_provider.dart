import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// High-performance [TileProvider] that leverages [CachedNetworkImageProvider]
/// to store raster map tiles on disk and in memory (bounded LRU).
///
/// Drastically cuts mobile data usage for drivers on shift and ensures 60fps
/// smooth panning on previously rendered map coordinates.
class AppCachedTileProvider extends TileProvider {
  AppCachedTileProvider({super.headers});

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return CachedNetworkImageProvider(
      getTileUrl(coordinates, options),
      headers: headers,
    );
  }
}
