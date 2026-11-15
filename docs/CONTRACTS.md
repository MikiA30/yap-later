# Contracts v0 — proposed, no app implementation yet

T004 finalizes these boundaries and reconciles schema/fixtures before feature adapters rely on them.

## 1. Interpretation request (app-owned)

Fields: `requestID` UUID; `text` nonempty String; `referenceInstant` absolute Date; `timeZoneID` IANA identifier; `localeID` identifier; optional clarification answers. The app creates these values. Never trust the model to supply the current date or a new reference clock.

The reference instant stays fixed for the interpretation conversation. A relative “in one minute” resolves against that instant; if it is no longer in the future at Save, ask the user to revise/refresh and reconfirm.

## 2. Model proposal (untrusted)

Machine format: `contracts/reminder-proposal.schema.json`. Exactly one reminder, no executable tool call. Three statuses: `ready`, `needs_clarification`, `unsupported`. Title can be absent until clarified. `schedule` is one of:

- `relative`: integer offset in seconds, plus the original time phrase.
- `calendar`: local Gregorian `YYYY-MM-DD` date and 24-hour `HH:MM:SS` time, optional explicit time-zone ID, plus original phrase. Relative calendar wording such as “tomorrow” must be checked against the request context; do not blindly trust model-generated dates.
- `unspecified`: no resolved schedule yet.

`clarification` is null or one focused question. `ready` requires a nonempty title, a specified schedule, and null clarification. `needs_clarification` requires a question. Multiple tasks, recurrence, or location requests outside scope return clarification/unsupported; do not silently drop requested work.

The JSON Schema is syntactic structure only. T006 must enforce cross-field semantics, date validity, reasonable ranges, past-date behavior, timezone validity, unsupported recurrence, and ambiguity. Matching JSON is not permission to save.

## 3. Validated draft (app-owned)

Fields: `draftID`, `revision`, `requestID`, original text/reference instant, validated nonempty title, absolute `dueAt`, display time-zone ID, selected writable list identifier, and validation state. Convert calendar components through the user's calendar/time-zone rules. Invalid dates, DST gaps, and repeated clock times need explicit handling; do not normalize silently to another time.

The preview formats dueAt into an explicit date, time, and time-zone label. Any user edit increments revision and invalidates prior confirmation. List identifiers originate from EventKit, never model text.

## 4. Save boundary

`ReminderRepository.save(confirmedDraft, saveIntentID)` returns a receipt or typed failure. A confirmed draft contains the exact reviewed revision and validated destination list. Revalidate the time and authorization immediately before the write. The repository creates an EKReminder with due components and an explicit EKAlarm for the intended instant, then commits it.

Proposed receipt: saveIntentID, EventKit reminder identifier, savedAt, title, dueAt, list identifier. A receipt proves persistence, not alert delivery. Disable duplicate taps while saving and reuse one intent for retry. Persist a minimal local receipt to reduce duplicate creation across relaunch; if a crash happens between EventKit commit and receipt persistence, report an uncertain outcome and reconcile rather than claiming exactly-once atomicity.

Do not read unrelated reminder contents for a simple save. Query only what is needed for list choice or explicit retry reconciliation. The system permission may be broader than the app's actual use.

## 5. State and errors

States: idle → loadingModel/interpreting → clarifying or reviewing → saving → saved. Errors return to an editable state without an implicit write. Cancellation increments the request generation; late inference results are ignored. A Save completion cannot attach to a newer draft.

Typed failures: modelMissing, runtimeUnavailable, inferenceCancelled, inferenceFailed, invalidProposal, clarificationRequired, invalidSchedule, permissionDenied, listUnavailable, saveFailed, saveOutcomeUnknown. Keep technical diagnostics separate from concise user-facing recovery guidance.

## 6. Optional voice

On-device speech yields text into the same InterpretationRequest boundary. User sees/corrects the transcript. No new save path. Microphone capture is explicitly started/stopped; no continuous background listening in this scope.

## Change record

2026-11-15: v0 proposed from the pivot conversation. No interface has been implemented or validated on-device.
