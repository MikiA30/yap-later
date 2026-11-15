# Yap Later specification

Interviewed 2026-11-15, 03:15–03:30 EST. Labels: [User] = the user's explicit choice; [Proposal] = Claude's default, changeable; [Unverified] = not yet measured on the device.

## One line

**Talk to your money, privately.** Yap Later is a voice-first expense tracker that runs entirely on your iPhone: say "just spent like $50 on groceries" and it logs, categorizes, and checks it against your weekly budget, with no bank login, no account, and no network.

## Why (the pitch)

[User] People are wary of giving apps like Rocket Money access to their bank accounts. Yap Later keeps everything local, and you just speak to it. Privacy is a product feature, not a footnote: the model, the speech recognition, and the data all stay on the phone, and it works in airplane mode.

## Interview answers

- [User] **Deadline: 8:30 AM today** (about 5 hours from 03:30). Scope accordingly.
- [User] **Voice is the hero.** Hold-to-talk is the main input; typing is the backup. On-device speech via Argmax WhisperKit (hackathon sponsor) is must-have.
- [User] **Model:** try Bonsai (sponsor) inside the iPhone app; if it fails by the hard stop, fall back to Apple's on-device Foundation Models, labeled honestly.
- [User] **Money comes first.** Expenses, budgets, and nudges are the product. Bills and reminders are secondary ("we can also turn it into a reminder app"). Location nudges (near a Starbucks you overspend at) are stretch.
- [User] **One entry per yap first**, then a **ramble → several entries** once one works.
- [User] **Ambiguity is resolved by asking back by voice:** the app speaks a short question and you answer by holding to talk again.
- [User] **Must work live at 8:30:** yap an expense → auto-categorized → budget bar drops → "Only $50 left for Groceries this week" nudge.
- [User] **Auto-save + undo** for expenses: the entry saves immediately and animates into the ledger, with a few seconds to Undo or tap to edit. Bills/reminders (stretch) keep explicit confirmation.
- [User] **Budgets are weekly, per category.**
- [User] **Look and feel: playful and bold**, with UI/UX quality on the level of Duolingo or Spotify (inspiration only; no copying their branding, mascot, or colors). Use the `swiftui-motion` skill; visuals must be deliberate, not generic.
- [User] **Triggers:** in-app hold-to-talk, plus the iPhone 17 Pro **Action Button** via an App Intent.
- [User] **Demo data:** pre-log a realistic week through the app before the demo so the live yap tips a budget into the nudge. [Proposal] Enter it through the real app flow so it is genuinely real entries; the pitch does not describe data as the user's real spending unless it is.

## Core loop (must work at 8:30)

1. Hold the big button (or press the Action Button) and say: "Just spent like fifty bucks on groceries at Walmart."
2. WhisperKit transcribes on the phone; the transcript appears live.
3. The on-device model returns a structured proposal: kind `expense`, amount 50.00 USD, merchant "Walmart", category Groceries, date today.
4. App code validates it: the amount must be present and plausible, the category must come from the fixed set, and relative dates ("yesterday") are resolved in code against the captured request time.
5. If something essential is missing (no amount, can't tell the category), the app **asks back by voice** ("How much was it?") and you answer by holding to talk again.
6. The entry **auto-saves** and animates from the card into its category; Undo (5 s) and tap-to-edit are available.
7. The weekly Groceries budget bar drops. When the remaining amount falls to the nudge threshold or below, a bold in-app nudge appears, is spoken aloud, and is also posted as a local notification if the app is in the background: "Only $50 left for Groceries this week."

Also by voice: "Set my coffee budget to $25 a week" → creates or updates a weekly budget (kind `budget_set`).

## Scope

**Must-have by 8:30:** hold-to-talk with on-device transcription; on-device interpretation (Bonsai or labeled fallback); expense logging with fixed categories; weekly per-category budgets (set by voice or a simple editor); ledger and budget screens; auto-save + undo + edit; voice ask-back; the budget nudge (in-app, spoken, local notification); playful, bold visual identity and signature motion; airplane-mode proof on the real iPhone; README, pitch, video.

**Should-have (if on schedule):** Action Button App Intent; ramble → several entries; typed input fallback.

**Stretch (after the core):** bill reminders ("rent due on the 1st", via a confirmed Apple Reminder or local notification); location nudges near frequent merchants; model comparison.

**Out:** bank connections, accounts, cloud sync, receipts/OCR, multiple currencies, continuous background listening, investments.

## Product rules

- [Proposal] The model proposes; app code decides. The model never writes to storage directly. Amount, category, date, and kind are validated independently. Never invent an amount: if none was spoken, ask.
- [Proposal] The amount in the proposal must be supported by the transcript (digits or number words). If it isn't, ask back instead of saving.
- [Proposal] Categories (fixed): Groceries, Dining, Coffee, Transport, Shopping, Bills, Fun, Health, Other. Unknown → Other, never a new category.
- [Proposal] Currency USD only. Store money as integer cents.
- [Proposal] Week = Monday through Sunday (changed 2026-11-15 from the locale's Sunday start, so a weekend's spending counts against the week it ends). "Yesterday", "this morning", and weekday names are resolved in code against the request time.
- [Proposal] Nudge rule: after an entry, if a category's remaining weekly budget is ≤ 25% of its limit (or ≤ $50 for limits over $200), or over the limit, nudge once per category per threshold per week. The nudge text only uses stored data.
- [Proposal] Undo removes the entry completely and recomputes budgets; edits recompute too. No duplicate entries from repeated taps or retried inference.
- Offline means the full flow works with Wi-Fi and cellular off and the Mac disconnected, after cold launch. All model and speech assets are provisioned beforehand.
- Never show "On-device" or "Private" claims the app can't back up.

## Architecture (proposal)

SwiftUI app, one process, iOS 26, iPhone 17 Pro.

- `Services/Speech`: WhisperKit hold-to-talk; `AVSpeechSynthesizer` for spoken questions and nudges (on-device voices).
- `Services/Inference`: one `MoneyInterpreter` protocol; Bonsai implementation if gate G1 passes, Foundation Models implementation as fallback; a labeled mock for UI work.
- `Domain`: `MoneyProposal` (untrusted), `Validator`, `Entry`, `Budget`, `Category`, `Nudge` rules (pure Swift, unit-tested).
- `Store`: SwiftData for entries and budgets.
- `Features`: Yap (record/transcript/card), Ledger, Budgets, Nudge banner; `DesignSystem`: color, type, spacing, `Motion` tokens.
- `Intents`: Action Button App Intent that opens straight into listening.

Proposal JSON (from the model): `{ "kind": "expense" | "budget_set" | "unsupported", "amount": number|null, "merchant": string|null, "category": one of the fixed set|null, "date_phrase": string|null, "period": "week"|null, "question": string|null }`. `docs/CONTRACTS.md` is rewritten to this in T004.

## Demo (target 2–3 min)

1. Airplane mode on, shown. "No bank login, no cloud, and it's all on this phone."
2. Press the Action Button: "Just spent fifty bucks on groceries at Walmart." Card appears, flies into Groceries, bar drops, nudge: "Only $50 left for Groceries this week" (spoken).
3. Ambiguity: "Grabbed coffee" → app asks "How much was it?" → "Six fifty" → logged.
4. "Set my fun budget to forty a week" → new budget bar animates in.
5. Stretch, if built: ramble with three expenses → three cards; or a bill reminder.

## Acceptance

- The core loop works on the user's iPhone 17 Pro in airplane mode after a cold launch, with the Mac disconnected.
- Recorded: model and runtime identity (or fallback), WhisperKit version and model, transcription and interpretation latency.
- No entry is saved without a validated amount; ask-back fires for missing amounts.
- Undo and edit update budgets correctly; no duplicates.
- The nudge fires exactly once at the threshold and its numbers match stored data.
- Reduce Motion, dark mode, and large text are checked.

## Open

- Event rules: judging criteria, required sponsor use, public repo, video/slide requirements (T015).
- Whether Bonsai runs on the phone (G1); WhisperKit model size vs. speed on the phone (G4).
- Exact nudge threshold wording and the visual identity details (decided in T017 with the user's review).
