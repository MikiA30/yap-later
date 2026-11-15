# Commands and verification

## App commands

Project: `app/YapLater.xcodeproj` (hand-written, Xcode 26.6, folders synced from disk: new Swift files under `app/YapLater/` or `app/YapLaterTests/` are picked up automatically). Scheme `YapLater`. Bundle ID `com.mikiyas.yaplater`. Signing: automatic, with a free Personal Team. Deployment target iOS 26.0, iPhone only.

| Check | Actual command (from `app/`) | Result/evidence |
|---|---|---|
| Unit tests, simulator | `xcodebuild test -project YapLater.xcodeproj -scheme YapLater -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO` | 2026-11-15 03:21 EST: TEST SUCCEEDED, 5 tests (Swift Testing) |
| Launch, simulator | `xcrun simctl install <sim> <YapLater.app>` then `xcrun simctl launch <sim> com.mikiyas.yaplater` | 2026-11-15 03:22 EST: launched on iPhone 17 Pro simulator; screenshot showed the MOCK-labeled home screen. Tapping the button in the simulator was not exercised by hand; the flow is covered by unit tests |
| Build and install, real iPhone | `xcodebuild -project YapLater.xcodeproj -scheme YapLater -destination 'id=<xcode device id>' -allowProvisioningUpdates build`, then `xcrun devicectl device install app --device <id> <YapLater.app>` and `xcrun devicectl device process launch --device <id> com.mikiyas.yaplater` | 2026-11-15: builds, installs, launches on the iPhone 17 Pro (needs the phone unlocked and the developer profile trusted) |
| llama.cpp framework | `scripts/fetch_llama.sh` (b12405) | Installed in `app/Vendor/`; device builds link and embed it, simulator builds skip it |
| Copy models to the phone | `xcrun devicectl device copy to --device <id> --domain-type appDataContainer --domain-identifier com.mikiyas.yaplater --source <file or folder> --destination Documents/models/<file>` (GGUF) or `Documents/speech` (folder holding `openai_whisper-small` with its tokenizer files) | Done for Bonsai 2 2B, 4B, and Whisper small; they survive reinstalls |
| Build and run, Mac | `scripts/setup_mac.sh`, then `open build/mac/Build/Products/Debug/YapLater.app`; eval: `YAP_EVAL=1 build/mac/Build/Products/Debug/YapLater.app/Contents/MacOS/YapLater` | 2026-11-15 08:29 EST: BUILD SUCCEEDED; eval 23/23, median 558 ms |
| Demo week | `scripts/demo_week.sh mac\|iphone replace\|restore\|clear` | 2026-11-15 09:38 EST: loaded on the iPhone and the Mac; 15 demo entries, week total $270.28; the earlier ledgers are saved as `ledger-before-demo.json` on each device |
| On-device model eval | launch with `--environment-variables '{"YAP_EVAL":"1"}'` and `--console`; add `"YAP_BONSAI":"2B"` to pick the 2B | 4B: 20/20; 2B: 12/20 |
| Try sentences on the phone | `'{"YAP_TRY":"sentence one|sentence two"}'` | Used to debug the ask-back |
| Speech self-test | `'{"YAP_SPEECH_EVAL":"1"}'` (the phone synthesizes phrases and transcribes them) | Number-word prompt confirmed |
| Action Button | Settings → Action Button → Shortcut → Yap Later → Start a Yap | Not yet tried by the user |

The simulator does not validate Metal inference, the microphone path, or notifications on a locked phone.
