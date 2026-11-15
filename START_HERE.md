# Yap Later: starting checklist

Work from this folder, not the ket-lite folder. The existing files are a head start, not evidence of completed app work.

## First session

- [ ] Open `ideation/PROJECT_BRIEF.md`; correct the context if needed.
- [ ] Open `ideation/EVENT.md`; confirm the actual time remaining and required sponsor integrations.
- [ ] Open Terminal and run:

```sh
cd <the folder you cloned this repository into>
claude
```

- [ ] Inside Claude, run `/interview`. It should ask the unresolved questions, starting with the deadline, typed-first versus voice-required scope, and available iOS model starter.
- [ ] Read `.plans/yap-later-spec.md`. Check that user decisions and proposals remain distinct.
- [ ] Run `/kickoff`. Review `docs/PLAN.md`, `docs/ARCHITECTURE.md`, `docs/CONTRACTS.md`, and `docs/FEASIBILITY.md`.
- [ ] Run `/tickets`. Review and promote the draft tasks that have settled requirements. Do not create an arbitrary large backlog.
- [ ] Save a local Git checkpoint before implementation. Configure Git identity only if needed, using your real identity.

## Prove the foundation

- [ ] Run `/skeleton` to implement T001, the iOS project and mock request → preview flow.
- [ ] Connect the iPhone 17 Pro, complete Xcode signing/device setup, and run that shell on the actual phone.
- [ ] Run `/task T002`: demonstrate the exact candidate Bonsai model on the phone, record memory/latency/output evidence, and select the supported runtime.
- [ ] Run `/task T003`: use a hardcoded reminder to prove EventKit permission, save, alarm, and locked-phone delivery without internet.
- [ ] Keep these proofs separate: a model reply does not prove reminder delivery, and a saved reminder does not prove an alert appeared.
- [ ] Record gate results in `docs/FEASIBILITY.md`. Resolve a failing runtime before building a large interface around it.

## Build the typed loop

- [ ] Use `/team-status` to pick the next ready task.
- [ ] Implement contracts/fixtures, local interpretation, validation, review UI, reminder persistence, and orchestration in the order in `docs/TICKETS.md`.
- [ ] Run `/task Txxx` for one real ready key at a time. Review the result and update task state after each integration.
- [ ] Test explicit times, relative times, missing AM/PM, invalid dates, denied permission, cancellation, stale results, and double taps.
- [ ] Complete T011: cold-launch the app with Wi-Fi and cellular off, parse a new request, confirm it, lock the phone, and observe the alert. The Mac must not be serving inference.
- [ ] Only then consider optional voice input or a model-size comparison.

## Finish

- [ ] Rehearse `docs/DEMO.md`, including one clarification and the locked-phone alert.
- [ ] Check the actual submission requirements and deadline; do not assume the original schedule is unchanged.
- [ ] Record model/runtime versions, setup instructions, measured results, limitations, and reused preparation work.
- [ ] Publish to a newly chosen Yap Later repository only when requested; do not reuse ket-lite's remote or issue numbers by accident.

## Returning later

- [ ] Ask Claude to save decisions, task progress, and the next concrete action before stopping.
- [ ] Start `claude --continue` from THIS directory, or start fresh and run `/team-status`.

If `/interview` is unknown, exit Claude and relaunch using the exact `cd` command above. For a session already in this folder, try `/reload-skills`. As a direct fallback, ask Claude to read `CLAUDE.md`, `prompts/INTERVIEW.md`, and `.claude/skills/interview/SKILL.md` and conduct the interview, updating `.plans/yap-later-spec.md`.
