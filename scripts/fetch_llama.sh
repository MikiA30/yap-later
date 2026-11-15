#!/bin/sh
# Downloads the llama.cpp iOS framework that runs the Bonsai 2 Q2_0 model inside the app.
# Bonsai 2 Q2_0 needs llama.cpp b11556 or newer (see PrismML's BACKEND-SUPPORT.md).
set -eu
TAG="${1:-b12405}"
DEST="$(cd "$(dirname "$0")/.." && pwd)/app/Vendor"
TMP="$(mktemp -d)"
mkdir -p "$DEST"
curl -fL -o "$TMP/xcf.zip" "https://github.com/ggml-org/llama.cpp/releases/download/$TAG/llama-$TAG-xcframework.zip"
unzip -q -o "$TMP/xcf.zip" -d "$TMP"
rm -rf "$DEST/llama.xcframework"
cp -R "$TMP/build-apple/llama.xcframework" "$DEST/"
rm -rf "$TMP"
echo "Installed llama.cpp $TAG at $DEST/llama.xcframework"
