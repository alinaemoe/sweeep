// Pigeon contract between Flutter and the Kotlin / Swift platform layer.
// Generate with:
//   dart run pigeon --input pigeon/media_api.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/platform/messages.g.dart',
  kotlinOut: 'android/app/src/main/kotlin/app/sweeep/sweeep/Messages.g.kt',
  kotlinOptions: KotlinOptions(package: 'app.sweeep.sweeep'),
  swiftOut: 'ios/Runner/Messages.g.swift',
))
enum PermissionState { granted, limited, denied }

enum MediaType { photo, video }

class AssetInfo {
  AssetInfo({
    required this.id,
    required this.mediaType,
    required this.width,
    required this.height,
    required this.sizeBytes,
    required this.createdAtMs,
    required this.modifiedAtMs,
    this.durationMs,
    this.bucket,
    this.isScreenshot = false,
    this.isScreenRecording = false,
    this.chatSource,
  });

  String id;
  MediaType mediaType;
  int width;
  int height;
  int sizeBytes;
  int createdAtMs;
  int modifiedAtMs;
  int? durationMs;
  String? bucket;
  bool isScreenshot;
  bool isScreenRecording;

  /// telegram, whatsapp, viber, messenger, signal (Android folder heuristic).
  String? chatSource;
}

class AssetPage {
  AssetPage({required this.assets, this.nextCursor});
  List<AssetInfo> assets;

  /// Null when the library has been fully enumerated.
  String? nextCursor;
}

/// 8-bit grayscale thumbnail, row-major, width * height bytes.
class GrayThumb {
  GrayThumb({required this.width, required this.height, required this.bytes});
  int width;
  int height;
  Uint8List bytes;
}

class DeleteResult {
  DeleteResult({required this.deletedIds, required this.cancelled});
  List<String> deletedIds;

  /// True when the user dismissed the system confirmation dialog.
  bool cancelled;
}

@HostApi()
abstract class MediaHostApi {
  @async
  PermissionState requestPermission();

  PermissionState permissionState();

  /// Enumerate assets modified since [sinceMs] (null = everything),
  /// newest first, [limit] per page.
  @async
  AssetPage listAssets(int? sinceMs, String? cursor, int limit);

  /// Every asset id currently in the library (cheap), used to detect deletions.
  @async
  List<String> allAssetIds();

  /// Decoded, downscaled grayscale thumbnail (max side = [maxSide]).
  @async
  GrayThumb? grayThumbnail(String assetId, int maxSide);

  /// JPEG-encoded color thumbnail (max side = [maxSide]) for display.
  @async
  Uint8List? thumbnail(String assetId, int maxSide);

  /// SHA-256 digest (32 bytes) of the file contents, streamed natively so
  /// large videos never cross the platform channel. Null if unreadable.
  @async
  Uint8List? sha256(String assetId);

  /// Single batched system delete (one OS confirmation dialog).
  @async
  DeleteResult deleteAssets(List<String> assetIds);
}

@HostApi()
abstract class ScanHostApi {
  /// Start / resume the scan service (foreground service / BGProcessingTask).
  void startService();
  void pauseService();
  void stopService();
}

@FlutterApi()
abstract class ScanFlutterApi {
  /// Pushed by the platform layer so UI can show live progress.
  void onProgress(int processed, int total, String stage);
}
