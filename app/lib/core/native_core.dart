import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

/// Result of analysing one grayscale thumbnail. Hashes are the raw 64-bit
/// patterns reinterpreted as signed ints (what the database stores).
class Analysis {
  const Analysis({
    required this.phash,
    required this.dhash,
    required this.ahash,
    required this.laplacianVar,
    required this.medianBrightness,
  });
  final int phash;
  final int dhash;
  final int ahash;
  final double laplacianVar;
  final int medianBrightness;
}

class GroupLabels {
  const GroupLabels(this.count, this.labels);

  /// Number of groups found.
  final int count;

  /// Per input item: group number, or -1 if it belongs to no group.
  final Int32List labels;
}

/// The analysis operations the app needs; implemented by [NativeCore]
/// (Rust via FFI) and faked in tests.
abstract class AnalysisCore {
  Analysis? analyze(Uint8List gray, int width, int height);

  /// [hashes] and [timestampsMs] must be the same length. A negative
  /// [windowMs] disables the time window.
  GroupLabels groupSimilar(List<int> hashes, List<int> timestampsMs, {int maxHamming = 6, int windowMs = 5000});
}

final class _SweeepAnalysis extends Struct {
  @Uint64()
  external int phash;
  @Uint64()
  external int dhash;
  @Uint64()
  external int ahash;
  @Double()
  external double laplacianVar;
  @Uint32()
  external int medianBrightness;
}

typedef _AnalyzeC = Int32 Function(Pointer<Uint8>, Uint32, Uint32, Pointer<_SweeepAnalysis>);
typedef _AnalyzeDart = int Function(Pointer<Uint8>, int, int, Pointer<_SweeepAnalysis>);
typedef _GroupC = Int32 Function(Pointer<Uint64>, Pointer<Int64>, IntPtr, Uint32, Int64, Pointer<Int32>);
typedef _GroupDart = int Function(Pointer<Uint64>, Pointer<Int64>, int, int, int, Pointer<Int32>);

/// Rust core (`libsweeep_core.so`) bound through dart:ffi.
class NativeCore implements AnalysisCore {
  NativeCore._(DynamicLibrary lib)
      : _analyze = lib.lookupFunction<_AnalyzeC, _AnalyzeDart>('sweeep_analyze'),
        _group = lib.lookupFunction<_GroupC, _GroupDart>('sweeep_group_labels');

  factory NativeCore.load() {
    final lib = Platform.isAndroid ? DynamicLibrary.open('libsweeep_core.so') : DynamicLibrary.process();
    return NativeCore._(lib);
  }

  final _AnalyzeDart _analyze;
  final _GroupDart _group;

  Pointer<Uint8> _buf = nullptr;
  int _bufLen = 0;
  final Pointer<_SweeepAnalysis> _out = calloc<_SweeepAnalysis>();

  @override
  Analysis? analyze(Uint8List gray, int width, int height) {
    final n = width * height;
    if (n <= 0 || gray.length < n) return null;
    if (_bufLen < n) {
      if (_buf != nullptr) calloc.free(_buf);
      _buf = calloc<Uint8>(n);
      _bufLen = n;
    }
    _buf.asTypedList(n).setAll(0, gray.length == n ? gray : gray.sublist(0, n));
    if (_analyze(_buf, width, height, _out) != 0) return null;
    final o = _out.ref;
    return Analysis(
      phash: o.phash,
      dhash: o.dhash,
      ahash: o.ahash,
      laplacianVar: o.laplacianVar,
      medianBrightness: o.medianBrightness,
    );
  }

  @override
  GroupLabels groupSimilar(List<int> hashes, List<int> timestampsMs, {int maxHamming = 6, int windowMs = 5000}) {
    final n = hashes.length;
    if (n == 0 || timestampsMs.length != n) return GroupLabels(0, Int32List(0));
    final h = calloc<Uint64>(n);
    final t = calloc<Int64>(n);
    final l = calloc<Int32>(n);
    try {
      h.asTypedList(n).setAll(0, hashes);
      t.asTypedList(n).setAll(0, timestampsMs);
      final groups = _group(h, t, n, maxHamming, windowMs, l);
      if (groups < 0) return GroupLabels(0, Int32List(n)..fillRange(0, n, -1));
      return GroupLabels(groups, Int32List.fromList(l.asTypedList(n)));
    } finally {
      calloc.free(h);
      calloc.free(t);
      calloc.free(l);
    }
  }
}
