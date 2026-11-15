# Yap Later operating plan

> **Superseded in part (2026-11-15 03:35):** the product pivoted to a voice-first local expense tracker. `.plans/yap-later-spec.md` and `docs/TICKETS.md` are authoritative; this file still describes the earlier reminders flow until its ticket rewrites it.

## Goal

Deliver one reliable offline iPhone loop: request → reviewed reminder → actual system alert. Review this draft during `/kickoff`; no application behavior has been implemented here.

## Demo

1. Show the app running on the iPhone with Wi-Fi/cellular off and the Mac disconnected.
2. Enter a fresh task due in one minute.
3. Show the locally generated draft with the exact date, time, time zone, and list.
4. Confirm Save; show the reminder in Apple Reminders.
5. Lock the phone and observe its alert.
6. If time permits, show an ambiguous request such as “tomorrow at six” asking AM/PM before saving anything.

## Order

Timed backlog with targets, lanes, and freeze: `docs/TICKETS.md`, mirrored as GitHub issues in `MikiA30/yap-later` (milestone "Hackathon submission").

| Milestone | Tasks | Exit evidence | Target (EST) |
|---|---|---|---|
| Rules and risk facts | T015 | Cutoff, judging, sponsor iOS answer recorded | 03:30 |
| Device shell | T001 | Signed SwiftUI mock flow runs on the actual phone | 04:15 |
| Independent proofs | T002, T003, T020 | Real local model response; reminder alarm; speech (optional lane) | 06:30 |
| Interpreter locked | T016 | Bonsai or labeled on-device fallback | 07:00 |
| Contracts, validation, identity | T004, T006, T017 | Fixtures, tested date policy, design tokens and icon | 06:00 |
| Typed implementation | T005, T007, T008, T009, T010 | Real interpretation, review, save, recovery | 09:15 |
| Polish (feature freeze 10:00) | T018, T019, T012 | Signature motion, onboarding, voice if ready | 10:00 |
| Offline acceptance | T011 | Cold-start full flow and locked-phone alert observed | 10:30 |
| Submission | T022, T023, T013 | README, video, pitch, rehearsal, submitted | 11:40 |
| After submission | T014, T021 | Model comparison, brain dump | — |

## Cut order and gates

Keep typed input and one reminder if time is tight. Cut in this order: brain dump and model comparison, voice, onboarding (keep a plain permission prompt), signature motion (keep the design tokens and one transition). Never cut confirmation, validation, honest labels, or the offline proof. If the sponsor cannot provide a supported iOS path and the spike fails, record the blocker and choose a new supported path explicitly; do not quietly route inference to the Mac/cloud while calling it on-device.

Default proposals: short responses with thinking disabled where supported, a small bounded context suited to a single request, and no continuous microphone or inference loop. Pick measured limits in T002 instead of setting theoretical maximum context lengths.

## Definition of done

- Real model interpretation on the target iPhone, recorded model/runtime identity.
- User-reviewed reminder and explicit alarm saved successfully to the intended list.
- Alert observed with the phone locked and networking off; restart/offline persistence tested.
- Clear handling for missing model, ambiguous request, invalid output/date, permission denial, cancellation, repeated taps, and failed save.
- No unlabelled mocks, no Mac runtime dependency, no requirement for live model downloads during the demo.
- Actual install/build/run instructions and limitations recorded.

## Timing

The original event schedule named November 15 noon; the actual remaining time is unconfirmed. During kickoff record the current cutoff, a short timebox for each proof, the feature freeze, and rehearsal time. The timeboxes are planning decisions, not promises that signing or model integration will succeed within them.
