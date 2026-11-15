#!/bin/sh
# Shows or removes the demo week (five earlier days of made-up, ordinary spending) in a debug build.
#   scripts/demo_week.sh mac|iphone replace   save the current ledger to a file, then show only the demo week
#   scripts/demo_week.sh mac|iphone restore   take the demo week out and put the saved ledger back
#   scripts/demo_week.sh mac|iphone clear     remove just the demo entries
# The demo week is demo data. Do not describe it as anyone's real spending.
set -eu
WHERE="${1:-}"; WHAT="${2:-}"
case "$WHAT" in replace|restore|clear|load|show) ;; *) echo "usage: $0 mac|iphone replace|restore|clear"; exit 1 ;; esac
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
case "$WHERE" in
  mac)
    APP="$ROOT/build/mac/Build/Products/Debug/YapLater.app/Contents/MacOS/YapLater"
    [ -x "$APP" ] || { echo "Build the Mac app first: scripts/setup_mac.sh"; exit 1; }
    pkill -f "YapLater.app/Contents/MacOS/YapLater" 2>/dev/null || true
    LOG="$(mktemp)"
    (YAP_DEMO_WEEK="$WHAT" "$APP" > "$LOG" 2>&1 &)
    for _ in $(seq 1 30); do sleep 1; grep -q YAPDUMP-END "$LOG" && break; done
    sed -n '/YAPDUMP-BEGIN/,/YAPDUMP-END/p' "$LOG" | tail -4
    echo "Done. The app is open; quit and reopen it normally when you like." ;;
  iphone)
    DEVICE="${3:-$(xcrun devicectl list devices 2>/dev/null | awk '/iPhone/ && /connected|available/ {for (i=1;i<=NF;i++) if ($i ~ /^[0-9A-F-]{36}$/) {print $i; exit}}')}"
    [ -n "$DEVICE" ] || { echo "No iPhone found; pass its device id as the third argument."; exit 1; }
    xcrun devicectl device process launch --terminate-existing \
      --environment-variables "{\"YAP_DEMO_WEEK\":\"$WHAT\"}" --device "$DEVICE" com.mikiyas.yaplater | tail -1 ;;
  *) echo "usage: $0 mac|iphone replace|restore|clear"; exit 1 ;;
esac
