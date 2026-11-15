# Yap Later specification — seeded, interview pending

## Known direction

See `ideation/PROJECT_BRIEF.md`. The user named the app Yap Later (first called VocaLedger) and requested a clean setup. Target: iPhone 17 Pro, 256 GB storage. Intended flow: on-phone interpretation of a reminder request, review, then an Apple Reminder with an alarm, usable offline after provisioning.

## Proposed first interaction

1. Enter a typed request such as “Remind me in one minute to check my homework.”
2. The app captures current date/time, locale, and time zone and runs the local model.
3. A structured proposal becomes a validated draft. If details are missing or ambiguous, ask a focused question.
4. Show editable title, full date/time/time zone, and destination reminder list.
5. On explicit Save, request/verify reminder access, validate the current draft again, and save once with an alarm.
6. Show a saved confirmation only after persistence succeeds. Lock the phone and verify the alert independently.

## Proposed scope

Must-have: typed input, one reminder, local inference, clarification, editable confirmation, EventKit save/alarm, useful failure states, actual-device offline proof.

Deferred unless the interview changes priorities: offline voice transcription, multiple-reminder extraction, recurring/location reminders, widgets, Siri/App Intents, screenshots, calendar events, accounts, cloud sync implementation, continuous background listening, text-to-speech, and finance features. Apple Reminders may sync separately when connectivity returns; the app must not depend on that sync to work.

## Architecture and model selection

Proposed: SwiftUI plus Swift services in one iOS process. Runtime and checkpoint are open until the model proof. Prefer supported sponsor code over implementing custom quantization kernels. Do not assume the Mac's Python MLX or LM Studio integration transfers to iOS.

The draft model response is specified in `docs/CONTRACTS.md`. Date normalization, validation, and save permissions remain deterministic application logic.

## Acceptance direction

- The cold-start airplane-mode flow works on the user's actual iPhone with the Mac disconnected.
- A saved reminder appears in Apple Reminders with the correct title and schedule, and its alarm is observed while the phone is locked.
- Ambiguous or malformed outputs cannot create reminders silently; explicit confirmation is required.
- Cancellation and repeated Save taps do not create unintended duplicates.
- Loading, inference latency, peak memory when measurable, and failure cases are recorded. Performance thresholds remain to be agreed.

## Open interview decisions

- Confirm deadline, available hours, and first demo audience.
- Confirm typed-first versus voice-required and excluded features.
- Confirm device access/signing and whether a sponsor iOS starter exists.
- Confirm language, acceptable latency, list-selection behavior, date/time ambiguity policy, and whether the proposed one-reminder scope is acceptable.
- Choose runtime/model only after evidence. A 2B fallback does not fix an unsupported architecture or loader.

## Decision and experiment record

Use `docs/DECISIONS.md` for settled choices, `docs/FEASIBILITY.md` for gate results, and `docs/PREPARATION.md` for provenance. Their initial entries are proposals and pending checks, not completed work.
