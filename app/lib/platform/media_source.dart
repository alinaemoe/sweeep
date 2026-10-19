import 'dart:typed_data';

import 'messages.g.dart';

/// What the app needs from the device's media library. The Android
/// implementation is [PlatformMediaSource] (MediaStore via Pigeon); tests
/// substitute a fake.
abstract class MediaSource {
  Future<PermissionState> permissionState();
  Future<PermissionState> requestPermission();
  Future<AssetPage> listAssets({int? sinceMs, String? cursor, int limit = 500});
  Future<List<String>> allAssetIds();
  Future<GrayThumb?> grayThumbnail(String assetId, {int maxSide = 128});

  /// JPEG color thumbnail for display.
  Future<Uint8List?> thumbnail(String assetId, {int maxSide = 256});

  /// SHA-256 digest of the file contents (32 bytes), computed natively.
  Future<Uint8List?> sha256(String assetId);
}

class PlatformMediaSource implements MediaSource {
  PlatformMediaSource([MediaHostApi? api]) : _api = api ?? MediaHostApi();
  final MediaHostApi _api;

  @override
  Future<PermissionState> permissionState() async => _api.permissionState();

  @override
  Future<PermissionState> requestPermission() => _api.requestPermission();

  @override
  Future<AssetPage> listAssets({int? sinceMs, String? cursor, int limit = 500}) =>
      _api.listAssets(sinceMs, cursor, limit);

  @override
  Future<List<String>> allAssetIds() => _api.allAssetIds();

  @override
  Future<GrayThumb?> grayThumbnail(String assetId, {int maxSide = 128}) =>
      _api.grayThumbnail(assetId, maxSide);

  @override
  Future<Uint8List?> thumbnail(String assetId, {int maxSide = 256}) => _api.thumbnail(assetId, maxSide);

  @override
  Future<Uint8List?> sha256(String assetId) => _api.sha256(assetId);
}
