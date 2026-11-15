# Yap Later tickets

Status as of 2026-11-15 04:35 EST: the core loop works on the iPhone with Bonsai 2 4B and WhisperKit; the airplane-mode acceptance (T011) is next. Revised 2026-11-15 03:35 EST after the interview (`.plans/yap-later-spec.md`): **voice-first, fully local expense tracker; deadline 8:30 AM today.** No implementation is complete. GitHub issues in `MikiA30/yap-later` mirror these tickets (key T0NN = issue #NN for T001–T023); this file is the source of dependencies and done-when criteria.

**Order.** Device shell → speech and model gates in parallel with pure-Swift domain work → store and UI → integrated voice loop → motion → offline acceptance → judge materials. **Feature freeze 07:15.** Bonsai hard stop **05:15**, then T016 locks the interpreter.

## Summary

| Key | Task | Depends on | Priority | Target (EST) |
|---|---|---|---|---|
| T015 | Confirm event rules, judging, and sponsor iOS path | none | must-have | 04:00 |
| T001 | Create the signed iPhone shell with a labeled mock yap flow | none | must-have | 04:15 |
| T004 | Define the money contracts and fixtures | T001 | must-have | 04:30 |
| T017 | Establish the playful, bold visual identity | T001 | must-have | 04:45 |
| T006 | Validate proposals and compute weekly budgets | T004 | must-have | 05:00 |
| T020 | Prove WhisperKit transcription offline on the iPhone | T001 | must-have | 05:00 |
| T002 | Prove a supported Bonsai model on the actual iPhone | T001 | must-have | 05:15 (hard stop) |
| T008 | Store entries and budgets locally with undo | T004 | must-have | 05:15 |
| T016 | Lock the on-device interpreter (Bonsai or fallback) | T002 | must-have | 05:30 |
| T003 | Prove the budget nudge notification offline | T001 | must-have | 05:30 |
| T007 | Build the yap, ledger, and budget screens | T004, T017 | must-have | 05:45 |
| T005 | Implement on-device money interpretation | T004, T016 | must-have | 06:00 |
| T012 | Add hold-to-talk and voice ask-back | T007, T020 | must-have | 06:15 |
| T009 | Connect the complete voice-to-budget loop | T003, T005, T006, T008, T012 | must-have | 06:30 |
| T010 | Handle undo, edits, retries, and duplicates | T009 | must-have | 06:50 |
| T018 | Build the signature transitions and motion | T007, T017 | must-have | 07:10 |
| T019 | Start a yap from the Action Button | T009 | should-have | 07:15 |
| T011 | Run full real-device offline acceptance | T010 | must-have | 07:35 |
| T022 | Write the judge-facing README | T009 | must-have | 07:50 |
| T023 | Record the demo video and write the pitch | T011 | must-have | 08:10 |
| T013 | Pre-log the demo week, rehearse, and submit | T011, T022, T023 | must-have | 08:25 |
| T021 | Ramble: several entries from one yap | T011 | should-have | if ahead |
| T024 | Bill reminders by voice | T011 | stretch | after 8:30 |
| T025 | Location nudges near frequent merchants | T011 | stretch | after 8:30 |
| T014 | Compare supported Bonsai variants | T011 | optional | after 8:30 |

**Cut order if behind:** T025, T024, T014 → T021 → T019 → reduce T018 to the one signature transition. Never cut: on-device voice and interpretation, validated amounts, undo, the nudge, the offline proof, honest labels.

## Tickets

### [T001] Create the signed iPhone shell with a labeled mock yap flow
Area: foundation
Priority: must-have
Status: integrated
Owner/session: Claude Code main session
Timebox: 40 min
Depends on: none
Allowed files: app/, docs/COMMANDS.md, docs/FEASIBILITY.md, .gitignore
Relevant contract: .plans/yap-later-spec.md
GitHub issue: #1

What:
Create `app/YapLater.xcodeproj` (SwiftUI, iOS 26, display name "Yap Later", Personal Team signing), the folder layout from the spec's architecture, and a visibly labeled MOCK flow: tap the yap button → mock transcript → mock expense card → appears in a list.

Done when:
- [ ] Builds and launches on the user's iPhone 17 Pro; team, bundle ID, iOS version, and exact build/run/test commands recorded in docs/COMMANDS.md.
- [ ] The mock flow works and is labeled MOCK on screen.
- [ ] A unit-test target runs on a simulator; G0 recorded in docs/FEASIBILITY.md.

### [T002] Prove a supported Bonsai model on the actual iPhone
Area: inference
Priority: must-have
Status: review
Owner/session: unclaimed
Timebox: hard stop 05:15 EST, then T016 decides
Depends on: T001
Allowed files: spikes/model/, app/YapLater/Services/Inference/, app/YapLater.xcodeproj/, docs/FEASIBILITY.md, docs/DECISIONS.md, docs/COMMANDS.md
Relevant contract: docs/CONTRACTS.md
GitHub issue: #2

What:
Run the exact Bonsai 2 2B or 4B artifact in-process (sponsor iOS code if T015 finds it; otherwise MLX Swift or llama.cpp, whichever has demonstrated support for that checkpoint) on "just spent like fifty bucks on groceries at Walmart".

Done when:
- [ ] Model ID, revision, quantization, file size, and runtime version recorded; a Mac or LM Studio response does not count.
- [ ] Real JSON output on the iPhone with Wi-Fi and cellular off; cold and warm latency, memory where measurable.
- [ ] G1 marked PASS, FAIL, or BLOCKED by 05:15 with evidence; no silent fallback.

### [T003] Prove the budget nudge notification offline
Area: notifications
Priority: must-have
Status: review
Owner/session: unclaimed
Timebox: 20 min
Depends on: T001
Allowed files: app/YapLater/Services/Notifications/, app/YapLater.xcodeproj/, docs/FEASIBILITY.md
Relevant contract: .plans/yap-later-spec.md
GitHub issue: #3

What:
Request notification permission and post a local notification ("Only $50 left for Groceries this week") a few seconds after the app goes to the background, with networking off.

Done when:
- [ ] Permission request and denial handled.
- [ ] Notification observed on the locked iPhone in airplane mode; Focus settings noted (G2).
- [ ] A spoken version via `AVSpeechSynthesizer` plays in the foreground, offline.

### [T004] Define the money contracts and fixtures
Area: domain
Priority: must-have
Status: integrated
Owner/session: unclaimed
Timebox: 20 min
Depends on: T001
Allowed files: contracts/, eval/requests.json, app/YapLater/Domain/, app/YapLaterTests/, docs/CONTRACTS.md
Relevant contract: docs/CONTRACTS.md
GitHub issue: #4

What:
Rewrite the contract for money: `MoneyProposal` (kind `expense` | `budget_set` | `unsupported`, amount, merchant, category, date_phrase, period, question), `Entry`, `Budget`, the fixed `Category` set, and synthetic utterances with expected results.

Done when:
- [ ] Schema, Swift types, and fixtures agree; malformed JSON fails safely in tests.
- [ ] At least 15 synthetic utterances (clear, missing amount, number words, "yesterday", budget set, unsupported) in eval/.
- [ ] docs/CONTRACTS.md replaced with the money contract.

### [T005] Implement on-device money interpretation
Area: inference
Priority: must-have
Status: integrated
Owner/session: unclaimed
Timebox: 30 min
Depends on: T004, T016
Allowed files: app/YapLater/Services/Inference/, app/YapLaterTests/, eval/
Relevant contract: docs/CONTRACTS.md
GitHub issue: #5

What:
Replace the mock interpreter with the one locked in T016: the transcript plus the request time and locale → a `MoneyProposal`.

Done when:
- [ ] Returns typed proposals or useful failures for malformed or truncated output; no storage access from inference.
- [ ] Cancellation ignores late results; runs off the main thread.
- [ ] Device results on the synthetic utterances recorded in eval/results/.

### [T006] Validate proposals and compute weekly budgets
Area: domain
Priority: must-have
Status: integrated
Owner/session: unclaimed
Timebox: 30 min
Depends on: T004
Allowed files: app/YapLater/Domain/, app/YapLaterTests/
Relevant contract: docs/CONTRACTS.md
GitHub issue: #6

What:
Pure Swift, unit-tested: amount must be present, plausible, and supported by the transcript; category from the fixed set (else Other); dates resolved in code; weekly totals per category; the nudge rule from the spec.

Done when:
- [ ] Missing or unsupported amounts produce an ask-back question, never a guess.
- [ ] "Yesterday", weekday names, and week boundaries resolve correctly against a fixed clock.
- [ ] Nudge fires once per category per threshold per week, with numbers that match the stored totals.

### [T007] Build the yap, ledger, and budget screens
Area: ui
Priority: must-have
Status: review
Owner/session: unclaimed
Timebox: 45 min
Depends on: T004, T017
Allowed files: app/YapLater/Features/, app/YapLaterTests/
Relevant contract: .claude/skills/swiftui-motion/SKILL.md
GitHub issue: #7

What:
The main yap screen (big hold-to-talk button, live transcript, expense card), the ledger (this week's entries by day), and budget bars per category with a simple editor, on the T017 tokens and mock services. Load the `swiftui-motion` skill.

Done when:
- [ ] Every screen uses design tokens only; dark mode and large text work.
- [ ] The card shows amount, merchant, category, and date, with tap-to-edit and an Undo affordance.
- [ ] VoiceOver labels on every control; mocks visibly labeled until T009.

### [T008] Store entries and budgets locally with undo
Area: store
Priority: must-have
Status: integrated
Owner/session: unclaimed
Timebox: 30 min
Depends on: T004
Allowed files: app/YapLater/Store/, app/YapLaterTests/
Relevant contract: docs/CONTRACTS.md
GitHub issue: #8

What:
SwiftData persistence for entries (integer cents) and weekly budgets, with insert, undo (hard delete), edit, and queries for this week's totals.

Done when:
- [ ] Data survives relaunch; no network or iCloud container.
- [ ] Undo and edit recompute totals; tested with an in-memory store.
- [ ] A save is idempotent per entry ID (retries cannot duplicate).

### [T009] Connect the complete voice-to-budget loop
Area: integration
Priority: must-have
Status: review
Owner/session: unclaimed
Timebox: 30 min
Depends on: T003, T005, T006, T008, T012
Allowed files: app/YapLater/App/, app/YapLater/Domain/, app/YapLater/Features/, app/YapLaterTests/
Relevant contract: .plans/yap-later-spec.md
GitHub issue: #9

What:
Wire speech → interpreter → validator → auto-save with undo → budget update → nudge (in-app, spoken, notification). Remove mocks from the default path.

Done when:
- [ ] "Just spent like fifty bucks on groceries at Walmart" becomes a saved Groceries entry and moves the budget bar, on the iPhone.
- [ ] Missing amount triggers a spoken ask-back; the spoken answer completes the entry.
- [ ] The nudge fires at the threshold; stale results cannot overwrite a newer yap.

### [T010] Handle undo, edits, retries, and duplicates
Area: reliability
Priority: must-have
Status: queued
Owner/session: unclaimed
Timebox: 20 min
Depends on: T009
Allowed files: app/YapLater/Domain/, app/YapLater/Services/, app/YapLater/Store/, app/YapLaterTests/
Relevant contract: .plans/yap-later-spec.md
GitHub issue: #10

What:
Harden the loop: repeated taps, cancelled recordings, interpretation failures, denied microphone permission, background and foreground transitions.

Done when:
- [ ] No duplicate entries from repeated taps or retries; Undo is reliable within its window.
- [ ] Every failure returns to a usable state with a clear, friendly message.
- [ ] Denied microphone permission falls back to typed input with a Settings link.

### [T011] Run full real-device offline acceptance
Area: acceptance
Priority: must-have
Status: ready
Owner/session: unclaimed
Timebox: 20 min
Depends on: T010
Allowed files: eval/, docs/FEASIBILITY.md, docs/COMMANDS.md, docs/PREPARATION.md
Relevant contract: .plans/yap-later-spec.md
GitHub issue: #11

What:
Run the demo script on the iPhone after a cold launch, airplane mode on, Mac disconnected.

Done when:
- [ ] Expense, ask-back, budget set, and nudge all pass; G3 recorded.
- [ ] Speech and interpretation latencies, model and runtime identity recorded.
- [ ] Limitations and untested cases labeled honestly.

### [T012] Add hold-to-talk and voice ask-back
Area: speech
Priority: must-have
Status: review
Owner/session: unclaimed
Timebox: 30 min
Depends on: T007, T020
Allowed files: app/YapLater/Services/Speech/, app/YapLater/Features/Yap/, app/YapLaterTests/
Relevant contract: .plans/yap-later-spec.md
GitHub issue: #12

What:
Hold-to-talk with WhisperKit (T020 setup), live transcript, and a spoken question with a follow-up answer turn when the validator asks back. Typed input stays as a fallback.

Done when:
- [ ] Microphone permission, start, stop, and cancel work; transcript is visible and editable.
- [ ] The ask-back speaks the question and accepts a held-to-talk answer that completes the same entry.
- [ ] Works offline on the iPhone.

### [T013] Pre-log the demo week, rehearse, and submit
Area: demo
Priority: must-have
Status: queued
Owner/session: user + Claude
Timebox: 15 min
Depends on: T011, T022, T023
Allowed files: docs/DEMO.md, README.md, docs/PREPARATION.md, eval/results/
Relevant contract: .plans/yap-later-spec.md
GitHub issue: #13

What:
Yap a realistic week of entries through the real app and set budgets so the live demo yap tips Groceries into the nudge; run the demo twice; submit.

Done when:
- [ ] The demo week was entered through the app's real flow; budgets set so the nudge fires on the live yap.
- [ ] Two clean rehearsals in airplane mode.
- [ ] The user submits; confirmation captured.

### [T014] Compare supported Bonsai variants
Area: optional-models
Priority: optional
Status: integrated
Owner/session: unclaimed
Timebox: after 8:30
Depends on: T011
Allowed files: spikes/model/, eval/, docs/DECISIONS.md
Relevant contract: docs/CONTRACTS.md
GitHub issue: #14

What:
Compare another compatible model on the same device and utterances.

Done when:
- [ ] Accuracy, latency, and memory compared on identical inputs.
- [ ] The proven model stays as fallback.
- [ ] Selection recorded with reasons.

### [T015] Confirm event rules, judging, and sponsor iOS path
Area: event
Priority: must-have
Status: ready
Owner/session: user
Timebox: 15 min
Depends on: none
Allowed files: ideation/EVENT.md, docs/DECISIONS.md, docs/TICKETS.md
Relevant contract: none
GitHub issue: #15

What:
The user asks organizers and sponsors; Claude records the answers.

Done when:
- [ ] Judging criteria, demo length and format, submission platform, and whether the repo must be public recorded.
- [ ] Whether Bonsai and Argmax use is required or rewarded, and whether an Apple on-device fallback is acceptable.
- [ ] Sponsor asked: "Do you have a working Swift/Xcode iPhone sample for Bonsai 2 2B or 4B, and which exact model file and runtime version should I use?"

### [T016] Lock the on-device interpreter (Bonsai or fallback)
Area: inference
Priority: must-have
Status: integrated
Owner/session: unclaimed
Timebox: 15 min decision; fallback build up to 30 min
Depends on: T002
Allowed files: app/YapLater/Services/Inference/, app/YapLater.xcodeproj/, docs/DECISIONS.md, docs/FEASIBILITY.md
Relevant contract: docs/CONTRACTS.md
GitHub issue: #16

What:
One `MoneyInterpreter` protocol. If G1 passed, lock Bonsai. If not, implement Apple's on-device Foundation Models with guided generation into `MoneyProposal`. Either way it runs on the phone.

Done when:
- [ ] Decision and evidence in docs/DECISIONS.md, labeled honestly (sponsor model vs. fallback).
- [ ] The chosen interpreter returns a valid proposal on the device offline.
- [ ] [Unverified] Foundation Models availability on the user's phone and event acceptance (T015).

### [T017] Establish the playful, bold visual identity
Area: design
Priority: must-have
Status: review
Owner/session: unclaimed
Timebox: 30 min
Depends on: T001
Allowed files: app/YapLater/DesignSystem/, app/YapLater/Assets.xcassets/, docs/DESIGN.md
Relevant contract: .claude/skills/swiftui-motion/SKILL.md
GitHub issue: #17

What:
Playful and bold, with Duolingo/Spotify-level craft (inspiration, not their branding): a confident palette with one color per category, chunky rounded type, big tactile buttons, the `Motion` tokens, app icon, launch screen. One-page docs/DESIGN.md.

Done when:
- [ ] Color, type, spacing, and `Motion` tokens in code; light and dark.
- [ ] App icon and launch screen appear on the device.
- [ ] Passes the skill's "not AI slop" checklist; screenshot reviewed by the user.

### [T018] Build the signature transitions and motion
Area: design
Priority: must-have
Status: review
Owner/session: unclaimed
Timebox: 25 min
Depends on: T007, T017
Allowed files: app/YapLater/Features/, app/YapLater/DesignSystem/
Relevant contract: .claude/skills/swiftui-motion/SKILL.md
GitHub issue: #18

What:
The moments people remember: a live, reactive voice waveform while holding; the transcript resolving into the expense card; the card flying into its category and the budget bar draining with `numericText` on the remaining amount; a bold nudge entrance with haptics; a satisfying Undo.

Done when:
- [ ] All moments smooth at 120 Hz on the device; interrupting never jumps or duplicates.
- [ ] Reduce Motion swaps movement for crossfades.
- [ ] A short screen recording reviewed by the user (kept out of Git).

### [T019] Start a yap from the Action Button
Area: intents
Priority: should-have
Status: review
Owner/session: unclaimed
Timebox: 15 min
Depends on: T009
Allowed files: app/YapLater/Intents/, app/YapLater/App/
Relevant contract: .plans/yap-later-spec.md
GitHub issue: #19

What:
An App Intent ("Start a Yap") that opens the app straight into listening, assignable to the iPhone 17 Pro Action Button.

Done when:
- [ ] The intent appears in Shortcuts and on the Action Button setting.
- [ ] Pressing the Action Button opens Yap Later already listening, offline.
- [ ] Setup steps recorded in docs/COMMANDS.md.

### [T020] Prove WhisperKit transcription offline on the iPhone
Area: speech
Priority: must-have
Status: review
Owner/session: unclaimed
Timebox: 40 min
Depends on: T001
Allowed files: spikes/speech/, app/YapLater/Services/Speech/, app/YapLater.xcodeproj/, docs/FEASIBILITY.md, docs/COMMANDS.md
Relevant contract: .plans/yap-later-spec.md
GitHub issue: #20

What:
Add Argmax's WhisperKit Swift package (sponsor) and transcribe spoken expenses on the phone with networking off; the model is bundled or provisioned before going offline.

Done when:
- [ ] Package version and model variant recorded.
- [ ] Three spoken expenses (including number words like "six fifty") transcribed offline; latency noted.
- [ ] G4 PASS, FAIL, or BLOCKED recorded in docs/FEASIBILITY.md.

### [T021] Ramble: several entries from one yap
Area: product
Priority: should-have
Status: integrated
Owner/session: unclaimed
Timebox: if ahead of schedule
Depends on: T011
Allowed files: app/YapLater/, app/YapLaterTests/, contracts/, eval/
Relevant contract: docs/CONTRACTS.md
GitHub issue: #21

What:
"Paid 12 for lunch, 40 for gas, and 6 for coffee" → three cards, each validated and auto-saved with its own undo.

Done when:
- [ ] Contract supports a list of proposals; each validated independently.
- [ ] Cards animate in sequence (staggered) into their categories.
- [ ] Offline acceptance repeated for the ramble path.

### [T022] Write the judge-facing README
Area: submission
Priority: must-have
Status: review
Owner/session: unclaimed
Timebox: 15 min
Depends on: T009
Allowed files: README.md, docs/, LICENSE
Relevant contract: none
GitHub issue: #22

What:
A two-minute read: the problem (bank-login anxiety), screenshots or GIF, how it works (voice → on-device speech → on-device model → validation → local ledger → nudge), privacy and offline, sponsor tech, measured results, honest limitations, build steps.

Done when:
- [ ] Real measurements only, from FEASIBILITY and eval/results.
- [ ] Attribution and LICENSE; no secrets, weights, or personal data in Git.
- [ ] Repo visibility set as T015 requires (the user flips it to public if needed).

### [T023] Record the demo video and write the pitch
Area: submission
Priority: must-have
Status: review
Owner/session: user + Claude
Timebox: 20 min
Depends on: T011
Allowed files: docs/DEMO.md, docs/PITCH.md
Relevant contract: none
GitHub issue: #23

What:
A timed pitch script (problem → live airplane-mode demo → how it works → what's next) and a backup screen recording of the real offline flow.

Done when:
- [ ] docs/PITCH.md fits the demo length; the first line states the problem.
- [ ] Backup video recorded on the device in airplane mode, labeled as a recording.
- [ ] Rehearsed once against the clock.

### [T024] Bill reminders by voice
Area: stretch
Priority: stretch
Status: integrated
Owner/session: unclaimed
Timebox: after 8:30
Depends on: T011
Allowed files: app/YapLater/, app/YapLaterTests/, contracts/
Relevant contract: docs/CONTRACTS.md
GitHub issue: #24

What:
"Rent's due on the 1st, $1,200" → a confirmed bill with a reminder (Apple Reminder with an explicit alarm, or a local notification), shown in an upcoming-bills list.

Done when:
- [ ] Explicit confirmation before creating the reminder; date resolved in code.
- [ ] The alert observed on the locked phone offline.
- [ ] Bills appear in the weekly view without double-counting as spending.

### [T025] Location nudges near frequent merchants
Area: stretch
Priority: stretch
Status: queued
Owner/session: unclaimed
Timebox: after 8:30
Depends on: T011
Allowed files: app/YapLater/, app/YapLaterTests/
Relevant contract: .plans/yap-later-spec.md
GitHub issue: #25

What:
With location permission, a geofence around a merchant the user logs often (e.g. a Starbucks) posts "Only $X left for Coffee this week" on arrival.

Done when:
- [ ] Opt-in permission flow; region monitoring entirely on the device.
- [ ] Nudge observed on the device with real numbers.
- [ ] Battery and privacy behavior explained in the README.

## State discipline

States: **queued** → **ready** (dependencies integrated) → **in-progress** → **review** → **integrated** (issue closed by the merged PR); **blocked** when a real dependency or device problem prevents progress. Mirror changes to the issue's `status:` label.
