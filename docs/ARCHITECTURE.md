# Architecture — proposal pending kickoff

One native iOS app, with boundaries expressed as Swift protocols. The phone owns inference, validation, UI, and reminder writes. Do not create a Python engine or a Mac-hosted server.

| Proposed path | Responsibility | Initial owner |
|---|---|---|
| `app/YapLater/App/` | Entry point and dependency wiring | User / integration session |
| `app/YapLater/Features/Capture/` | Text entry; optional later push-to-talk | User / active ticket |
| `app/YapLater/Features/Review/` | Clarification and editable confirmation | User / active ticket |
| `app/YapLater/Domain/` | Proposal DTOs, validated draft, state machine | Integration owner |
| `app/YapLater/Services/Inference/` | In-process runtime, local assets, cancellation | User / active ticket |
| `app/YapLater/Services/Validation/` | Deterministic date resolution and validation | User / active ticket |
| `app/YapLater/Services/Reminders/` | EventKit permission, list access, save/alarm | User / active ticket |
| `app/YapLater/Services/Speech/` | Offline transcription (Argmax WhisperKit) | T020, T012 |
| `app/YapLater/DesignSystem/` | Color, type, spacing, `Motion` tokens | T017 |
| `app/YapLater/Features/Onboarding/` | First run and permission priming | T019 |
| `app/YapLaterTests/` | Contract, date, state, and persistence-boundary tests | Ticket owner |
| `contracts/`, `eval/` | Shared schema, synthetic cases, device evidence | Integration owner |
| `app/YapLater.xcodeproj` | Project/signing/dependency configuration | Integration owner |

Paths are proposed until T001 creates the actual project. Reconcile path changes in tickets and docs together.

## Flow

Capture text + reference instant/locale/time zone → local inference → untrusted Proposal DTO → deterministic validator → clarification or reviewed draft → explicit user Save → ReminderRepository → receipt.

The inference service never receives an EventKit handle. The reminder repository accepts a validated, user-confirmed draft. UI state tracks request ID and draft revision so old responses cannot replace a newer edit.

## Assets and lifecycle

Model provisioning is a development/setup step. Runtime must find already-local assets and show useful missing/loading/failed states. Do not hardcode a Mac filesystem path into iOS. Decide bundle versus application-support storage once signing, artifact size, and sponsor runtime are known. Keep the UI responsive and support cancellation. Record real memory limits and unload behavior from device tests.

## Parallel work

Begin with one session. After T001/T004, inference, review UI, and EventKit adapters may be split only with distinct file ownership and stable contracts. Shared domain types, project files, and central wiring have one integration owner. Two sessions do not edit the same Xcode project simultaneously.
