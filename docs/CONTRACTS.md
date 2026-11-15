# Contracts

How a spoken sentence becomes stored data. Types live in `app/YapLater/Domain/`; JSON shapes in `contracts/`.

## 1. Request (app-owned)

`InterpretationRequest`: `id`, `transcript`, `referenceInstant`, `timeZoneID`, `localeID`. The app owns the clock; the model is never asked what time it is. When the app has asked a question, the answer is appended to the earlier transcript ("Grabbed a coffee. Six fifty") and the whole thing is interpreted again.

## 2. Proposal (from the model, untrusted)

`MoneyProposal`, shaped by `contracts/money-proposal.schema.json` and forced by a grammar: `kind` (`expense`, `budget_set`, `reminder`, `unsupported`), `amount` (dollars as said, or null), `merchant`, `category` (one of nine, or null), `date_phrase`, `period`.

For `reminder`, a second model step returns `contracts/reminder-details.schema.json`: `title`, `day` (`today`, `tomorrow`, a weekday, or `date`), `day_of_month`, `month`, `hour`, `minute`, `in_minutes`, `amount`. The model copies what was said; it does not compute dates.

## 3. Validation (app code decides)

`ProposalValidator` and `ReminderResolver` return one `ValidationOutcome`:

- `expense(Entry)`: the amount must be one the transcript could mean (`AmountEvidence`: digits, number words, and spoken prices like "six fifty"), within $0.01 to $100,000. Unknown categories become Other. Dates like "yesterday", "two days ago", "on Friday" are resolved in code and are never in the future.
- `budgetSet(Budget)`: needs a known category and a said amount; weekly.
- `reminder(ReminderDraft)`: needs a title and a time. An hour from 1 to 11 with no morning/evening word asks "At 6, morning or evening?"; evening words move the hour in code. A day with no time defaults to 9:00 AM, shown on the card. Past times roll forward when no day was given, otherwise are refused.
- `askBack(question)`: something essential is missing. Spoken aloud; at most two questions per yap.
- `unsupported(message)`.

## 4. Storage and side effects

- Expenses auto-save through `LedgerStore.upsert` (idempotent per entry id; the id is the request id) with a six-second Undo and tap-to-edit. Money is integer cents, USD.
- Budgets: one per category, replaced on set.
- Nudges: `BudgetMath.nudge(before:after:)` fires only when a budget's level gets worse (fine → low → spent → over). Low is 25% of the limit left, or $50 for limits over $200. The message uses stored numbers only. Shown in the app, spoken, and posted as a notification.
- Reminders: nothing is written until the user taps Save on the card; then one `EKReminder` with due date components and an explicit `EKAlarm`. A second tap while saving is ignored. Saved reminders are listed under "Coming up" from a local log.

## 5. States

`AppModel.Phase`: idle → listening → transcribing → thinking → idle, asking(question), or failed(message). Cancelling or starting a new yap bumps a generation counter; late results are dropped.

## Change record

- 2026-11-15: v1 for the money pivot; replaces the reminders-only v0. Implemented and exercised on the iPhone 17 Pro; reminders verified by unit tests and the on-device model eval, not yet by a live voice run.
