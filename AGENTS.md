# Yap Later project instructions

## Scope and current state

This is **Yap Later** (first called VocaLedger; the local folder keeps that name), a fresh, independent project: an iPhone app that interprets a reminder request locally, shows an editable confirmation, and saves an Apple Reminder with an alarm. Target device: the user's iPhone 17 Pro, 256 GB storage. Storage is not inference memory.

The user requested this restart on November 15, 2026. This folder contains a seeded specification, draft operating documents, a draft backlog, and workflows. No Yap Later app, successful model run, permission grant, reminder save, or alert delivery has been demonstrated. Preserve that distinction in reports.

The previous ket-lite project remains in its own folder. Do not inherit its Mac/Python architecture, LM Studio dependency, GitHub remote, issue numbers, tests, or completed work. Runtime inference for Yap Later must happen inside the iPhone app. A Mac is a development tool, not a runtime dependency.

## Read and update

1. `ideation/PROJECT_BRIEF.md` and `ideation/EVENT.md`: known context and unresolved event details.
2. `.plans/yap-later-spec.md`: seeded specification; finish the remaining decisions with the user.
3. `docs/DECISIONS.md`, `docs/PLAN.md`, `docs/FEASIBILITY.md`: scope, decisions, and evidence gates.
4. `docs/ARCHITECTURE.md`, `docs/CONTRACTS.md`, `contracts/`: proposed boundaries and examples.
5. `docs/TICKETS.md`: source of dependencies and done-when criteria; GitHub issues in `MikiA30/yap-later` mirror it, with state in `status:` labels.

Use [User] for explicit user choices, [Direction] for the adopted discussion direction, [Proposal] for suggested defaults, [Evidence] for documented facts, and [Unverified] for unmeasured claims. Never turn a suggestion or mock into a successful device result.

## Interview

`/interview` uses Johnathan Mo's original skill at `.claude/skills/interview/SKILL.md`. Read `prompts/INTERVIEW.md` for this project's context and unresolved questions before using it. Keep the original skill intact. Resume from the seeded spec and save to the absolute path of `.plans/yap-later-spec.md` in THIS repository.

Ask one to three related questions at a time in the main conversation. Prioritize questions that change the next implementation step. Do not repeat the known name, device, or offline goal, or force an hour-long interview. Explain choices in plain language. Record unresolved details and proceed on independent work when possible. A product interview does not establish runtime compatibility.

## Proposed first release

SwiftUI iOS app; typed input first (voice via Argmax WhisperKit as a parallel should-have lane, see T012/T020), one reminder per request, offline model inference, clarification when date/time is ambiguous, editable preview, explicit Save, then EventKit. Whether voice is required in the demo is the user's call.

Choose a runtime with demonstrated support for the EXACT Bonsai checkpoint and quantization. Prefer a working sponsor iOS starter. Compare 2B/4B on the actual phone; do not pick by parameter count alone. Stock MLX Swift support for the selected model is not established. Record artifact revisions and measurements before declaring a model selected. No Python server, localhost-on-Mac service, or cloud model in the delivered flow. If the Bonsai gate fails by its hard stop, T016 may switch to Apple's on-device Foundation Models, labeled honestly as a fallback.

## Product invariants

- Model output proposes data; it never directly writes to EventKit or executes actions.
- Pass the current instant, locale, and IANA time zone into interpretation. Validate all fields independently. Do not silently guess missing AM/PM, time zone, date, or recurrence.
- Resolve relative dates in application code against the captured request time. Keep that anchor stable while the user clarifies; refresh before Save if the reminder has become past due.
- Show the exact title, date, time, time zone, and destination list for confirmation. A due date alone is not an alarm: explicitly create the alarm and verify notification delivery on the real device.
- Only a fresh explicit Save of a valid reviewed draft permits a reminder write. Cancellation, stale model responses, malformed JSON, denied permission, and repeated taps must not create extra reminders.
- Keep inference cancellable and off the UI thread. No continuous background model process is required for a saved system reminder.
- Offline means the full flow works without Wi-Fi, cellular, or the Mac after model provisioning. Prove this after a cold launch as well as a warm run.
- Do not claim a reminder notification will appear until tested with the device's Reminders notifications and Focus settings. Report saved versus alert observed separately.

## Development and Git

- Start with one implementation session. Only add simultaneous writers after the foundation and contracts work; isolate them in worktrees or clones with explicit ownership.
- Remote: `origin` = `https://github.com/MikiA30/yap-later` (private; chosen by the user 2026-11-15). Never touch ket-lite's remote or issues.
- `main` is the integration branch. Branch per ticket as `miki/<issue#>-short-desc` (e.g. `miki/1-ios-shell`); rebase on `main`, open a PR with `Closes #<issue>`, merge with a merge commit once checks pass. Update shared contracts with their consumers. Keep changes focused and preserve other people's work.
- Local keys (T001…) and issue numbers are different; each ticket in `docs/TICKETS.md` records its `GitHub issue: #N`. Use `scripts/create_issues.py` to publish new tickets and labels.
- Ticket state lives on the issue as one `status:` label (queued, ready, in-progress, review, blocked); closing the issue via the merged PR means integrated.
- Commits credit only the user; do not add AI co-author trailers or generated-by lines. Record tool use in `docs/PREPARATION.md` instead.
- Keep credentials, model weights, device recordings, personal reminders, provisioning profiles, and build products out of Git. Use synthetic evaluation inputs.
- Follow the active request. Planning commands update planning documents; they do not silently launch an implementation or unattended loop.

## Commands

`python3 scripts/check_setup.py` validates the starter's structure and ticket graph. Application build/run/test/signing commands are NOT established; record real commands and observed results in `docs/COMMANDS.md` when T001 creates the Xcode project.
