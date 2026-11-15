# Yap Later tickets

Reviewed backlog, 2026-11-15 03:00 EST. No implementation is complete. GitHub issues in `MikiA30/yap-later` mirror these tickets; this file stays the source of dependencies and done-when criteria. Local keys (T001…) are stable; each ticket records its mapped issue number.

**Clock.** [Proposal] Targets assume the last known submission cutoff, **Sunday Nov 15, 12:00 EST** (unconfirmed for this pivot; T015 confirms it). If the cutoff moves, shift the targets, not the order.

**Order.** Risk first: device shell → model gate and reminder gate in parallel → contracts and validation → integrated typed loop → identity and motion → offline acceptance → judge materials → submit. Voice (Argmax, a sponsor) runs as a parallel lane once the shell exists. The name "Yap Later" suggests voice; whether voice is required for the demo is a user decision (see T012).

## Summary

| Key | Task | Depends on | Priority | Target (EST) |
|---|---|---|---|---|
| T015 | Confirm event rules, cutoff, judging, and sponsor iOS path | none | must-have | 03:30 |
| T001 | Create the signed iPhone shell and mock review flow | none | must-have | 04:15 |
| T004 | Finalize domain contracts and synthetic fixtures | T001 | must-have | 04:45 |
| T003 | Prove an Apple Reminder alarm offline | T001 | must-have | 05:15 |
| T017 | Establish the visual identity and design tokens | T001 | must-have | 05:30 |
| T020 | Prove Argmax WhisperKit transcription offline on the iPhone | T001 | should-have | 06:00 |
| T006 | Implement date resolution and proposal validation | T004 | must-have | 06:00 |
| T002 | Prove a supported Bonsai model on the actual iPhone | T001 | must-have | 06:30 (hard stop) |
| T008 | Implement the EventKit reminder repository | T003, T004 | must-have | 06:15 |
| T007 | Build capture, clarification, and editable review | T004, T017 | must-have | 06:45 |
| T016 | Lock the on-device interpreter (Bonsai or fallback) | T002 | must-have | 07:00 |
| T005 | Implement local request interpretation | T004, T016 | must-have | 07:45 |
| T009 | Connect the complete typed reminder loop | T005, T006, T007, T008 | must-have | 08:30 |
| T010 | Handle retries, lifecycle, and duplicate saves | T009 | must-have | 09:15 |
| T018 | Build the signature transitions and motion | T007, T017 | should-have | 09:45 |
| T019 | Add first-run onboarding, permission priming, and the offline badge | T008, T017 | should-have | 09:45 |
| T012 | Add offline push-to-talk ("yap") input | T009, T020 | should-have | 10:00 |
| T011 | Run full real-device offline acceptance | T010 | must-have | 10:30 |
| T022 | Write the judge-facing README and make the repo submission-ready | T009 | must-have | 10:45 |
| T023 | Record the demo video and write the pitch | T011 | must-have | 11:15 |
| T013 | Rehearse and submit | T011, T022, T023 | must-have | 11:40 |
| T014 | Compare supported 2B and 4B variants | T011 | optional | after submit |
| T021 | Brain dump: several reminders from one ramble | T011 | optional | after submit |

**Feature freeze: 10:00.** After that, only fixes, acceptance, and submission materials.

**Lanes for parallel sessions** (only after T001 and T004 land; one Xcode-project owner at a time, see AGENTS.md):

- Lane A (integration owner): T001 → T004 → T006 → T016 → T005 → T009 → T010 → T011
- Lane B (device gates): T003 → T008, then T002 (model gate)
- Lane C (design): T017 → T007 → T018 → T019
- Lane D (voice, optional): T020 → T012
- Human: T015 now; device checks in T001/T002/T003/T011; T023 recording; T013 submit.

**Cut order if behind:** T021, T014 → T012 voice → T019 onboarding (keep a plain permission prompt) → T018 motion (keep T017 tokens and one transition) → never cut confirmation, validation, honest labels, or the offline proof.

## Tickets

### [T001] Create the signed iPhone shell and mock review flow
Area: foundation
Priority: must-have
Status: ready
Owner/session: unclaimed
Timebox: 60 min
Depends on: none
Allowed files: app/, docs/COMMANDS.md, docs/FEASIBILITY.md, .gitignore
Relevant contract: docs/CONTRACTS.md
GitHub issue: pending

What:
Create `app/YapLater.xcodeproj` (SwiftUI, iOS 26 deployment target, display name "Yap Later"), the folder boundaries in docs/ARCHITECTURE.md, typed input, a visibly labeled MOCK draft preview, edit, and cancel. Run `/skeleton`.

Done when:
- [ ] Builds and launches on the user's iPhone 17 Pro from Xcode; signing team, bundle ID, iOS version, and exact build/run/test commands recorded in docs/COMMANDS.md.
- [ ] Mock request → preview → edit → Cancel works; the mock is labeled on screen; no EventKit write exists yet.
- [ ] A unit-test target runs (`xcodebuild test` on a simulator); G0 recorded in docs/FEASIBILITY.md.

### [T002] Prove a supported Bonsai model on the actual iPhone
Area: inference
Priority: must-have
Status: queued
Owner/session: unclaimed
Timebox: hard stop 06:30 EST, then T016 decides
Depends on: T001
Allowed files: spikes/model/, app/YapLater/Services/Inference/, app/YapLater.xcodeproj/, docs/FEASIBILITY.md, docs/DECISIONS.md, docs/COMMANDS.md
Relevant contract: docs/CONTRACTS.md
GitHub issue: pending

What:
Use sponsor-supported iOS code if T015 finds it; otherwise try the exact Bonsai 2 2B or 4B artifact in-process (MLX Swift or llama.cpp, whichever has demonstrated support for that checkpoint). Text-only use.

Done when:
- [ ] Model ID, revision, quantization, file size, and runtime version recorded; a Mac or LM Studio response does not count.
- [ ] Real output on the iPhone with Wi-Fi and cellular off; cold and warm latency, and memory where measurable.
- [ ] Five repeated short requests and one cancellation; whether thinking can be disabled and whether JSON lands in the normal output field (ket-lite saw it in the reasoning field on the Mac) recorded.
- [ ] G1 marked PASS, FAIL, or BLOCKED by 06:30 with evidence; no silent fallback.

### [T003] Prove an Apple Reminder alarm offline
Area: reminders
Priority: must-have
Status: queued
Owner/session: unclaimed
Timebox: 45 min
Depends on: T001
Allowed files: spikes/reminders/, app/YapLater/Services/Reminders/, app/YapLater.xcodeproj/, docs/FEASIBILITY.md, docs/COMMANDS.md
Relevant contract: docs/CONTRACTS.md
GitHub issue: pending

What:
Create a hardcoded one-minute reminder through EventKit, independent of the model.

Done when:
- [ ] `NSRemindersFullAccessUsageDescription` set; full access requested; denial handled; a writable list chosen.
- [ ] Reminder saved with a due date AND an explicit `EKAlarm`; persistence verified in the Reminders app.
- [ ] With Wi-Fi and cellular off, the phone locked: alert observed. Saved and alert observed reported separately, with the notification and Focus settings used (G2).

### [T004] Finalize domain contracts and synthetic fixtures
Area: domain
Priority: must-have
Status: queued
Owner/session: unclaimed
Timebox: 30 min
Depends on: T001
Allowed files: contracts/, eval/requests.json, app/YapLater/Domain/, app/YapLaterTests/, docs/CONTRACTS.md
Relevant contract: docs/CONTRACTS.md
GitHub issue: pending

What:
Turn the proposed schema, request clock, draft revision, confirmation, receipt, and errors into shared Swift types.

Done when:
- [ ] Swift decode/encode agrees with the fixtures; malformed payloads fail safely in tests.
- [ ] Cross-field checks and the date policy are written down; schema conformance never counts as permission to save.
- [ ] Request IDs, draft revisions, and save intents are explicit; docs match actual file paths.

### [T005] Implement local request interpretation
Area: inference
Priority: must-have
Status: queued
Owner/session: unclaimed
Timebox: 45 min
Depends on: T004, T016
Allowed files: app/YapLater/Services/Inference/, app/YapLaterTests/, eval/
Relevant contract: docs/CONTRACTS.md
GitHub issue: pending

What:
Replace mock interpretation with the interpreter locked in T016, producing bounded structured output.

Done when:
- [ ] The captured reference instant, locale, IANA time zone, and clarification context are passed in.
- [ ] Typed proposals or useful failures for malformed or truncated output; inference has no EventKit access.
- [ ] Cancellation ignores late results; device results on the synthetic corpus recorded in eval/results/.

### [T006] Implement date resolution and proposal validation
Area: validation
Priority: must-have
Status: queued
Owner/session: unclaimed
Timebox: 60 min
Depends on: T004
Allowed files: app/YapLater/Services/Validation/, app/YapLater/Domain/, app/YapLaterTests/
Relevant contract: docs/CONTRACTS.md
GitHub issue: pending

What:
Resolve and validate reminder drafts in deterministic code, independent of the model.

Done when:
- [ ] Explicit dates and relative offsets ("in one minute", "tomorrow at six") resolve against the fixed request clock; unit-tested.
- [ ] Missing AM/PM, invalid dates, past times, invalid zones, DST gaps and overlaps, recurrence, and multiple tasks follow the written policy (ask, reject, or flag; never guess).
- [ ] Edits invalidate the prior confirmation; revalidation before Save catches a relative reminder that has become past due.

### [T007] Build capture, clarification, and editable review
Area: ui
Priority: must-have
Status: queued
Owner/session: unclaimed
Timebox: 60 min
Depends on: T004, T017
Allowed files: app/YapLater/Features/, app/YapLaterTests/
Relevant contract: docs/CONTRACTS.md
GitHub issue: pending

What:
Typed input, focused clarification, and an editable confirmation card built on the T017 tokens, using mock services until adapters land. Load the `swiftui-motion` skill.

Done when:
- [ ] The card shows title, human-readable date and time, time zone, and destination list, all editable.
- [ ] Save is disabled for invalid or incomplete drafts; edit, cancel, and retry paths are clear.
- [ ] Inference shows an honest working state with Cancel; mocks stay visibly labeled; VoiceOver labels on every control.

### [T008] Implement the EventKit reminder repository
Area: reminders
Priority: must-have
Status: queued
Owner/session: unclaimed
Timebox: 45 min
Depends on: T003, T004
Allowed files: app/YapLater/Services/Reminders/, app/YapLaterTests/
Relevant contract: docs/CONTRACTS.md
GitHub issue: pending

What:
Replace the reminder probe with a repository that accepts only confirmed, validated drafts.

Done when:
- [ ] Denied or revoked permission, and missing or read-only lists, handled without a write.
- [ ] A save creates the intended title, due date, explicit alarm, and a receipt in the chosen list; the default list policy is decided (system default or a dedicated "Yap Later" list for clean demos).
- [ ] Failures never show success; no duplicate app notification is scheduled for the same reminder.

### [T009] Connect the complete typed reminder loop
Area: integration
Priority: must-have
Status: queued
Owner/session: unclaimed
Timebox: 45 min
Depends on: T005, T006, T007, T008
Allowed files: app/YapLater/App/, app/YapLater/Domain/, app/YapLaterTests/
Relevant contract: docs/CONTRACTS.md
GitHub issue: pending

What:
Wire real inference, validation, review, and reminders through the agreed state machine. Remove the mock from the default path.

Done when:
- [ ] A fresh typed request becomes a reviewed Apple Reminder using only the iPhone.
- [ ] Ambiguity asks before saving; stale responses cannot overwrite a newer request or edit.
- [ ] Save requires explicit confirmation of the exact current revision; cancelled drafts never persist.

### [T010] Handle retries, lifecycle, and duplicate saves
Area: reliability
Priority: must-have
Status: queued
Owner/session: unclaimed
Timebox: 45 min
Depends on: T009
Allowed files: app/YapLater/Domain/, app/YapLater/Services/, app/YapLaterTests/
Relevant contract: docs/CONTRACTS.md
GitHub issue: pending

What:
Harden failure recovery and local save intent and receipt handling.

Done when:
- [ ] Repeated taps and retries create no extra reminder; an in-flight Save is guarded.
- [ ] A crash between save and receipt is treated as uncertain and reconciled, not claimed as exactly-once.
- [ ] Missing model, cancelled inference, background and foreground transitions, denied permission, and failed save keep useful editable state.

### [T011] Run full real-device offline acceptance
Area: acceptance
Priority: must-have
Status: queued
Owner/session: unclaimed
Timebox: 30 min
Depends on: T010
Allowed files: eval/, docs/FEASIBILITY.md, docs/COMMANDS.md, docs/PREPARATION.md
Relevant contract: docs/CONTRACTS.md
GitHub issue: pending

What:
Measure the cold and warm full pipeline with the Mac disconnected and networking off.

Done when:
- [ ] G0, G1 (or the T016 fallback), and G2 evidence present; cold launch finds all local assets.
- [ ] Fresh input, clarification, review, real save, and locked-phone alert pass on the iPhone; voice too if T012 landed.
- [ ] G3, timings, failures, runtime and artifact revisions, and limitations recorded; untested cases labeled.

### [T012] Add offline push-to-talk ("yap") input
Area: speech
Priority: should-have (user to confirm whether voice is required for the demo)
Status: queued
Owner/session: unclaimed
Timebox: 45 min
Depends on: T009, T020
Allowed files: app/YapLater/Services/Speech/, app/YapLater/Features/Capture/, app/YapLaterTests/, eval/
Relevant contract: docs/CONTRACTS.md
GitHub issue: pending

What:
Hold-to-talk capture transcribed on the phone with the T020 WhisperKit setup, feeding the same request flow.

Done when:
- [ ] Microphone permission, start, stop, and cancel work; the transcript is visible and editable before interpretation.
- [ ] Speech runs on the iPhone with networking off using provisioned assets.
- [ ] Voice uses the same validation, confirmation, and save path; typed input stays available.

### [T013] Rehearse and submit
Area: demo
Priority: must-have
Status: queued
Owner/session: unclaimed
Timebox: 25 min
Depends on: T011, T022, T023
Allowed files: docs/DEMO.md, README.md, docs/PREPARATION.md, eval/results/
Relevant contract: docs/CONTRACTS.md
GitHub issue: pending

What:
Run the live demo twice end to end, then submit before the confirmed cutoff.

Done when:
- [ ] Two clean rehearsals of the one-minute reminder and the ambiguity example, with the real model, offline.
- [ ] Every docs/DEMO.md item checked or explicitly marked not done.
- [ ] The user submits (Claude does not submit externally without being asked); confirmation captured.

### [T014] Compare supported 2B and 4B variants
Area: optional-models
Priority: optional
Status: queued
Owner/session: unclaimed
Timebox: after submission
Depends on: T011
Allowed files: spikes/model/, eval/, docs/DECISIONS.md
Relevant contract: docs/CONTRACTS.md
GitHub issue: pending

What:
Compare another compatible model on the same device and corpus.

Done when:
- [ ] Extraction quality, clarification, cold and warm latency, and memory compared on identical fixed-clock inputs.
- [ ] The proven model stays as fallback; affected offline acceptance repeated after a switch.
- [ ] Selection reasoned and recorded; parameter count alone is not the criterion.

### [T015] Confirm event rules, cutoff, judging, and sponsor iOS path
Area: event
Priority: must-have
Status: ready
Owner/session: user
Timebox: 20 min
Depends on: none
Allowed files: ideation/EVENT.md, docs/DECISIONS.md, docs/PLAN.md, docs/TICKETS.md
Relevant contract: none
GitHub issue: pending

What:
Get the facts that decide what "winning" requires. The user asks organizers and sponsors; Claude records the answers.

Done when:
- [ ] Submission cutoff, demo length and format, judging criteria, and submission platform recorded in ideation/EVENT.md; ticket targets shifted if the cutoff differs.
- [ ] Required or rewarded sponsor tech recorded (Bonsai, Argmax, LM Studio), and whether a non-sponsor on-device fallback is acceptable.
- [ ] Sponsor asked: "Do you have a working Swift/Xcode iPhone sample for Bonsai 2 2B or 4B, and which exact model file and runtime version should I use?" Answer recorded.
- [ ] Whether the repo must be public, and any required video, slides, or README, recorded.

### [T016] Lock the on-device interpreter (Bonsai or fallback)
Area: inference
Priority: must-have
Status: queued
Owner/session: unclaimed
Timebox: 30 min (decision at 06:30; fallback build up to 60 min)
Depends on: T002
Allowed files: app/YapLater/Services/Inference/, app/YapLater.xcodeproj/, docs/DECISIONS.md, docs/FEASIBILITY.md
Relevant contract: docs/CONTRACTS.md
GitHub issue: pending

What:
Decide the interpreter behind one `ReminderInterpreter` protocol. If G1 passed, lock Bonsai. If not, implement the fallback: Apple's on-device Foundation Models framework (iOS 26, runs on iPhone 17 Pro without network when Apple Intelligence is enabled) with guided structured output. Either way, it runs on the phone.

Done when:
- [ ] Decision and evidence in docs/DECISIONS.md, labeled honestly (sponsor model vs. fallback).
- [ ] The chosen interpreter returns a proposal on the device offline for the one-minute example.
- [ ] If the fallback is used, the README and pitch say so and the Bonsai attempt stays documented. [Unverified] Foundation Models availability on the user's phone, and whether the event accepts it (T015).

### [T017] Establish the visual identity and design tokens
Area: design
Priority: must-have
Status: queued
Owner/session: unclaimed
Timebox: 45 min
Depends on: T001
Allowed files: app/YapLater/DesignSystem/, app/YapLater/Assets.xcassets/, docs/DESIGN.md
Relevant contract: .claude/skills/swiftui-motion/SKILL.md
GitHub issue: pending

What:
A small, specific identity so the app doesn't look generated: palette (light and dark), type scale, spacing, corner radii, the `Motion` tokens from the skill, app icon, and launch screen. One-page docs/DESIGN.md with the rationale.

Done when:
- [ ] Color, type, spacing, and `Motion` tokens exist in code and every screen uses them (no ad-hoc values).
- [ ] App icon (all required sizes via a single 1024 asset) and launch screen appear on the device.
- [ ] Passes the skill's "not AI slop" checklist in light and dark mode; screenshots reviewed by the user.

### [T018] Build the signature transitions and motion
Area: design
Priority: should-have
Status: queued
Owner/session: unclaimed
Timebox: 60 min
Depends on: T007, T017
Allowed files: app/YapLater/Features/, app/YapLater/DesignSystem/
Relevant contract: .claude/skills/swiftui-motion/SKILL.md
GitHub issue: pending

What:
The moments judges remember, following the `swiftui-motion` skill: the typed (or spoken) request morphs into the confirmation card (`matchedGeometryEffect`); a calm, honest thinking state; changed fields animate with `numericText` during clarification; Save success (symbol replace + `.sensoryFeedback(.success)`) only after EventKit confirms.

Done when:
- [ ] All four moments work on the device at 120 Hz without hitches; interrupting any of them (Cancel, edit) never jumps or saves.
- [ ] Reduce Motion replaces movement with crossfades; largest Dynamic Type and dark mode still read clearly.
- [ ] A short screen recording reviewed by the user (kept out of Git).

### [T019] Add first-run onboarding, permission priming, and the offline badge
Area: ux
Priority: should-have
Status: queued
Owner/session: unclaimed
Timebox: 40 min
Depends on: T008, T017
Allowed files: app/YapLater/Features/Onboarding/, app/YapLater/Features/, app/YapLater/App/
Relevant contract: docs/CONTRACTS.md
GitHub issue: pending

What:
A two- or three-screen first run explaining what Yap Later does and that everything stays on the phone, priming Reminders (and microphone, if voice) before the system prompt. A small persistent "On-device" indicator that is true: it reflects that interpretation ran locally, not just network state.

Done when:
- [ ] First run, permission granted, and permission denied (with a Settings deep link) all work on the device.
- [ ] Onboarding shows once, and can be reset for demos without reinstalling.
- [ ] The badge never claims more than was verified.

### [T020] Prove Argmax WhisperKit transcription offline on the iPhone
Area: speech
Priority: should-have
Status: queued
Owner/session: unclaimed
Timebox: 60 min
Depends on: T001
Allowed files: spikes/speech/, app/YapLater/Services/Speech/, app/YapLater.xcodeproj/, docs/FEASIBILITY.md, docs/COMMANDS.md
Relevant contract: docs/CONTRACTS.md
GitHub issue: pending

What:
Add Argmax's WhisperKit Swift package (a hackathon sponsor) and transcribe a spoken reminder on the phone, offline. ket-lite measured WhisperKit small on the Mac (1% word error, 0.5 s resident); the phone is untested.

Done when:
- [ ] Package version and model variant recorded; the model is bundled or provisioned before going offline.
- [ ] Three spoken reminders transcribed on the iPhone with networking off; latency and accuracy noted.
- [ ] G4 (speech) PASS, FAIL, or BLOCKED recorded in docs/FEASIBILITY.md.

### [T021] Brain dump: several reminders from one ramble
Area: product
Priority: optional (user decision; fits the "yap" name)
Status: queued
Owner/session: unclaimed
Timebox: after submission unless the core is done early
Depends on: T011
Allowed files: app/YapLater/, app/YapLaterTests/, contracts/, eval/
Relevant contract: docs/CONTRACTS.md
GitHub issue: pending

What:
Let one long ramble produce a stack of draft reminders, each reviewed and saved individually with the same rules.

Done when:
- [ ] Contract extended for multiple proposals; each draft validated independently.
- [ ] The user reviews, edits, or drops each one; only explicitly saved drafts are written.
- [ ] Offline acceptance repeated for the multi-reminder path.

### [T022] Write the judge-facing README and make the repo submission-ready
Area: submission
Priority: must-have
Status: queued
Owner/session: unclaimed
Timebox: 30 min
Depends on: T009
Allowed files: README.md, docs/, LICENSE
Relevant contract: none
GitHub issue: pending

What:
A README a judge can read in two minutes: the problem, a GIF or screenshots, how it works (diagram: input → on-device model → validation → your confirmation → Apple Reminders), why it is private and offline, sponsor tech used, measured results, honest limitations, and build steps.

Done when:
- [ ] README written with real measurements from FEASIBILITY.md and eval/results/ only.
- [ ] Model and library attribution and a project LICENSE added; no secrets, weights, or personal data in Git.
- [ ] Repository visibility set as T015 requires (the user flips it to public if needed).

### [T023] Record the demo video and write the pitch
Area: submission
Priority: must-have
Status: queued
Owner/session: user + Claude
Timebox: 35 min
Depends on: T011
Allowed files: docs/DEMO.md, docs/PITCH.md
Relevant contract: none
GitHub issue: pending

What:
A pitch script that fits the confirmed demo length (problem → live demo in airplane mode → how it works → what's next) and a backup screen recording of the real offline flow.

Done when:
- [ ] docs/PITCH.md with a timed script; the opening line states the problem in one sentence.
- [ ] Backup video recorded on the device in airplane mode, labeled as a recording, no personal reminders visible.
- [ ] The user has rehearsed the pitch once against the clock.

## State discipline

States: **queued** (reviewed, waiting on dependencies) → **ready** (dependencies integrated) → **in-progress** (claimed by a session) → **review** → **integrated**; **blocked** when a real dependency or device problem prevents progress. Mirror state changes to the GitHub issue's `status:` label. Mark a device-gated task integrated only with its required evidence. Preserve keys and results when revising scope.
