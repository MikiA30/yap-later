# Yap Later project instructions

## Scope and current state

This is **Yap Later** (first called VocaLedger; the local folder keeps that name): a voice-first, fully local expense tracker for iPhone. You say "just spent like $50 on groceries"; on-device speech and an on-device model log it, categorize it, and check it against a weekly budget, with a nudge when a budget runs low. No bank login, no account, no network. The authoritative product description is `.plans/yap-later-spec.md` (interviewed 2026-11-15). Target device: the user's iPhone 17 Pro. **Deadline: 8:30 AM EST, November 15, 2026.**

The project began as a reminders app; the user pivoted it to money-first during the interview. Bill reminders and location nudges are stretch. Where older docs (`docs/PLAN.md`, `docs/ARCHITECTURE.md`, `docs/CONTRACTS.md`, `docs/DEMO.md`, `ideation/PROJECT_BRIEF.md`) still describe the reminders flow, the spec and `docs/TICKETS.md` win until those docs are rewritten.

No Yap Later app, model run, transcription, or notification has been demonstrated on the device yet. Preserve that distinction in reports.

The previous ket-lite project remains in its own folder. Do not inherit its Mac/Python architecture, LM Studio dependency, GitHub remote, issue numbers, tests, or completed work. All inference and speech recognition must happen inside the iPhone app. A Mac is a development tool, not a runtime dependency.

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

## First release

SwiftUI iOS 26 app. Hold-to-talk (Argmax WhisperKit, on-device) → on-device interpretation (Bonsai if gate G1 passes by its hard stop; otherwise Apple's Foundation Models, labeled honestly as a fallback) → validation in app code → auto-save with undo → weekly per-category budgets → nudge (in-app, spoken, local notification). Look and feel: playful and bold, with deliberate motion; always load the `swiftui-motion` skill for UI work.

Choose a runtime with demonstrated support for the EXACT Bonsai checkpoint and quantization. Record artifact revisions and measurements before declaring a model selected. No Python server, localhost-on-Mac service, or cloud model in the delivered flow.

## Product invariants

- The model proposes; app code decides. The model never writes to storage. Validate amount, category, date, and kind independently.
- Never invent an amount. If none was spoken, or the proposed amount isn't supported by the transcript, ask back by voice instead of saving.
- Categories come from the fixed set in the spec; unknown maps to Other. Money is stored as integer cents, USD.
- Resolve relative dates and week boundaries in app code against the captured request time.
- Expenses auto-save with Undo and tap-to-edit (user decision). Repeated taps, retries, and stale model responses must not create duplicate entries. Stretch features that create Apple Reminders keep explicit confirmation.
- Nudges state only numbers computed from stored data, and fire once per threshold.
- Keep speech and inference cancellable and off the UI thread. No continuous background listening.
- Offline means the full flow works without Wi-Fi, cellular, or the Mac after assets are provisioned. Prove it after a cold launch on the real iPhone.
- Never show "on-device" or "private" claims the app can't back up; never present mock or seeded data as the user's real spending.

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
