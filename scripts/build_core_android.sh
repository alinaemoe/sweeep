#!/usr/bin/env bash
# Builds the Rust core for Android and copies the .so into the Flutter app's jniLibs.
# Builds arm64-v8a, armeabi-v7a, x86_64 and x86 (emulators / old phones).
# Requires: rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android, ANDROID_HOME with an NDK.
# Usage: scripts/build_core_android.sh [ndk-version]   (default 27.1.12297006)
set -euo pipefail

NDK_VERSION="${1:-27.1.12297006}"
API=26
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NDK="$ANDROID_HOME/ndk/$NDK_VERSION"
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) HOST=windows-x86_64; EXT=.cmd ;;
  Darwin) HOST=darwin-x86_64; EXT= ;;
  *) HOST=linux-x86_64; EXT= ;;
esac
BIN="$NDK/toolchains/llvm/prebuilt/$HOST/bin"

build() { # rust-triple android-abi clang-triple
  local triple=$1 abi=$2 clang=$3
  local linker="$BIN/${clang}${API}-clang${EXT}"
  local envname="CARGO_TARGET_$(echo "$triple" | tr 'a-z-' 'A-Z_')_LINKER"
  env "$envname=$linker" cargo build --release --manifest-path "$ROOT/core/Cargo.toml" --target "$triple"
  mkdir -p "$ROOT/app/android/app/src/main/jniLibs/$abi"
  cp "$ROOT/core/target/$triple/release/libsweeep_core.so" "$ROOT/app/android/app/src/main/jniLibs/$abi/"
  echo "copied $abi"
}

build aarch64-linux-android arm64-v8a aarch64-linux-android
build armv7-linux-androideabi armeabi-v7a armv7a-linux-androideabi
build x86_64-linux-android x86_64 x86_64-linux-android
build i686-linux-android x86 i686-linux-android
