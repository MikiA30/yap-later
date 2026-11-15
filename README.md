# Yap Later

**Talk to your money, privately.** Yap Later is a voice-first expense tracker that runs entirely on your iPhone or your Mac, with Wi-Fi off. Hold a button and say "just spent fifty bucks on groceries at Walmart": it logs the expense, picks the category, counts it against your weekly budget, and warns you out loud when a budget is running low. No bank login, no account, no cloud.

Built for Cornell's Local AI Hackathon, November 2026. The theme was **Recreate**: take an existing AI app and remake it fully on-device. Yap Later recreates the AI budgeting assistant (the kind that asks for your bank login and thinks in the cloud) with speech recognition, the language model, and your data all on the device. It is for exactly the moments you have no signal or no wish to share: in a store basement, on a plane, abroad without data, or any time you would rather not hand a company your bank credentials.

## Why

Budgeting apps want your bank credentials, and a lot of people won't hand those over. The alternative has been typing every purchase into a form, which nobody keeps up. Yap Later makes logging as easy as saying it, and keeps every word and every number on the device.

## What it does

- **Yap an expense.** "Grabbed lunch at Chipotle, thirteen forty five" becomes $13.45 · Dining · Chipotle.
- **It asks when it isn't sure.** Say "grabbed a coffee" and it asks, out loud, "How much was it?" Answer by voice and the entry is completed. It never invents an amount.
- **Weekly budgets by voice.** "Set my coffee budget to twenty five a week."
- **Ramble.** "Fifty on groceries, twelve on lunch and six fifty on coffee" logs three expenses; one Undo removes all three.
- **Reminders by voice.** "Remind me to call mom tomorrow at six pm" shows a card; tapping Save creates an Apple Reminder with an alert.
- **Nudges.** When an expense pushes a budget low, you see and hear it: "Only $50 left for Groceries this week."
- **Your week in charts.** The chart button opens a page with spending by day, a category ring you can tilt, and a short list of what deserves attention (budgets over or nearly used, the biggest expense, a simple pace projection). Every number comes from stored entries; no model writes them.
- **Undo and edit.** Entries save immediately with an Undo, and any entry can be corrected by tapping it.
- **Mac and iPhone, same app.** A Sync button is meant to copy the ledger between the two over Bluetooth with no internet. Its merge logic is tested, but the Bluetooth link has not yet been run between the two devices, so treat it as experimental.
- **Action Button.** "Start a Yap" opens the app already listening.

## How it works

```
 hold to talk ──▶ Argmax WhisperKit ──▶ Ternary Bonsai 2 (4B) ──▶ app-code checks ──▶ SwiftData ──▶ budgets ──▶ nudge
   microphone      speech to text        sentence to JSON          amount, category,     on-device      weekly      banner, voice,
                   (on device)           via llama.cpp + Metal     date; ask if unsure   storage        totals      notification
                                         (on device)
```

- **Speech:** [Argmax WhisperKit](https://github.com/argmaxinc/argmax-oss-swift) 1.1.1 with the Whisper small Core ML model, loaded from the phone's storage. A vocabulary prompt makes it write amounts as words ("six fifty"), because the digits "650" lose the difference between $6.50 and $650.
- **Voice:** on the Mac, questions and nudges are spoken by [Argmax TTSKit](https://github.com/argmaxinc/argmax-oss-swift) (Qwen3-TTS 0.6B as Core ML, about 1.1 GB) when its model is present; first audio arrived in 0.2 to 0.5 s there. On the iPhone 17 Pro it also works (first audio 0.3 to 0.6 s, stops cleanly when you start talking), but it takes about 20 s to load after launch and speaks a short line slower than real time, so the phone keeps the instant system voice unless you run `scripts/voice.sh iphone on`.
- **Understanding:** [Ternary Bonsai 2 4B](https://huggingface.co/prism-ml/Ternary-Bonsai-2-4B-gguf) (PrismML, Q2_0 GGUF, 1.2 GB) run in-process by [llama.cpp](https://github.com/ggml-org/llama.cpp) b12405 on the iPhone GPU. The model's output is constrained by a grammar to one JSON object, so it cannot ramble or "think" out loud.
- **The model proposes; app code decides.** Swift code checks the amount, maps the category to a fixed set, resolves dates like "yesterday", and asks back when something is missing. The model never touches storage.
- **Storage:** SwiftData on the device. No iCloud container, no network calls in the app.
- **Interface:** SwiftUI; one codebase for iPhone (iOS 26) and Mac (macOS 26).

## Measured on an iPhone 17 Pro (iOS 26.6.2)

| What | Result |
|---|---|
| Bonsai 2 4B on a 23-sentence eval (expenses, number words, missing amounts, budgets, reminders, off-topic) | 23/23 correct, median 1.3 s per request (reminders 3.6 to 6 s) |
| Bonsai 2 2B on the same eval | 12/20 correct, about 0.7 s per request; we ship the 4B |
| Model load (4B) | about 0.3 s warm, 1.2 to 1.6 s cold |
| WhisperKit transcription of a 2 to 6 s yap | 0.25 to 0.85 s |
| Live voice test (expense, ask-back answered by voice, budget set by voice, budget reduced by a second expense) | worked |

The eval report is in [`eval/results/`](eval/results/). The eval sentences are synthetic; a few of the twenty-three overlap with example wording, so treat the score as a sanity check, not a benchmark. See [`docs/FEASIBILITY.md`](docs/FEASIBILITY.md) for what has and has not been verified, including the airplane-mode run.

## Right-sized by measurement

The sustainability question for local AI is whether the work is sized to the task. What Yap Later does, with what was and was not measured:

- **The smallest model that passes.** Both ternary Bonsai 2 sizes were run on the same phone and sentences. The 2B got 12 of 20, the 4B 20 of 20 (now 23 of 23), so the app ships the 4B (1.2 GB) and nothing larger.
- **One short model call per expense.** Output is limited by a grammar to a single JSON object of at most 140 tokens, with the model's reasoning block skipped. A reminder takes two calls.
- **The fixed prompt is read once.** The 947-token instructions and examples are processed one time and restored from a saved snapshot for each request, so each yap only costs the new sentence.
- **Plain code where a model is not needed.** Checking the amount, date math, budget math, the nudge wording, the follow-up question, and splitting a ramble are ordinary Swift, not model calls.
- **A small speech model, only while you hold the button.** Whisper small (about 490 MB) instead of a larger one; no background listening.
- **No server.** Nothing is sent anywhere, so there is no data-center inference at all.

Not measured: energy or battery use. The latencies are in the table above; no claim is made here about joules or carbon.

## Honest limitations

- The demo video starts from a pre-loaded **demo week**: five earlier days of made-up, ordinary spending (`scripts/demo_week.sh`), so the charts and budgets have some history. It is demo data, not anyone's real spending. Everything said into the app during the video is interpreted live.
- A week runs Monday through Sunday.
- English and US dollars only.
- A yap with several expenses is split in app code at commas and joining words, one amount per part; if any part is not a clear expense, the whole yap is treated as one request.
- The app checks that the proposed amount matches a number you said; unusual phrasings of amounts may make it ask again.
- If no Bonsai file is on the phone, the app falls back to Apple's on-device model, and to a labeled MOCK if neither is available. The header shows which.
- The spoken voice on the iPhone is iOS's built-in synthesizer by default. The Argmax voice runs on both devices but has been checked by timing and microphone tests only; switch it with `scripts/voice.sh`.
- Reminders are saved to Apple Reminders only after you tap Save. Location nudges are designed but not built.

## Build and run

### On a Mac (Apple Silicon, macOS 26, Xcode 26.6)

```sh
scripts/setup_mac.sh        # fetches llama.cpp, downloads Bonsai 2 4B and Whisper small once, builds the app
                            # add --voice to also download the Argmax voice (1.1 GB); otherwise the system voice is used
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

This project was written with AI coding assistance (cloud models), so it does not qualify for, and does not claim, the Locally Made subtrack. Ternary Bonsai 2 by PrismML. WhisperKit by Argmax. llama.cpp by ggml-org and contributors. Whisper by OpenAI. Project planning docs: [`START_HERE.md`](START_HERE.md), [`.plans/yap-later-spec.md`](.plans/yap-later-spec.md), [`docs/TICKETS.md`](docs/TICKETS.md).
