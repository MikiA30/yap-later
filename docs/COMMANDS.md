# Commands and verification

## Starter

```sh
cd '/Users/mikiyasasmamaw/Documents/ChatGPT/VocaLedger'
python3 scripts/check_setup.py
claude
```

Tracker: `gh issue list -R MikiA30/yap-later --milestone "Hackathon submission"`. Publish new tickets: `python3 scripts/create_issues.py`.

Inside Claude: `/interview`, `/kickoff`, `/tickets`, `/skeleton`, `/task T002`, `/task T003`, `/team-status` as appropriate to the current stage.

`claude plugin validate --strict .claude/skills` and `claude plugin validate --strict .claude/commands` check Claude configuration when that CLI is installed.

## App commands

Project: `app/YapLater.xcodeproj` (hand-written, Xcode 26.6, folders synced from disk: new Swift files under `app/YapLater/` or `app/YapLaterTests/` are picked up automatically). Scheme `YapLater`. Bundle ID `com.mikiyas.yaplater`. Signing: automatic, Personal Team `MWY85H9F24`. Deployment target iOS 26.0, iPhone only.

| Check | Actual command (from `app/`) | Result/evidence |
|---|---|---|
| Unit tests, simulator | `xcodebuild test -project YapLater.xcodeproj -scheme YapLater -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO` | 2026-11-15 03:21 EST: TEST SUCCEEDED, 5 tests (Swift Testing) |
| Launch, simulator | `xcrun simctl install <sim> <YapLater.app>` then `xcrun simctl launch <sim> com.mikiyas.yaplater` | 2026-11-15 03:22 EST: launched on iPhone 17 Pro simulator; screenshot showed the MOCK-labeled home screen. Tapping the button in the simulator was not exercised by hand; the flow is covered by unit tests |
| Build and install, real iPhone | `xcodebuild -project YapLater.xcodeproj -scheme YapLater -destination 'platform=iOS,name=Miki’s iPhone' -allowProvisioningUpdates build`, then `xcrun devicectl device install app --device <id> <YapLater.app>` and `xcrun devicectl device process launch --device <id> com.mikiyas.yaplater` | NOT RUN: the iPhone was listed as unavailable (not connected) |

The simulator does not validate Metal inference, the microphone path, or notifications on a locked phone.
