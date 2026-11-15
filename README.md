# Yap Later

**Talk to your money, privately.** Yap Later is a voice-first expense tracker that runs entirely on your iPhone or your Mac, with Wi-Fi off. Hold a button and say "just spent fifty bucks on groceries at Walmart": it logs the expense, picks the category, counts it against your weekly budget, and warns you out loud when a budget is running low. No bank login, no account, no cloud.

Built for Cornell's local AI hackathon, November 2026.

## Why

Budgeting apps want your bank credentials, and a lot of people won't hand those over. The alternative has been typing every purchase into a form, which nobody keeps up. Yap Later makes logging as easy as saying it, and keeps every word and every number on the phone.

## What it does

- **Yap an expense.** "Grabbed lunch at Chipotle, thirteen forty five" becomes $13.45 · Dining · Chipotle.
- **It asks when it isn't sure.** Say "grabbed a coffee" and it asks, out loud, "How much was it?" Answer by voice and the entry is completed. It never invents an amount.
- **Weekly budgets by voice.** "Set my coffee budget to twenty five a week."
- **Ramble.** "Fifty on groceries, twelve on lunch and six fifty on coffee" logs three expenses; one Undo removes all three.
- **Reminders by voice.** "Remind me to call mom tomorrow at six pm" shows a card; tapping Save creates an Apple Reminder with an alert.
- **Nudges.** When an expense pushes a budget low, you see and hear it: "Only $50 left for Groceries this week."
- **Undo and edit.** Entries save immediately with an Undo, and any entry can be corrected by tapping it.
- **Action Button.** "Start a Yap" opens the app already listening.

## How it works

```
 hold to talk ──▶ Argmax WhisperKit ──▶ Ternary Bonsai 2 (4B) ──▶ app-code checks ──▶ SwiftData ──▶ budgets ──▶ nudge
   microphone      speech to text        sentence to JSON          amount, category,     on-device      weekly      banner, voice,
                   (on device)           via llama.cpp + Metal     date; ask if unsure   storage        totals      notification
                                         (on device)
```

- **Speech:** [Argmax WhisperKit](https://github.com/argmaxinc/argmax-oss-swift) 1.1.1 with the Whisper small Core ML model, loaded from the phone's storage. A vocabulary prompt makes it write amounts as words ("six fifty"), because the digits "650" lose the difference between $6.50 and $650.
- **Understanding:** [Ternary Bonsai 2 4B](https://huggingface.co/prism-ml/Ternary-Bonsai-2-4B-gguf) (PrismML, Q2_0 GGUF, 1.2 GB) run in-process by [llama.cpp](https://github.com/ggml-org/llama.cpp) b12405 on the iPhone GPU. The model's output is constrained by a grammar to one JSON object, so it cannot ramble or "think" out loud.
- **The model proposes; app code decides.** Swift code checks the amount, maps the category to a fixed set, resolves dates like "yesterday", and asks back when something is missing. The model never touches storage.
- **Storage:** SwiftData on the device. No iCloud container, no network calls in the app.
- **Interface:** SwiftUI, iOS 26.

## Measured on an iPhone 17 Pro (iOS 26.6.2)

| What | Result |
|---|---|
| Bonsai 2 4B on a 23-sentence eval (expenses, number words, missing amounts, budgets, reminders, off-topic) | 23/23 correct, median 1.3 s per request (reminders 3.6 to 6 s) |
| Bonsai 2 2B on the same eval | 12/20 correct, about 0.7 s per request; we ship the 4B |
| Model load (4B) | about 0.3 s warm, 1.2 to 1.6 s cold |
| WhisperKit transcription of a 2 to 6 s yap | 0.25 to 0.85 s |
| Live voice test (expense, ask-back answered by voice, budget set by voice, budget reduced by a second expense) | worked |

The eval report is in [`eval/results/`](eval/results/). The eval sentences are synthetic; a few of the twenty-three overlap with example wording, so treat the score as a sanity check, not a benchmark. See [`docs/FEASIBILITY.md`](docs/FEASIBILITY.md) for what has and has not been verified, including the airplane-mode run.

## Honest limitations

- English and US dollars only.
- A yap with several expenses is split in app code at commas and joining words, one amount per part; if any part is not a clear expense, the whole yap is treated as one request.
- The app checks that the proposed amount matches a number you said; unusual phrasings of amounts may make it ask again.
- If no Bonsai file is on the phone, the app falls back to Apple's on-device model, and to a labeled MOCK if neither is available. The header shows which.
- The spoken voice is iOS's built-in synthesizer.
- Reminders are saved to Apple Reminders only after you tap Save. Location nudges are designed but not built.

## Build and run

### On a Mac (Apple Silicon, macOS 26, Xcode 26.6)

```sh
scripts/setup_mac.sh        # fetches llama.cpp, downloads Bonsai 2 4B and Whisper small once, builds the app
open build/mac/Build/Products/Debug/YapLater.app
```

Then turn Wi-Fi off and hold the orange button to talk (or use the keyboard button to type). The Mac build is the same app and code as the iPhone build, signed to run locally, so no Apple developer account is needed. Models are stored in `~/Library/Application Support/YapLater`. On this project's Mac (M-series, 24 GB) Bonsai 2 4B scored 23/23 on the built-in eval at a median 0.56 s per request, and WhisperKit transcribed the synthetic speech test correctly. The script's download step was verified only by checking that the URLs respond; the models on that Mac were copied from a local download.

### On an iPhone

Requirements: Xcode 26.6, an iPhone on iOS 26, about 2 GB free on the phone.

```sh
scripts/fetch_llama.sh                      # llama.cpp iOS framework into app/Vendor (not in Git)
open app/YapLater.xcodeproj                 # set your signing team, build to your iPhone
```

Then copy the models into the app's Documents folder (they are not in Git):

```sh
# Bonsai 2 4B, Q2_0: https://huggingface.co/prism-ml/Ternary-Bonsai-2-4B-gguf
xcrun devicectl device copy to --device <id> --domain-type appDataContainer \
  --domain-identifier com.mikiyas.yaplater --source Ternary-Bonsai-2-4B-Q2_0.gguf \
  --destination Documents/models/Ternary-Bonsai-2-4B-Q2_0.gguf
# Whisper small for WhisperKit (argmaxinc/whisperkit-coreml: openai_whisper-small, plus tokenizer.json
# and tokenizer_config.json from openai/whisper-small in the same folder)
xcrun devicectl device copy to --device <id> --domain-type appDataContainer \
  --domain-identifier com.mikiyas.yaplater --source speech --destination Documents/speech
```

Exact commands and results are in [`docs/COMMANDS.md`](docs/COMMANDS.md). Unit tests: `xcodebuild test -project app/YapLater.xcodeproj -scheme YapLater -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO` (the simulator uses mock speech and has no llama framework).

## Credits

Ternary Bonsai 2 by PrismML. WhisperKit by Argmax. llama.cpp by ggml-org and contributors. Whisper by OpenAI. Project planning docs: [`START_HERE.md`](START_HERE.md), [`.plans/yap-later-spec.md`](.plans/yap-later-spec.md), [`docs/TICKETS.md`](docs/TICKETS.md).
