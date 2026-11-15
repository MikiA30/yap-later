#!/bin/sh
# Turns the Argmax voice on or off.  usage: scripts/voice.sh mac|iphone on|off [device-id]
# Without a setting, the Mac uses the Argmax voice and the iPhone uses the system voice.
set -eu
WHERE="${1:-}"; CHOICE="${2:-}"
case "$CHOICE" in on|off) ;; *) echo "usage: $0 mac|iphone on|off [device-id]"; exit 1 ;; esac
TMP="$(mktemp -d)"; printf '%s\n' "$CHOICE" > "$TMP/voice.txt"
case "$WHERE" in
  mac)
    mkdir -p "$HOME/Library/Application Support/YapLater/tts"
    cp "$TMP/voice.txt" "$HOME/Library/Application Support/YapLater/tts/voice.txt" ;;
  iphone)
    DEVICE="${3:-$(xcrun devicectl list devices 2>/dev/null | awk '/iPhone/ && /connected|available/ {for (i=1;i<=NF;i++) if ($i ~ /^[0-9A-F-]{36}$/) {print $i; exit}}')}"
    [ -n "$DEVICE" ] || { echo "No iPhone found; pass its device id as the third argument."; exit 1; }
    xcrun devicectl device copy to --device "$DEVICE" --domain-type appDataContainer \
      --domain-identifier com.mikiyas.yaplater --source "$TMP/voice.txt" --destination Documents/tts/voice.txt >/dev/null ;;
  *) echo "usage: $0 mac|iphone on|off [device-id]"; exit 1 ;;
esac
rm -rf "$TMP"
echo "Argmax voice $CHOICE on the $WHERE. Quit and reopen Yap Later."
