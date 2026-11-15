#!/bin/sh
# Builds Yap Later for an Apple Silicon Mac and downloads the two models it needs.
# Needs a network connection once; after that the app runs with Wi-Fi off.
# No Apple developer account is needed: the Mac build is signed to run locally.
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS="$HOME/Library/Application Support/YapLater"
GGUF="Ternary-Bonsai-2-4B-Q2_0.gguf"
WHISPER="openai_whisper-small"

[ -d "$ROOT/app/Vendor/llama.xcframework" ] || "$ROOT/scripts/fetch_llama.sh"

mkdir -p "$ASSETS/models" "$ASSETS/speech/$WHISPER"
if [ ! -f "$ASSETS/models/$GGUF" ]; then
  echo "Downloading Bonsai 2 4B (about 1.2 GB)..."
  curl -fL --progress-bar -o "$ASSETS/models/$GGUF.part" \
    "https://huggingface.co/prism-ml/Ternary-Bonsai-2-4B-gguf/resolve/main/$GGUF"
  mv "$ASSETS/models/$GGUF.part" "$ASSETS/models/$GGUF"
fi
if [ ! -f "$ASSETS/speech/$WHISPER/tokenizer.json" ]; then
  echo "Downloading Whisper small for WhisperKit (about 490 MB)..."
  python3 - "$ASSETS/speech" "$WHISPER" <<'PY'
import json, os, sys, urllib.request
dest, name = sys.argv[1], sys.argv[2]
repo = "https://huggingface.co/argmaxinc/whisperkit-coreml"
listing = json.load(urllib.request.urlopen(
    f"https://huggingface.co/api/models/argmaxinc/whisperkit-coreml/tree/main/{name}?recursive=1"))
for item in listing:
    if item["type"] != "file":
        continue
    target = os.path.join(dest, item["path"])
    os.makedirs(os.path.dirname(target), exist_ok=True)
    if not os.path.exists(target) or os.path.getsize(target) != item["size"]:
        urllib.request.urlretrieve(f"{repo}/resolve/main/{item['path']}", target)
# The tokenizer goes last, so a finished folder is recognizable by it.
for file in ("tokenizer_config.json", "tokenizer.json"):
    urllib.request.urlretrieve(f"https://huggingface.co/openai/whisper-small/resolve/main/{file}",
                               os.path.join(dest, name, file))
PY
fi

echo "Building..."
xcodebuild -project "$ROOT/app/YapLater.xcodeproj" -scheme YapLater -configuration Debug \
  -destination 'platform=macOS,arch=arm64' -derivedDataPath "$ROOT/build/mac" build \
  | grep -E "error:|BUILD (SUCCEEDED|FAILED)" || true
APP="$ROOT/build/mac/Build/Products/Debug/YapLater.app"
[ -d "$APP" ] || { echo "The build did not produce $APP"; exit 1; }
echo "Built $APP"
echo "Run it with:  open \"$APP\"   (then turn Wi-Fi off and hold the orange button to talk)"
